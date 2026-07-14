#将cnc_card.o编译成内核模块（.ko）
obj-m := cnc_card.o

#变量赋值
KERNELDIR ?= /lib/modules/$(shell uname -r)/build
#KERNELDIR ?= /lib/modules/4.15.0-29-generic/build
PWD := $(shell pwd)

#默认目标（最好设置成伪目标）
#“M=”选项的作用是，当用户需要以某个内核为基础编译一个外部模块的话，需要在make modules 命令中加入“M=dir”，程序会自动到你所指定的dir目录中查找模块源码，将其编译，生成KO文件。
default:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules


#clean目标（最好设置成伪目标）
clean:
	$(RM) *.o *.ko *.mod.c Module.symvers modules.order
