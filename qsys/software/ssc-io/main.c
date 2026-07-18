/*=============================================================

 *
 *
 *  Created by F_T
===============================================================*/



//#include  <stm32f10x_conf.h>
//#include  <stm32f10x.h>
#include <stdio.h>
#include <unistd.h>					//使用usleep（）函数	,延时微妙
#include "ec_def.h"					//自定义EtherCAT相关类型、结构体与变量
#include "system.h"					//硬件信息等
#include "alt_types.h"				//altera宏定义的数据类型
#include "sys/alt_irq.h"			//各中断服务函数相关配置
#include "altera_avalon_spi.h"		//spi
#include "altera_avalon_spi_regs.h"
#include "altera_avalon_pio_regs.h"	//pio

//类型定义（1）
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

#define u32 unsigned int				//不要用UINT8/16/32,使用u8/16/32
#define u16 unsigned short int
#define u8 	unsigned char


//常量定义（2）
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
#define STATE_ERRACK ((UINT8)0x10)		//AL错误应答
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

#define MAILBOX_WRITE_EVENT ((UINT16)0x0100)		//SM0为邮箱写
#define MAILBOX_READ_EVENT ((UINT16)0x0200)			//SM1为邮箱写
#define PROCESS_OUTPUT_EVENT ((UINT16)0x0400)		//SM2为过程数据输出 ， 主站  ---> 从站
#define PROCESS_INPUT_EVENT ((UINT16)0x0800)		//SM2为过程数据输入 ， 主站  <--- 从站

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


//全局变量定义（3）
//u8 m_maxsyncman;
//u32 EscAlEvent;
//UINT8 nAlStatus;
//UINT8 nAlStatusFailed;
//UINT16 nAlStatusCode;
//UINT8 nAlControl;
////UINT16 nPdInputSize;								//F_T modified
////UINT16 nPdOutputSize;
////UINT16 nEscAddrOutputData;
////UINT16 nEscAddrInputData;
//UINT8 m_maxsyncman;
//BOOL m_mbxrunning;
//BOOL m_pdooutrun;
//BOOL m_pdoinrun;
//BOOL bEscIntEnabled;
//u8 aPdOutputData[MAX_PD_OUTPUT_SIZE];
//u8 aPdInputData[MAX_PD_INPUT_SIZE];
//u8 aMbOutputData[MAX_MB_OUTPUT_SIZE];
//u8 aMbInputData[MAX_MB_INPUT_SIZE];
//BOOL bEcatOutputUpdateRunning;
//BOOL bDcSyncActive;

u8 master_8=0x00;
u16 master_16=0x0000;
u32 master_32=0x00000000;
void pdi_irq();


//==================================================================================
//函数定义


//-------------------硬件层相关    Start------------------------------------------------
//---------------spi_rw.c  Start------------------------------------------------
#define MAX_PD_INPUT_SIZE 0x0040
#define MAX_PD_OUTPUT_SIZE 0x0040
#define MAX_MB_INPUT_SIZE 0x0040
#define MAX_MB_OUTPUT_SIZE 0x0040

extern u16 nPdInputSize;
extern u16 nPdOutputSize;
extern u16 nEscAddrOutputData;
extern u16 nEscAddrInputData;
extern u8 aPdOutputData[MAX_PD_OUTPUT_SIZE];
extern u8 aPdInputData[MAX_PD_INPUT_SIZE];
extern u8 aMbOutputData[MAX_MB_OUTPUT_SIZE];
extern u8 aMbInputData[MAX_MB_INPUT_SIZE];


//extern void  Usart_Send_byte(USART_TypeDef* USARTx,u8 Data);
//extern void delay_ms(u16 nms);
//extern u16 Get_Adc(void);


u8 value_in=255;
char temp_flag=0;

u8 spi_tx_rx_8(alt_u32 base,u8 data,u8 hold_flag)
{
	u8 rx_data = 0;
	int status =0;
	int i=6;

	//IOWR_ALTERA_AVALON_SPI_SLAVE_SEL(base, 1 << slave);

	IORD_ALTERA_AVALON_SPI_RXDATA(base);

//	do
//	    {
//	      status = IORD_ALTERA_AVALON_SPI_STATUS(base);
//	    }
//	while (((status & ALTERA_AVALON_SPI_STATUS_TRDY_MSK) == 1 ) &&((status & ALTERA_AVALON_SPI_STATUS_RRDY_MSK) == 0));

	status = IORD_ALTERA_AVALON_SPI_STATUS(base);
	if( (status & ALTERA_AVALON_SPI_STATUS_TRDY_MSK) != 0 )			//TRDY位为1，表示可以发送数据了
		IOWR_ALTERA_AVALON_SPI_TXDATA(base, data);					//在spi_clk控制下，进行一次数据的移位（互换），该函数会输出spi_clk时钟

	i=6;															//延时几个时钟，再开始读接收寄存器数据，此有必要
	while(i--);														//经测试，如果不延时，接收数据为0

	status = IORD_ALTERA_AVALON_SPI_STATUS(base);
	if( (status & ALTERA_AVALON_SPI_STATUS_RRDY_MSK) != 0 )			//RRDY位为1，表示可以接收数据了
		rx_data = IORD_ALTERA_AVALON_SPI_RXDATA(base);				//读取数据，此时并不产生spi_clk时钟

	if(hold_flag == 0)												//当hold_flag为0时，延时几个时钟拉高spi_sel片选信号
	{
		i=5;
		while(i--);
		IOWR_ALTERA_AVALON_SPI_CONTROL(base, 0);
	}
	return rx_data;
}

u8 spi_read_8(u16 address)
{
	 u8 high;
	 u8 low;
	 u8 ctrl_stop;
	 u8 result;
	 u16 temp;
	 temp=(address<<3)|(0x02);      //地址+读命令字0x02
	 high=(u8)(temp>>8);
	 low=(u8)temp;

	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&high,
	 								0,NULL,
	 								1);
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&low,
	 								0,NULL,
	 								1);
	 result = 0;
//	 ctrl_stop = 0xFF;										//ft 1.0 有问题：这里alt_avalon_spi_command函数是先发送一个ctrl_stop数据；
//	 alt_avalon_spi_command(SPI_BASE,0,						//然后再读一个数据，并且在读数据的时候，mosi一直为0
//	 								1,&ctrl_stop,
//	 								1,&result,
//	 								0);
	 result = spi_tx_rx_8(SPI_BASE,0xFF,0);					//ft 2.0


//	 GPIO_ResetBits(GPIOA, GPIO_Pin_4);     //片选有效
//	 SPI1_ReadWriteByte(high);
//	 SPI1_ReadWriteByte(low);
//	 result=SPI1_ReadWriteByte(0xFF);
//	 GPIO_SetBits(GPIOA, GPIO_Pin_4);
	 return result;
}

u16 spi_read_16(u16 address)
{
	 u8 high;
	 u8 low;
	 u8 ctrl_stop;
	 u8 result1;
	 u8 result2;
	 u16 temp;
	 temp=(address<<3)|(0x02);
	 high=(u8)(temp>>8);
	 low=(u8)temp;
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&high,
	 								0,NULL,
	 								1);
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&low,
	 								0,NULL,
	 								1);
	 result1 = 0;
//	 ctrl_stop = 0x00;										//ft 1.0 有问题
//	 alt_avalon_spi_command(SPI_BASE,0,
//	 								1,&ctrl_stop,
//	 								1,&result1,
//	 								1);
	 result1 = spi_tx_rx_8(SPI_BASE,0x00,1);

	 result2 = 0;
//	 ctrl_stop = 0xFF;										//ft 1.0 有问题
//	 alt_avalon_spi_command(SPI_BASE,0,
//	 								1,&ctrl_stop,
//	 								1,&result2,
//	 								0);
	 result2 = spi_tx_rx_8(SPI_BASE,0xFF,0);

//	 GPIO_ResetBits(GPIOA, GPIO_Pin_4);
//	 SPI1_ReadWriteByte(high);
//	 SPI1_ReadWriteByte(low);
//	 result1=SPI1_ReadWriteByte(0x00);
//	 result2=SPI1_ReadWriteByte(0xFF);
//	 GPIO_SetBits(GPIOA, GPIO_Pin_4);
	 return (result2<<8)|(result1);
}

u32 spi_read_32(u16 address)
{
     u8 high;
	 u8 low;
	 u8 ctrl_stop;
	 u8 result1;
	 u8 result2;
	 u8 result3;
	 u8 result4;
	 u16 temp;
	 temp=(address<<3)|(0x02);
	 high=(u8)(temp>>8);
	 low=(u8)temp;
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&high,
	 								0,NULL,
	 								1);
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&low,
	 								0,NULL,
	 								1);

	 result1 = 0;
//	 ctrl_stop = 0x00;										//ft 1.0 有问题
//	 alt_avalon_spi_command(SPI_BASE,0,
//	 								1,&ctrl_stop,
//	 								1,&result1,
//	 								1);
	 result1 = spi_tx_rx_8(SPI_BASE,0x00,1);

	 result2 = 0;
//	 ctrl_stop = 0x00;										//ft 1.0 有问题
//	 alt_avalon_spi_command(SPI_BASE,0,
//	 								1,&ctrl_stop,
//	 								1,&result2,
//	 								1);
	 result2 = spi_tx_rx_8(SPI_BASE,0x00,1);

	 result3 = 0;
//	 ctrl_stop = 0x00;										//ft 1.0 有问题
//	 alt_avalon_spi_command(SPI_BASE,0,
//	 								1,&ctrl_stop,
//	 								1,&result3,
//	 								1);
	 result3 = spi_tx_rx_8(SPI_BASE,0x00,1);

	 result4 = 0;
//	 ctrl_stop = 0xFF;										//ft 1.0 有问题
//	 alt_avalon_spi_command(SPI_BASE,0,
//	 								1,&ctrl_stop,
//	 								1,&result4,
//	 								0);
	 result4 = spi_tx_rx_8(SPI_BASE,0xFF,0);

//	 GPIO_ResetBits(GPIOA, GPIO_Pin_4);
//	 SPI1_ReadWriteByte(high);
//	 SPI1_ReadWriteByte(low);
//	 result1=SPI1_ReadWriteByte(0x00);
//	 result2=SPI1_ReadWriteByte(0x00);
//	 result3=SPI1_ReadWriteByte(0x00);
//	 result4=SPI1_ReadWriteByte(0xFF);
//	 GPIO_SetBits(GPIOA, GPIO_Pin_4);
	 return (result4<<24)|(result3<<16)|(result2<<8)|(result1);
}

void spi_write_8(u16 address,u8 data)
{
     u8 high;
	 u8 low;
//	 u8 result=data;
	 u16 temp;
	 temp=(address<<3)|(0x04);      //地址+写命令字0x04
	 high=(u8)(temp>>8);
	 low=(u8)temp;
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&high,
	 								0,NULL,
	 								1);
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&low,
	 								0,NULL,
	 								1);
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&data,
	 								0,NULL,
	 								0);

//	 GPIO_ResetBits(GPIOA, GPIO_Pin_4);     //片选有效
//	 SPI1_ReadWriteByte(high);
//	 SPI1_ReadWriteByte(low);
//	 SPI1_ReadWriteByte(data);
//	 GPIO_SetBits(GPIOA, GPIO_Pin_4);
}

void spi_write_16(u16 address,u16 data)
{
     u8 high;
	 u8 low;
//	 u8 result;
	 u16 temp;
	 temp=(address<<3)|(0x04);
	 high=(u8)(temp>>8);
	 low=(u8)temp;
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&high,
	 								0,NULL,
	 								1);
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&low,
	 								0,NULL,
	 								1);
	 high=(u8)(data>>8);
	 low=(u8)data;
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&low,
	 								0,NULL,
	 								1);
	 alt_avalon_spi_command(SPI_BASE,0,
	 								1,&high,
	 								0,NULL,
	 								0);

//	 GPIO_ResetBits(GPIOA, GPIO_Pin_4);
//	 SPI1_ReadWriteByte(high);
//	 SPI1_ReadWriteByte(low);
//	 SPI1_ReadWriteByte((u8)data);
//	 SPI1_ReadWriteByte((u8)(data>>8));
//	 GPIO_SetBits(GPIOA, GPIO_Pin_4);
}

u32 readoutputdata(void)
{
	u16 i;
	u16 address;
	u32 tmp;
//
	for(i=0,address=nEscAddrOutputData;i<nPdOutputSize;i++,address++)
	{
	    aPdOutputData[i]= spi_read_8(address);
	}
	tmp=aPdOutputData[0]+(aPdOutputData[1]<<8)+(aPdOutputData[2]<<16)+(aPdOutputData[3]<<24);//接收主站发来的数据
//	GPIO_Write(GPIOE,tmp);//通过LED上进行显示
	return tmp;
}

void writeinputdata(void)
{
   u16 i;
   u16 address;
//   u16 value=0;
//
//	 value=Get_Adc();
//	 value=value*3300/4096;// 转换成mV，0-3300mV
//
   for(i=0,address=nEscAddrInputData;i<nPdInputSize;i++,address++)
	 {
	   	 	  if(i==0)spi_write_8(address,0x11);
		 else if(i==1)spi_write_8(address,0x22);
		 else if(i==2)spi_write_8(address,0x33);//模拟量分低位发送
		 else if(i==3)spi_write_8(address,0x44);
		 else spi_write_8(address,0);
	 }

}
//-------------------spi_rw.c  End--------------------------------------------

void HW_init()
{
//	RCC_Configuration();
//	GPIO_init();    //不用-137
//	Adc_Init();     //不用-137
//	NVIC_Configuration();
//	USART4_Config(UART4,115200);
//	SPI1_Init();
//	SPI1_SetSpeed(SPI_BaudRatePrescaler_4);
//

//注册中断服务函数方式1：
//	int alt_irq_register (alt_u32 id,
//	                      void* context,
//	                      alt_isr_func handler);

//注册中断服务函数方式2：
//	extern int alt_ic_isr_register(alt_u32 ic_id,
//	                        alt_u32 irq,
//	                        alt_isr_func isr,
//	                        void *isr_context,
//	                        void *flags);

//	IOWR_ALTERA_AVALON_PIO_IRQ_MASK(PIO_IRQ_BASE, 0xff);		//使能中断
//	IOWR_ALTERA_AVALON_PIO_EDGE_CAP(PIO_IRQ_BASE, 0xff);		//清楚中断标志
//	alt_ic_isr_register(PIO_IRQ_IRQ_INTERRUPT_CONTROLLER_ID,	//注册中断函数
//						PIO_IRQ_IRQ,
//						pdi_irq,
//		                NULL,
//		                0);

}
//-------------------硬件层相关    End---------------------------------------------------



//-------------------协议层相关    Start--------------------------------------------------
//---------------------status.c Start-------------------------------------------
TSYNCMAN get_sm(u8 channel)
{
     TSYNCMAN temp;
     u16 address;
	 address=0x0800+channel*0x08;
	 temp.sm_physical_addr=spi_read_16(address);        //返回SM通道的物理起始地址
	 temp.sm_length=spi_read_16(address+2);
	 temp.sm_register_control=spi_read_8(address+4);
	 temp.sm_register_status=spi_read_8(address+5);
	 temp.sm_register_activate=spi_read_8(address+6);
	 temp.sm_register_pdictl=spi_read_8(address+7);
	 return temp;
}

void set_intmask(u16 intMask)
{
    u16 mask;
	mask= spi_read_16(0x0204);
	mask=mask|intMask;
	spi_write_16(0x0204,mask);
}

void reset_intmask(u16 intMask)
{
    u16 mask;
	mask= spi_read_16(0x0204);
	mask=mask&intMask;
	spi_write_16(0x0204,mask);
}

void enable_syncmanchannel(u8 channel)
{
    u16	address;
	u8 temp;
	address=0x0800+channel*0x08;
	temp=spi_read_8(address+7);
	temp &=~((u8)SM_PDIDISABLE);
	spi_write_8(address+7,temp);
}

void disable_syncmanchannel(u8 channel)
{
    u16	address;
	u8 temp;
	address=0x0800+channel*0x08;
	temp=spi_read_8(address+7);
	temp |=((u8)SM_PDIDISABLE);
	spi_write_8(address+7,temp);
}

void SetAlStatus(u16 alstatus,u16 alstatuscode)
{
    spi_write_16(0x0130,alstatus);
	if(alstatuscode!=0xFF)
	spi_write_16(0x0134,alstatuscode);
}

u8 checksmsettings(u8 maxChannel)
{
     return 0;
}

u8 mbx_startmailboxhandler(void)
{
    u16 ReceiveMbxSize;
	u16 EscAddrReceiveMbx;
	u16 SendMbxSize;
	u16 EscAddrSendMbx;
    TSYNCMAN pSyncMan;
	pSyncMan=get_sm(MAILBOX_WRITE);
	ReceiveMbxSize=	pSyncMan.sm_length;
	EscAddrReceiveMbx=pSyncMan.sm_physical_addr;
//  pMbxWriteData=

	pSyncMan=get_sm(MAILBOX_READ);
	SendMbxSize=pSyncMan.sm_length;
	EscAddrSendMbx=pSyncMan.sm_physical_addr;
//  pMbxReadData=
//  省略检查内存重叠。。。

    enable_syncmanchannel(MAILBOX_WRITE);
	enable_syncmanchannel(MAILBOX_READ);
	m_mbxrunning=TRUE;
    return 0;
}

u8 pdo_startinputhandler(void)
{
    u16 nPdInputBuffer=3;
	u16 nPdOutputBuffer=3;
	TSYNCMAN pSyncMan;
	u16 intMask=0;
	u8 dcControl;
	u32 cycleTime;

	pSyncMan=get_sm(PROCESS_DATA_OUT);      //PROCESS_DATA_OUT=2，即获取通道2的信息
	nEscAddrOutputData=pSyncMan.sm_physical_addr;
	nPdOutputSize=pSyncMan.sm_length;
//	pPdOutputData=
    if(pSyncMan.sm_register_control & ONE_BUFFER)
	nPdOutputBuffer=1;

//	Usart_Send_byte(UART4,nPdOutputSize>>8);
//	Usart_Send_byte(UART4,nPdOutputSize);

	pSyncMan=get_sm(PROCESS_DATA_IN);
	nEscAddrInputData=pSyncMan.sm_physical_addr;
	nPdInputSize=pSyncMan.sm_length;
//  pPdInputData=
    if(pSyncMan.sm_register_control & ONE_BUFFER)
	nPdInputBuffer=1;

//	Usart_Send_byte(UART4,nPdInputSize>>8);
//	Usart_Send_byte(UART4,nPdInputSize);

	if(pSyncMan.sm_length==0)
	return ALSTATUSCODE_NOERROR;

//省略检测内存重叠

	dcControl=spi_read_8(0x0981);
	if(dcControl & (DC_SYNC0_ACTIVE|DC_SYNC1_ACTIVE))
	{//分布式时钟启用，检查sync0\sync1设置
//	    if(dcControl!=(DC_CYCLIC_ACTIVE|DC_SYNC_ACTIVE))
//		    return ALSTATUSCODE_DCINVALIDSYNCCFG;
		//激活DC事件
		intMask=DC_EVENT_MASK;
		bDcSyncActive=TRUE;

		cycleTime=spi_read_32(0x09A0);
    }

	if(nPdOutputSize!=0)
    	intMask|=PROCESS_OUTPUT_EVENT;
	else
	    intMask|=PROCESS_INPUT_EVENT;

    if(nPdInputSize>0)
	{
	    enable_syncmanchannel(PROCESS_DATA_IN);
		m_pdoinrun=TRUE;
	}
    if(nPdOutputSize>0)
	{
	    if(!bEcatLocalError)
		enable_syncmanchannel(PROCESS_DATA_OUT);
		m_pdooutrun=TRUE;
	}
    set_intmask(intMask);

    return 0;
}

u8 pdo_startoutputhandler(void)
{
    u16 result=0;
	if(nPdOutputSize>0)
	{
	    if(bEcatLocalError && (result==0||NOERROR_INWORK))
		{
		    enable_syncmanchannel(PROCESS_DATA_OUT);
			bEcatLocalError=FALSE;
		}
		if(result!=0)
		{
		    if(result!=NOERROR_INWORK)
			bEcatLocalError=TRUE;
			return result;
		}
		m_pdooutrun=TRUE;
	}
	bEcatOutputUpdateRunning=TRUE;
    return 0;
}

void mbx_stopmailboxhandler(void)
{
	m_mbxrunning=FALSE;
	disable_syncmanchannel(MAILBOX_WRITE);
	disable_syncmanchannel(MAILBOX_READ);
}

u8 pdo_stopinputhandler(void)
{
    disable_syncmanchannel(PROCESS_DATA_OUT);
	reset_intmask(~(SYNC0_EVENT|SYNC1_EVENT|PROCESS_INPUT_EVENT|PROCESS_OUTPUT_EVENT));
	bEscIntEnabled=FALSE;
	m_pdoinrun=FALSE;
	disable_syncmanchannel(PROCESS_DATA_IN);
    return 0;
}

u8 pdo_stopoutputhandler(void)
{
    bEcatOutputUpdateRunning=FALSE;
    return 0;
}

void al_statemachine(u16 alcontrolvar)
{
	u8 result=0;
	u8 statetrans;
	u8 val;
	u8 al;				//ft 2.0
	al=alcontrolvar;

	if(alcontrolvar & STATE_ERRACK)		//主站应答了错误，即根据状态嘛处理了错误
	{
	    nAlStatus &= ~STATE_ERROR;		//从站清零状态错误提示位
	}
	else if((nAlStatus & STATE_ERROR)&&(((u8)alcontrolvar & STATE_MASK)>(nAlStatus & STATE_MASK)))	//从站出现状态错误，且主站仍在请求状态向OP方向转换
	return;

	alcontrolvar &= STATE_MASK;
	statetrans=nAlStatus;
	statetrans<<=4;
	statetrans +=alcontrolvar; //得到转换状态变量（高4位为当前状态，低4位为请求转换的状态）

	switch(statetrans)
	{
	    case INIT_2_PREOP:
		case OP_2_PREOP:
		case SAFEOP_2_PREOP:
		case PREOP_2_PREOP:
		    val=MAILBOX_READ+1;
			result=checksmsettings(val);
			break;
		case PREOP_2_SAFEOP:
		case SAFEOP_2_OP:
		case OP_2_SAFEOP:
		case SAFEOP_2_SAFEOP:
		case OP_2_OP:
		    result=checksmsettings(m_maxsyncman);
			break;
	}

	//如果SM设置正确，则进行下一步
	if(result==0)
	{
	    switch(statetrans)
		{
		    case INIT_2_PREOP:
			    result=mbx_startmailboxhandler();
			    break;
			case PREOP_2_SAFEOP:
			    result=pdo_startinputhandler();
			    break;
			case SAFEOP_2_OP:
			    result=pdo_startoutputhandler();
			    break;

			case OP_2_INIT:
			case SAFEOP_2_INIT:
			case PREOP_2_INIT:
			    mbx_stopmailboxhandler();
			case OP_2_PREOP:
			case SAFEOP_2_PREOP:
			    result=pdo_stopinputhandler();
			    if(result!=0)
				break;
			case OP_2_SAFEOP:
			    result=pdo_stopoutputhandler();
			    break;

			case INIT_2_INIT:
			case PREOP_2_PREOP:
			case SAFEOP_2_SAFEOP:
			case OP_2_OP:
			    result=NOERROR_NOSTATECHANGE;
				break;
			case INIT_2_SAFEOP:
			case INIT_2_OP:
			case PREOP_2_OP:
			    result=ALSTATUSCODE_INVALIDALCONTROL;
				break;
			default:
			    result=ALSTATUSCODE_UNKNOWNALCONTROL;
				break;
		}
	}
	else
	{
	    switch(nAlStatus)
		{
		    case STATE_OP:
			    pdo_stopoutputhandler();
				break;
			case STATE_SAFEOP:
			    pdo_stopinputhandler();
			case STATE_PREOP:
			    if(result==ALSTATUSCODE_INVALIDMBXCFGINPRE)
				{
				    mbx_stopmailboxhandler();
					nAlStatus=STATE_INIT;
				}
				else
				{
				    nAlStatus=STATE_PREOP;
				}
				break;
		}
	}

	//设置alStatus和alStatusCode
	if((u8)alcontrolvar!=(nAlStatus & STATE_MASK))
	{
	    if(result!=0)
		{
		    nAlStatusFailed = nAlStatus;
			nAlStatus |= STATE_CHANGE;
		}
		else
		    {
		    if(nAlStatusCode!=0)
			{
			    result=nAlStatusCode;
				nAlStatusFailed =alcontrolvar;
				alcontrolvar|=STATE_CHANGE;
			}
			else if(alcontrolvar<=nAlStatusFailed)
			{
			    result=0xFF;
			}
			else
			    nAlStatusFailed=0;
			nAlStatus=alcontrolvar;
			}
		SetAlStatus(nAlStatus,result);
		nAlStatusCode=0;
		}
	else
	{
	    SetAlStatus(nAlStatus,0xFF);
	}

}
//---------------------status.c End-------------------------------------------------
void rw_test()
{
	u8 intMask1;
	u16 intMask2;
	u32 info = 0;

	//test rw_8
	do
	{
		intMask1 = 1;
		spi_write_8(0x0204,intMask1);
		intMask1 = 0;
		intMask1 = spi_read_8(0x0204);
	}
	while(intMask1 != 0x1);

	//test rw_16
	do
	{
		intMask2 = 0x93;
		spi_write_16(0x0204,intMask2);
		intMask2 = 0;
		intMask2 = spi_read_16(0x0204);
	}
	while(intMask2 != 0x93);

	//test r_32
	do
	{
		info = spi_read_32(0x0004);
	}
	while(info != 0x0f080808);
}


void ECAT_init()
{
    u8 temp_DC;			//ft 2.0

    rw_test();

    //清除事件屏蔽寄存器
	spi_write_16(0x0204,0x0000);
	//清除事件请求寄存器
	spi_write_16(0x0206,0x0000);
	//读取ESC支持的SM通道数目
	do{
	m_maxsyncman=0;
    m_maxsyncman=spi_read_8(0x0005);
	}while(m_maxsyncman == 0);

	nAlStatus=STATE_INIT;
	//设置当前状态为初始化状态
	SetAlStatus(nAlStatus,0);

	//初始化通讯变量
	nPdInputSize=0;
	nPdOutputSize=0;
//	bEcatLocalError=0;
	bEscIntEnabled=FALSE;		//IRQ中断是否使能
}
//-------------------协议层相关    End----------------------------------------------------


//-------------------应用层相关    Start--------------------------------------------------
void dda_out(u32 data)
{
	IOWR_ALTERA_AVALON_PIO_DATA(PIO_DDA_BASE, data);
//
//	IOWR_ALTERA_AVALON_PIO_DATA(PIO_START_BASE, 0);
//	//usleep(1);		//延时1us
//	IOWR_ALTERA_AVALON_PIO_DATA(PIO_START_BASE, 1);
//	//usleep(1);		//延时1us
//	IOWR_ALTERA_AVALON_PIO_DATA(PIO_START_BASE, 0);
//
//	IOWR_ALTERA_AVALON_PIO_DATA(PIO_DDA_BASE, 0);
}

void free_run()
{
	u32 tmp = 0;
	if((u8)(EscAlEvent>>8)&(PROCESS_OUTPUT_EVENT>>8))
	{
	    if(bEcatOutputUpdateRunning==TRUE)
	    tmp = readoutputdata();
		writeinputdata();
		dda_out(tmp);
	}

}

void pdi_irq()
{
	u32 tmp;
	if((u8)(EscAlEvent>>8)&(PROCESS_OUTPUT_EVENT>>8))
	{
	    if(bEcatOutputUpdateRunning==TRUE)
	    tmp = readoutputdata();
	    //printf("rx_pdo=  %d\n",tmp);
		writeinputdata();
		dda_out(tmp);
	}
	IOWR_ALTERA_AVALON_PIO_EDGE_CAP(PIO_IRQ_BASE, 0xff);
}

//邮箱数据
void mb_process()
{

}

void al_event()
{
    u16 alcontrol;
	EscAlEvent=spi_read_32(0x0220);
	//判断是否有AL控制变化事件发生
	if((u8)EscAlEvent & AL_CONTROL_EVENT)
	{ //是，读AL控制寄存器0x120以响应事件
	    alcontrol=spi_read_16(0x0120);
		nAlControl=alcontrol;
		//调用状态机处理函数
		al_statemachine(alcontrol);     
	}
	if(m_mbxrunning)
	{
	    if((u8)(EscAlEvent>>8) & (MAILBOX_WRITE_EVENT>>8))
		mb_process();
	}
}

int main()
{
//    int i=0;
    HW_init();
	ECAT_init();
	IOWR_ALTERA_AVALON_PIO_DATA(PIO_DDA_BASE, 1);
	//bEscIntEnabled=TRUE;
 
    while(1)
	{
        //读应用事件请求寄存器
        EscAlEvent=spi_read_32(0x0220);
		if(!bEscIntEnabled)
		{
		     //未使能中断，处于自由运行模式
		    free_run();	    //查看周期性数据   ft 2.0
		}
		al_event();	  //应用层事件处 理，包括状态机和非周期通讯
	   
//		delay_ms(300);
	 }

    return 0;
}



//void delay_ms(u16 nms)			//ft 2.0
//{
//	u16 i=0;
//	while(nms--)
//	{
//	     i=12000;
//		 while(i--);
//	}
//}
