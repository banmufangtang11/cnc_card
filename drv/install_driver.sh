#!/bin/Bash
#编译
make

#安装模块
insmod cnc_card.ko

#创建设备节点
mknod /dev/cnc_card c 100 0

make clean


#test 
