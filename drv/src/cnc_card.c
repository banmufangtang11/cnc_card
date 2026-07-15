// SPDX-License-Identifier: GPL-2.0
/*
 * CNC Controller PCIe Driver
 *
 * Copyright (C) 2022 FangTong <fangtong@cnc.com>
 *
 * This driver provides PCIe interface for CNC motion controller card,
 * supporting position reading, command writing, and I/O control.
 *
 * Features:
 * - Miscdevice for simplified char device registration
 * - PCIe BAR mapping with pcim helpers
 * - MSI/MSI-X interrupt support
 * - Sysfs interface for monitoring
 * - Device tree / platform data support
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/fs.h>
#include <linux/types.h>
#include <linux/errno.h>
#include <linux/mm.h>
#include <linux/slab.h>
#include <linux/cdev.h>
#include <linux/kdev_t.h>
#include <linux/uaccess.h>
#include <asm/io.h>
#include <linux/spinlock.h>
#include <linux/interrupt.h>
#include <linux/mutex.h>
#include <linux/wait.h>
#include <linux/sysfs.h>
#include <linux/device.h>
#include <linux/miscdevice.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/mod_devicetable.h>
#include "cnc.h"
#include "cncdrive_cmd.h"

/* Version information */
#define CNC_DRIVER_VERSION "1.1.0"
#define CNC_DRIVER_RELEASE_DATE "2022-01-01"

/* Device identification */
#define CNC_DEV_NAME "cnc_card"
#define CNC_VENDOR_ID 0x1172
#define CNC_DEVICE_ID 0x4258
#define CNC_SUBSYS_VENDOR_ID 0x1172
#define CNC_SUBSYS_DEVICE_ID 0x4258

/* Memory region definitions */
#define CNC_BAR0_IO_SIZE 0x1000
#define CNC_BAR1_MEM_SIZE 0x400000

/* Register offsets (32-bit aligned) */
#define CNC_INTCSR_REG        0x01    /* Interrupt control/status */
#define CNC_PCTOCARD_REG      0x05    /* PC to card data */
#define CNC_DCSR_REG          0x06    /* Device control/status */

#define CNC_POS_X_REG         0x08    /* X position */
#define CNC_POS_Y_REG         0x09    /* Y position */
#define CNC_POS_Z_REG         0x0a    /* Z position */
#define CNC_POS_A_REG         0x0b    /* A position */

#define CNC_POS_X0_REG        0x0c    /* X reference position */
#define CNC_POS_Y0_REG        0x0d    /* Y reference position */
#define CNC_POS_Z0_REG        0x0e    /* Z reference position */
#define CNC_POS_A0_REG        0x0f    /* A reference position */

#define CNC_POS_X1_REG        0x10    /* X machine position */
#define CNC_POS_Y1_REG        0x11    /* Y machine position */
#define CNC_POS_Z1_REG        0x12    /* Z machine position */
#define CNC_POS_A1_REG        0x13    /* A machine position */

#define CNC_POS_X2_REG        0x14    /* X breakpoint */
#define CNC_POS_Y2_REG        0x15    /* Y breakpoint */
#define CNC_POS_Z2_REG        0x16    /* Z breakpoint */
#define CNC_POS_A2_REG        0x17    /* A breakpoint */

#define CNC_AXIS1_CTRL_REG    0x18    /* Axis 1 control */
#define CNC_AXIS2_CTRL_REG    0x19    /* Axis 2 control */
#define CNC_AXIS3_CTRL_REG    0x1a    /* Axis 3 control */
#define CNC_AXIS4_CTRL_REG    0x1b    /* Axis 4 control */
#define CNC_AXIS5_CTRL_REG    0x1c    /* Axis 5 control */
#define CNC_AXIS6_CTRL_REG    0x1d    /* Axis 6 control */
#define CNC_AXIS7_CTRL_REG    0x1e    /* Axis 7 control */
#define CNC_AXIS8_CTRL_REG    0x1f    /* Axis 8 control */

#define CNC_XP_CTRL_REG       0x20    /* X+ direction */
#define CNC_YP_CTRL_REG       0x21    /* Y+ direction */
#define CNC_ZP_CTRL_REG       0x22    /* Z+ direction */
#define CNC_AP_CTRL_REG       0x23    /* A+ direction */
#define CNC_XN_CTRL_REG       0x24    /* X- direction */
#define CNC_YN_CTRL_REG       0x25    /* Y- direction */
#define CNC_ZN_CTRL_REG       0x26    /* Z- direction */
#define CNC_AN_CTRL_REG       0x27    /* A- direction */

#define CNC_RETURN0_REG       0x28    /* Return to zero */
#define CNC_AUX_DATA_REG      0x2a    /* Auxiliary data */
#define CNC_AUX_CTRL_REG      0x2b    /* Auxiliary control */

#define CNC_CARD_POS_X_REG    0x30    /* Card X position */
#define CNC_CARD_POS_Y_REG    0x31    /* Card Y position */
#define CNC_CARD_POS_Z_REG    0x32    /* Card Z position */
#define CNC_CARD_POS_A_REG    0x33    /* Card A position */
#define CNC_SPD_X_REG         0x34    /* X speed */
#define CNC_SPD_Y_REG         0x35    /* Y speed */
#define CNC_SPD_Z_REG         0x36    /* Z speed */
#define CNC_SPD_A_REG         0x37    /* A speed */

#define CNC_CARD_POS_X0_REG   0x38    /* Card X reference */
#define CNC_CARD_POS_Y0_REG   0x39    /* Card Y reference */
#define CNC_CARD_POS_Z0_REG   0x3a    /* Card Z reference */
#define CNC_CARD_POS_A0_REG   0x3b    /* Card A reference */

#define CNC_CARD_POS_X1_REG   0x40    /* Card X machine */
#define CNC_CARD_POS_Y1_REG   0x41    /* Card Y machine */
#define CNC_CARD_POS_Z1_REG   0x42    /* Card Z machine */
#define CNC_CARD_POS_A1_REG   0x43    /* Card A machine */

#define CNC_COOLANT_REG       0x44    /* Coolant control */
#define CNC_SPINDLE_POS_REG   0x45    /* Spindle forward */
#define CNC_SPINDLE_REV_REG   0x46    /* Spindle reverse */

/* Buffer sizes */
#define CNC_DATA_BUF_SIZE     1000
#define CNC_POS_BUF_SIZE      34

/* Interrupt status values */
#define CNC_INT_ACTIVE        0x00000003
#define CNC_INT_ENABLE        0x00000002
#define CNC_INT_DISABLE       0x00000000

/* Forward declarations */
static int cnc_open(struct inode *inode, struct file *filp);
static int cnc_release(struct inode *inode, struct file *filp);
static ssize_t cnc_read(struct file *filp, char __user *buf, size_t count, loff_t *ppos);
static ssize_t cnc_write(struct file *filp, const char __user *buf, size_t count, loff_t *ppos);
static long cnc_ioctl(struct file *filp, unsigned int cmd, unsigned long arg);

/* Platform data for device configuration */
struct cnc_platform_data {
    unsigned int num_axes;
    unsigned int max_speed;
    unsigned int use_msi:1;
    unsigned int use_dma:1;
};

/* Per-device data structure */
struct cnc_device {
    struct pci_dev *pdev;
    struct miscdevice miscdev;

    /* Memory mappings */
    void __iomem *mem_base;
    void __iomem *io_base;

    /* Resource information */
    resource_size_t mem_start;
    resource_size_t mem_len;
    resource_size_t io_start;
    resource_size_t io_len;

    /* Buffer management */
    u32 data_buf[CNC_DATA_BUF_SIZE];
    unsigned int data_buf_count;
    u32 pos_buf[CNC_POS_BUF_SIZE];
    unsigned int pos_buf_count;

    /* Synchronization */
    spinlock_t lock;
    struct mutex mutex;
    wait_queue_head_t write_wait;

    /* Interrupt */
    int irq;
    bool use_msi;

    /* Device state */
    bool initialized;
    bool interrupt_enabled;

    /* Debug */
    unsigned int debug_level;
};

/*--------------------------------------------------------------------------
 * Register access helpers
 *--------------------------------------------------------------------------*/

static inline u32 cnc_readl(struct cnc_device *dev, unsigned int offset)
{
    return ioread32(dev->mem_base + offset);
}

static inline void cnc_writel(struct cnc_device *dev, u32 value, unsigned int offset)
{
    iowrite32(value, dev->mem_base + offset);
}

/*--------------------------------------------------------------------------
 * Position reading
 *--------------------------------------------------------------------------*/

static void cnc_update_position(struct cnc_device *dev)
{
    unsigned long flags;

    spin_lock_irqsave(&dev->lock, flags);

    dev->pos_buf[0] = cnc_readl(dev, CNC_POS_X_REG);
    dev->pos_buf[1] = cnc_readl(dev, CNC_POS_Y_REG);
    dev->pos_buf[2] = cnc_readl(dev, CNC_POS_Z_REG);
    dev->pos_buf[3] = cnc_readl(dev, CNC_POS_A_REG);

    dev->pos_buf[4] = cnc_readl(dev, CNC_POS_X0_REG);
    dev->pos_buf[5] = cnc_readl(dev, CNC_POS_Y0_REG);
    dev->pos_buf[6] = cnc_readl(dev, CNC_POS_Z0_REG);
    dev->pos_buf[7] = cnc_readl(dev, CNC_POS_A0_REG);

    dev->pos_buf[8] = cnc_readl(dev, CNC_POS_X1_REG);
    dev->pos_buf[9] = cnc_readl(dev, CNC_POS_Y1_REG);
    dev->pos_buf[10] = cnc_readl(dev, CNC_POS_Z1_REG);
    dev->pos_buf[11] = cnc_readl(dev, CNC_POS_A1_REG);

    dev->pos_buf[12] = cnc_readl(dev, CNC_AUX_DATA_REG);
    dev->pos_buf[13] = cnc_readl(dev, CNC_AUX_CTRL_REG);
    dev->pos_buf[14] = cnc_readl(dev, CNC_POS_Z2_REG);
    dev->pos_buf[15] = cnc_readl(dev, CNC_POS_A2_REG);

    dev->pos_buf[16] = cnc_readl(dev, CNC_DCSR_REG);

    dev->pos_buf[17] = cnc_readl(dev, CNC_SPD_X_REG);
    dev->pos_buf[18] = cnc_readl(dev, CNC_SPD_Y_REG);
    dev->pos_buf[19] = cnc_readl(dev, CNC_SPD_Z_REG);
    dev->pos_buf[20] = cnc_readl(dev, CNC_SPD_A_REG);

    dev->pos_buf[21] = cnc_readl(dev, CNC_CARD_POS_X_REG);
    dev->pos_buf[22] = cnc_readl(dev, CNC_CARD_POS_Y_REG);
    dev->pos_buf[23] = cnc_readl(dev, CNC_CARD_POS_Z_REG);
    dev->pos_buf[24] = cnc_readl(dev, CNC_CARD_POS_A_REG);

    dev->pos_buf[25] = cnc_readl(dev, CNC_CARD_POS_X0_REG);
    dev->pos_buf[26] = cnc_readl(dev, CNC_CARD_POS_Y0_REG);
    dev->pos_buf[27] = cnc_readl(dev, CNC_CARD_POS_Z0_REG);
    dev->pos_buf[28] = cnc_readl(dev, CNC_CARD_POS_A0_REG);

    dev->pos_buf[29] = cnc_readl(dev, CNC_CARD_POS_X1_REG);
    dev->pos_buf[30] = cnc_readl(dev, CNC_CARD_POS_Y1_REG);
    dev->pos_buf[31] = cnc_readl(dev, CNC_CARD_POS_Z1_REG);
    dev->pos_buf[32] = cnc_readl(dev, CNC_CARD_POS_A1_REG);

    dev->pos_buf[33] = cnc_readl(dev, CNC_AUX_DATA_REG);

    dev->pos_buf_count = CNC_POS_BUF_SIZE;

    spin_unlock_irqrestore(&dev->lock, flags);
}

/*--------------------------------------------------------------------------
 * Data sending
 *--------------------------------------------------------------------------*/

static void cnc_send_data(struct cnc_device *dev)
{
    unsigned long flags;
    int i;

    spin_lock_irqsave(&dev->lock, flags);

    if (dev->data_buf_count == CNC_DATA_BUF_SIZE) {
        for (i = 0; i < CNC_DATA_BUF_SIZE; i++) {
            cnc_writel(dev, dev->data_buf[i], CNC_PCTOCARD_REG);
        }
        dev->data_buf_count = 0;
        wake_up_interruptible(&dev->write_wait);
    }

    spin_unlock_irqrestore(&dev->lock, flags);
}

/*--------------------------------------------------------------------------
 * Interrupt handler
 *--------------------------------------------------------------------------*/

static irqreturn_t cnc_interrupt(int irq, void *dev_id)
{
    struct cnc_device *dev = dev_id;
    u32 status;

    spin_lock(&dev->lock);

    status = cnc_readl(dev, CNC_INTCSR_REG);
    if (status != CNC_INT_ACTIVE) {
        spin_unlock(&dev->lock);
        return IRQ_NONE;
    }

    cnc_writel(dev, CNC_INT_DISABLE, CNC_INTCSR_REG);

    cnc_send_data(dev);

    cnc_writel(dev, CNC_INT_ENABLE, CNC_INTCSR_REG);

    spin_unlock(&dev->lock);
    return IRQ_HANDLED;
}

/*--------------------------------------------------------------------------
 * File operations implementation
 *--------------------------------------------------------------------------*/

static int cnc_open(struct inode *inode, struct file *filp)
{
    struct cnc_device *dev = container_of(inode->i_cdev, struct cnc_device, miscdev.this_device->cdev);

    filp->private_data = dev;

    if (!dev->initialized) {
        dev_err(&dev->pdev->dev, "Device not initialized\n");
        return -ENODEV;
    }

    return 0;
}

static int cnc_release(struct inode *inode, struct file *filp)
{
    return 0;
}

static ssize_t cnc_read(struct file *filp, char __user *buf, size_t count, loff_t *ppos)
{
    struct cnc_device *dev = filp->private_data;
    size_t bytes_to_copy;
    int ret;

    if (mutex_lock_interruptible(&dev->mutex))
        return -ERESTARTSYS;

    cnc_update_position(dev);

    bytes_to_copy = min(count, (size_t)(dev->pos_buf_count * sizeof(u32)));

    if (copy_to_user(buf, dev->pos_buf, bytes_to_copy)) {
        ret = -EFAULT;
        goto out;
    }

    ret = bytes_to_copy;

out:
    mutex_unlock(&dev->mutex);
    return ret;
}

static ssize_t cnc_write(struct file *filp, const char __user *buf, size_t count, loff_t *ppos)
{
    struct cnc_device *dev = filp->private_data;
    size_t bytes_to_copy;
    unsigned int words_to_copy;
    int ret = 0;

    if (mutex_lock_interruptible(&dev->mutex))
        return -ERESTARTSYS;

    while (dev->data_buf_count >= CNC_DATA_BUF_SIZE) {
        if (filp->f_flags & O_NONBLOCK) {
            ret = -EAGAIN;
            goto out;
        }

        mutex_unlock(&dev->mutex);
        ret = wait_event_interruptible(dev->write_wait,
                                      dev->data_buf_count < CNC_DATA_BUF_SIZE);
        if (ret < 0)
            return ret;
        if (mutex_lock_interruptible(&dev->mutex))
            return -ERESTARTSYS;
    }

    words_to_copy = count / sizeof(u32);
    words_to_copy = min(words_to_copy, CNC_DATA_BUF_SIZE - dev->data_buf_count);
    bytes_to_copy = words_to_copy * sizeof(u32);

    if (copy_from_user(dev->data_buf + dev->data_buf_count, buf, bytes_to_copy)) {
        ret = -EFAULT;
        goto out;
    }

    dev->data_buf_count += words_to_copy;
    ret = bytes_to_copy;

out:
    mutex_unlock(&dev->mutex);
    return ret;
}

static long cnc_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
    struct cnc_device *dev = filp->private_data;

    if (_IOC_TYPE(cmd) != TEST_MAGIC)
        return -EINVAL;

    if (_IOC_NR(cmd) > TEST_MAX_NR)
        return -EINVAL;

    switch (cmd) {
    case AXIS1_ON: cnc_writel(dev, 1, CNC_AXIS1_CTRL_REG); break;
    case AXIS2_ON: cnc_writel(dev, 1, CNC_AXIS2_CTRL_REG); break;
    case AXIS3_ON: cnc_writel(dev, 1, CNC_AXIS3_CTRL_REG); break;
    case AXIS4_ON: cnc_writel(dev, 1, CNC_AXIS4_CTRL_REG); break;
    case AXIS5_ON: cnc_writel(dev, 1, CNC_AXIS5_CTRL_REG); break;
    case AXIS6_ON: cnc_writel(dev, 1, CNC_AXIS6_CTRL_REG); break;
    case AXIS7_ON: cnc_writel(dev, 1, CNC_AXIS7_CTRL_REG); break;
    case AXIS8_ON: cnc_writel(dev, 1, CNC_AXIS8_CTRL_REG); break;

    case AXIS1_OFF: cnc_writel(dev, 0, CNC_AXIS1_CTRL_REG); break;
    case AXIS2_OFF: cnc_writel(dev, 0, CNC_AXIS2_CTRL_REG); break;
    case AXIS3_OFF: cnc_writel(dev, 0, CNC_AXIS3_CTRL_REG); break;
    case AXIS4_OFF: cnc_writel(dev, 0, CNC_AXIS4_CTRL_REG); break;
    case AXIS5_OFF: cnc_writel(dev, 0, CNC_AXIS5_CTRL_REG); break;
    case AXIS6_OFF: cnc_writel(dev, 0, CNC_AXIS6_CTRL_REG); break;
    case AXIS7_OFF: cnc_writel(dev, 0, CNC_AXIS7_CTRL_REG); break;
    case AXIS8_OFF: cnc_writel(dev, 0, CNC_AXIS8_CTRL_REG); break;

    case XP_ON: cnc_writel(dev, 1, CNC_XP_CTRL_REG); break;
    case XN_ON: cnc_writel(dev, 1, CNC_XN_CTRL_REG); break;
    case YP_ON: cnc_writel(dev, 1, CNC_YP_CTRL_REG); break;
    case YN_ON: cnc_writel(dev, 1, CNC_YN_CTRL_REG); break;
    case ZP_ON: cnc_writel(dev, 1, CNC_ZP_CTRL_REG); break;
    case ZN_ON: cnc_writel(dev, 1, CNC_ZN_CTRL_REG); break;
    case AP_ON: cnc_writel(dev, 1, CNC_AP_CTRL_REG); break;
    case AN_ON: cnc_writel(dev, 1, CNC_AN_CTRL_REG); break;

    case XP_OFF: cnc_writel(dev, 0, CNC_XP_CTRL_REG); break;
    case XN_OFF: cnc_writel(dev, 0, CNC_XN_CTRL_REG); break;
    case YP_OFF: cnc_writel(dev, 0, CNC_YP_CTRL_REG); break;
    case YN_OFF: cnc_writel(dev, 0, CNC_YN_CTRL_REG); break;
    case ZP_OFF: cnc_writel(dev, 0, CNC_ZP_CTRL_REG); break;
    case ZN_OFF: cnc_writel(dev, 0, CNC_ZN_CTRL_REG); break;
    case AP_OFF: cnc_writel(dev, 0, CNC_AP_CTRL_REG); break;
    case AN_OFF: cnc_writel(dev, 0, CNC_AN_CTRL_REG); break;

    case RETURN0_ON: cnc_writel(dev, 1, CNC_RETURN0_REG); break;
    case RETURN0_OFF: cnc_writel(dev, 0, CNC_RETURN0_REG); break;

    case COOLANT_ON: cnc_writel(dev, 1, CNC_COOLANT_REG); break;
    case COOLANT_OFF: cnc_writel(dev, 0, CNC_COOLANT_REG); break;

    case SPINDLE_POS: cnc_writel(dev, 1, CNC_SPINDLE_POS_REG); break;
    case SPINDLE_REV: cnc_writel(dev, 1, CNC_SPINDLE_REV_REG); break;
    case SPINDLE_STOP:
        cnc_writel(dev, 0, CNC_SPINDLE_POS_REG);
        cnc_writel(dev, 0, CNC_SPINDLE_REV_REG);
        break;

    case AUX_CLR: cnc_writel(dev, 0, CNC_AUX_CTRL_REG); break;
    case SET_ON: cnc_writel(dev, 2, CNC_AUX_CTRL_REG); break;
    case SET_OFF: cnc_writel(dev, 3, CNC_AUX_CTRL_REG); break;
    case MAG_ON: cnc_writel(dev, 4, CNC_AUX_CTRL_REG); break;
    case MAG_OFF: cnc_writel(dev, 5, CNC_AUX_CTRL_REG); break;
    case MAG_GO: cnc_writel(dev, 6, CNC_AUX_CTRL_REG); break;
    case MAG_BACK: cnc_writel(dev, 7, CNC_AUX_CTRL_REG); break;
    case LOOSE_ON: cnc_writel(dev, 8, CNC_AUX_CTRL_REG); break;
    case LOOSE_OFF: cnc_writel(dev, 9, CNC_AUX_CTRL_REG); break;

    case TOOL_1: cnc_writel(dev, 0x1A, CNC_AUX_CTRL_REG); break;
    case TOOL_2: cnc_writel(dev, 0x2A, CNC_AUX_CTRL_REG); break;
    case TOOL_3: cnc_writel(dev, 0x3A, CNC_AUX_CTRL_REG); break;
    case TOOL_4: cnc_writel(dev, 0x4A, CNC_AUX_CTRL_REG); break;
    case TOOL_5: cnc_writel(dev, 0x5A, CNC_AUX_CTRL_REG); break;
    case TOOL_6: cnc_writel(dev, 0x6A, CNC_AUX_CTRL_REG); break;
    case TOOL_7: cnc_writel(dev, 0x7A, CNC_AUX_CTRL_REG); break;
    case TOOL_8: cnc_writel(dev, 0x8A, CNC_AUX_CTRL_REG); break;

    default:
        return -EINVAL;
    }

    return 0;
}

/*--------------------------------------------------------------------------
 * Sysfs attributes
 *--------------------------------------------------------------------------*/

static ssize_t version_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    return sprintf(buf, "%s (%s)\n", CNC_DRIVER_VERSION, CNC_DRIVER_RELEASE_DATE);
}

static ssize_t position_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct cnc_device *cnc_dev = dev_get_drvdata(dev);
    return sprintf(buf, "X:%u Y:%u Z:%u A:%u\n",
                   cnc_readl(cnc_dev, CNC_POS_X_REG),
                   cnc_readl(cnc_dev, CNC_POS_Y_REG),
                   cnc_readl(cnc_dev, CNC_POS_Z_REG),
                   cnc_readl(cnc_dev, CNC_POS_A_REG));
}

static ssize_t status_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct cnc_device *cnc_dev = dev_get_drvdata(dev);
    u32 dcsr = cnc_readl(cnc_dev, CNC_DCSR_REG);
    return sprintf(buf, "DCSR:0x%08x INT:%s MSI:%s\n",
                   dcsr, cnc_dev->interrupt_enabled ? "enabled" : "disabled",
                   cnc_dev->use_msi ? "enabled" : "disabled");
}

static ssize_t debug_level_store(struct device *dev, struct device_attribute *attr,
                                  const char *buf, size_t count)
{
    struct cnc_device *cnc_dev = dev_get_drvdata(dev);
    unsigned int val;

    if (kstrtouint(buf, 0, &val))
        return -EINVAL;

    cnc_dev->debug_level = val;
    return count;
}

static ssize_t debug_level_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct cnc_device *cnc_dev = dev_get_drvdata(dev);
    return sprintf(buf, "%u\n", cnc_dev->debug_level);
}

static DEVICE_ATTR_RO(version);
static DEVICE_ATTR_RO(position);
static DEVICE_ATTR_RO(status);
static DEVICE_ATTR_RW(debug_level);

static struct attribute *cnc_sysfs_attrs[] = {
    &dev_attr_version.attr,
    &dev_attr_position.attr,
    &dev_attr_status.attr,
    &dev_attr_debug_level.attr,
    NULL,
};

ATTRIBUTE_GROUPS(cnc);

/*--------------------------------------------------------------------------
 * File operations structure
 *--------------------------------------------------------------------------*/

static const struct file_operations cnc_fops = {
    .owner = THIS_MODULE,
    .open = cnc_open,
    .release = cnc_release,
    .read = cnc_read,
    .write = cnc_write,
    .unlocked_ioctl = cnc_ioctl,
    .llseek = no_llseek,
};

/*--------------------------------------------------------------------------
 * PCI probe/remove
 *--------------------------------------------------------------------------*/

static int cnc_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
    struct cnc_device *dev;
    int ret;
    const struct cnc_platform_data *pdata;
    struct device_node *np = pdev->dev.of_node;

    dev = devm_kzalloc(&pdev->dev, sizeof(*dev), GFP_KERNEL);
    if (!dev)
        return -ENOMEM;

    dev->pdev = pdev;
    spin_lock_init(&dev->lock);
    mutex_init(&dev->mutex);
    init_waitqueue_head(&dev->write_wait);
    dev->debug_level = 0;
    dev->use_msi = false;

    ret = pcim_enable_device(pdev);
    if (ret) {
        dev_err(&pdev->dev, "Failed to enable PCI device\n");
        return ret;
    }

    pci_set_master(pdev);

    ret = pcim_iomap_regions(pdev, 1 << 0 | 1 << 1, CNC_DEV_NAME);
    if (ret) {
        dev_err(&pdev->dev, "Failed to map PCI regions\n");
        return ret;
    }

    dev->mem_base = pcim_iomap_table(pdev)[1];
    dev->io_base = pcim_iomap_table(pdev)[0];
    dev->mem_start = pci_resource_start(pdev, 1);
    dev->mem_len = pci_resource_len(pdev, 1);
    dev->io_start = pci_resource_start(pdev, 0);
    dev->io_len = pci_resource_len(pdev, 0);

    ret = pci_set_dma_mask(pdev, DMA_BIT_MASK(32));
    if (ret) {
        dev_err(&pdev->dev, "Failed to set DMA mask\n");
        return ret;
    }

    if (np) {
        dev_info(&pdev->dev, "Probing device via device tree\n");
        of_property_read_u32(np, "cnc,num-axes", &dev->debug_level);
    } else if ((pdata = pci_get_drvdata(pdev)) != NULL) {
        dev_info(&pdev->dev, "Probing device via platform data\n");
        dev->use_msi = pdata->use_msi;
    }

    if (pci_enable_msi(pdev) == 0) {
        dev->use_msi = true;
        dev_info(&pdev->dev, "MSI interrupt enabled\n");
    }

    cnc_writel(dev, CNC_INT_ENABLE, CNC_INTCSR_REG);
    cnc_writel(dev, 0, CNC_PCTOCARD_REG);

    dev->miscdev.minor = MISC_DYNAMIC_MINOR;
    dev->miscdev.name = CNC_DEV_NAME;
    dev->miscdev.fops = &cnc_fops;
    dev->miscdev.parent = &pdev->dev;
    dev->miscdev.groups = cnc_groups;

    ret = misc_register(&dev->miscdev);
    if (ret) {
        dev_err(&pdev->dev, "Failed to register misc device\n");
        return ret;
    }

    dev_set_drvdata(&dev->miscdev.this_device, dev);

    dev->irq = pdev->irq;
    ret = devm_request_irq(&pdev->dev, dev->irq, cnc_interrupt,
                           IRQF_SHARED, CNC_DEV_NAME, dev);
    if (ret) {
        dev_err(&pdev->dev, "Failed to request IRQ %d\n", dev->irq);
        misc_deregister(&dev->miscdev);
        return ret;
    }

    dev->interrupt_enabled = true;
    dev->initialized = true;
    pci_set_drvdata(pdev, dev);

    dev_info(&pdev->dev, "CNC card driver loaded (irq=%d, mem=%pa, io=%pa, msi=%s)\n",
             dev->irq, &dev->mem_start, &dev->io_start,
             dev->use_msi ? "yes" : "no");

    return 0;
}

static void cnc_pci_remove(struct pci_dev *pdev)
{
    struct cnc_device *dev = pci_get_drvdata(pdev);

    if (!dev)
        return;

    cnc_writel(dev, CNC_INT_DISABLE, CNC_INTCSR_REG);

    misc_deregister(&dev->miscdev);

    if (dev->use_msi)
        pci_disable_msi(pdev);

    dev_info(&pdev->dev, "CNC card driver unloaded\n");
}

/*--------------------------------------------------------------------------
 * PCI driver structure
 *--------------------------------------------------------------------------*/

static const struct pci_device_id cnc_pci_ids[] = {
    {PCI_DEVICE(CNC_VENDOR_ID, CNC_DEVICE_ID),
     .subvendor = CNC_SUBSYS_VENDOR_ID,
     .subdevice = CNC_SUBSYS_DEVICE_ID,
     .driver_data = 0},
    {PCI_DEVICE(CNC_VENDOR_ID, CNC_DEVICE_ID),
     .subvendor = PCI_ANY_ID,
     .subdevice = PCI_ANY_ID,
     .driver_data = 0},
    {0,}
};
MODULE_DEVICE_TABLE(pci, cnc_pci_ids);

#ifdef CONFIG_OF
static const struct of_device_id cnc_of_match[] = {
    {.compatible = "cnc,cnc-card"},
    {0,}
};
MODULE_DEVICE_TABLE(of, cnc_of_match);
#endif

static struct pci_driver cnc_pci_driver = {
    .name = CNC_DEV_NAME,
    .id_table = cnc_pci_ids,
    .probe = cnc_pci_probe,
    .remove = cnc_pci_remove,
#ifdef CONFIG_OF
    .of_match_table = cnc_of_match,
#endif
};

/*--------------------------------------------------------------------------
 * Module initialization/exit
 *--------------------------------------------------------------------------*/

static int __init cnc_driver_init(void)
{
    int ret;

    pr_info("CNC Controller Driver v%s initializing...\n", CNC_DRIVER_VERSION);

    ret = pci_register_driver(&cnc_pci_driver);
    if (ret) {
        pr_err("Failed to register PCI driver: %d\n", ret);
        return ret;
    }

    pr_info("CNC Controller Driver initialized successfully\n");
    return 0;
}

static void __exit cnc_driver_exit(void)
{
    pci_unregister_driver(&cnc_pci_driver);

    pr_info("CNC Controller Driver unloaded\n");
}

module_init(cnc_driver_init);
module_exit(cnc_driver_exit);

/*--------------------------------------------------------------------------
 * Module information
 *--------------------------------------------------------------------------*/

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("CNC Controller PCIe Driver");
MODULE_AUTHOR("FangTong <fangtong@cnc.com>");
MODULE_VERSION(CNC_DRIVER_VERSION);
MODULE_ALIAS("pci:" __stringify(CNC_VENDOR_ID) ":" __stringify(CNC_DEVICE_ID) "*");
