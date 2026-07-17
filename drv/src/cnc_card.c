#include <linux/init.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/fs.h>
#include <linux/types.h>
#include <linux/errno.h>
#include <linux/mm.h>
#include <linux/slab.h>
#include <linux/sched/signal.h>
#include <linux/cdev.h>
#include <linux/kdev_t.h>
#include <linux/uaccess.h>
#include <linux/io.h>
#include <linux/spinlock.h>
#include <linux/delay.h>
#include <linux/interrupt.h>
#include <linux/irq.h>
#include <linux/semaphore.h>
#include <linux/mutex.h>
#include <linux/device.h>
#include "cnc.h"
#include "cncdrive_cmd.h"

/** 设备名称，用于注册字符设备和PCI驱动 */
#define DEVICENAME "cnc_card"
/** 设备类名称，用于创建设备节点 */
#define CLASS_NAME "cnc_card_class"
/** PCIe设备厂商ID */
#define PCI_VENDOR_ID_CNC 0x1172
/** PCIe设备产品ID */
#define PCI_DEVICE_ID_CNC 0x4258

/** 发送缓冲区大小（32位字） */
#define BUF_SIZE 1000
/** 位置数据缓冲区大小（32位字） */
#define POS_SIZE 34

/** 中断控制寄存器偏移地址 */
#define INTCSR_V_MEM_ADDR 0x01
/** PC到卡的数据寄存器偏移地址 */
#define PCTOCARD_V_MEM_ADDR 0x05

struct cnc_dev_t {
    struct pci_dev *pdev;        /**< PCI设备指针，用于访问PCI配置空间 */
    struct cdev cdev;            /**< 字符设备结构体，用于注册字符设备操作接口 */
    dev_t devt;                  /**< 设备号（主设备号+次设备号） */
    struct class *cls;           /**< 设备类指针，用于创建设备节点 */
    struct device *device;       /**< 设备节点指针 */

    u32 data_buf[BUF_SIZE];      /**< 发送缓冲区，存储待发送到FPGA的插补数据 */
    int current_buf_num;         /**< 发送缓冲区当前待发送数据数量 */

    u32 pos_data_buf[POS_SIZE]; /**< 位置数据缓冲区，存储从FPGA读取的位置信息 */
    int current_pos_buf_num;     /**< 位置数据缓冲区当前数据数量 */

    u32 irq;                     /**< 中断号 */

    u32 iobase;                  /**< IO端口空间物理基地址 */
    u32 io_size;                 /**< IO端口空间大小 */
    u32 membase;                 /**< 内存空间物理基地址 */
    u32 mem_size;                /**< 内存空间大小 */

    void __iomem *mem_addr;      /**< 内存空间映射后的内核虚拟地址 */
    void __iomem *io_addr;       /**< IO端口空间映射后的内核虚拟地址 */

    spinlock_t lock;             /**< 自旋锁，保护中断处理中的临界区 */
    struct mutex mutex;          /**< 互斥锁，保护所有用户态操作（读/写/ioctl） */
    wait_queue_head_t w_wait;    /**< 写等待队列头，用于阻塞式写操作 */
};

/** 全局设备指针，用于中断处理和ioctl操作 */
static struct cnc_dev_t *cnc_dev;

/**
 * @brief PCI设备ID表
 *
 * 定义驱动支持的PCI设备列表，内核通过此表匹配PCI设备并调用probe函数。
 */
static struct pci_device_id cnc_pci_tbl[] = {
    {PCI_DEVICE(PCI_VENDOR_ID_CNC, PCI_DEVICE_ID_CNC), 0},
    {0}  /**< 终止符 */
};
MODULE_DEVICE_TABLE(pci, cnc_pci_tbl);

static void pos_readfrom_card(struct cnc_dev_t *dev)
{
    u32 aux_data, aux_ctl;                    /**< 刀库数据和控制寄存器 */
    u32 pos_x, pos_y, pos_z, pos_a;          /**< X/Y/Z/A轴编码器当前计数值 */
    u32 pos_x0, pos_y0, pos_z0, pos_a0;      /**< X/Y/Z/A轴参考点编码器值 */
    u32 pos_x1, pos_y1, pos_z1, pos_a1;      /**< X/Y/Z/A轴机床坐标系坐标 */
    u32 pos_x2, pos_y2, pos_z2, pos_a2;      /**< X/Y/Z/A轴断点位置 */
    u32 dcsr;                                 /**< 设备控制状态寄存器 */
    u32 spd_x, spd_y, spd_z, spd_a;          /**< X/Y/Z/A轴速度寄存器 */
    u32 card_pos_x, card_pos_y, card_pos_z, card_pos_a;      /**< 卡模块编码器值 */
    u32 card_pos_x0, card_pos_y0, card_pos_z0, card_pos_a0;  /**< 卡模块参考点值 */
    u32 card_pos_x1, card_pos_y1, card_pos_z1, card_pos_a1;  /**< 卡模块机床坐标 */

    /* 读取刀库数据寄存器 */
    aux_data = ioread32(dev->mem_addr + 0x2a);
    aux_ctl = ioread32(dev->mem_addr + 0x2b);

    /* 读取各轴编码器当前计数值 */
    pos_x = ioread32(dev->mem_addr + 0x08);
    pos_y = ioread32(dev->mem_addr + 0x09);
    pos_z = ioread32(dev->mem_addr + 0x0a);
    pos_a = ioread32(dev->mem_addr + 0x0b);

    /* 读取各轴参考点编码器值 */
    pos_x0 = ioread32(dev->mem_addr + 0x0c);
    pos_y0 = ioread32(dev->mem_addr + 0x0d);
    pos_z0 = ioread32(dev->mem_addr + 0x0e);
    pos_a0 = ioread32(dev->mem_addr + 0x0f);

    /* 读取各轴机床坐标系坐标 */
    pos_x1 = ioread32(dev->mem_addr + 0x10);
    pos_y1 = ioread32(dev->mem_addr + 0x11);
    pos_z1 = ioread32(dev->mem_addr + 0x12);
    pos_a1 = ioread32(dev->mem_addr + 0x13);

    /* 读取各轴断点位置 */
    pos_x2 = ioread32(dev->mem_addr + 0x14);
    pos_y2 = ioread32(dev->mem_addr + 0x15);
    pos_z2 = ioread32(dev->mem_addr + 0x16);
    pos_a2 = ioread32(dev->mem_addr + 0x17);

    /* 读取设备控制状态寄存器 */
    dcsr = ioread32(dev->mem_addr + 0x06);

    /* 读取卡模块编码器值 */
    card_pos_x = ioread32(dev->mem_addr + 0x30);
    card_pos_y = ioread32(dev->mem_addr + 0x31);
    card_pos_z = ioread32(dev->mem_addr + 0x32);
    card_pos_a = ioread32(dev->mem_addr + 0x33);

    /* 读取卡模块参考点值 */
    card_pos_x0 = ioread32(dev->mem_addr + 0x38);
    card_pos_y0 = ioread32(dev->mem_addr + 0x39);
    card_pos_z0 = ioread32(dev->mem_addr + 0x3a);
    card_pos_a0 = ioread32(dev->mem_addr + 0x3b);

    /* 读取卡模块机床坐标 */
    card_pos_x1 = ioread32(dev->mem_addr + 0x40);
    card_pos_y1 = ioread32(dev->mem_addr + 0x41);
    card_pos_z1 = ioread32(dev->mem_addr + 0x42);
    card_pos_a1 = ioread32(dev->mem_addr + 0x43);

    /* 读取各轴速度寄存器 */
    spd_x = ioread32(dev->mem_addr + 0x34);
    spd_y = ioread32(dev->mem_addr + 0x35);
    spd_z = ioread32(dev->mem_addr + 0x36);
    spd_a = ioread32(dev->mem_addr + 0x37);

    /* 将读取的数据存入位置数据缓冲区 */
    dev->pos_data_buf[0] = pos_x;
    dev->pos_data_buf[1] = pos_y;
    dev->pos_data_buf[2] = pos_z;
    dev->pos_data_buf[3] = pos_a;

    dev->pos_data_buf[4] = pos_x0;
    dev->pos_data_buf[5] = pos_y0;
    dev->pos_data_buf[6] = pos_z0;
    dev->pos_data_buf[7] = pos_a0;

    dev->pos_data_buf[8] = pos_x1;
    dev->pos_data_buf[9] = pos_y1;
    dev->pos_data_buf[10] = pos_z1;
    dev->pos_data_buf[11] = pos_a1;

    dev->pos_data_buf[12] = aux_data;
    dev->pos_data_buf[13] = aux_ctl;
    dev->pos_data_buf[14] = pos_z2;
    dev->pos_data_buf[15] = pos_a2;

    dev->pos_data_buf[16] = dcsr;

    dev->pos_data_buf[17] = spd_x;
    dev->pos_data_buf[18] = spd_y;
    dev->pos_data_buf[19] = spd_z;
    dev->pos_data_buf[20] = spd_a;

    dev->pos_data_buf[21] = card_pos_x;
    dev->pos_data_buf[22] = card_pos_y;
    dev->pos_data_buf[23] = card_pos_z;
    dev->pos_data_buf[24] = card_pos_a;

    dev->pos_data_buf[25] = card_pos_x0;
    dev->pos_data_buf[26] = card_pos_y0;
    dev->pos_data_buf[27] = card_pos_z0;
    dev->pos_data_buf[28] = card_pos_a0;

    dev->pos_data_buf[29] = card_pos_x1;
    dev->pos_data_buf[30] = card_pos_y1;
    dev->pos_data_buf[31] = card_pos_z1;
    dev->pos_data_buf[32] = card_pos_a1;

    dev->pos_data_buf[33] = aux_data;

    /* 更新位置数据缓冲区数据数量 */
    dev->current_pos_buf_num = 34;
}

static ssize_t cnc_read(struct file *filp, char __user *user_data_buf, size_t size, loff_t *ppos)
{
    int ret;
    struct cnc_dev_t *dev = filp->private_data;  /**< 获取设备私有数据 */
    int count;

    (void)ppos;                                  /**< 未使用文件偏移量 */

    mutex_lock(&dev->mutex);                     /**< 获取互斥锁，保护并发访问 */
    count = size / sizeof(u32);                  /**< 计算32位字数量 */

    pos_readfrom_card(dev);                      /**< 从FPGA卡读取位置数据 */

    /* 检查请求读取的数量是否超出缓冲区容量 */
    if (count > dev->current_pos_buf_num) {
        count = dev->current_pos_buf_num;
    }

    /* 将数据从内核空间拷贝到用户空间 */
    if (copy_to_user(user_data_buf, dev->pos_data_buf, count * sizeof(u32))) {
        printk(KERN_ERR "cnc_card: copy_to_user failed.\n");
        ret = -EFAULT;
        goto out;
    }

    ret = count * sizeof(u32);                   /**< 返回实际读取的字节数 */

out:
    mutex_unlock(&dev->mutex);                   /**< 释放互斥锁 */
    return ret;
}

static ssize_t cnc_write(struct file *filp, const char __user *data_buf, size_t size, loff_t *ppos)
{
    int ret;
    int count;
    struct cnc_dev_t *dev = filp->private_data;  /**< 获取设备私有数据 */
    DECLARE_WAITQUEUE(wait, current);            /**< 定义等待队列项 */

    (void)ppos;                                  /**< 未使用文件偏移量 */

    /* 获取互斥锁（可中断），与read/ioctl共享同一把锁 */
    ret = mutex_lock_interruptible(&dev->mutex);
    if (ret)
        return ret;

    add_wait_queue(&dev->w_wait, &wait);         /**< 将当前进程加入等待队列 */

    /* 如果发送缓冲区已满 */
    if (dev->current_buf_num == BUF_SIZE) {
        /* 如果是非阻塞访问，直接返回 */
        if (filp->f_flags & O_NONBLOCK) {
            ret = -EAGAIN;
            goto out;
        }

        __set_current_state(TASK_INTERRUPTIBLE); /**< 将进程状态设置为可中断睡眠 */
        mutex_unlock(&dev->mutex);               /**< 释放互斥锁 */

        schedule();                              /**< 调度其他进程执行 */

        /* 如果是因为信号唤醒 */
        if (signal_pending(current)) {
            ret = -ERESTARTSYS;
            goto out2;
        }

        /* 重新获取互斥锁（可中断） */
        ret = mutex_lock_interruptible(&dev->mutex);
        if (ret)
            goto out2;
    }

    /* 计算实际可写入的32位字数量 */
    count = size / sizeof(dev->data_buf[0]);
    if (count > (BUF_SIZE - dev->current_buf_num)) {
        count = BUF_SIZE - dev->current_buf_num;
    }

    /* 将数据从用户空间拷贝到内核缓冲区（追加到已有数据之后） */
    if (copy_from_user(dev->data_buf + dev->current_buf_num, data_buf, count * sizeof(dev->data_buf[0]))) {
        ret = -EFAULT;
        goto out;
    } else {
        dev->current_buf_num += count;           /**< 更新缓冲区数据数量 */
        ret = count * sizeof(dev->data_buf[0]);  /**< 返回实际写入的字节数 */
    }

out:
    mutex_unlock(&dev->mutex);                   /**< 释放互斥锁 */
out2:
    remove_wait_queue(&dev->w_wait, &wait);      /**< 从等待队列移除 */
    set_current_state(TASK_RUNNING);             /**< 设置进程状态为运行 */
    return ret;
}

static void data_send(struct cnc_dev_t *dev)
{
    int i;

    /* 只有当缓冲区满时才发送数据 */
    if (dev->current_buf_num == BUF_SIZE) {
        /* 将缓冲区中的数据逐个写入FPGA卡的数据寄存器 */
        for (i = 0; i < BUF_SIZE; i++) {
            iowrite32(dev->data_buf[i], dev->mem_addr + PCTOCARD_V_MEM_ADDR);
        }

        dev->current_buf_num = 0;                /**< 清空缓冲区计数 */
        wake_up_interruptible(&dev->w_wait);     /**< 唤醒等待队列中的进程 */
    }
}

static irqreturn_t cnc_interrupt(int irq, void *dev_id)
{
    struct cnc_dev_t *dev = (struct cnc_dev_t *)dev_id;
    u32 status;

    spin_lock(&dev->lock);                       /**< 获取自旋锁，保护中断临界区 */

    /* 读取中断状态寄存器 */
    status = ioread32(dev->mem_addr + INTCSR_V_MEM_ADDR);
    /* 检查是否为本设备的中断 */
    if (status != 0x00000003) {
        spin_unlock(&dev->lock);
        return IRQ_NONE;
    }

    /* 关闭PCI中断（清除中断标志） */
    iowrite32(0x00000000, dev->mem_addr + INTCSR_V_MEM_ADDR);

    /* 将缓冲区数据发送到FPGA卡 */
    data_send(dev);

    /* 重新使能PCI中断 */
    iowrite32(0x00000002, dev->mem_addr + INTCSR_V_MEM_ADDR);

    spin_unlock(&dev->lock);                     /**< 释放自旋锁 */
    return IRQ_HANDLED;                          /**< 中断已处理 */
}

static long cnc_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
    int ret = 0;
    struct cnc_dev_t *dev = filp->private_data;  /**< 获取设备私有数据 */

    /* 验证命令幻数是否正确 */
    if (_IOC_TYPE(cmd) != TEST_MAGIC)
        return -EINVAL;

    /* 验证命令序号是否在有效范围内 */
    if (_IOC_NR(cmd) > TEST_MAX_NR)
        return -EINVAL;

    mutex_lock(&dev->mutex);                     /**< 获取互斥锁，保护硬件访问 */

    /* 根据命令类型执行相应操作 */
    switch (cmd) {
    case AXIS1_ON:                               /**< 轴1使能 */
        iowrite32(0x00000001, dev->mem_addr + 0x18);
        break;
    case AXIS2_ON:                               /**< 轴2使能 */
        iowrite32(0x00000001, dev->mem_addr + 0x19);
        break;
    case AXIS3_ON:                               /**< 轴3使能 */
        iowrite32(0x00000001, dev->mem_addr + 0x1A);
        break;
    case AXIS4_ON:                               /**< 轴4使能 */
        iowrite32(0x00000001, dev->mem_addr + 0x1B);
        break;
    case AXIS5_ON:                               /**< 轴5使能 */
        iowrite32(0x00000001, dev->mem_addr + 0x1C);
        break;
    case AXIS6_ON:                               /**< 轴6使能 */
        iowrite32(0x00000001, dev->mem_addr + 0x1D);
        break;
    case AXIS7_ON:                               /**< 轴7使能 */
        iowrite32(0x00000001, dev->mem_addr + 0x1E);
        break;
    case AXIS8_ON:                               /**< 轴8使能 */
        iowrite32(0x00000001, dev->mem_addr + 0x1F);
        break;
    case AXIS1_OFF:                              /**< 轴1禁用 */
        iowrite32(0x00000000, dev->mem_addr + 0x18);
        break;
    case AXIS2_OFF:                              /**< 轴2禁用 */
        iowrite32(0x00000000, dev->mem_addr + 0x19);
        break;
    case AXIS3_OFF:                              /**< 轴3禁用 */
        iowrite32(0x00000000, dev->mem_addr + 0x1A);
        break;
    case AXIS4_OFF:                              /**< 轴4禁用 */
        iowrite32(0x00000000, dev->mem_addr + 0x1B);
        break;
    case AXIS5_OFF:                              /**< 轴5禁用 */
        iowrite32(0x00000000, dev->mem_addr + 0x1C);
        break;
    case AXIS6_OFF:                              /**< 轴6禁用 */
        iowrite32(0x00000000, dev->mem_addr + 0x1D);
        break;
    case AXIS7_OFF:                              /**< 轴7禁用 */
        iowrite32(0x00000000, dev->mem_addr + 0x1E);
        break;
    case AXIS8_OFF:                              /**< 轴8禁用 */
        iowrite32(0x00000000, dev->mem_addr + 0x1F);
        break;
    case XP_ON:                                  /**< X轴正向运动 */
        iowrite32(0x00000001, dev->mem_addr + 0x20);
        break;
    case XN_ON:                                  /**< X轴负向运动 */
        iowrite32(0x00000001, dev->mem_addr + 0x24);
        break;
    case YP_ON:                                  /**< Y轴正向运动 */
        iowrite32(0x00000001, dev->mem_addr + 0x21);
        break;
    case YN_ON:                                  /**< Y轴负向运动 */
        iowrite32(0x00000001, dev->mem_addr + 0x25);
        break;
    case ZP_ON:                                  /**< Z轴正向运动 */
        iowrite32(0x00000001, dev->mem_addr + 0x22);
        break;
    case ZN_ON:                                  /**< Z轴负向运动 */
        iowrite32(0x00000001, dev->mem_addr + 0x26);
        break;
    case AP_ON:                                  /**< A轴正向运动 */
        iowrite32(0x00000001, dev->mem_addr + 0x23);
        break;
    case AN_ON:                                  /**< A轴负向运动 */
        iowrite32(0x00000001, dev->mem_addr + 0x27);
        break;
    case XP_OFF:                                 /**< X轴正向停止 */
        iowrite32(0x00000000, dev->mem_addr + 0x20);
        break;
    case XN_OFF:                                 /**< X轴负向停止 */
        iowrite32(0x00000000, dev->mem_addr + 0x24);
        break;
    case YP_OFF:                                 /**< Y轴正向停止 */
        iowrite32(0x00000000, dev->mem_addr + 0x21);
        break;
    case YN_OFF:                                 /**< Y轴负向停止 */
        iowrite32(0x00000000, dev->mem_addr + 0x25);
        break;
    case ZP_OFF:                                 /**< Z轴正向停止 */
        iowrite32(0x00000000, dev->mem_addr + 0x22);
        break;
    case ZN_OFF:                                 /**< Z轴负向停止 */
        iowrite32(0x00000000, dev->mem_addr + 0x26);
        break;
    case AP_OFF:                                 /**< A轴正向停止 */
        iowrite32(0x00000000, dev->mem_addr + 0x23);
        break;
    case AN_OFF:                                 /**< A轴负向停止 */
        iowrite32(0x00000000, dev->mem_addr + 0x27);
        break;
    case RETURN0_ON:                             /**< 回零使能 */
        iowrite32(0x00000001, dev->mem_addr + 0x28);
        break;
    case RETURN0_OFF:                            /**< 回零禁用 */
        iowrite32(0x00000000, dev->mem_addr + 0x28);
        break;
    case COOLANT_ON:                             /**< 冷却液开启 */
        iowrite32(0x00000001, dev->mem_addr + 0x44);
        break;
    case COOLANT_OFF:                            /**< 冷却液关闭 */
        iowrite32(0x00000000, dev->mem_addr + 0x44);
        break;
    case SPINDLE_POS:                            /**< 主轴正转 */
        iowrite32(0x00000001, dev->mem_addr + 0x45);
        break;
    case SPINDLE_REV:                            /**< 主轴反转 */
        iowrite32(0x00000001, dev->mem_addr + 0x46);
        break;
    case SPINDLE_STOP:                           /**< 主轴停止 */
        iowrite32(0x00000000, dev->mem_addr + 0x45);
        iowrite32(0x00000000, dev->mem_addr + 0x46);
        break;
    case AUX_CLR:                                /**< 辅助寄存器清零 */
        iowrite32(0x00000000, dev->mem_addr + 0x2B);
        break;
    case SET_ON:                                 /**< 对刀仪使能 */
        iowrite32(0x00000002, dev->mem_addr + 0x2B);
        break;
    case SET_OFF:                                /**< 对刀仪禁用 */
        iowrite32(0x00000003, dev->mem_addr + 0x2B);
        break;
    case MAG_ON:                                 /**< 刀库使能 */
        iowrite32(0x00000004, dev->mem_addr + 0x2B);
        break;
    case MAG_OFF:                                /**< 刀库禁用 */
        iowrite32(0x00000005, dev->mem_addr + 0x2B);
        break;
    case MAG_GO:                                 /**< 刀库前进 */
        iowrite32(0x00000006, dev->mem_addr + 0x2B);
        break;
    case MAG_BACK:                               /**< 刀库后退 */
        iowrite32(0x00000007, dev->mem_addr + 0x2B);
        break;
    case LOOSE_ON:                               /**< 主轴松刀 */
        iowrite32(0x00000008, dev->mem_addr + 0x2B);
        break;
    case LOOSE_OFF:                              /**< 主轴夹紧刀具 */
        iowrite32(0x00000009, dev->mem_addr + 0x2B);
        break;
    case TOOL_1:                                 /**< 选刀1号 */
        iowrite32(0x0000001A, dev->mem_addr + 0x2B);
        break;
    case TOOL_2:                                 /**< 选刀2号 */
        iowrite32(0x0000002A, dev->mem_addr + 0x2B);
        break;
    case TOOL_3:                                 /**< 选刀3号 */
        iowrite32(0x0000003A, dev->mem_addr + 0x2B);
        break;
    case TOOL_4:                                 /**< 选刀4号 */
        iowrite32(0x0000004A, dev->mem_addr + 0x2B);
        break;
    case TOOL_5:                                 /**< 选刀5号 */
        iowrite32(0x0000005A, dev->mem_addr + 0x2B);
        break;
    case TOOL_6:                                 /**< 选刀6号 */
        iowrite32(0x0000006A, dev->mem_addr + 0x2B);
        break;
    case TOOL_7:                                 /**< 选刀7号 */
        iowrite32(0x0000007A, dev->mem_addr + 0x2B);
        break;
    case TOOL_8:                                 /**< 选刀8号 */
        iowrite32(0x0000008A, dev->mem_addr + 0x2B);
        break;
    default:                                     /**< 未知命令 */
        ret = -EINVAL;
        break;
    }

    mutex_unlock(&dev->mutex);                   /**< 释放互斥锁 */
    return ret;
}

static int cnc_open(struct inode *inode, struct file *filp)
{
    struct cnc_dev_t *dev = container_of(inode->i_cdev, struct cnc_dev_t, cdev);
    filp->private_data = dev;
    return 0;
}

static int cnc_release(struct inode *inode, struct file *filp)
{
    return 0;
}

static const struct file_operations cnc_fops = {
    .owner = THIS_MODULE,        /**< 模块所有者，用于模块引用计数 */
    .write = cnc_write,          /**< 写操作函数 */
    .read = cnc_read,            /**< 读操作函数 */
    .open = cnc_open,            /**< 打开操作函数 */
    .release = cnc_release,      /**< 关闭操作函数 */
    .unlocked_ioctl = cnc_ioctl, /**< IO控制操作函数 */
};

/**
 * @brief PCI设备探测函数
 *
 * 当系统发现匹配的PCI设备时调用此函数，完成以下初始化工作：
 * 1. 分配设备私有数据结构
 * 2. 初始化同步机制
 * 3. 启用PCI设备并请求资源
 * 4. 映射BAR空间到内核虚拟地址
 * 5. 初始化硬件寄存器
 * 6. 注册字符设备并创建设备节点
 * 7. 注册中断处理函数
 *
 * @param pdev PCI设备指针
 * @param id PCI设备ID表项
 * @return 成功返回0，失败返回负错误码
 */
static int cnc_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
    int ret;
    struct cnc_dev_t *dev;

    /* 使用devm_kzalloc分配设备私有数据，支持自动释放 */
    dev = devm_kzalloc(&pdev->dev, sizeof(*dev), GFP_KERNEL);
    if (!dev)
        return -ENOMEM;

    dev->pdev = pdev;

    /* 初始化同步机制 */
    mutex_init(&dev->mutex);
    spin_lock_init(&dev->lock);
    init_waitqueue_head(&dev->w_wait);

    /* 启用PCI设备 */
    ret = pci_enable_device(pdev);
    if (ret) {
        printk(KERN_ERR "cnc_card: pci_enable_device failed.\n");
        return ret;
    }

    /* 请求BAR0（IO端口空间）资源 */
    ret = pci_request_region(pdev, 0, DEVICENAME);
    if (ret) {
        printk(KERN_ERR "cnc_card: cannot allocate io region.\n");
        goto err_pci_disable;
    }

    /* 请求BAR1（内存空间）资源 */
    ret = pci_request_region(pdev, 1, DEVICENAME);
    if (ret) {
        printk(KERN_ERR "cnc_card: cannot allocate mem region.\n");
        goto err_pci_release_io;
    }

    /* 获取BAR空间物理地址和大小,PCI域物理地址->存储域物理地址 */
    dev->iobase = pci_resource_start(pdev, 0);
    dev->io_size = pci_resource_len(pdev, 0);
    dev->membase = pci_resource_start(pdev, 1);
    dev->mem_size = pci_resource_len(pdev, 1);

    /* 映射BAR1（内存空间）到内核虚拟地址 */
    dev->mem_addr = pci_iomap(pdev, 1, dev->mem_size);
    if (!dev->mem_addr) {
        printk(KERN_ERR "cnc_card: cannot iomap mem region.\n");
        ret = -EIO;
        goto err_pci_release_mem;
    }

    /* 映射BAR0（IO端口空间）到内核虚拟地址 */
    dev->io_addr = pci_iomap(pdev, 0, dev->io_size);
    if (!dev->io_addr) {
        printk(KERN_ERR "cnc_card: cannot iomap io region.\n");
        ret = -EIO;
        goto err_iounmap_mem;
    }

    /* 初始化PCIe中断控制寄存器和数据寄存器 */
    iowrite32(0x00000002, dev->mem_addr + INTCSR_V_MEM_ADDR);
    iowrite32(0x00000000, dev->mem_addr + PCTOCARD_V_MEM_ADDR);

    /* 分配字符设备号 */
    ret = alloc_chrdev_region(&dev->devt, 0, 1, DEVICENAME);
    if (ret < 0) {
        printk(KERN_ERR "cnc_card: cannot allocate char dev region.\n");
        goto err_iounmap_io;
    }

    /* 初始化字符设备 */
    cdev_init(&dev->cdev, &cnc_fops);
    dev->cdev.owner = THIS_MODULE;

    /* 添加字符设备到内核 */
    ret = cdev_add(&dev->cdev, dev->devt, 1);
    if (ret) {
        printk(KERN_ERR "cnc_card: cannot add cdev.\n");
        goto err_unregister_chrdev;
    }

    /* 创建设备类 */
    dev->cls = class_create(THIS_MODULE, CLASS_NAME);
    if (IS_ERR(dev->cls)) {
        printk(KERN_ERR "cnc_card: cannot create class.\n");
        ret = PTR_ERR(dev->cls);
        goto err_cdev_del;
    }

    /* 在/dev目录下创建设备节点 */
    dev->device = device_create(dev->cls, NULL, dev->devt, NULL, DEVICENAME);
    if (IS_ERR(dev->device)) {
        printk(KERN_ERR "cnc_card: cannot create device.\n");
        ret = PTR_ERR(dev->device);
        goto err_class_destroy;
    }

    /* 获取PCI设备中断号 */
    dev->irq = pdev->irq;

    /* 注册中断处理函数 */
    ret = request_irq(dev->irq, cnc_interrupt, IRQF_SHARED, DEVICENAME, dev);
    if (ret) {
        printk(KERN_ERR "cnc_card: unable to allocate irq %d.\n", dev->irq);
        goto err_device_destroy;
    }

    /* 将设备私有数据保存到PCI设备中 */
    pci_set_drvdata(pdev, dev);
    cnc_dev = dev;

    printk(KERN_INFO "cnc_card: probe successful.\n");
    return 0;

/* 错误处理标签，按逆序释放已分配的资源 */
err_device_destroy:
    device_destroy(dev->cls, dev->devt);
err_class_destroy:
    class_destroy(dev->cls);
err_cdev_del:
    cdev_del(&dev->cdev);
err_unregister_chrdev:
    unregister_chrdev_region(dev->devt, 1);
err_iounmap_io:
    pci_iounmap(pdev, dev->io_addr);
err_iounmap_mem:
    pci_iounmap(pdev, dev->mem_addr);
err_pci_release_mem:
    pci_release_region(pdev, 1);
err_pci_release_io:
    pci_release_region(pdev, 0);
err_pci_disable:
    pci_disable_device(pdev);
    return ret;
}

/**
 * @brief PCI设备移除函数
 *
 * 当PCI设备被移除或驱动被卸载时调用此函数，完成以下清理工作：
 * 1. 释放中断
 * 2. 销毁设备节点和类
 * 3. 删除字符设备并注销设备号
 * 4. 解除BAR空间映射
 * 5. 释放PCI资源
 * 6. 禁用PCI设备
 *
 * @param pdev PCI设备指针
 */
static void cnc_remove(struct pci_dev *pdev)
{
    struct cnc_dev_t *dev = pci_get_drvdata(pdev);

    /* 释放中断 */
    free_irq(dev->irq, dev);

    /* 销毁设备节点和类 */
    device_destroy(dev->cls, dev->devt);
    class_destroy(dev->cls);

    /* 删除字符设备并注销设备号 */
    cdev_del(&dev->cdev);
    unregister_chrdev_region(dev->devt, 1);

    /* 解除BAR空间映射 */
    pci_iounmap(pdev, dev->io_addr);
    pci_iounmap(pdev, dev->mem_addr);

    /* 释放PCI资源 */
    pci_release_region(pdev, 1);
    pci_release_region(pdev, 0);

    /* 禁用PCI设备 */
    pci_disable_device(pdev);
}

static struct pci_driver cnc_pci_driver = {
    .name = DEVICENAME,      /**< 驱动名称 */
    .id_table = cnc_pci_tbl, /**< 支持的PCI设备列表 */
    .probe = cnc_probe,      /**< 设备探测函数 */
    .remove = cnc_remove,    /**< 设备移除函数 */
};

/**
 * @brief 模块注册宏
 *
 * 使用module_pci_driver宏自动生成module_init和module_exit函数，
 * 简化驱动注册和卸载流程。
 */
module_pci_driver(cnc_pci_driver);

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("F.T");
MODULE_DESCRIPTION("CNC Controller Driver");
MODULE_VERSION("1.0");
