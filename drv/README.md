# CNC控制器PCIe驱动

## 概述

本驱动为CNC运动控制卡提供PCIe接口，实现Linux内核与CNC硬件之间的通信。支持位置读取、命令写入和I/O控制等功能。

## 目录结构

```
drv/
├── src/
│   ├── cnc_card.c      # 驱动主实现
│   ├── cnc.h           # CNC定义
│   └── cncdrive_cmd.h  # IOCTL命令定义
├── Makefile            # 编译配置
└── README.md           # 本文档
```

## 工作机制

### 1. 模块加载与PCI注册

驱动加载流程：

```
insmod cnc_card.ko
    ↓
cnc_driver_init()
    ↓
pci_register_driver(&cnc_pci_driver)
    ↓
内核PCI子系统扫描匹配设备
    ↓
为每个匹配设备调用cnc_pci_probe()
```

**cnc_pci_probe()中的关键步骤：**

| 步骤 | 函数 | 描述 |
|------|----------|-------------|
| 1 | `devm_kzalloc()` | 分配设备数据结构（自动释放） |
| 2 | `pcim_enable_device()` | 启用PCI设备 |
| 3 | `pci_set_master()` | 开启Bus Master以支持DMA |
| 4 | `pcim_iomap_regions()` | 映射BAR0（I/O）和BAR1（内存） |
| 5 | `pci_set_dma_mask()` | 设置DMA掩码为32位 |
| 6 | `pci_enable_msi()` | 启用MSI中断（如支持） |
| 7 | `misc_register()` | 注册misc设备，创建 `/dev/cnc_card` |
| 8 | `devm_request_irq()` | 请求中断线 |

### 2. 设备数据结构

```c
struct cnc_device {
    struct pci_dev *pdev;           // PCI设备指针
    struct miscdevice miscdev;      // Misc设备结构
    
    void __iomem *mem_base;         // BAR1（内存区域）
    void __iomem *io_base;          // BAR0（I/O区域）
    
    u32 data_buf[1000];             // TX数据缓冲区
    unsigned int data_buf_count;    // TX缓冲区计数
    u32 pos_buf[34];                // RX位置缓冲区
    unsigned int pos_buf_count;     // RX缓冲区计数
    
    spinlock_t lock;                // 自旋锁（中断安全访问）
    struct mutex mutex;             // 互斥锁（文件操作）
    wait_queue_head_t write_wait;   // 写阻塞等待队列
    
    int irq;                        // 中断号
    bool use_msi;                   // MSI启用标志
    bool initialized;               // 设备初始化标志
    bool interrupt_enabled;         // 中断启用标志
};
```

### 3. 文件操作

驱动通过 `/dev/cnc_card` 暴露标准文件操作：

#### 打开/关闭

```
用户: open("/dev/cnc_card", O_RDWR)
    ↓
cnc_open()
    ↓
container_of(inode->i_cdev, ...)  // 获取设备指针
    ↓
filp->private_data = dev          // 保存供后续操作使用
```

#### 读取（位置获取）

```
用户: read(fd, buf, count)
    ↓
cnc_read()
    ↓
mutex_lock_interruptible()        // 保护共享数据
    ↓
cnc_update_position()             // 读取所有位置寄存器
    ↓
copy_to_user()                    // 复制数据到用户空间
    ↓
mutex_unlock()
    ↓
返回读取的字节数
```

**位置缓冲区布局（34个32位寄存器）：**

| 索引 | 寄存器 | 描述 |
|-------|----------|-------------|
| 0-3 | POS_X/Y/Z/A | 当前位置（4轴） |
| 4-7 | POS_X0/Y0/Z0/A0 | 参考位置 |
| 8-11 | POS_X1/Y1/Z1/A1 | 机械位置 |
| 12 | AUX_DATA | 辅助数据 |
| 13 | AUX_CTRL | 辅助控制 |
| 14-15 | POS_Z2/A2 | 断点位置 |
| 16 | DCSR | 设备控制状态 |
| 17-20 | SPD_X/Y/Z/A | 速度（4轴） |
| 21-24 | CARD_POS_X/Y/Z/A | 卡位置 |
| 25-28 | CARD_POS_X0/Y0/Z0/A0 | 卡参考位置 |
| 29-32 | CARD_POS_X1/Y1/Z1/A1 | 卡机械位置 |
| 33 | AUX_DATA | 辅助数据 |

#### 写入（命令发送）

```
用户: write(fd, buf, count)
    ↓
cnc_write()
    ↓
mutex_lock_interruptible()        // 保护共享数据
    ↓
while (data_buf_count >= 1000)    // 等待缓冲区空间
    ↓
    wait_event_interruptible()    // 阻塞直到中断发送数据
    ↓
copy_from_user()                  // 从用户空间复制数据
    ↓
data_buf_count += words_to_copy   // 更新缓冲区计数
    ↓
mutex_unlock()
    ↓
返回写入的字节数
```

**缓冲区管理：**
- 缓冲区最多容纳1000个32位字
- 缓冲区满时通过中断发送数据到硬件
- 缓冲区满时写操作会阻塞（除非使用O_NONBLOCK）

#### IOCTL（控制命令）

```
用户: ioctl(fd, CMD, arg)
    ↓
cnc_ioctl()
    ↓
_IOC_TYPE(cmd) != TEST_MAGIC → -EINVAL
    ↓
_IOC_NR(cmd) > TEST_MAX_NR → -EINVAL
    ↓
switch(cmd)
    ↓
cnc_writel(dev, value, register)  // 写入硬件寄存器
```

**支持的IOCTL命令：**

| 类别 | 命令 | 目标寄存器 |
|----------|----------|-----------------|
| 轴使能 | AXIS1_ON/OFF ... AXIS8_ON/OFF | AXISx_CTRL_REG |
| 方向控制 | XP/YP/ZP/AP_ON/OFF, XN/YN/ZN/AN_ON/OFF | XP/YP/ZP/AP/XN/YN/ZN/AN_CTRL_REG |
| 回零控制 | RETURN0_ON/OFF | RETURN0_REG |
| 冷却液 | COOLANT_ON/OFF | COOLANT_REG |
| 主轴 | SPINDLE_POS/REV/STOP | SPINDLE_POS/REV_REG |
| 辅助控制 | SET_ON/OFF, MAG_ON/OFF/GO/BACK, LOOSE_ON/OFF | AUX_CTRL_REG |
| 换刀控制 | TOOL_1 ... TOOL_8 | AUX_CTRL_REG |

### 4. 中断处理

```
硬件中断
    ↓
cnc_interrupt()
    ↓
spin_lock(&dev->lock)             // 自旋锁（中断上下文）
    ↓
读取INTCSR_REG → status
    ↓
if (status != INT_ACTIVE) → IRQ_NONE
    ↓
cnc_writel(INT_DISABLE)           // 禁用中断
    ↓
cnc_send_data()                   // 发送缓冲数据到硬件
    ↓
cnc_writel(INT_ENABLE)            // 重新启用中断
    ↓
spin_unlock(&dev->lock)
    ↓
wake_up_interruptible(&write_wait) // 唤醒等待中的write()
    ↓
返回IRQ_HANDLED
```

**数据发送流程：**
```c
cnc_send_data()
    ↓
for (i = 0; i < 1000; i++)
    cnc_writel(dev, data_buf[i], PCTOCARD_REG)
    ↓
data_buf_count = 0
    ↓
wake_up_interruptible(&write_wait)
```

### 5. Sysfs接口

驱动通过sysfs暴露监控属性：

```
/sys/class/misc/cnc_card/
├── version        (只读)  → 驱动版本和发布日期
├── position       (只读)  → 当前X/Y/Z/A位置
├── status         (只读)  → DCSR寄存器值、中断/MSI状态
└── debug_level    (读写)  → 调试级别(0-255)
```

**使用示例：**
```bash
cat /sys/class/misc/cnc_card/position
# 输出: X:1234 Y:5678 Z:9012 A:0

cat /sys/class/misc/cnc_card/status
# 输出: DCSR:0x00000003 INT:enabled MSI:yes

echo 5 > /sys/class/misc/cnc_card/debug_level
```

### 6. 模块卸载

```
rmmod cnc_card
    ↓
cnc_driver_exit()
    ↓
pci_unregister_driver()
    ↓
为每个设备调用cnc_pci_remove()
    ↓
cnc_writel(INT_DISABLE)           // 禁用中断
    ↓
misc_deregister()                 // 移除 /dev/cnc_card
    ↓
pci_disable_msi()                 // 禁用MSI（如启用）
```

## 数据流

### TX数据流（用户→硬件）

```
用户空间                        内核空间                      硬件
──────────                      ────────────                      ────────
write()                          │                                   │
    │                            │                                   │
    ↓                            ↓                                   │
copy_from_user()             data_buf[]                            │
    │                            │                                   │
    │                            │ data_buf_count >= 1000?           │
    │                            │       │                           │
    │                            │       ↓ (通过中断)                │
    │                            │   cnc_send_data()                 │
    │                            │       │                           │
    │                            │       ↓                           │
    │                            │  cnc_writel() → PCTOCARD_REG      │
    │                            │       │                           │
    ↓                            ↓       ↓                           ↓
return bytes                data_buf_count = 0               硬件接收数据
```

### RX数据流（硬件→用户）

```
用户空间                        内核空间                      硬件
──────────                      ────────────                      ────────
read()                           │                                   │
    │                            │                                   │
    ↓                            ↓                                   │
                                cnc_update_position()               │
                                    │                               │
                                    ↓ (34个寄存器)                   │
                                cnc_readl() ← POS_X_REG             │
                                cnc_readl() ← POS_Y_REG             │
                                cnc_readl() ← POS_Z_REG             │
                                ...                                 │
                                    │                               │
                                    ↓                               │
                                pos_buf[]                           │
                                    │                               │
                                    ↓                               │
copy_to_user()                    │                                   │
    │                            │                                   │
    ↓                            ↓                                   ↓
用户接收                  return bytes                            (来自硬件的数据)
位置数据
```

## 架构

### 驱动层次

```
┌─────────────────────────────────────────────────────────────┐
│                      用户空间                                 │
│  应用程序、CNC控制软件、诊断工具                               │
└───────────────────┬─────────────────────────────────────────┘
                    │ read/write/ioctl
                    ↓
┌─────────────────────────────────────────────────────────────┐
│                   Linux内核                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              文件操作层                                 │  │
│  │  cnc_open / cnc_release / cnc_read / cnc_write        │  │
│  │  cnc_ioctl                                             │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              PCI子系统层                               │  │
│  │  cnc_pci_probe / cnc_pci_remove                       │  │
│  │  pci_set_master / pcim_iomap_regions                  │  │
│  │  pci_enable_msi / pci_set_dma_mask                    │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              中断处理层                                 │  │
│  │  cnc_interrupt / cnc_send_data                        │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Sysfs接口                                 │  │
│  │  version / position / status / debug_level            │  │
│  └───────────────────────────────────────────────────────┘  │
└───────────────────┬─────────────────────────────────────────┘
                    │ PCIe BAR0/BAR1访问
                    ↓
┌─────────────────────────────────────────────────────────────┐
│                    CNC控制器硬件                             │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │   位置寄存器     │  │   命令寄存器     │                   │
│  │  POS_X/Y/Z/A    │  │  AXISx_CTRL     │                   │
│  │  SPD_X/Y/Z/A    │  │  XP/YP/ZP_CTRL  │                   │
│  │  CARD_POS_*     │  │  COOLANT        │                   │
│  │                 │  │  SPINDLE        │                   │
│  └─────────────────┘  └─────────────────┘                   │
│                           │                                  │
│                           ↓                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              运动控制逻辑                                │  │
│  │  电机驱动、编码器反馈、回零控制                          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 同步机制

| 机制 | 作用域 | 用途 |
|-----------|-------|-------|
| `spinlock_t lock` | 中断上下文 | 保护中断期间的data_buf和pos_buf |
| `struct mutex mutex` | 进程上下文 | 保护文件操作（read/write） |
| `wait_queue_head_t write_wait` | 进程上下文 | 缓冲区满时阻塞write() |

## PCI资源

| BAR | 类型 | 大小 | 用途 |
|-----|------|------|-------|
| BAR0 | I/O | 4KB | 传统I/O访问 |
| BAR1 | 内存 | 4MB | 寄存器访问 |

**厂商/设备ID：**
- Vendor ID: `0x1172`
- Device ID: `0x4258`
- Subsystem Vendor ID: `0x1172`
- Subsystem Device ID: `0x4258`

## 编译与安装

### 前提条件

- Linux内核源码头文件
- GCC编译器
- 具有匹配Vendor/Device ID的PCIe硬件

### 编译

```bash
cd drv
make
```

### 安装

```bash
insmod cnc_card.ko
```

### 验证

```bash
lsmod | grep cnc_card
cat /proc/devices | grep cnc_card
ls -la /dev/cnc_card
```

## 测试

### 基础测试

```bash
# 读取位置数据
dd if=/dev/cnc_card of=position.bin bs=136 count=1

# 写入命令数据
echo -n -e '\x01\x00\x00\x00' > /dev/cnc_card

# 检查sysfs属性
cat /sys/class/misc/cnc_card/position
cat /sys/class/misc/cnc_card/status
```

### 调试

```bash
# 启用调试消息
echo 5 > /sys/class/misc/cnc_card/debug_level

# 检查内核日志
dmesg | grep -i cnc
```

## 特性

- **Miscdevice接口**：简化字符设备注册
- **PCIe BAR映射**：内存和I/O区域映射，自动清理
- **MSI中断支持**：消息信号中断，提高性能
- **Sysfs监控**：实时位置和状态监控
- **DMA支持**：32位DMA掩码，支持高速数据传输
- **设备树支持**：兼容使用设备树的嵌入式平台
- **平台数据**：通过平台数据配置设备参数

## 兼容性

- Linux内核4.15+
- PCIe Gen1 x4接口
- Vendor ID 0x1172、Device ID 0x4258的CNC运动控制卡

## 许可证

GPL-2.0

## 作者

F_T
