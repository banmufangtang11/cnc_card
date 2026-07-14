/*-----------------------------------------------------------------------*/
/*---------------------- For Linux Kernel 4.15.0 ------------------------*/
/*------------------------ Updated by FangTong -------------------------*/
/*-------------------------------- 2022 ---------------------------------*/
/*-----------------------------------------------------------------------*/
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
#include <asm/io.h>
#include <asm/switch_to.h>
#include <linux/kernel.h>
#include <linux/spinlock.h>
#include <linux/delay.h>
#include <linux/interrupt.h>
#include <linux/irq.h>
#include <linux/semaphore.h>
#include "cnc.h"
#include "cncdrive_cmd.h"

#define GLOB_STA 0x04 /*PCIe配置空间中断地址*/
// #define INT_MASK  0xfffffeff    //中断掩码
// #define INTCSR_MEM_ADDR 0x04

#define INTCSR_V_MEM_ADDR 0x01   // 中断控制寄存器
#define PCTOCARD_V_MEM_ADDR 0x05 // pc到卡的插补数据寄存器

#define POS_X_V_MEM_ADDR 0x06
#define POS_Y_V_MEM_ADDR 0x07
#define POS_Z_V_MEM_ADDR 0x08
#define POS_A_V_MEM_ADDR 0x09

#define DEVICENAME "cnc_card"    // 设备名
#define PCI_VENDOR_ID_CNC 0x1172 // Pci供应商id
#define PCI_DEVICE_ID_CNC 0x4258 // Pci设备id
#define CNC_MAJOR 100            // 预设的cnc_card 的主设备号

#define BUF_SIZE 1000 // 设备驱动缓存区的容量
#define POS_SIZE 34   // 缓存区的容量

#define __devinit
#define __devexit

/* 设备结构体声明*/
struct cnc_dev_t
{
    struct cdev cdev; // 字符设备结构体

    u32 data_buf[BUF_SIZE]; // 设备驱动发送缓存区
    int current_buf_num;    // 设备驱动发送缓存区待发送的数量

    u32 pos_data_buf[POS_SIZE]; // 读设备用
    int current_pos_buf_num;    // 读设备用当前的使用的容量

    u32 irq; // 中断号

    // 存储域物理地址
    u32 iobase;   // IO空间的基地址,IO端口方式
    u32 io_size;  // IO空间地址范围大小
    u32 membase;  // 内存空间的基地址，IO内存方式
    u32 mem_size; // 内存空间地址范围大小

    // 存储域虚拟地址
    u32 *mem_addr; // 映射后内核虚拟基地址
    u32 *io_addr;

    spinlock_t lock;          // 自旋锁
    struct semaphore sem;     // 用户态并发控制用的信号量
    wait_queue_head_t w_wait; // 阻塞写用的等待队列头
};

static int cnc_major = CNC_MAJOR;
static struct cnc_dev_t *cnc_dev; // 定义设备结构体指针(全局指针，在所有函数中都可以使用)

/* 指明本驱动程序适用于哪一些PCIe设备，查找指定的PCIe板卡，系统根据板卡的设备号去查找对应的板卡 */
static struct pci_device_id cnc_pci_tbl[] __initdata = {
    {PCI_VENDOR_ID_CNC, PCI_DEVICE_ID_CNC, PCI_ANY_ID, PCI_ANY_ID, 0, 0, 0}, {0}};

MODULE_DEVICE_TABLE(pci, cnc_pci_tbl);

/*从卡上读一串数据到驱动缓存区*/
static void pos_readfrom_card(void)
{
    /*从卡上读编码器计数值寄存器数据*/
    u32 pos_x, pos_y, pos_z, pos_a;     // 编码器
    u32 pos_x0, pos_y0, pos_z0, pos_a0; // 参考点编码器的值
    u32 pos_x1, pos_y1, pos_z1, pos_a1; // x1=x-x0，机床坐标系下的坐标

    u32 pos_x2, pos_y2, pos_z2, pos_a2; // break point
    u32 dcsr;                           // device control state reg
    u32 spd_x, spd_y, spd_z, spd_a;     // 速度寄存器，每两秒刷新一次

    u32 card_pos_x, card_pos_y, card_pos_z, card_pos_a;     // 卡modul get 编码器
    u32 card_pos_x0, card_pos_y0, card_pos_z0, card_pos_a0; // 卡modul get 参考点编码器的值
    u32 card_pos_x1, card_pos_y1, card_pos_z1, card_pos_a1; // x1=x-x0，卡modul get 机床坐标系下的坐标

    u32 aux_data; // 刀库数据寄存器
    u32 aux_ctl;

    aux_data = ioread32(cnc_dev->mem_addr + 0x2a);
    aux_ctl = ioread32(cnc_dev->mem_addr + 0x2b);

    pos_x = ioread32(cnc_dev->mem_addr + 0x08);
    pos_y = ioread32(cnc_dev->mem_addr + 0x09);
    pos_z = ioread32(cnc_dev->mem_addr + 0x0a);
    pos_a = ioread32(cnc_dev->mem_addr + 0x0b);

    pos_x0 = ioread32(cnc_dev->mem_addr + 0x0c);
    pos_y0 = ioread32(cnc_dev->mem_addr + 0x0d);
    pos_z0 = ioread32(cnc_dev->mem_addr + 0x0e);
    pos_a0 = ioread32(cnc_dev->mem_addr + 0x0f);

    pos_x1 = ioread32(cnc_dev->mem_addr + 0x10);
    pos_y1 = ioread32(cnc_dev->mem_addr + 0x11);
    pos_z1 = ioread32(cnc_dev->mem_addr + 0x12);
    pos_a1 = ioread32(cnc_dev->mem_addr + 0x13);

    pos_x2 = ioread32(cnc_dev->mem_addr + 0x14);
    pos_y2 = ioread32(cnc_dev->mem_addr + 0x15);
    pos_z2 = ioread32(cnc_dev->mem_addr + 0x16);
    pos_a2 = ioread32(cnc_dev->mem_addr + 0x17);

    dcsr = ioread32(cnc_dev->mem_addr + 0x06);

    card_pos_x = ioread32(cnc_dev->mem_addr + 0x30);
    card_pos_y = ioread32(cnc_dev->mem_addr + 0x31);
    card_pos_z = ioread32(cnc_dev->mem_addr + 0x32);
    card_pos_a = ioread32(cnc_dev->mem_addr + 0x33);

    card_pos_x0 = ioread32(cnc_dev->mem_addr + 0x38);
    card_pos_y0 = ioread32(cnc_dev->mem_addr + 0x39);
    card_pos_z0 = ioread32(cnc_dev->mem_addr + 0x3a);
    card_pos_a0 = ioread32(cnc_dev->mem_addr + 0x3b);

    card_pos_x1 = ioread32(cnc_dev->mem_addr + 0x40);
    card_pos_y1 = ioread32(cnc_dev->mem_addr + 0x41);
    card_pos_z1 = ioread32(cnc_dev->mem_addr + 0x42);
    card_pos_a1 = ioread32(cnc_dev->mem_addr + 0x43);

    spd_x = ioread32(cnc_dev->mem_addr + 0x34);
    spd_y = ioread32(cnc_dev->mem_addr + 0x35);
    spd_z = ioread32(cnc_dev->mem_addr + 0x36);
    spd_a = ioread32(cnc_dev->mem_addr + 0x37);

    cnc_dev->pos_data_buf[0] = pos_x;
    cnc_dev->pos_data_buf[1] = pos_y;
    cnc_dev->pos_data_buf[2] = pos_z;
    cnc_dev->pos_data_buf[3] = pos_a;

    cnc_dev->pos_data_buf[4] = pos_x0;
    cnc_dev->pos_data_buf[5] = pos_y0;
    cnc_dev->pos_data_buf[6] = pos_z0;
    cnc_dev->pos_data_buf[7] = pos_a0;

    cnc_dev->pos_data_buf[8] = pos_x1;
    cnc_dev->pos_data_buf[9] = pos_y1;
    cnc_dev->pos_data_buf[10] = pos_z1;
    cnc_dev->pos_data_buf[11] = pos_a1;

    cnc_dev->pos_data_buf[12] = aux_data;
    cnc_dev->pos_data_buf[13] = aux_ctl;
    cnc_dev->pos_data_buf[14] = pos_z2;
    cnc_dev->pos_data_buf[15] = pos_a2;

    cnc_dev->pos_data_buf[16] = dcsr;

    cnc_dev->pos_data_buf[17] = spd_x;
    cnc_dev->pos_data_buf[18] = spd_y;
    cnc_dev->pos_data_buf[19] = spd_z;
    cnc_dev->pos_data_buf[20] = spd_a;

    cnc_dev->pos_data_buf[21] = card_pos_x;
    cnc_dev->pos_data_buf[22] = card_pos_y;
    cnc_dev->pos_data_buf[23] = card_pos_z;
    cnc_dev->pos_data_buf[24] = card_pos_a;

    cnc_dev->pos_data_buf[25] = card_pos_x0;
    cnc_dev->pos_data_buf[26] = card_pos_y0;
    cnc_dev->pos_data_buf[27] = card_pos_z0;
    cnc_dev->pos_data_buf[28] = card_pos_a0;

    cnc_dev->pos_data_buf[29] = card_pos_x1;
    cnc_dev->pos_data_buf[30] = card_pos_y1;
    cnc_dev->pos_data_buf[31] = card_pos_z1;
    cnc_dev->pos_data_buf[32] = card_pos_a1;

    cnc_dev->pos_data_buf[33] = aux_data;

    cnc_dev->current_pos_buf_num = 34;

    // for(i=0; i < 34; i++)
    // {
    // 	cnc_dev->pos_data_buf[i] = ioread32(cnc_dev->mem_addr+ i);
    // }
}

/* 驱动设备读操作 */
static ssize_t cnc_read(struct file *filp, char __user *user_data_buf, size_t size, loff_t *ppos)
{
    int ret;
    struct cnc_dev_t *dev = filp->private_data; // 获得设备结构体指针
    int count;

    down(&dev->sem); // 获得信号量
    count = size / 4;

    pos_readfrom_card(); // 从IO卡中读到驱动缓存区

    if (count > dev->current_pos_buf_num) // size
    {
        ret = -1;
        printk("Error: count num bigger than current_pos_buf_num.\n");
        goto out;
    }

    if (copy_to_user(user_data_buf, cnc_dev->pos_data_buf, 4 * 17)) // 从驱动缓存区拷贝到应用层缓存区
    {
        printk("Failed: copy_to_user\n");
        ret = -EFAULT;
        goto out;
    }

    printk("copy_to_user success.\n");
    ret = count;

out:
    up(&dev->sem); // 释放信号量
    return ret;
}

/* 驱动设备写操作 */
static ssize_t cnc_write(struct file *filp, const char *data_buf, size_t size, loff_t *ppos)
{
    int ret;
    int count;                                  // 写入数据的数量
    struct cnc_dev_t *dev = filp->private_data; // 获得设备结构体指针

    printk("\n写设备模块  cnc_write start!\n");

    printk("定义等待队列\n");
    DECLARE_WAITQUEUE(wait, current); // 定义等待队列
    printk("获取信号量\n");
    down(&dev->sem); // 获取信号量

    printk("进入写等待队列头\n");
    add_wait_queue(&dev->w_wait, &wait); // 进入写等待队列头

    /* 等待设备缓冲区data_buf读空 */
    if (dev->current_buf_num == BUF_SIZE)
    {
        if (filp->f_flags & O_NONBLOCK) // 如果是非阻塞访问
        {
            printk("........非阻塞访问......\n");
            ret = -EAGAIN;
            goto out;
        }

        printk("write buffer if full\n");
        __set_current_state(TASK_INTERRUPTIBLE); // 改变进程状态为睡眠
        up(&dev->sem);                           // 释放信号量

        printk("@cnc_write  调度其他进程执行  before__schedule()\n");
        schedule(); // 调度其他进程执行

        printk("by interrupt wake up come back @cnc_write behind__schedule(); \n");

        if (0 != signal_pending(current)) // 如果是因为信号唤醒
        {
            printk("因为信号唤醒\n");
            ret = -ERESTARTSYS;
            goto out2;
        }
        down(&dev->sem); // 获得信号量
    }

    count = size / sizeof(dev->data_buf[0]); // 用来取整
    if (count > (BUF_SIZE - dev->current_buf_num))
    {
        count = BUF_SIZE - dev->current_buf_num;
        printk("BUF_SIZE - dev->current_buf_num is too long,  count = %d\n", count);
    }

    /*从用户空间拷贝到内核空间*/
    printk("从用户空间拷贝到内核空间\n");
    if (copy_from_user(dev->data_buf, data_buf, count * sizeof(dev->data_buf[0])))
    {
        ret = -EFAULT;
        goto out;
    }
    else
    {
        dev->current_buf_num += count;
        printk("copy_from_user() finish.\n");
        printk(KERN_INFO "written %d bytes(s),current_buf_num:%d\n", count, dev->current_buf_num);
        ret = count;
    }
out:
    up(&dev->sem); // 释放信号量
out2:
    remove_wait_queue(&dev->w_wait, &wait); // 从附属的等待队列头移除
    set_current_state(TASK_RUNNING);        // 改变进程状态为任务调度

    printk("写设备模块 cnc_write end\n\n\n");
    return ret;
}
/*驱动缓存区的数据写一串数据到卡上，这里采用的是IO内存的方式，映射到板卡内存空间*/
static void data_send(void)
{
    int i = 0;

    printk("驱动数据缓冲区current_buf_num = %d\n", cnc_dev->current_buf_num);

    if (cnc_dev->current_buf_num == BUF_SIZE)
    {
        printk("start send data to card... 开始从驱动数据缓冲区写到FPGA卡.\n");

        for (i = 0; i < BUF_SIZE; i++)
        {
            iowrite32(cnc_dev->data_buf[i], cnc_dev->mem_addr + 0x05);
        }

        cnc_dev->current_buf_num = 0;
        printk("写一串数据到卡上完成,cnc_dev->current_buf_num = %d.\n", cnc_dev->current_buf_num);

        printk("wake_up_interruptible(&cnc_dev->w_wait);唤醒写等待队列（被阻塞的进程）\n");
        wake_up_interruptible(&cnc_dev->w_wait);
    }
    else
    {
        printk("驱动数据缓冲区未满There is no data in data_buf!\n");
    }
}

// 驱动设备中断操作
static irqreturn_t cnc_interrupt(int irq, void *dev_id)
{
    struct cnc_dev_t *cnc_dev = (struct cnc_dev_t *)dev_id;
    u32 status;

    spin_lock(&cnc_dev->lock); // 获得自旋锁

    printk("开始响应中断处理cnc_interrupt. \n");

    status = ioread32(cnc_dev->mem_addr + 0x01); // 读取PCIe卡中断寄存器值
    printk("INTCSR status = %x\n", status);
    if (status != 0x00000003) /*读取中断源判断是否是本设备的中断*/
    {
        printk("并非本PCIe设备的中断  spin_unlock and return IRQ_NONE\n");
        spin_unlock(&cnc_dev->lock);
        return IRQ_NONE;
    }

    /* 去使能PCI中断 */
    printk("告诉PCIE设备已经收到中断  关闭PCI中断\n");
    iowrite32(0x00000000, cnc_dev->mem_addr + 0x01);
    status = ioread32(cnc_dev->mem_addr + 0x01);
    printk("INTCSR status = %x\n", status);

    /*往卡上发送数据*/
    data_send();

    /* 使能PCI中断 */
    iowrite32(0x00000002, cnc_dev->mem_addr + 0x01);
    status = ioread32(cnc_dev->mem_addr + 0x01);
    printk("INTCSR status = %x\n", status);
    spin_unlock(&cnc_dev->lock);
    return IRQ_HANDLED;
}

// 设备IO操作
long cnc_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
    int ret = 0;
    // struct cnc_dev_t  *dev = filp->private_data; //获得设备结构体指针

    printk("ioctl_fuction\n");

    /* 检验命令是否有效 */
    if (_IOC_TYPE(cmd) != TEST_MAGIC)
        return -EINVAL;

    if (_IOC_NR(cmd) > TEST_MAX_NR)
        return -EINVAL;

    switch (cmd)
    {
    case AXIS1_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x18);
        printk("AXIS1_ON send once!\n");
        break;
    case AXIS2_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x19);
        printk("AXIS2_ON send once!\n");
        break;
    case AXIS3_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x1A);
        printk("AXIS3_ON send once!\n");
        break;
    case AXIS4_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x1B);
        printk("AXIS4_ON send once!\n");
        break;
    case AXIS5_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x1C);
        printk("AXIS5_ON send once!\n");
        break;
    case AXIS6_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x1D);
        printk("AXIS6_ON send once!\n");
        break;
    case AXIS7_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x1E);
        printk("AXIS7_ON send once!\n");
        break;
    case AXIS8_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x1F);
        printk("AXIS8_ON send once!\n");
        break;
    case AXIS1_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x18);
        printk("AXIS1_OFF send once!\n");
        break;
    case AXIS2_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x19);
        printk("AXIS2_OFF send once!\n");
        break;
    case AXIS3_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x1A);
        printk("AXIS3_OFF send once!\n");
        break;
    case AXIS4_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x1B);
        printk("AXIS4_OFF send once!\n");
        break;
    case AXIS5_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x1C);
        printk("AXIS5_OFF send once!\n");
        break;
    case AXIS6_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x1D);
        printk("AXIS6_OFF send once!\n");
        break;
    case AXIS7_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x1E);
        printk("AXIS7_OFF send once!\n");
        break;
    case AXIS8_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x1F);
        printk("AXIS8_OFF send once!\n");
        break;
    case XP_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x20);
        printk("XP_ON send once!\n");
        break;
    case XN_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x24);
        printk("XN_ON send once!\n");
        break;
    case YP_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x21);
        printk("YP_ON send once!\n");
        break;
    case YN_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x25);
        printk("YN_ON send once!\n");
        break;
    case ZP_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x22);
        printk("ZP_ON send once!\n");
        break;
    case ZN_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x26);
        printk("ZN_ON send once!\n");
        break;
    case AP_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x23);
        printk("AP_ON send once!\n");
        break;
    case AN_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x27);
        printk("AN_ON send once!\n");
        break;
    case XP_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x20);
        printk("XP_OFF send once!\n");
        break;
    case XN_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x24);
        printk("XN_OFF send once!\n");
        break;
    case YP_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x21);
        printk("YP_OFF send once!\n");
        break;
    case YN_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x25);
        printk("YN_OFF send once!\n");
        break;
    case ZP_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x22);
        printk("ZP_OFF send once!\n");
        break;
    case ZN_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x26);
        printk("ZN_OFF send once!\n");
        break;
    case AP_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x23);
        printk("AP_OFF send once!\n");
        break;
    case AN_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x27);
        printk("AN_OFF send once!\n");
        break;
    case RETURN0_ON:
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x28);
        printk("RETURN0_ON send once!\n");
        break;
    case RETURN0_OFF:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x28);
        printk("RETURN0_OFF send once!\n");
        break;
    case COOLANT_ON: // lzz
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x44);
        printk("COOLANT_ON send once!\n");
        break;
    case COOLANT_OFF: // lzz
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x44);
        printk("COOLANT_OFF send once!\n");
        break;
    case SPINDLE_POS: // lzz
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x45);
        printk("SPINDLE_POS send once!\n");
        break;
    case SPINDLE_REV: // lzz
        iowrite32(0x00000001, cnc_dev->mem_addr + 0x46);
        printk("SPINDLE_REV send once!\n");
        break;
    case SPINDLE_STOP: // lzz
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x45);
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x46);
        printk("SPINDLE_STOP send once!\n");
        break;
    case AUX_CLR:
        iowrite32(0x00000000, cnc_dev->mem_addr + 0x2B);
        printk("aux reg clear send once!\n");
        break;
    case SET_ON: // toolsetter on
        iowrite32(0x00000002, cnc_dev->mem_addr + 0x2B);
        printk("SET_ON send once!\n");
        break;
    case SET_OFF:
        iowrite32(0x00000003, cnc_dev->mem_addr + 0x2B);
        printk("SET_OFF send once!\n");
        break;
    case MAG_ON: // toolmagazine enable
        iowrite32(0x00000004, cnc_dev->mem_addr + 0x2B);
        printk("MAG_ON send once!\n");
        break;
    case MAG_OFF:
        iowrite32(0x00000005, cnc_dev->mem_addr + 0x2B);
        printk("MAG_OFF send once!\n");
        break;
    case MAG_GO: // move on
        iowrite32(0x00000006, cnc_dev->mem_addr + 0x2B);
        printk("MAG_GO send once!\n");
        break;
    case MAG_BACK: // move back
        iowrite32(0x00000007, cnc_dev->mem_addr + 0x2B);
        printk("MAG_GO send once!\n");
        break;
    case LOOSE_ON: // spindle loose the tool
        iowrite32(0x00000008, cnc_dev->mem_addr + 0x2B);
        printk("LOOSE_ON send once!\n");
        break;
    case LOOSE_OFF:
        iowrite32(0x00000009, cnc_dev->mem_addr + 0x2B);
        printk("LOOSE_OFF send once!\n");
        break;
    case TOOL_1: // give the tool, rotating to the tool number
        iowrite32(0x0000001A, cnc_dev->mem_addr + 0x2B);
        printk("tool1 send once!\n");
        break;
    case TOOL_2:
        iowrite32(0x0000002A, cnc_dev->mem_addr + 0x2B);
        printk("tool2 send once!\n");
        break;
    case TOOL_3:
        iowrite32(0x0000003A, cnc_dev->mem_addr + 0x2B);
        printk("tool3 send once!\n");
        break;
    case TOOL_4:
        iowrite32(0x0000004A, cnc_dev->mem_addr + 0x2B);
        printk("tool4 send once!\n");
        break;
    case TOOL_5:
        iowrite32(0x0000005A, cnc_dev->mem_addr + 0x2B);
        printk("tool5 send once!\n");
        break;
    case TOOL_6:
        iowrite32(0x0000006A, cnc_dev->mem_addr + 0x2B);
        printk("tool6 send once!\n");
        break;
    case TOOL_7:
        iowrite32(0x0000007A, cnc_dev->mem_addr + 0x2B);
        printk("tool7 send once!\n");
        break;
    case TOOL_8:
        iowrite32(0x0000008A, cnc_dev->mem_addr + 0x2B);
        printk("tool8 send once!\n");
        break;
    default: /*命令错误时的处理*/
        printk("error cmd!\n");
        ret = -EINVAL;
        break;
    }

    return ret;
}

// 打开设备 Open cnc device
static int cnc_open(struct inode *inode, struct file *filp)
{
    /*获取设备结构体指针*/
    filp->private_data = cnc_dev;
    printk(KERN_INFO "INFO:FPGA card opened\n");
    return 0;
}

// 关闭设备Shut down cnc device
static int cnc_release(struct inode *inode, struct file *filp)
{
    printk(KERN_INFO "INFO:FPGA card closed\n");
    return 0;
}

// 设备文件操作接口
static struct file_operations cnc_fops = {
    .owner = THIS_MODULE,        // cnc_fops所属的设备模块
    .write = cnc_write,          // 写设备操作
    .read = cnc_read,            // 读设备操作 cch
    .open = cnc_open,            // 打开设备操作
    .release = cnc_release,      // 释放设备操作
    .unlocked_ioctl = cnc_ioctl, // IO控制操作
};

// 在PCIe设备初始化时，初始化cdev结构体
static void cnc_setup_cdev(struct cnc_dev_t *dev_s, int index)
{
    int err;
    dev_t devno = MKDEV(cnc_major, index);

    printk("添加并初始化cdev结构体 start\n");

    cdev_init(&cnc_dev->cdev, &cnc_fops);
    cnc_dev->cdev.owner = THIS_MODULE;

    err = cdev_add(&cnc_dev->cdev, devno, 1);
    if (err)
    {
        printk(KERN_NOTICE "Error %d adding cnc_card", err);
    }

    return;
}

// 完成PCIe设备初始化及设备本身身份驱动的注册
static int __devinit cnc_probe(struct pci_dev *pci_dev, const struct pci_device_id *pci_id)
{
    int retval = 0;                    // 设备的返回值，负数则失败
    struct pci_dev *prv_dev = pci_dev; // 传递函数形参pci_dev
    dev_t devno = MKDEV(cnc_major, 0); // 获取设备编号：主设备号（cnc_major）+次设备号（0）

    /*分配cnc_dev_t设备数据结构体内存*/
    printk("分配cnc_dev_t 内存 START \n");
    cnc_dev = kmalloc(sizeof(struct cnc_dev_t), GFP_KERNEL);
    if (!cnc_dev)
    {
        printk(KERN_ERR "cnc_card: kmalloc failed.\n ");
        return -ENOMEM;
    }

    /*初始化cnc_dev_t设备数据结构体*/
    memset(cnc_dev, 0, sizeof(struct cnc_dev_t));

    // 初始化信号量、锁等
    sema_init(&cnc_dev->sem, 1);           // 初始化信号量
    spin_lock_init(&cnc_dev->lock);        // 初始化自旋锁
    init_waitqueue_head(&cnc_dev->w_wait); // 初始化写等待队列头

    /* 使能PCI设备*/
    if (pci_enable_device(prv_dev))
    {
        printk("pci_enable_device failed.\n");
        kfree(cnc_dev);
        return -ENODEV;
    }

    /*从PCIe IP核中的配置寄存器中读取IO端口、IO内存基地址，给读写操作提供地址范围 */
    cnc_dev->iobase = pci_resource_start(prv_dev, 0);
    cnc_dev->io_size = pci_resource_len(prv_dev, 0);
    cnc_dev->membase = pci_resource_start(prv_dev, 1);
    cnc_dev->mem_size = pci_resource_len(prv_dev, 1);

    /* 申请IO端口资源和IO内存资源*/
    printk("申请I/O内存资源和I/O资源 START \n");
    // 申请I/O内存资源
    if (!request_mem_region(cnc_dev->membase, cnc_dev->mem_size, DEVICENAME))
    {
        printk(KERN_ERR "cnc_card: cannot allocate mem region\n");
        kfree(cnc_dev);
        return -EIO;
    }
    // 申请I/O端口资源
    if (!request_region(cnc_dev->iobase, cnc_dev->io_size, DEVICENAME))
    {
        printk(KERN_ERR "cnc_card: cannot allocate io region %lx \n", cnc_dev->iobase);
        kfree(cnc_dev);
        return -EIO;
    }

    /*物理地址映射到内核虚拟地址*/
    printk("设备所处物理地址映射到内核虚拟地址 START \n");
    cnc_dev->mem_addr = ioremap(cnc_dev->membase, cnc_dev->mem_size);
    if (cnc_dev->mem_addr == NULL)
    {
        printk(KERN_ERR "cnc_card: cannot ioremap membase\n ");
        kfree(cnc_dev);
        return -EIO;
    }
    cnc_dev->io_addr = ioremap(cnc_dev->iobase, cnc_dev->io_size);
    if (cnc_dev->io_addr == NULL)
    {
        printk(KERN_ERR "cnc_card: cannot ioremap io base\n");
        kfree(cnc_dev);
        return -EIO;
    }

    /* 初始化PCIe IP核中断控制状态寄存器，偏移地址*4 */
    iowrite32(0x00000002, cnc_dev->mem_addr + 0x01); // 设置中断寄存器
    iowrite32(0x00000000, cnc_dev->mem_addr + 0x05); // 设置PC到卡的数据寄存器
    printk("INTCSR status = %x\n", ioread32(cnc_dev->mem_addr + 0x01));
    printk("cnc_dev->mem_addr+ 0x05 = %d\n", *(cnc_dev->mem_addr + 0x05));

    /* 申请字符设备号*/
    printk("申请字符设备号 START \n");
    if (cnc_major)
    {
        retval = register_chrdev_region(devno, 1, "cnc_card"); // count连续编码范围1，只申请一个设备
    }
    else
    {
        printk("动态分配设备号 \n");
        retval = alloc_chrdev_region(&devno, 0, 1, "cnc_card"); // 动态分配设备号
        cnc_major = MAJOR(devno);
    }

    if (retval < 0)
    {
        printk(KERN_NOTICE "Error %d cnc_setup_cdev", retval);
        return retval;
    }

    /* 添加并初始化cdev 结构体 */
    printk("添加并初始化cdev结构体 START \n");
    cnc_setup_cdev(cnc_dev, 0);

    /*获取PCIe中断号*/
    cnc_dev->irq = pci_dev->irq;
    printk("cnc_dev->irq: %d\n", cnc_dev->irq);

    /* 注册中断处理函数 */
    if (request_irq(cnc_dev->irq, &cnc_interrupt, IRQF_SHARED, DEVICENAME, cnc_dev))
    {
        printk(KERN_ERR "cnc_card: unable to allocate irq %d\n", cnc_dev->irq);
        kfree(cnc_dev);
        return -EIO;
    }

    printk("REG+0x04 status = %x\n", ioread32(cnc_dev->mem_addr + 0x01));
    printk("REG+0x08 status = %x\n", ioread32(cnc_dev->mem_addr + 0x02));
    printk("REG+0x0C status = %x\n", ioread32(cnc_dev->mem_addr + 0x03));
    printk("REG+0x10 status = %x\n", ioread32(cnc_dev->mem_addr + 0x04));
    printk("REG+0x14 status = %x\n", ioread32(cnc_dev->mem_addr + 0x05));

    printk("cnc_probe finish.\n");

    return 0;
}

// 卸载设备函数
static void cnc_remove(struct pci_dev *pcidev)
{
    dev_t devno = MKDEV(cnc_major, 0);

    printk("Starting device removal.\n");

    // 释放中断号
    if (free_irq(cnc_dev->irq, cnc_dev))
    {
        printk(KERN_ERR "Failed to free IRQ.\n");
    }

    // 注销字符设备
    cdev_del(&cnc_dev->cdev);

    // 注销字符设备号
    if (unregister_chrdev_region(devno, 1))
    {
        printk(KERN_ERR "Failed to unregister character device region.\n");
    }

    // 取消内存映射
    if (iounmap(cnc_dev->mem_addr))
    {
        printk(KERN_ERR "Failed to iounmap memory.\n");
    }

    // 释放设备IO端口
    if (release_region(cnc_dev->iobase, cnc_dev->io_size))
    {
        printk(KERN_ERR "Failed to release IO region.\n");
    }

    // 释放设备IO内存
    if (release_mem_region(cnc_dev->membase, cnc_dev->mem_size))
    {
        printk(KERN_ERR "Failed to release memory region.\n");
    }

    // 禁止PCI设备
    pci_disable_device(pcidev);

    // 释放动态分配的内存
    kfree(cnc_dev);
    printk("Device removal completed.\n");
    return;
}

/* PCI设备模块信息 */
static struct pci_driver cnc_pci_driver = {
    .name = DEVICENAME,      /* 设备模块名*/
    .id_table = cnc_pci_tbl, /* 能够驱动的设备列表 */
    .probe = cnc_probe,      /* 注册时处理 */
    .remove = cnc_remove,    /* 注销时处理 */
};

/*内核模块加载函数*/
static int __init cnc_init(void)
{
    int result;

    printk("cnc_init.\n");
    result = pci_register_driver(&cnc_pci_driver);
    if (result)
    {
        printk(KERN_ERR "err: can not register driver.\n");
        // unregister_chrdev(cnc_major, DEVICENAME);
        return result;
    }
    printk("cnc_init finish.\n");
    return 0;
}

static void __exit cnc_exit(void)
{
    printk("cnc_exit.\n");
    pci_unregister_driver(&cnc_pci_driver);
    return;
}

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("F.T");
MODULE_DESCRIPTION("CNC Controller Driver");

module_init(cnc_init);
module_exit(cnc_exit);
