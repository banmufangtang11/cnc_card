library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity txproc is port(
clk,rst : in std_logic;															--一位一般定义为std_logic，多位定义std_logic_vector（类似数组）
txfifodq : out std_logic_vector(71 downto 0);							--输出发送模块的状态
memrdreq,memrddxfer : in std_logic;											--存储器读请求，第二个接VCC
memrdack : out std_logic;														--存储器写完成
tag,busnum : in std_logic_vector(7 downto 0);							--TLP的tag字段
reqid : in std_logic_vector(15 downto 0);									--TLP的requester id字段
tc : in std_logic_vector(2 downto 0);										--TLP的TC字段
attrib : in std_logic_vector(1 downto 0);									--TLP的attribute字段
devnum : in std_logic_vector(4 downto 0);									--TLP的设备ID
tx_cred : in std_logic_vector(35 downto 0);								--TLP的发送数量
tx_st_ready,memsel1,data_rd,data_wr : in std_logic;					--发送准备信号，存储空间1选择，读数据，写数据信号
ext_add : in std_logic_vector(21 downto 0);								--偏移地址
extdq : inout std_logic_vector(31 downto 0);								--中间寄存器
fifordempty,app_int_ack,rxfifowr : in std_logic;						--***
fiforddw : in std_logic_vector(8 downto 0);								--***
fifodqin : in std_logic_vector(63 downto 0);								--***
fiford,clrfifo,dmaen,app_int_sts : out std_logic;						--***
tx_st_err,tx_st_valid,led1,led2,led3,led4 : buffer std_logic;		--Avalon64位发送数据有效信号 buffer类似out输出，不过buffer允许内部引用该信号

ext_int_req : in std_logic;													--中断请求信号
iosel: in std_logic; 															--IO空间选择

wrreq: out std_logic;															--数据接收FIFO写信号

set_ref : in std_logic;															--参考点设置信号

posx : in std_logic_vector(31 downto 0);									--各轴脉冲计数输入（接编码器计数模块输出）
posy : in std_logic_vector(31 downto 0);
posz : in std_logic_vector(31 downto 0);
posa : in std_logic_vector(31 downto 0);									

card_posx : in std_logic_vector(31 downto 0);							--PC到卡的粗插补数据经精插补后的脉冲计数值
card_posy : in std_logic_vector(31 downto 0);
card_posz : in std_logic_vector(31 downto 0);
card_posa : in std_logic_vector(31 downto 0);

delta_x : in std_logic_vector(31 downto 0);								--***
delta_y : in std_logic_vector(31 downto 0);
delta_z : in std_logic_vector(31 downto 0);
delta_a : in std_logic_vector(31 downto 0);

s1,s2,s3,s4,s5,s6 : in std_logic; --v2.5  限位开关

posx_ref : out std_logic_vector(31 downto 0);							--各轴参考点寄存器
posy_ref : out std_logic_vector(31 downto 0);
posz_ref : out std_logic_vector(31 downto 0);
posa_ref : out std_logic_vector(31 downto 0);

card_posx_ref : out std_logic_vector(31 downto 0);						--***
card_posy_ref : out std_logic_vector(31 downto 0);
card_posz_ref : out std_logic_vector(31 downto 0);
card_posa_ref : out std_logic_vector(31 downto 0);

co1,co2,co3,co4,co5,co6,co7,co8: out std_logic;  --v2.8 联动轴使能

xen,yen,zen,aen : out std_logic;  --v2.5   四轴使能（未使用）

jog_posx,jog_negx,jog_posy,jog_negy,jog_posz,jog_negz,jog_posa,jog_nega: out std_logic;  --v3.2
szero_soft: out std_logic;  --v3.2  PC点动控制
----------------------------------------------------------------------------------------------------
m_cool,m_cw,m_atcw: out std_logic;  --v4.1 M指令（主轴正反转，加工吹气）

aux_ctl: out std_logic_vector(31 downto 0);  --v5.3 刀库管理
aux_back : in std_logic_vector(31 downto 0)

);

end txproc;
architecture beha of txproc is 
--下面 TYPE xx IS 为用户自定义数据类型，用于发送状态机状态跳转 （txstate/发送状态类型）
type txstate is (idle,memrdcpldhead1,memrdcpldhead2,memrdcpldwaitst1,memrdcpldwaitst2,memrdcplddatast1,memrdcplddone
                 ,memrdcpldwaitst3,memrdcpldwaitst4,memrdcpldwaitst5,memrdcpldwaitst6,memrdcpldwaitst7
					  ,dmawrwaitst1,dmawrhead1,dmawrhead2,dmawrdatast1,dmawrdatast2,dmawrwaitst3,dmawrwaitst4,dmawrwaitst5,dmawrwaitst6,dmawrwaitst7,dmawrwaitst8
					  ,dmardwaitst1,dmardwaitst2,dmardhead1,dmardhead2,dmardwaitst3,dmardwaitst4,dmardwaitst5,dmardwaitst6);
signal pre_state,nxt_state : txstate;

--***
signal txen : std_logic;
signal memrdcpheadrega,memrdcpheadregb,memrdcpdatareg,dmawrheadrega,dmawrheadregb,dmardheadrega,dmardheadregb : std_logic_vector(63 downto 0);
signal postheaden,postdataen,npheaden,npdataen,cpheaden,cpdataen : std_logic;
signal intregsel,headregsel,countregsel,cmdregsel,clrcmd,startdmawr,countale,clrct,dmarden,clrcmd1 : std_logic;

--数据寄存器
signal pctocardregsel : std_logic;
signal pctocardreg : std_logic_vector(31 downto 0);

--设备状态寄存器
signal dcsregsel : std_logic;  --v2.5
signal dcsreg : std_logic_vector(31 downto 0);  --v2.5

--运动控制模式寄存器
signal mcmregsel : std_logic;  --v2.5
signal mcmreg : std_logic_vector(31 downto 0);  --v2.5

--***联动轴寄存器
signal co1regsel,co2regsel,co3regsel,co4regsel,co5regsel,co6regsel,co7regsel,co8regsel : std_logic;  --v2.8
signal co1reg,co2reg,co3reg,co4reg,co5reg,co6reg,co7reg,co8reg : std_logic_vector(31 downto 0);  --v2.8


----------------------------------------------------------------------------------------pc
--PC***寄存器
signal posx_regsel,posy_regsel,posz_regsel,posa_regsel : std_logic;
signal posx_reg,posy_reg,posz_reg,posa_reg : std_logic_vector(31 downto 0);

--PC参考点位置寄存器
signal posx_ref_regsel,posy_ref_regsel,posz_ref_regsel,posa_ref_regsel : std_logic;
signal posx_ref_reg,posy_ref_reg,posz_ref_reg,posa_ref_reg : std_logic_vector(31 downto 0);


--PC绝对坐标寄存器
signal posx_real_regsel,posy_real_regsel,posz_real_regsel,posa_real_regsel : std_logic;
signal posx_real_reg,posy_real_reg,posz_real_reg,posa_real_reg : std_logic_vector(31 downto 0);

--PC断点位置寄存器
signal posx_break_regsel,posy_break_regsel,posz_break_regsel,posa_break_regsel : std_logic;  --v2.5
signal posx_break_reg,posy_break_reg,posz_break_reg,posa_break_reg : std_logic_vector(31 downto 0);  --v2.5

---------------------------------------------------------------------------------------------------------------CARD
--卡上***寄存器
signal card_posx_regsel,card_posy_regsel,card_posz_regsel,card_posa_regsel : std_logic;
signal card_posx_reg,card_posy_reg,card_posz_reg,card_posa_reg : std_logic_vector(31 downto 0);

--卡上参考点位置寄存器
signal card_posx_ref_regsel,card_posy_ref_regsel,card_posz_ref_regsel,card_posa_ref_regsel : std_logic;
signal card_posx_ref_reg,card_posy_ref_reg,card_posz_ref_reg,card_posa_ref_reg : std_logic_vector(31 downto 0);

--卡上绝对坐标寄存器
signal card_posx_real_regsel,card_posy_real_regsel,card_posz_real_regsel,card_posa_real_regsel : std_logic;
signal card_posx_real_reg,card_posy_real_reg,card_posz_real_reg,card_posa_real_reg : std_logic_vector(31 downto 0);

----------------------------------------------------------------------------------------------------------------------------
--***
signal spdx_regsel,spdy_regsel,spdz_regsel,spda_regsel : std_logic;  --v2.5
signal spdx_reg,spdy_reg,spdz_reg,spda_reg : std_logic_vector(31 downto 0);  --v2.5

--回零/参考点寄存器
signal szero_softregsel : std_logic;  --v3.2
signal szero_softreg : std_logic_vector(31 downto 0);  --v3.2

--正向点动控制
signal jog_posx_regsel,jog_posy_regsel,jog_posz_regsel,jog_posa_regsel : std_logic;  --v3.2
signal jog_posx_reg,jog_posy_reg,jog_posz_reg,jog_posa_reg : std_logic_vector(31 downto 0);  --v3.2

--反向点动控制
signal jog_negx_regsel,jog_negy_regsel,jog_negz_regsel,jog_nega_regsel : std_logic;  --v3.2
signal jog_negx_reg,jog_negy_reg,jog_negz_reg,jog_nega_reg : std_logic_vector(31 downto 0);  --v3.2

----------------------------------------------------------------------------------------------------------------------------
--M指令
signal m_cool_regsel,m_cw_regsel,m_atcw_regsel : std_logic;  --v4.1
signal m_cool_reg,m_cw_reg,m_atcw_reg : std_logic_vector(31 downto 0);  --v4.1

--对刀和换刀控制
signal aux_ctl_regsel,aux_back_regsel : std_logic;  --v5.3
signal aux_ctl_reg,aux_back_reg : std_logic_vector(31 downto 0); --v5.3

--***
signal intreg,headreg,countreg,cmdreg,rdcountreg : std_logic_vector(31 downto 0);	

signal boundry4k,headreglow4k,canntcross4k,extpayload : std_logic_vector(12 downto 0);

signal cross4klength,fifodwlength,ctlength,bytelength,pctreg,maxpayload : std_logic_vector(8 downto 0);

signal dmawrtag,dmardtag,rxfifowrct : std_logic_vector(7 downto 0);

signal dmardcpldtag : std_logic_vector(11 downto 0);

--用于状态机跳转(intstate/中断状态类型)
type intstate is (idle1,inten,intack1,intdisable,intack2);		--空、中断使能、中断应答1、中断失效、中断应答2
signal pre_state1,nxt_state1 : intstate; 
signal wr_flag : std_logic;
signal cnt: std_logic_vector(1 downto 0);

begin 
  con_pro : process(clk,rst)
    begin	 
			if rising_edge(clk) then
				  if ext_int_req='1' then intreg(0)<='1';			--中断请求信号置1
				  else intreg(0)<='0';									-- intreg(0)<='1' when (ext_int_req ='1') else '0';
				  end if;
			end if;
			
			--状态跳转
			case pre_state1 is 
			when idle1 => 	if (intreg(0)='1' and intreg(1)='1') --or  (ext_int_req='1' and intreg(1)='1')
			                               then nxt_state1<=inten;
			                               else nxt_state1<=idle1;
								end if;
			when inten => 	if app_int_ack='1' then nxt_state1<=intack1;
			                                 else nxt_state1<=inten;
								end if;
			when intack1 => if intreg(0)='0' then nxt_state1<=intdisable;
			                                  else nxt_state1<=intack1;
								end if;
			when intdisable => if app_int_ack='1' then nxt_state1<=intack2;
			                                      else nxt_state1<=intdisable;
									 end if;
			when intack2 => nxt_state1<=idle1;
         when others => nxt_state1<=idle1;
         end case;
			
         if rising_edge(clk) then 
               if pre_state1=inten or pre_state1=intack1 then app_int_sts<='1';		--app_int_sts为输出信号 
		                                                   else app_int_sts<='0';
					end if;
		   end if;
			
         if rst='0' then pre_state1<=idle1;
			elsif rising_edge(clk) then 
			pre_state1<=nxt_state1;
			end if;
			
	if rising_edge(clk) then
--虚拟映射地址0x01-0x05(后面两位都是0，不算入其中）
	             if memsel1='1' and ext_add="0000000000000000000100" 						--BAR1 + 0x4    ext_add 为22位偏移地址
					            then intregsel<='1';													--中断状态标志置1
									else intregsel<='0';													
					 end if;
	             if memsel1='1' and ext_add="0000000000000000001000"						--BAR1 + 0x8
					            then headregsel<='1';												--DMA传送首地址寄存器标志置1													
									else headregsel<='0';
					 end if;
	             if memsel1='1' and ext_add="0000000000000000001100"						--BAR1 + 0xC 
					            then countregsel<='1';												--DMA传送大小寄存器标志置1
									else countregsel<='0';
					 end if;
	             if memsel1='1' and ext_add="0000000000000000010000"						--BAR1 + 0x10 
					            then cmdregsel<='1';													--DMA命令寄存器标志置1
									else cmdregsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000000010100"						--BAR1 + 0x14 
					            then pctocardregsel<='1';											--PC到卡寄存器标志置1
									else pctocardregsel<='0';
					 end if;
					 
--位置寄存器(改：位移寄存器) 虚拟映射地址0x08-0x0B(后面两位都是0，不算入其中）
					 if memsel1='1' and ext_add="0000000000000000100000" 						--BAR1 + 0x20 
					            then posx_regsel<='1';
									else posx_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000000100100"						--BAR1 + 0x24 
					            then posy_regsel<='1';
									else posy_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000000101000"						--BAR1 + 0x28  
					            then posz_regsel<='1';
									else posz_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000000101100"						--BAR1 + 0x2C 
					            then posa_regsel<='1';
									else posa_regsel<='0';
					 end if;
					 
--辅助功能寄存器，虚拟映射地址0x2A-2B(后面两位都是0，不算入其中）
					 if memsel1='1' and ext_add="0000000000000010101000" 						--BAR1 + 0xA8
					            then aux_back_regsel<='1';											--对刀反馈寄存器标志置1
									else aux_back_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000010101100" 						--BAR1 + 0xAC
					            then aux_ctl_regsel<='1';											--对刀控制寄存器标志置1
									else aux_ctl_regsel<='0';
					 end if;

--卡位置寄存器，虚拟映射地址0x30-0x33(后面两位都是0，不算入其中）			 
					 if memsel1='1' and ext_add="0000000000000011000000" 						--BAR1 + 0xC0
					            then card_posx_regsel<='1';										
									else card_posx_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000011000100"						--BAR1 + 0xC4 
					            then card_posy_regsel<='1';
									else card_posy_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000011001000"						--BAR1 + 0xC8 
					            then card_posz_regsel<='1';
									else posz_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000011001100"						--BAR1 + 0xCC 
					            then card_posa_regsel<='1';
									else card_posa_regsel<='0';
					 end if;
					 
--参考点位置寄存器，虚拟映射地址0x0c-0x0F(后面两位都是0，不算入其中）
					 if memsel1='1' and ext_add="0000000000000000110000"						--BAR1 + 0x30 
					            then posx_ref_regsel<='1';
									else posx_ref_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000000110100" 						--BAR1 + 0x34
					            then posy_ref_regsel<='1';
									else posy_ref_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000000111000"						--BAR1 + 0x38 
					            then posz_ref_regsel<='1';
									else posz_ref_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000000111100"						--BAR1 + 0x3C 
					            then posa_ref_regsel<='1';
									else posa_ref_regsel<='0';
					 end if;
--卡参考点位置寄存器，虚拟映射地址0x38-0x3B(后面两位都是0，不算入其中）
					 if memsel1='1' and ext_add="0000000000000011100000" 						--BAR1 + 0xE0
					            then card_posx_ref_regsel<='1';
									else card_posx_ref_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000011100100"						--BAR1 + 0xE4 
					            then card_posy_ref_regsel<='1';
									else card_posy_ref_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000011101000"						--BAR1 + 0xE8 
					            then card_posz_ref_regsel<='1';
									else card_posz_ref_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000011101100"						--BAR1 + 0xEC 
					            then card_posa_ref_regsel<='1';
									else card_posa_ref_regsel<='0';
					 end if;
					 
--绝对坐标寄存器，虚拟映射地址0x10-0x13(后面两位都是0，不算入其中）					 
					 if memsel1='1' and ext_add="0000000000000001000000"						--BAR1 + 0x40 
					            then posx_real_regsel<='1';
									else posx_real_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001000100"						--BAR1 + 0x44 
					            then posy_real_regsel<='1';
									else posy_real_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001001000"						--BAR1 + 0x48 
					            then posz_real_regsel<='1';
									else posz_real_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001001100"						--BAR1 + 0x4C 
					            then posa_real_regsel<='1';
									else posa_real_regsel<='0';
					 end if;
		
--卡绝对坐标寄存器，虚拟映射地址0x40-0x43(后面两位都是0，不算入其中）					 
					 if memsel1='1' and ext_add="0000000000000100000000"						--BAR1 + 0x100 
					            then card_posx_real_regsel<='1';
									else card_posx_real_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000100000100" 						--BAR1 + 0x104
					            then card_posy_real_regsel<='1';
									else card_posy_real_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000100001000" 						--BAR1 + 0x108
					            then card_posz_real_regsel<='1';
									else card_posz_real_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000100001100" 						--BAR1 + 0x10C
					            then card_posa_real_regsel<='1';
									else card_posa_real_regsel<='0';
					 end if;
--断点位置寄存器，虚拟映射地址0X14-0X17(后面两位都是0，不算入其中）
                if memsel1='1' and ext_add="0000000000000001010000" 						--BAR1 + 0x50
					            then posx_break_regsel<='1';
									else posx_break_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001010100" 						--BAR1 + 0x54
					            then posy_break_regsel<='1';
									else posy_break_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001011000" 						--BAR1 + 0x58
					            then posz_break_regsel<='1';
									else posz_break_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001011100" 						--BAR1 + 0x5C
					            then posa_break_regsel<='1';
									else posa_break_regsel<='0';
					 end if;
--速度寄存器，虚拟映射地址0x34-0x37(后面两位都是0，不算入其中）
                if memsel1='1' and ext_add="0000000000000011010000" 						--BAR1 + 0xD0
					            then spdx_regsel<='1';
									else spdx_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000011010100" 						--BAR1 + 0xD4
					            then spdy_regsel<='1';
									else spdy_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000011011000" 						--BAR1 + 0xD8
					            then spdz_regsel<='1';
									else spdz_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000011011100" 						--BAR1 + 0xDC
					            then spda_regsel<='1';
									else spda_regsel<='0';
					 end if;
--设备状态寄存器DCSreg
                if memsel1='1' and ext_add="0000000000000000011000" 						--BAR1 + 0x18
					            then dcsregsel<='1';
									else dcsregsel<='0';
					 end if;
--运动控制模式寄存器MCMreg
					 if memsel1='1' and ext_add="0000000000000000011100" 						--BAR1 + 0x1C
					            then mcmregsel<='1';
									else mcmregsel<='0';
					 end if;
	end if;
	
	
--联动轴寄存器 --v2.8
                if memsel1='1' and ext_add="0000000000000001100000" 						--BAR1 + 0x60
					            then co1regsel<='1';
									else co1regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001100100" 						--BAR1 + 0x64
					            then co2regsel<='1';
									else co2regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001101000" 						--BAR1 + 0x68
					            then co3regsel<='1';
									else co3regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001101100" 						--BAR1 + 0x6C
					            then co4regsel<='1';
									else co4regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001110000" 						--BAR1 + 0x70
					            then co5regsel<='1';
									else co5regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001110100" 						--BAR1 + 0x74
					            then co6regsel<='1';
									else co6regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001111000" 						--BAR1 + 0x78
					            then co7regsel<='1';
									else co7regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000001111100" 						--BAR1 + 0x7C
					            then co8regsel<='1';
									else co8regsel<='0';
					 end if;
					 
--点动、回参考点按钮寄存器
                if memsel1='1' and ext_add="0000000000000010000000" 						--BAR1 + 0x80
					            then jog_posx_regsel<='1';
									else jog_posx_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000010000100" 						--BAR1 + 0x84
					            then jog_posy_regsel<='1';
									else jog_posy_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000010001000" 						--BAR1 + 0x88
					            then jog_posz_regsel<='1';
									else jog_posz_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000010001100" 						--BAR1 + 0x8C
					            then jog_posa_regsel<='1';
									else jog_posa_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000010010000" 						--BAR1 + 0x90
					            then jog_negx_regsel<='1';
									else jog_negx_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000010010100" 						--BAR1 + 0x94
					            then jog_negy_regsel<='1';
									else jog_negy_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000010011000" 						--BAR1 + 0x98
					            then jog_negz_regsel<='1';
									else jog_negz_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000010011100" 						--BAR1 + 0x9C
					            then jog_nega_regsel<='1';
									else jog_nega_regsel<='0';
					 end if;
					 
					 if memsel1='1' and ext_add="0000000000000010100000" 						--BAR1 + 0xA0
					            then szero_softregsel<='1';
									else szero_softregsel<='0';
					 end if;

--M指令寄存器，虚拟映射地址0x44-0x46(后面两位都是0，不算入其中）  --v4.1					 
					 if memsel1='1' and ext_add="0000000000000100010000" 						--BAR1 + 0x110
					            then m_cool_regsel<='1';
									else m_cool_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000100010100" 						--BAR1 + 0x114
					            then m_cw_regsel<='1';
									else m_cw_regsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000100011000" 						--BAR1 + 0x118
					            then m_atcw_regsel<='1';
									else m_atcw_regsel<='0';
					 end if;							 
					 
					 
--位置寄存器输入，ref位置寄存器输出			
			if rising_edge(clk) then 
				posx_reg<=posx;																--posx位置输入接编码器，表示位移
				posy_reg<=posy;
				posz_reg<=posz;
				posa_reg<=posa;
				posx_ref<=posx_ref_reg;														--参考点位置输出接posx_ref_reg
				posy_ref<=posy_ref_reg;
				posz_ref<=posz_ref_reg;
				posa_ref<=posa_ref_reg;
				posx_real_reg <= posx_reg - posx_ref_reg;								--绝对坐标位置（相对参考点坐标）=位置坐标（总位移坐标）-参考点坐标（回零坐标） 
				posy_real_reg <= posy_reg - posy_ref_reg;
				posz_real_reg <= posz_reg - posz_ref_reg;
				posa_real_reg <= posa_reg - posa_ref_reg;
				
				aux_ctl<=aux_ctl_reg; --send control data, v5.3  					--aux_ctl为输出
				aux_back_reg<=aux_back;  --recerve feedback data					--aux_back为输入
			end if;
			
--卡位置寄存器输入，卡ref位置寄存器输出			
				if rising_edge(clk) then 
				   card_posx_reg<=card_posx;												--card_posx为输入
					card_posy_reg<=card_posy;
					card_posz_reg<=card_posz;
					card_posa_reg<=card_posa;
					card_posx_ref<=card_posx_ref_reg;									--card_posx_ref为输出
					card_posy_ref<=card_posy_ref_reg;
					card_posz_ref<=card_posz_ref_reg;
					card_posa_ref<=card_posa_ref_reg;
					card_posx_real_reg <= card_posx_reg - card_posx_ref_reg;
					card_posy_real_reg <= card_posy_reg - card_posy_ref_reg;
					card_posz_real_reg <= card_posz_reg - card_posz_ref_reg;
					card_posa_real_reg <= card_posa_reg - card_posa_ref_reg;
            end if;
				
--速度寄存器输入，reg位置寄存器输出
				if rising_edge(clk) then 
				   spdx_reg<=delta_x;														--delta_x为输入
					spdy_reg<=delta_y;
					spdz_reg<=delta_z;
					spda_reg<=delta_a;

            end if;
				
--参考点寄存器逻辑				
				if rising_edge(clk) then
					if set_ref='1' then 			--设置参考点置1
						posx_ref_reg<=posx_reg;												--将当前位置坐标（位移坐标）赋值为参考点坐标
						posy_ref_reg<=posy_reg;  
						posz_ref_reg<=posz_reg;  
						posa_ref_reg<=posa_reg;
						card_posx_ref_reg<=card_posx_reg; 
						card_posy_ref_reg<=card_posy_reg;  
						card_posz_ref_reg<=card_posz_reg;  
						card_posa_ref_reg<=card_posa_reg;				
					else 
						posx_ref_reg<=posx_ref_reg;  
						posy_ref_reg<=posy_ref_reg;  
						posz_ref_reg<=posz_ref_reg;  
						posa_ref_reg<=posa_ref_reg;
						card_posx_ref_reg<=card_posx_ref_reg;  
						card_posy_ref_reg<=card_posy_ref_reg;  
						card_posz_ref_reg<=card_posz_ref_reg;  
						card_posa_ref_reg<=card_posa_ref_reg;
					end if;
				end if;
				
--断点位置寄存器逻辑 --v2.5				
				if rising_edge(clk) then
					if (s1='1') or (s2='1') or (s3='1') 
						or (s4='1') or (s5='1') or (s6='1')  then 
						posx_break_reg<=posx_real_reg;  
						posy_break_reg<=posy_real_reg;  
						posz_break_reg<=posz_real_reg;  
						posa_break_reg<=posa_real_reg;
					else 
						posx_break_reg<=posx_break_reg;  
						posy_break_reg<=posy_break_reg;  
						posz_break_reg<=posz_break_reg;  
						posa_break_reg<=posa_break_reg;
					end if;
				end if;
				
--M指令reg/jog/szero输出逻辑  --v2.5  v3.2
            if rising_edge(clk) then
					xen<=mcmreg(0);								--X轴使能 <= 32位运动模式控制寄存器第0位
					yen<=mcmreg(1);
					zen<=mcmreg(2);
					aen<=mcmreg(3);
					co1<=co1reg(0);								--联动轴1使能 <= 32位联动轴1寄存器第0位
					co2<=co2reg(0);
					co3<=co3reg(0);
					co4<=co4reg(0);
					co5<=co5reg(0);
					co6<=co6reg(0);
					co7<=co7reg(0);
					co8<=co8reg(0);
					jog_posx<=jog_posx_reg(0);					--点动控制 <= 点动寄存器
					jog_posy<=jog_posy_reg(0);
					jog_posz<=jog_posz_reg(0);
					jog_posa<=jog_posa_reg(0);
					jog_negx<=jog_negx_reg(0);
					jog_negy<=jog_negy_reg(0);
					jog_negz<=jog_negz_reg(0);
					jog_nega<=jog_nega_reg(0);
					szero_soft<=szero_softreg(0);				--回零控制 <= 回零寄存器
					
					m_cool <= m_cool_reg(0);					--M指令寄存器
					m_cw <= m_cw_reg(0);
					m_atcw <= m_atcw_reg(0);
				end if;
				
--设备状态寄存器输入逻辑  --v2.5
            if rising_edge(clk) then
				  if s1='1' then 
					dcsreg(0)<='1';
				  else 
					dcsreg(0)<='0';
				  end if;
			   end if;				
				if rising_edge(clk) then
				  if s2='1' then 
					dcsreg(1)<='1';
				  else 
					dcsreg(1)<='0';
				  end if;
			   end if;				
				if rising_edge(clk) then
				  if s3='1' then 
					dcsreg(2)<='1';
				  else 
					dcsreg(2)<='0';
				  end if;
			   end if;				
				if rising_edge(clk) then
				  if s4='1' then 
					dcsreg(3)<='1';
				  else 
					dcsreg(3)<='0';
				  end if;
			   end if;				
				if rising_edge(clk) then
				  if s5='1' then 
					dcsreg(4)<='1';
				  else 
					dcsreg(4)<='0';
				  end if;
			   end if;				
				if rising_edge(clk) then
				  if s6='1' then 
					dcsreg(5)<='1';
				  else 
					dcsreg(5)<='0';
				  end if;
			   end if;
				
--INTCSR中断寄存器输出			
--				if rst='0' or clrcmd='1' then intreg(0)<='1';
            if rst='0'  then 
					intreg<="00000000000000000000000000000010";	--初始值
				elsif rising_edge(clk) then 
					if data_wr='1' and intregsel='1' then 			--数据读、中断状态标志置1
						intreg<=extdq;										--输入输出型寄存器赋值
					--	elsif ext_int_req='1' then intreg(3)<='1';
					end if;
				end if;
				
--PC to card数据寄存器输出
            if rst='0'  then 
					pctocardreg<="00000000000000000000000000000000";
					wr_flag<='0';
				elsif rising_edge(clk) then 
					if data_wr='1' and pctocardregsel='1' then 
						pctocardreg<=extdq;
						wr_flag<='1';										--写标志置1
					else 
					wr_flag<='0';
					end if;
				end if;
				
				if rst='0' then 
					wrreq<='0';												--写请求
					cnt<="00";
            elsif rising_edge(clk)then 
					if(wr_flag ='1'and cnt="00") then
						wrreq<='1';
						cnt<=cnt+"01";
               elsif(cnt="01") then 
						wrreq<='0';
						cnt<="00";
               else 
						wrreq<='0';
						cnt<="00";
               end if;
				end if;
					
--v5.3, aux registers write  对刀寄存器写
				if rst='0'  then 
					pctocardreg<="00000000000000000000000000000000";
					--aux_ctl_reg<="00000000000000000000000000000000";   --v7.1
				elsif rising_edge(clk) then 
					if data_wr='1' and aux_ctl_regsel='1' then 
						aux_ctl_reg<=extdq;
					end if;
				end if;
				--v5.8.3
				if rst='0'  then 
					aux_back_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
					if data_wr='1' and aux_back_regsel='1' then 
						aux_back_reg<=extdq;
					end if;
				end if;
				
--pos位置寄存器			
            if rst='0'  then posx_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posx_regsel='1' then 
					       posx_reg<=extdq;
				end if;end if;
				
            if rst='0'  then posy_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posy_regsel='1' then 
					       posy_reg<=extdq;
				end if;end if;
				
            if rst='0'  then posz_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posz_regsel='1' then 
					       posz_reg<=extdq;
				end if;end if;
				
            if rst='0'  then posa_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posa_regsel='1' then 
					       posa_reg<=extdq;
				end if;end if;	
				
--卡pos位置寄存器			
            if rst='0'  then card_posx_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posx_regsel='1' then 
					       card_posx_reg<=extdq;
				end if;end if;
				
            if rst='0'  then card_posy_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posy_regsel='1' then 
					       card_posy_reg<=extdq;
				end if;end if;
				
            if rst='0'  then card_posz_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posz_regsel='1' then 
					       card_posz_reg<=extdq;
				end if;end if;
				
            if rst='0'  then card_posa_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posa_regsel='1' then 
					       card_posa_reg<=extdq;
				end if;end if;		
				
--pos_ref位置寄存器
            if rst='0'  then posx_ref_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posx_ref_regsel='1' then 
					       posx_ref_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posy_ref_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posy_ref_regsel='1' then 
					       posy_ref_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posz_ref_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posz_ref_regsel='1' then 
					       posz_ref_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posa_ref_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posa_ref_regsel='1' then 
					       posa_ref_reg<=extdq;
				end if;end if;
				
--卡pos_ref位置寄存器
            if rst='0'  then card_posx_ref_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posx_ref_regsel='1' then 
					       card_posx_ref_reg<=extdq;
				end if;end if;
				
				if rst='0'  then card_posy_ref_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posy_ref_regsel='1' then 
					       card_posy_ref_reg<=extdq;
				end if;end if;
				
				if rst='0'  then card_posz_ref_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posz_ref_regsel='1' then 
					       card_posz_ref_reg<=extdq;
				end if;end if;
				
				if rst='0'  then card_posa_ref_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posa_ref_regsel='1' then 
					       card_posa_ref_reg<=extdq;
				end if;end if;
				
--pos_real位置寄存器
            if rst='0'  then posx_real_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posx_real_regsel='1' then 
					       posx_real_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posy_real_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posy_real_regsel='1' then 
					       posy_real_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posz_real_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posz_real_regsel='1' then 
					       posz_real_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posa_real_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posa_real_regsel='1' then 
					       posa_real_reg<=extdq;
				end if;end if;

--卡pos_real位置寄存器
            if rst='0'  then card_posx_real_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posx_real_regsel='1' then 
					       card_posx_real_reg<=extdq;
				end if;end if;
				
				if rst='0'  then card_posy_real_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posy_real_regsel='1' then 
					       card_posy_real_reg<=extdq;
				end if;end if;
				
				if rst='0'  then card_posz_real_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posz_real_regsel='1' then 
					       card_posz_real_reg<=extdq;
				end if;end if;
				
				if rst='0'  then card_posa_real_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and card_posa_real_regsel='1' then 
					       card_posa_real_reg<=extdq;
				end if;end if;
				
--pos_break位置寄存器
            if rst='0'  then posx_break_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posx_break_regsel='1' then 
					       posx_break_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posy_break_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posy_break_regsel='1' then 
					       posy_break_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posz_break_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posz_break_regsel='1' then 
					       posz_break_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posa_break_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and posa_break_regsel='1' then 
					       posa_break_reg<=extdq;
				end if;end if;
				
--spd_reg位置寄存器
            if rst='0'  then spdx_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and spdx_regsel='1' then 
					       spdx_reg<=extdq;
				end if;end if;
				
				if rst='0'  then spdy_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and spdy_regsel='1' then 
					       spdy_reg<=extdq;
				end if;end if;
				
				if rst='0'  then spdz_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and spdz_regsel='1' then 
					       spdz_reg<=extdq;
				end if;end if;
				
				if rst='0'  then spda_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and spda_regsel ='1' then 
					       spda_reg<=extdq;
				end if;end if;
				
--DCSreg设备状态寄存器
            if rst='0'  then dcsreg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and dcsregsel='1' then 
					       dcsreg<=extdq;
				end if;end if;
				
--MCMreg运动控制寄存器
            if rst='0'  then mcmreg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and mcmregsel='1' then 
					       mcmreg<=extdq;
				end if;end if;
				
--联动轴寄存器 --v2.8
            if rst='0'  then co1reg<="00000000000000000000000000000001";
				elsif rising_edge(clk) then 
				     if data_wr='1' and co1regsel='1' then 
					       co1reg<=extdq;
				end if;end if;
				
				if rst='0'  then co2reg<="00000000000000000000000000000001";
				elsif rising_edge(clk) then 
				     if data_wr='1' and co2regsel='1' then 
					       co2reg<=extdq;
				end if;end if;
				
				if rst='0'  then co3reg<="00000000000000000000000000000001";
				elsif rising_edge(clk) then 
				     if data_wr='1' and co3regsel='1' then 
					       co3reg<=extdq;
				end if;end if;
				
				if rst='0'  then co4reg<="00000000000000000000000000000001";
				elsif rising_edge(clk) then 
				     if data_wr='1' and co4regsel='1' then 
					       co4reg<=extdq;
				end if;end if;
				
				if rst='0'  then co5reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and co5regsel='1' then 
					       co5reg<=extdq;
				end if;end if;
				
				if rst='0'  then co6reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and co6regsel='1' then 
					       co6reg<=extdq;
				end if;end if;
				
				if rst='0'  then co7reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and co7regsel='1' then 
					       co7reg<=extdq;
				end if;end if;
				
				if rst='0'  then co8reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and co8regsel='1' then 
					       co8reg<=extdq;
				end if;end if;
				
--点动、回参考点寄存器wr
            if rst='0'  then jog_posx_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and jog_posx_regsel='1' then 
					       jog_posx_reg<=extdq;
				end if;end if;
				
				if rst='0'  then jog_posy_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and jog_posy_regsel='1' then 
					       jog_posy_reg<=extdq;
				end if;end if;
				
				if rst='0'  then jog_posz_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and jog_posz_regsel='1' then 
					       jog_posz_reg<=extdq;
				end if;end if;
				
				if rst='0'  then jog_posa_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and jog_posa_regsel='1' then 
					       jog_posa_reg<=extdq;
				end if;end if;
				
				if rst='0'  then jog_negx_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and jog_negx_regsel='1' then 
					       jog_negx_reg<=extdq;
				end if;end if;
				
				if rst='0'  then jog_negy_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and jog_negy_regsel='1' then 
					       jog_negy_reg<=extdq;
				end if;end if;
				
				if rst='0'  then jog_negz_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and jog_negz_regsel='1' then 
					       jog_negz_reg<=extdq;
				end if;end if;
				
				if rst='0'  then jog_nega_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and jog_nega_regsel='1' then 
					       jog_nega_reg<=extdq;
				end if;end if;
				
				if rst='0'  then szero_softreg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and szero_softregsel='1' then 
					       szero_softreg<=extdq;
				end if;end if;

--M指令寄存器 --v4.1
            if rst='0'  then m_cool_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and m_cool_regsel='1' then 
					       m_cool_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posy_real_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and m_cw_regsel='1' then 
					       m_cw_reg<=extdq;
				end if;end if;
				
				if rst='0'  then posz_real_reg<="00000000000000000000000000000000";
				elsif rising_edge(clk) then 
				     if data_wr='1' and m_atcw_regsel='1' then 
					       m_atcw_reg<=extdq;
				end if;end if;
				
				
--DMA首地址赋值及累加	
			if rst='0' then headreg<=(others=>'0');				--DMA传送首地址寄存器其他位（这里为所有位）赋值为1
			elsif rising_edge(clk) then 
				if data_wr='1' and headregsel='1' then				--DMA传送首地址寄存器标志置1 
					headreg<=extdq;
				elsif (pre_state=dmawrdatast1 or pre_state=dmawrdatast2) and tx_st_ready='1' then			--DMA写状态、及发送准备信号置1 
					headreg(31 downto 3)<=headreg(31 downto 3)+1;
				elsif pre_state=dmardhead2 then 
					headreg(31 downto 9)<=headreg(31 downto 9)+1;
				end if;
			end if;

--DMA大小寄存器赋值及计数			
			if rst='0' or clrcmd='1' then 
				countreg<="00000000000000000000000001000000";															--DMA传送大小寄存器（第6位）
			elsif rising_edge(clk) then 
				if data_wr='1' and countregsel='1' then 
					countreg<=extdq;
				elsif ((pre_state=dmawrdatast1 or pre_state=dmawrdatast2) and tx_st_ready='1') 
				       or rxfifowr='1' then 
					countreg(22 downto 3)<=countreg(22 downto 3)-1;
              end if;
			end if;

--DMA命令寄存器			
			if rst='0' or clrcmd='1' then 
				rdcountreg<="00000000000000000000000001000000";
			elsif rising_edge(clk) then 
			     if data_wr='1' and countregsel='1' then 
				       rdcountreg<=extdq;
				  elsif pre_state=dmardhead2 then 
				       rdcountreg(22 downto 9)<=rdcountreg(22 downto 9)-1;                      
			end if;end if;
			
			if rising_edge(clk) then 
			   if rdcountreg(22 downto 3)="00000000000000000000" then 
					clrcmd1<='1';
				else 
					clrcmd1<='0';
				end if;
			end if; 
			
			if rising_edge(clk) then 
			   if countreg(22 downto 3)="00000000000000000000" then 
					clrcmd<='1';
				else 
					clrcmd<='0';
				end if;
			end if;
			
			if rst='0' or clrcmd='1' or clrcmd1='1' then 
				cmdreg(15 downto 0)<="0000000000000000";							--cmdreg为DMA命令寄存器
			elsif rising_edge(clk) then 
				if data_wr='1' and cmdregsel='1' then 
					cmdreg<=extdq;
				end if;
			end if;	
			
           if cmdreg(8)='1' and fifordempty='0' then 
				startdmawr<='1';
			else 
				startdmawr<='0';
			end if;
				
		     if rising_edge(clk) then 
              clrfifo<=cmdreg(31) or not(rst);
				dmaen<=cmdreg(30);
	        end if;				

--主机内存4K字节边界确定
				boundry4k<="1000000000000";
				headreglow4k(12)<='0';
				headreglow4k(11 downto 0)<=headreg(11 downto 0);
				
				if rising_edge(clk) then 
					canntcross4k<=boundry4k-headreglow4k;
					if canntcross4k>="0000010000000" then 
						cross4klength<="010000000";
					else 
						cross4klength<=canntcross4k(8 downto 0);
					end if; 			                                     
					if fiforddw>="000010000" then 
						fifodwlength<="010000000";
					else 
						fifodwlength(2 downto 0)<="000";
						fifodwlength(8 downto 3)<=fiforddw(5 downto 0);
					end if;
					if countreg(22 downto 0)>="00000000000000010000000" then 
						ctlength<="010000000";
					else 
						ctlength<=countreg(8 downto 0);
					end if;

--每TX存储器写包大小确定						
				   if pre_state=dmawrwaitst1 then
						if cross4klength>=ctlength then 
							if ctlength>=fifodwlength then 
								bytelength<=fifodwlength;
							else 
								bytelength<=ctlength;
							end if;
						else 
							if cross4klength>=fifodwlength then 
								bytelength<=fifodwlength;
							else 
								bytelength<=cross4klength;
							end if;
						end if;
					end if;
				end if;
				
				
--DMA写请求TLP				
				dmawrtag<="00000000";
				
				--DW1
				dmawrheadrega(0)<='0';
				dmawrheadrega(6 downto 1)<=bytelength(8 downto 3);	
				dmawrheadrega(9 downto 7)<="000";								--以上为length字段
				dmawrheadrega(11 downto 10)<="00";								--AT
				dmawrheadrega(13 downto 12)<="10";								--Attr
				dmawrheadrega(15 downto 14)<="00";								--EP、TD
				dmawrheadrega(23 downto 16)<="00000000";	
				dmawrheadrega(31 downto 24)<="01000000";
				
				--DW2
				dmawrheadrega(39 downto 32)<="11111111";					--Last_DW_BE 与 First DW BE
				dmawrheadrega(47 downto 40)<=dmawrtag;						--tag字段
				dmawrheadrega(50 downto 48)<="000";							--Requester ID （功能号）
				dmawrheadrega(55 downto 51)<=devnum;						--Requester ID （设备号）
				dmawrheadrega(63 downto 56)<=busnum;						--Requester ID （总线号）
				
				--DW3
				dmawrheadregb(1 downto 0)<="00";								--缺省为0
				dmawrheadregb(31 downto 2)<=headreg(31 downto 2);
				
				--DW4
				dmawrheadregb(63 downto 32)<="00000000000000000000000000000000"; 

            if rst='0' then 
					dmardtag<=(others=>'0');
				elsif rising_edge(clk) then 
					if pre_state=dmardhead2 then 
						dmardtag<=dmardtag+1;
					end if;
				end if;
				if rst<='0' then 
					dmardcpldtag<=(others=>'0');
				elsif rising_edge(clk) then 
					if rxfifowr='1' then 
						dmardcpldtag<=dmardcpldtag+1;
					end if;
				end if;
				if rising_edge(clk) then 
					if (dmardtag(3)/=dmardcpldtag(9)) and 
						(dmardtag(2 downto 0)=dmardcpldtag(8 downto 6)) then 
						dmarden<='0';
					else 
						dmarden<='1';
					end if;
				end if;

--DMA读请求TLP				
            dmardheadrega(9 downto 0)<="0010000000";
            dmardheadrega(11 downto 10)<="00";
				dmardheadrega(13 downto 12)<="10";
				dmardheadrega(15 downto 14)<="00";
				dmardheadrega(23 downto 16)<="00000000";
				dmardheadrega(31 downto 24)<="00000000";
				
				dmardheadrega(39 downto 32)<="11111111";
				dmardheadrega(44 downto 40)<=dmardtag(4 downto 0);
				dmardheadrega(47 downto 45)<="000";
				dmardheadrega(50 downto 48)<="000";
				dmardheadrega(55 downto 51)<=devnum;
				dmardheadrega(63 downto 56)<=busnum;
				
				dmardheadregb(1 downto 0)<="00";
				dmardheadregb(31 downto 2)<=headreg(31 downto 2);
				
				dmardheadregb(63 downto 32)<="00000000000000000000000000000000"; 

--TX包流量控制，避免溢出					  
	         if rising_edge(clk) then
	                if tx_cred(2 downto 0)>="011" then postheaden<='1';
						                               else postheaden<='0';
						 end if;
						 if tx_cred(14 downto 3)>="000000011000" then postdataen<='1';
						                                         else postdataen<='0';
						 end if;		
                   if tx_cred(17 downto 15)>="010" then npheaden<='1';
                                                   else npheaden<='0';
						 end if;
                   if tx_cred(20 downto 18)>="010" then npdataen<='1';
                                                   else npdataen<='0';
						 end if;
                   if tx_cred(23 downto 21)>="010" then cpheaden<='1';
                                                   else cpheaden<='0';
						 end if;
                   if tx_cred(35 downto 24)>="000000000100" then cpdataen<='1';
                                                            else cpdataen<='0';
						 end if;		
				end if;
	 
--存储器读完成包产生 
			if rising_edge(clk) then 
				memrdcpheadrega(9 downto 0)<="0000000001";
				memrdcpheadrega(11 downto 10)<="00";
				memrdcpheadrega(13 downto 12)<=attrib;
				memrdcpheadrega(19 downto 14)<="000000";
				memrdcpheadrega(22 downto 20)<=tc;
				memrdcpheadrega(31 downto 23)<="010010100";
				
				memrdcpheadrega(47 downto 32)<="0000000000000100";
            memrdcpheadrega(50 downto 48)<="000";
				memrdcpheadrega(55 downto 51)<=devnum;
				memrdcpheadrega(63 downto 56)<=busnum;
				
				memrdcpheadregb(6 downto 0)<=ext_add(6 downto 0);
				memrdcpheadregb(7)<='0';
				memrdcpheadregb(15 downto 8)<=tag;
				memrdcpheadregb(31 downto 16)<=reqid;
					 
				if ext_add(2)='1' 
				                  then memrdcpheadregb(63 downto 32)<=extdq;
									--    then memrdcpheadregb(63 downto 32)<="00010010001101001010111110110111";
				                  else memrdcpheadregb(63 downto 32)<="00000000000000000000000000000000";
				end if;
				
				if pre_state=memrdcpldwaitst2 then 
				memrdcpdatareg(31 downto 0)<=extdq;
					--    memrdcpdatareg(31 downto 0)<="00010010001101001010111110110111";		
				memrdcpdatareg(63 downto 32)<="00000000000000000000000000000000";
				end if;
			end if;
			
			
--TX包状态机产生
				 case pre_state is 
				 when idle => if memrdreq='1' and tx_st_ready='1' and cpheaden='1' and cpdataen='1'
				                              then nxt_state<=memrdcpldwaitst1;
								  elsif startdmawr='1' and postheaden='1' and postdataen='1' and tx_st_ready='1' 
								                  then nxt_state<=dmawrwaitst1;
								  elsif dmarden='1' and cmdreg(0)='1' and tx_st_ready='1' and npheaden='1' 
								                  then nxt_state<=dmardwaitst1;
				              else nxt_state<=idle;
								  end if;
             when memrdcpldwaitst1 => nxt_state<=memrdcpldwaitst2;
				 when memrdcpldwaitst2 => nxt_state<=memrdcpldwaitst3;
				 when memrdcpldwaitst3 => if memrddxfer='1' then nxt_state<=memrdcpldwaitst4;
				                                            else nxt_state<=memrdcpldwaitst3;
													end if;
				 when memrdcpldwaitst4 => nxt_state<=memrdcpldhead1;
				 when memrdcpldhead1 =>   if tx_st_ready='0' then nxt_state<=memrdcpldhead1;
				                                             else nxt_state<=memrdcpldhead2;
												  end if;
             when memrdcpldhead2 =>  if tx_st_ready='1' then  
				                         if ext_add(2)='1' then nxt_state<=memrdcplddone;
				                          else nxt_state<=memrdcplddatast1;
												  end if;
												  else nxt_state<=memrdcpldhead2;
												  end if;
				 when memrdcplddatast1 => if tx_st_ready='1' then nxt_state<=memrdcplddone;
				                                            else nxt_state<=memrdcplddatast1;
												  end if;
				 when memrdcplddone => nxt_state<=memrdcpldwaitst5;
                 when memrdcpldwaitst5 => nxt_state<=memrdcpldwaitst6;
                 when memrdcpldwaitst6 => nxt_state<=memrdcpldwaitst7;
                 when memrdcpldwaitst7 => nxt_state<=idle;
	--			 when dmawrwaitst1 => nxt_state<=dmawrwaitst2;
		         when dmawrwaitst1 => if tx_st_ready='1' then nxt_state<=dmawrhead1;
		                                               else nxt_state<=dmawrwaitst1;
									       end if;
				 when dmawrhead1 => if tx_st_ready='1' then nxt_state<=dmawrhead2;
		                                               else nxt_state<=dmawrhead1;
									       end if;		 
				 when dmawrhead2 => if tx_st_ready='1' then if pctreg="000001000" then nxt_state<=dmawrdatast2;
				                                                                  else nxt_state<=dmawrdatast1;
																		  end if;
		                                               else nxt_state<=dmawrhead2;
									       end if;					
 				 when dmawrdatast1 => if tx_st_ready='1' and countale='1' then nxt_state<=dmawrdatast2;
				                      elsif tx_st_ready='0' then nxt_state<=dmawrwaitst8;
											 else nxt_state<=dmawrdatast1;
											 end if;
				 when dmawrwaitst8 => if tx_st_ready='1' then if pctreg="000001000" then nxt_state<=dmawrdatast2;
				                                                                    else nxt_state<=dmawrdatast1;
																			 end if;
											                    else nxt_state<=dmawrwaitst8;
											 end if;
				 when dmawrdatast2 => if tx_st_ready='1' then nxt_state<=dmawrwaitst3;
	                                                  else nxt_state<=dmawrdatast2;
											 end if;		  
				 when dmawrwaitst3 => 
                                      if memrdreq='1' and tx_st_ready='1' and cpheaden='1' and cpdataen='1'
				                              then nxt_state<=memrdcpldwaitst1;
                                      elsif fiforddw>"000100101" and countreg(22 downto 0)>"00000000000000100000000" 
                                        and canntcross4k>="0000100000000" and startdmawr='1' 
                                        and postheaden='1' and postdataen='1' and tx_st_ready='1'
                                        then nxt_state<=dmawrwaitst1;
                                        else nxt_state<=dmawrwaitst4;
                                      end if;				 
				 when dmawrwaitst4 => nxt_state<=dmawrwaitst5;		 
				 when dmawrwaitst5 => nxt_state<=dmawrwaitst6;											 
				 when dmawrwaitst6 => nxt_state<=dmawrwaitst7;
				 when dmawrwaitst7 => nxt_state<=idle;				
				 when dmardwaitst1 => if tx_st_ready='1' then nxt_state<=dmardwaitst2;
				                                         else nxt_state<=dmardwaitst1;
											 end if;
				 when dmardwaitst2 => if tx_st_ready='1' then nxt_state<=dmardhead1;
				                                         else nxt_state<=dmardwaitst1;
											 end if;
				 when dmardhead1 => nxt_state<=dmardhead2;
				 when dmardhead2 => nxt_state<=dmardwaitst3;
				 when dmardwaitst3 => nxt_state<=dmardwaitst4;
				 when dmardwaitst4 => nxt_state<=dmardwaitst5;
				 when dmardwaitst5 => nxt_state<=dmardwaitst6;
				 when dmardwaitst6 => nxt_state<=idle;
				 when others => nxt_state<=idle;
				 end case;
             if rising_edge(clk) then 
                   if pre_state=dmawrhead1 then pctreg<=bytelength;
		             elsif (pre_state=dmawrdatast1 or pre_state=dmawrdatast2) and tx_st_ready='1' then 
		                    pctreg(8 downto 3)<=pctreg(8 downto 3)-1;
					    end if;
		       end if;
   --          if rising_edge(clk) then 
                  if pctreg<="000010000" then countale<='1';
	                                     else countale<='0';
						end if;
--	          end if;					


--TX包协议控制信号产生				 
				 if rising_edge(clk) then 
				       if (pre_state=memrdcpldhead1 or pre_state=dmawrhead1 or pre_state=dmardhead1) and tx_st_ready='1'
						                             then txfifodq(64)<='1';
						                             else txfifodq(64)<='0';
						 end if;
						 if ((ext_add(2)='1' and pre_state=memrdcpldhead2) or (ext_add(2)='0' and pre_state=memrdcplddatast1) 
						     or pre_state=dmawrdatast2 or pre_state=dmardhead2) and tx_st_ready='1' 
						                    then txfifodq(65)<='1';
												  else txfifodq(65)<='0';
						 end if;

						 if pre_state=memrdcpldhead1 then txfifodq(63 downto 0)<=memrdcpheadrega;
						 elsif pre_state=memrdcpldhead2 then txfifodq(63 downto 0)<=memrdcpheadregb;
						 elsif pre_state=memrdcplddatast1 then txfifodq(63 downto 0)<=memrdcpdatareg;
						 elsif pre_state=dmawrhead1 then txfifodq(63 downto 0)<=dmawrheadrega;
						 elsif pre_state=dmawrhead2 then txfifodq(63 downto 0)<=dmawrheadregb;
						 elsif pre_state=dmawrdatast1 or pre_state=dmawrdatast2 then txfifodq(63 downto 0)<=fifodqin; 
						 elsif pre_state=dmardhead1 then txfifodq(63 downto 0)<=dmardheadrega;
						 elsif pre_state=dmardhead2 then txfifodq(63 downto 0)<=dmardheadregb;
						 end if;
						 txfifodq(71 downto 66)<="000000";
						 if (pre_state=memrdcpldhead1 or pre_state=memrdcpldhead2 or pre_state=memrdcplddatast1
						     or pre_state=dmawrhead1 or pre_state=dmawrhead2 or pre_state=dmawrdatast1 
							  or pre_state=dmawrdatast2 or pre_state=dmardhead1 or pre_state=dmardhead2)						     
						     and tx_st_ready='1' then tx_st_valid<='1';
							                      else tx_st_valid<='0';
						 end if;
						 

				 end if;
						 if (pre_state=dmawrdatast1 or pre_state=dmawrdatast2)						     
						     and tx_st_ready='1' then fiford<='1';
							                      else fiford<='0';
						 end if;
								 if pre_state=memrdcplddone
                                                     then memrdack<='1';
						                             else memrdack<='0';
						 end if;

--测试LED信号产生						 
             if rst='0' then pre_state<=idle;
				 elsif rising_edge(clk) then pre_state<=nxt_state;
				 end if;
				 tx_st_err<='0';
				 if rst='0' then led1<='0';
				 elsif rising_edge(clk) then 
				     if busnum="00000010" 
					        then led1<='1';
							  else led1<='0';
				 end if;end if;
				 
             if rst='0' then led2<='0';
				 elsif rising_edge(clk) then 
				    if devnum="00000" then led2<='1';
					                   else led2<='0';
				 end if;end if;
				 if rst='0' then led3<='0';
				 elsif rising_edge(clk) then 
				    if pre_state=dmawrhead1 and bytelength>"010000000" then 
					     led3<='1';
				 end if;end if;                      
             if rst='0' then led4<='0';
				 elsif rising_edge(clk) then 
				    if pre_state=dmawrhead1 and bytelength="010000000" then
					     led4<='1';
				 end if;end if;
	 end process con_pro;
	 
	 
--读取寄存器逻辑  read registers
	 extdq <= intreg when data_rd='1' and intregsel='1'							--条件信号代入语句	（类似assign语句）					
	         else headreg when data_rd='1' and headregsel='1'
				else countreg when data_rd='1' and countregsel='1'
				else cmdreg when data_rd='1' and cmdregsel='1'
				else pctocardreg when data_rd='1' and pctocardregsel='1'
				else posx_reg when data_rd='1' and posx_regsel='1'
				else posy_reg when data_rd='1' and posy_regsel='1'
				else posz_reg when data_rd='1' and posz_regsel='1'
				else posa_reg when data_rd='1' and posa_regsel='1'
				else posx_ref_reg when data_rd='1' and posx_ref_regsel='1'
				else posy_ref_reg when data_rd='1' and posy_ref_regsel='1'
				else posz_ref_reg when data_rd='1' and posz_ref_regsel='1'
				else posa_ref_reg when data_rd='1' and posa_ref_regsel='1'
				else posx_real_reg when data_rd='1' and posx_real_regsel='1'
				else posy_real_reg when data_rd='1' and posy_real_regsel='1'
				else posz_real_reg when data_rd='1' and posz_real_regsel='1'
				else posa_real_reg when data_rd='1' and posa_real_regsel='1'
				else posx_break_reg when data_rd='1' and posx_break_regsel='1'
				else posy_break_reg when data_rd='1' and posy_break_regsel='1'
				else posz_break_reg when data_rd='1' and posz_break_regsel='1'
				else posa_break_reg when data_rd='1' and posa_break_regsel='1'
				
				else aux_back_reg when data_rd='1' and aux_back_regsel='1'  --v5.3
				else aux_ctl_reg when data_rd='1' and aux_ctl_regsel='1'
				
				else card_posx_reg when data_rd='1' and card_posx_regsel='1'
				else card_posy_reg when data_rd='1' and card_posy_regsel='1'
				else card_posz_reg when data_rd='1' and card_posz_regsel='1'
				else card_posa_reg when data_rd='1' and card_posa_regsel='1'
				else card_posx_ref_reg when data_rd='1' and card_posx_ref_regsel='1'
				else card_posy_ref_reg when data_rd='1' and card_posy_ref_regsel='1'
				else card_posz_ref_reg when data_rd='1' and card_posz_ref_regsel='1'
				else card_posa_ref_reg when data_rd='1' and card_posa_ref_regsel='1'
				else card_posx_real_reg when data_rd='1' and card_posx_real_regsel='1'
				else card_posy_real_reg when data_rd='1' and card_posy_real_regsel='1'
				else card_posz_real_reg when data_rd='1' and card_posz_real_regsel='1'
				else card_posa_real_reg when data_rd='1' and card_posa_real_regsel='1'
				
				else spdx_reg when data_rd='1' and spdx_regsel='1'
				else spdy_reg when data_rd='1' and spdy_regsel='1'
				else spdz_reg when data_rd='1' and spdz_regsel='1'
				else spda_reg when data_rd='1' and spda_regsel='1'				--zy
				
				else dcsreg when data_rd='1' and dcsregsel='1'
				else mcmreg when data_rd='1' and mcmregsel='1'
				else co1reg when data_rd='1' and co1regsel='1'
				else co2reg when data_rd='1' and co2regsel='1'
				else co3reg when data_rd='1' and co3regsel='1'
				else co4reg when data_rd='1' and co4regsel='1'
				else co5reg when data_rd='1' and co5regsel='1'
				else co6reg when data_rd='1' and co6regsel='1'
				else co7reg when data_rd='1' and co7regsel='1'
				else co8reg when data_rd='1' and co8regsel='1'
				else jog_posx_reg when data_rd='1' and jog_posx_regsel='1'
				else jog_posy_reg when data_rd='1' and jog_posy_regsel='1'
				else jog_posz_reg when data_rd='1' and jog_posz_regsel='1'
				else jog_posa_reg when data_rd='1' and jog_posa_regsel='1'
				else jog_negx_reg when data_rd='1' and jog_negx_regsel='1'
				else jog_negy_reg when data_rd='1' and jog_negy_regsel='1'
				else jog_negz_reg when data_rd='1' and jog_negz_regsel='1'
				else jog_nega_reg when data_rd='1' and jog_nega_regsel='1'
				else szero_softreg when data_rd='1' and szero_softregsel='1'
				
				else m_cool_reg when data_rd='1' and m_cool_regsel='1'
				else m_cw_reg when data_rd='1' and m_cw_regsel='1'
				else m_atcw_reg when data_rd='1' and m_atcw_regsel='1'  --v4.1
				
				else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	end beha; 
