#ifndef _TEST_CMD_H

#define _TEST_CMD_H


#define TEST_MAGIC 'x' //定义（幻数/设备类型）

#define TEST_MAX_NR 60//定义命令的最大序数，只有一个命令当然是1



#define AXIS1_ON _IO(TEST_MAGIC, 1)
#define AXIS2_ON _IO(TEST_MAGIC, 2)
#define AXIS3_ON _IO(TEST_MAGIC, 3)
#define AXIS4_ON _IO(TEST_MAGIC, 4)
#define AXIS5_ON _IO(TEST_MAGIC, 5)
#define AXIS6_ON _IO(TEST_MAGIC, 6)
#define AXIS7_ON _IO(TEST_MAGIC, 7)
#define AXIS8_ON _IO(TEST_MAGIC, 8)


#define AXIS1_OFF _IO(TEST_MAGIC, 9)
#define AXIS2_OFF _IO(TEST_MAGIC, 10)
#define AXIS3_OFF _IO(TEST_MAGIC, 11)
#define AXIS4_OFF _IO(TEST_MAGIC, 12)
#define AXIS5_OFF _IO(TEST_MAGIC, 13)
#define AXIS6_OFF _IO(TEST_MAGIC, 14)
#define AXIS7_OFF _IO(TEST_MAGIC, 15)
#define AXIS8_OFF _IO(TEST_MAGIC, 16)

#define XP_ON _IO(TEST_MAGIC, 17)
#define XN_ON _IO(TEST_MAGIC, 18)
#define YP_ON _IO(TEST_MAGIC, 19)
#define YN_ON _IO(TEST_MAGIC, 20)
#define ZP_ON _IO(TEST_MAGIC, 21)
#define ZN_ON _IO(TEST_MAGIC, 22)
#define AP_ON _IO(TEST_MAGIC, 23)
#define AN_ON _IO(TEST_MAGIC, 24)
#define BP_ON _IO(TEST_MAGIC, 25)
#define BN_ON _IO(TEST_MAGIC, 26)

#define XP_OFF _IO(TEST_MAGIC, 27)
#define XN_OFF _IO(TEST_MAGIC, 28)
#define YP_OFF _IO(TEST_MAGIC, 29)
#define YN_OFF _IO(TEST_MAGIC, 30)
#define ZP_OFF _IO(TEST_MAGIC, 31)
#define ZN_OFF _IO(TEST_MAGIC, 32)
#define AP_OFF _IO(TEST_MAGIC, 33)
#define AN_OFF _IO(TEST_MAGIC, 34)
#define BP_OFF _IO(TEST_MAGIC, 35)
#define BN_OFF _IO(TEST_MAGIC, 36)

#define RETURN0_OFF _IO(TEST_MAGIC, 37)
#define RETURN0_ON _IO(TEST_MAGIC, 38)

#define COOLANT_ON _IO(TEST_MAGIC, 39)   //lzz,ckh
#define COOLANT_OFF _IO(TEST_MAGIC, 40)   //lzz,ckh

#define SPINDLE_POS _IO(TEST_MAGIC, 41)   //lzz,ckh--Positive and Reverse Control of Machine Tool Spindle
#define SPINDLE_REV _IO(TEST_MAGIC, 42)   //lzz,ckh
#define SPINDLE_STOP _IO(TEST_MAGIC, 43)   //lzz,ckh

//---lzz
#define SET_ON _IO(TEST_MAGIC, 44) 
#define SET_OFF _IO(TEST_MAGIC, 45)
#define MAG_ON _IO(TEST_MAGIC, 46)
#define MAG_OFF _IO(TEST_MAGIC, 47)
#define MAG_GO _IO(TEST_MAGIC, 48)
#define MAG_BACK _IO(TEST_MAGIC, 49)
#define LOOSE_ON _IO(TEST_MAGIC, 50)
#define LOOSE_OFF _IO(TEST_MAGIC, 51)

//#define MAG_ROT _IO(TEST_MAGIC, 52)
#define AUX_CLR _IO(TEST_MAGIC, 52)
#define TOOL_1 _IO(TEST_MAGIC, 53)
#define TOOL_2 _IO(TEST_MAGIC, 54)
#define TOOL_3 _IO(TEST_MAGIC, 55)
#define TOOL_4 _IO(TEST_MAGIC, 56)
#define TOOL_5 _IO(TEST_MAGIC, 57)
#define TOOL_6 _IO(TEST_MAGIC, 58)
#define TOOL_7 _IO(TEST_MAGIC, 59)
#define TOOL_8 _IO(TEST_MAGIC, 60)

//----
#endif 
