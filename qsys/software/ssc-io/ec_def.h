//############################################################
// Created on: 2022-04-15

//############################################################
//该头文件主要定义了重要的常量、数据结构及全局变量


//（1）基本类型定义
//========================Start（1）====================================
#define UINT8 unsigned char				//F_T modified
#define UINT16 unsigned short int
#define UINT32 unsigned int
//#define UINT8 unsigned char
//#define UINT16 unsigned int
//#define UINT32 unsigned long
#define INT8 char
#define INT16 int
#define INT32 long
#define UCHAR unsigned char
#define BOOL unsigned char
#define	TRUE 1
#define FALSE 0
//========================END（1）====================================

//ESC基地址定义
//#define ESC_REG_ENTRY 0x2000


//（2）常量定义
//========================Start（2）====================================
//协议相关变量定义，主要为ProcessData和MailBox
#define	MAX_RX_PDOS 0x0001
#define MAX_TX_PDOS 0x0001
#define MIN_PD_WRITE_ADDRESS 0x1000
#define MAX_PD_WRITE_ADDRESS 0x2000
#define MIN_PD_READ_ADDRESS 0x1000
#define MAX_PD_READ_ADDRESS 0x2000
#define NO_OF_PD_INPUT_BUFFER 0x0003
#define NO_OF_PD_OUTPUT_BUFFER 0x0003

#define MAX_PD_INPUT_SIZE 0x0040
#define MAX_PD_OUTPUT_SIZE 0x0040
#define MAX_MB_INPUT_SIZE 0x0040
#define MAX_MB_OUTPUT_SIZE 0x0040
#define MIN_MBX_SIZE 0x0020
#define MAX_MBX_SIZE 0x0400
#define MIN_MBX_WRITE_ADDRESS 0x1000
#define MIN_MBX_READ_ADDRESS 0x1000
#define MAX_MBX_WRUTE_ADDRESS 0x2000
#define MAX_MBX_READ_ADDRESS 0x2000

#define STATE_INIT ((UINT8)0x01)
#define STATE_PREOP ((UINT8)0x02)
#define STATE_BOOT ((UINT8)0x03)
#define STATE_SAFEOP ((UINT8)0x04)
#define STATE_OP ((UINT8)0x08)

#define STATE_MASK ((UINT8)0x0F)
#define STATE_CHANGE ((UINT8)0x10)
#define STATE_ERRACK ((UINT8)0x10)
#define STATE_ERROR ((UINT8)0x10)

#define INIT_2_INIT ((STATE_INIT<<4)|STATE_INIT)
#define INIT_2_PREOP ((STATE_INIT<<4)|STATE_PREOP)
#define INIT_2_SAFEOP ((STATE_INIT<<4)|STATE_SAFEOP)
#define INIT_2_OP ((STATE_INIT<<4)|STATE_OP)

#define PREOP_2_INIT ((STATE_PREOP<<4)|STATE_INIT)
#define PREOP_2_PREOP ((STATE_PREOP<<4)|STATE_PREOP)
#define PREOP_2_SAFEOP ((STATE_PREOP<<4)|STATE_SAFEOP)
#define PREOP_2_OP ((STATE_PREOP<<4)|STATE_OP)

#define SAFEOP_2_INIT ((STATE_SAFEOP<<4)|STATE_INIT)
#define SAFEOP_2_PREOP ((STATE_SAFEOP<<4)|STATE_PREOP)
#define SAFEOP_2_SAFEOP ((STATE_SAFEOP<<4)|STATE_SAFEOP)
#define SAFEOP_2_OP ((STATE_SAFEOP<<4)|STATE_OP)

#define OP_2_INIT ((STATE_OP<<4)|STATE_INIT)
#define OP_2_PREOP ((STATE_OP<<4)|STATE_PREOP)
#define OP_2_SAFEOP ((STATE_OP<<4)|STATE_SAFEOP)
#define OP_2_OP ((STATE_OP<<4)|STATE_OP)

//SM通道定义
#define MAILBOX_WRITE 0
#define MAILBOX_READ 1
#define PROCESS_DATA_OUT 2
#define PROCESS_DATA_IN 3

//相关中断定义，寄存器0x220-0x221位判断
#define AL_CONTROL_EVENT ((UINT16)0x0001)
#define SYNC0_EVENT ((UINT16)0x0400)
#define SYNC1_EVENT ((UINT16)0x0800)
#define SM_CHANGE_EVENT ((UINT16)0x0010)

#define MAILBOX_WRITE_EVENT ((UINT16)0x0100)
#define MAILBOX_READ_EVENT ((UINT16)0x0200)
#define PROCESS_OUTPUT_EVENT ((UINT16)0x0400)
#define PROCESS_INPUT_EVENT ((UINT16)0x0800)

//AL状态码，写入寄存器0x134-0x135
#define ALSTATUSCODE_NOERROR 0x0000
#define ALSTATUSCODE_UNSPECIFIEDERROR 0x0001
#define ALSTATUSCODE_INVALIDALCONTROL 0x0011
#define ALSTATUSCODE_UNKNOWNALCONTROL 0x0012
#define ALSTATUSCODE_BOOTNOTSUPP 0x0013
#define ALSTATUSCODE_NOVALIDFIRMWARE 0x0014
#define ALSTATUSCODE_INVALIDMBXCFGINBOOT 0x0015
#define ALSTATUSCODE_INVALIDMBXCFGINPRE 0x0016
#define ALSTATUSCODE_INVALIDSMCFG 0x0017
#define ALSTATUSCODE_NOVALIDINPUTS 0x0018
#define ALSTATUSCODE_NOVALIDOUTPUTS 0x0019
#define ALSTATUSCODE_SYNCERROR 0x001A
#define ALSTATUSCODE_SMWATCHDOG 0x001B
#define ALSTATUSCODE_SYNCTYPESNOTCOMPATIBLE 0x001C
#define ALSTATUSCODE_INVALIDSMOUTCFG 0x001D
#define ALSTATUSCODE_INVALIDSMINCFG 0x001E

#define ALSTATUSCODE_WAITFORCOLDSTART 0x0020
#define ALSTATUSCODE_WAITFORINIT 0x0021
#define ALSTATUSCODE_WAITFORPREOP 0x0022
#define ALSTATUSCODE_WAITFORSAFEOP 0x0023
#define ALSTATUSCODE_DCINVALIDSYNCCFG 0x0030
#define NOERROR_NOSTATECHANGE 0xFE
#define NOERROR_INWORK 0xFF

//配置出错标识代码
#define SYNCMANCHADDRESS 0x01
#define SYNCMANCHSETTINGS 0x03
#define SYNCMANCHSIZE 0x02

//SYNC MANAGER 寄存器位定义
#define SM_PDINITMASK 0x0D
#define SM_TOGGLEMASTER 0x02
#define SM_ECATENABLE 0x01
#define SM_INITMASK 0x0F
#define ONE_BUFFER 0x02
#define THREE_BUFFER 0x00
#define PD_OUT_BUFFER_TYPE THREE_BUFFER
#define PD_IN_BUFFER_TYPE THREE_BUFFER
#define SM_WRITESETTINGS 0x04
#define SM_READSETTINGS 0x00
#define SM_PDIDISABLE 0x01
#define WATCHDOG_TRIGGER 0x40
#define DC_SYNC0_ACTIVE 0x02
#define DC_SYNC1_ACTIVE	0x04
#define DC_EVENT_MASK 0x0002
//========================END（2）====================================


//（3）ESC寄存器结构体定义
//========================Start（3）====================================
//AL中断事件寄存器定义，0x220-0x223
typedef struct
{
     UINT8 Byte[4];
}UALEVENT;

//中断屏蔽寄存器定义，0x204-0x207
typedef struct
{
     UINT16 Word[2];
}UALEVENTMASK;

//SM结构体定义
typedef struct
{
     UINT16 sm_physical_addr;
	 UINT16 sm_length;
	 UINT8 sm_register_control;
	 UINT8 sm_register_status;
	 UINT8 sm_register_activate;
	 UINT8 sm_register_pdictl;
}TSYNCMAN;

//EEPROM 操作结构体定义
typedef struct
{
     UINT8 eeprom_config;
	 UINT8 eeprom_pdi_acstate;
	 UINT16 eeprom_ctl_status;
	 UINT32 eeprom_addr;
	 UINT32 eeprom_data[2];
}TEEPROM_DEF;

//MII操作结构体订体定义
typedef struct
{
     UINT16 mii_ctl_status;
	 UINT8 mii_phy_addr;
	 UINT8 mii_phy_registeraddr;
	 UINT16 mii_phy_data;
}TMII;

//FMMU结构体定义
typedef struct
{
     UINT32 logical_start_addr;
	 UINT16 length;
	 UINT8 logical_start_bit;
	 UINT8 logical_stop_bit;
	 UINT16 physical_start_bit;
	 UINT8 physical_stop_bit;
	 UINT8 type;
	 UINT8 activate;
	 UINT8 res[3];
}TFMMU;

//分布式时钟结构体定义
typedef struct
{
     UINT32 receive_port[4];
	 UINT32 sys_time[2];
	 UINT8 receive_time_pu[8];
	 UINT32 sys_time_offset[2];
	 UINT32 sys_time_delay;
	 UINT32 sys_time_diff;
	 UINT16 speed_cnt_start;
	 UINT16 speed_cnt_diff;
	 UINT8 sys_filter_depth;
	 UINT16 res27[37];
	 UINT8 cyclic_unit_ctl;
	 UINT8 activation;
	 UINT16 pulse_length;
	 UINT16 res28[5];
	 UINT8 sync0_status;
	 UINT8 sync1_status;
	 UINT32 start_time_cyclic[2];
	 UINT32 next_sync1_pulse[2];
	 UINT32 sync0_cyclic_time;
	 UINT32 sync1_cyclic_time;
	 UINT8 latch0_ctl;
	 UINT8 latch1_ctl;
	 UINT16 res29[2];
	 UINT8 latch0_status;
	 UINT8 latch1_status;
	 UINT32 latch0_time_pedge[2];
	 UINT32 latch0_time_nedge[2];
	 UINT32 latch1_time_pedge[2];
	 UINT32 latch1_time_nedge[2];
	 UINT16 res30[16];
	 UINT32 ecat_bchangee_time;
	 UINT16 res31[17];
	 UINT32 pdi_bstarte_time;
	 UINT32 pdi_bchangee_time;
}TDC;

//ESC寄存器整体结构体设计
typedef struct
{
    UINT8 type;
	UINT8 revision;
	UINT16 build;
	UINT8 fmmus_supported;
	UINT8 sm_supported;
	UINT8 ram_size;
	UINT8 port_descriptor;
	UINT16 esc_feature;
	UINT16 res1[3];
	UINT16 station_addr;
	UINT16 alias_addr;
	UINT16 res2[6];
	UINT8 write_enable;
	UINT8 write_protection;
	UINT16 res3[7];
	UINT8 esc_wrenable;
	UINT8 esc_wrprotection;
	UINT16 res4[7];
	UINT8 esc_reset;
	UINT8 res5[191];
	UINT32 esc_dlctl;
	UINT16 res6[2];
	UINT16 physical_rdwr_offset;
	UINT16 res7[3];
	UINT16 esc_dlstatus;
	UINT16 res8[7];
	UINT16 al_ctl;
	UINT16 res9[7];
	UINT16 al_status;
	UINT16 res10;
	UINT16 al_statuscode;
	UINT16 res11[5];
	UINT16 pdi_ctl;
	UINT16 res12[7];
	UINT32 pdi_config;
	UINT16 res13[86];
	UINT16 ecat_interrupt_mask;
	UINT16 res14;
	UALEVENTMASK al_event_mask;
	UINT16 res15[4];
	UINT16 ecat_interrupt_request;
	UINT16 res16[7];
	UALEVENT AlEvent;
	UINT16 res17[110];
	UINT16 rx_error_counter[4];
	UINT8 rx_error_cntforwarded[4];
	UINT8 ecat_pu_errorcnt;
	UINT8 pdi_error_cnt;
	UINT16 res18;
	UINT8 lost_link_cnt[4];
	UINT16 res19[118];
	UINT16 watchdog_divider;
	UINT16 res20[7];
	UINT16 watchdog_time_pdi;
	UINT16 res21[7];
	UINT16 watchdog_time_pd;
	UINT16 res22[15];
	UINT16 watchdog_status_pd;
	UINT8 watchdog_cnt_pd;
	UINT8 watchdog_cnt_pdi;
	UINT16 res23[94];
	TEEPROM_DEF eeprom_interface;
	TMII mii_man;
	UINT16 res24[117];
	TFMMU fmmu_register[16];
	UINT16 res25[128];
	TSYNCMAN sm_register[8];
	UINT16 res26[64];
	TDC dc_register;
	UINT16 res32[512];
	UINT8 esc_specific_register;
	UINT32 digital_io_outpd;
	UINT16 res33[6];
	UINT16 general_purp_outputs;
	UINT16 res34[3];
	UINT16 general_purp_inputs;
	UINT16 res35[51];
	UINT8 user_ram[128];
}TESC_REG;
//========================END（3）====================================


//（4）全局变量定义
//========================Start（4）====================================
//TESC_REG MEMTYPE * pEsc;
TESC_REG * pEsc;

#define u32 unsigned int
//UALEVENT EscAlEvent;
u32 EscAlEvent;

UINT8 nAlStatus;
UINT8 nAlStatusFailed;
UINT16 nAlStatusCode;
UINT8 nAlControl;
UINT16 nPdInputSize;
UINT16 nPdOutputSize;
UINT16 nEscAddrOutputData;
UINT16 nEscAddrInputData;

//UINT8 MEMTYPE * pPdOutputData;
UINT8 * pPdOutputData;

//UINT8 MEMTYPE * pPdInputData;
UINT8 * pPdInputData;
UINT16 u16SendMbxSize;
UINT16 u16ReceiveMbxSize;
UINT16 u16EscAddrReceiveMbx;
UINT16 u16EscAddrSendMbx;

//UINT8 MEMTYPE * pMbxWriteData;
UINT8 * pMbxWriteData;

//UINT8 MEMTYPE * pMbxReadData;
UINT8 * pMbxReadData;

//程序运行状态
UINT8 m_maxsyncman;
BOOL m_mbxrunning;
BOOL m_pdooutrun;
BOOL m_pdoinrun;

//ESC中断使能标志
BOOL bEscIntEnabled;

BOOL bEcatLocalError=TRUE;

//标志输入输出是否运行在3个缓冲区模式
BOOL b3BufferMode;

//标志看门狗是否触发
BOOL bWdTrigger;

//标志在op状态
BOOL bEcatOutputUpdateRunning;

BOOL bDcSyncActive=FALSE;

//通讯数据储存
UINT8 aPdOutputData[MAX_PD_OUTPUT_SIZE];
UINT8 aPdInputData[MAX_PD_INPUT_SIZE];
UINT8 aMbOutputData[MAX_MB_OUTPUT_SIZE];
UINT8 aMbInputData[MAX_MB_INPUT_SIZE];
UINT32 mb_counter,pd_counter;	
//========================End（4）====================================






















