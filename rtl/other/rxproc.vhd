library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity rxproc is port(
clk,rst,fifoempty,fifoalempty : in std_logic;
rxdw : in std_logic_vector(9 downto 0);						--显示FIFO已存储字节数
rxdq : in std_logic_vector(95 downto 0);						--读FIFO数据

ext_add : out std_logic_vector(21 downto 0);					--偏移地址
iosel : out std_logic;												--I/O空间选择
memsel1,memsel2 : out std_logic;									--存储器空间选择

extdq : inout std_logic_vector(31 downto 0);					--双向数据传输

ext_rd,ext_wr,fiford : out std_logic;							--数据读、写、FIFO缓冲区读
led0,led1,led2,led3 : out std_logic;

tag : out std_logic_vector(7 downto 0);						--TLP的tag字段
reqid : out std_logic_vector(15 downto 0);
memrdrq : out std_logic;											--存储器读请求信号，发往数据发送模块
attrib : out std_logic_vector(1 downto 0);					--TLP的attr字段
tc : out std_logic_vector(2 downto 0);							--TLP的TC字段

extdfer,memrdack : in std_logic;									--memrdack为存储器读完成信号

dmardfifowr : out std_logic;										
dmardfifodq : out std_logic_vector(63 downto 0);
dmardfifodw : in std_logic_vector(8 downto 0));				--上述三个为数据接收FIFO模块接口信号
end rxproc;

architecture beha of rxproc is

--接收包状态机定义  
type rxprost is (idle,rdhead1,headpro1,rdhead2,headpro2,waitst1,datast1,datast2,
                 memwrst1,memwrst2,memwrst3,memwrst4,unsp1,unsp2,memrdst1,memrdst2,memrdst3,memrdst4
					  ,cpldwaitst1,cplddatast1,cpldwaitst6
					  ,cpldwaitst7,cpldwaitst8,cpldwaitst9);
signal pre_state,nxt_state : rxprost;


signal rxdata,headrega,headregb : std_logic_vector(63 downto 0);									--接收数据、TLP包头1、TLP包头2
signal rxbe,rxbardec : std_logic_vector(7 downto 0);													--
signal rxvalid,rxerr,rxsop,rxeop,td,ep,dw3sel,rxen,tlpover,dqoen : std_logic;
signal fmt : std_logic_vector(1 downto 0);
signal tysel : std_logic_vector(4 downto 0);
signal lenth,dwlength : std_logic_vector(9 downto 0);
signal fbe : std_logic_vector(3 downto 0);
signal addr,extdqreg : std_logic_vector(31 downto 0);
signal memrdsel,memwrsel,iordsel,iowrsel,cfgrdsel,cfgwrsel,messrdsel,messwrsel,cplsel,cpldsel : std_logic;


begin 
    con_pro : process(clk,rst)
	   begin  
				--RX包接口协议
		       rxdata<=rxdq(63 downto 0);
				 rxbe<=rxdq(71 downto 64);
				 rxbardec<=rxdq(79 downto 72);
				 rxvalid<=rxdq(80);
				 rxerr<=rxdq(81);
				 rxsop<=rxdq(82);
				 rxeop<=rxdq(83);
				 
				 --LED测试信号输出
				 if rst='0' then led0<='0';
				 elsif rising_edge(clk) then 
				  if cpldsel='1' then led0<='1';
				  end if;
				  end if;
				  led1<=cplsel;
				  led2<=cplsel;
				  led3<='0';
				  
				  --RX包头1、2格式定义
				 if rst='0' then headrega<=(others=>'1');
				 elsif rising_edge(clk) then 
				      if pre_state=rdhead1 then headrega<=rxdata;
				 end if;end if;
				 
				 --RX包数据长度定义
				 if rst='0' then dwlength<=(others=>'0');									--dwlength为数据载荷剩余个数
				 elsif rising_edge(clk) then 
				      if pre_state=rdhead1 then dwlength<=rxdata(9 downto 0);
						elsif pre_state=cplddatast1 then 
						          dwlength(9 downto 1)<=dwlength(9 downto 1)-1;
				 end if;end if;
				 
				 --RX包头内容解析
				 tc<=headrega(21 downto 19);
				 fmt<=headrega(30 downto 29);
				 tysel<=headrega(28 downto 24);
				 td<=headrega(15);
				 ep<=headrega(14);
				 attrib<=headrega(13 downto 12);
				 lenth(9 downto 8)<=headrega(9 downto 8);
				 lenth(7 downto 0)<=headrega(7 downto 0);
				 reqid<=headrega(63 downto 48);
				 tag<=headrega(47 downto 40);
				 fbe<=headrega(35 downto 32);
				 
				 --RX包头3、4格式定义
				 if rst='0' then headregb<=(others=>'0');
				 elsif rising_edge(clk) then 
				        if pre_state=rdhead2 then headregb<=rxdata;
				 end if;end if;
				 if rising_edge(clk) then 
				        if dw3sel='1' then 
						       addr(7 downto 2)<=headregb(7 downto 2);
							    addr(15 downto 8)<=headregb(15 downto 8);
							    addr(23 downto 16)<=headregb(23 downto 16);
							    addr(31 downto 24)<=headregb(31 downto 24);
							else 
						       addr(7 downto 2)<=headregb(39 downto 34);
							    addr(15 downto 8)<=headregb(47 downto 40);
							    addr(23 downto 16)<=headregb(55 downto 48);
							    addr(31 downto 24)<=headregb(63 downto 56);
                     end if;
             end if;			
                 addr(1 downto 0)<="00";
				
-----------------------------------------------------------------------------------------------------				
				 if rising_edge(clk) then
					 --RX包格式解析，存储器读
				    if (headrega(28 downto 24)="00000" or headrega(28 downto 24)="00001") and headrega(30)='0'  
					        then memrdsel<='1';
							  else memrdsel<='0';
					 end if;
					 
					 --RX包解析，存储器写
				    if (headrega(28 downto 24)="00000") and headrega(30)='1'  
					        then memwrsel<='1';
							  else memwrsel<='0';
					 end if;
					 
					 --IO读
				    if (headrega(28 downto 24)="00010") and headrega(30)='0'  
					        then iordsel<='1';
							  else iordsel<='0';
					 end if;
			
					 --IO写
				    if (headrega(28 downto 24)="00010") and headrega(30)='1'  
					        then iowrsel<='1';
							  else iowrsel<='0';
					 end if;	
			
					 --配置读
				    if (headrega(28 downto 24)="00100" or headrega(28 downto 24)="00101") and headrega(30)='0'  
					        then cfgrdsel<='1';
							  else cfgrdsel<='0';
					 end if;
				
					 --配置写
				    if (headrega(28 downto 24)="00100" or headrega(28 downto 24)="00101") and headrega(30)='1'  
					        then cfgwrsel<='1';
							  else cfgwrsel<='0';
					 end if;
					 
					 --消息读
				    if (headrega(28 downto 27)="10") and headrega(30)='0' 
					        then messrdsel<='1';
							  else messrdsel<='0';
					 end if;
					 
					 --消息写
				    if (headrega(28 downto 27)="10") and headrega(30)='1' 
					        then messwrsel<='1';
							  else messwrsel<='0';
					 end if;
		
					--完成数据包
				    if (headrega(28 downto 24)="01010" or headrega(28 downto 24)="01011") and headrega(30)='0'  
					        then cplsel<='1';
							  else cplsel<='0';
					 end if;
					 
					 --带数据的完成包
				    if (headrega(28 downto 24)="01010" or headrega(28 downto 24)="01011") and headrega(30)='1' 
					       and headrega(47 downto 45)="000"  
					        then cpldsel<='1';
							  else cpldsel<='0';
					 end if;
				 end if;
				 
				 --3字头定义
					 if headrega(29)='0' then dw3sel<='1';
					                    else dw3sel<='0';
					 end if;
				 
				 --RX包接口
				 if rising_edge(clk) then 
			        if rxdw>="0000000010" then rxen<='1';						--rxdw为FIFO已存储字节数，检测Avalon缓冲区是否有数据
					                      else rxen<='0';
						end if;
						
						--RX包结束信号
						if iordsel='1' or cfgrdsel='1' or messrdsel='1' or cplsel='1' then tlpover<='1';
						                                                              else tlpover<='0';
						end if;
				 end if;
				 
-----------------------------------------------------------------------------------------------------------			
				--RX包状态机
		       case pre_state is
             when idle => if rxen='1' and rxsop='1' then nxt_state<=rdhead1;
			                                  else nxt_state<=idle;
								  end if;
								  when rdhead1 => nxt_state<=headpro1;				--加一个headPro等待周期是因为状态机是边沿触发（上升沿或下降沿）
								  when headpro1 => nxt_state<=rdhead2;				--而Avalon64位数据是一整个时钟周期（上升沿）更新一次，所以用来等待半周期	
			    when rdhead2 => nxt_state<=headpro2;
             when headpro2 => nxt_state<=waitst1;
			    when waitst1 => if memwrsel='1' and addr(2)='1' and dw3sel='1' then nxt_state<=datast2;
				                  elsif memwrsel='1' then nxt_state<=datast1;
										elsif memrdsel='1' then nxt_state<=memrdst1;
										elsif cpldsel='1' then nxt_state<=cpldwaitst1;
				                  else nxt_state<=unsp1;
							         end if;
				 when unsp1 => if rxeop='1' then nxt_state<=idle;
				                            else nxt_state<=unsp2;
									end if;
				 when unsp2 => nxt_state<=unsp1;
				 when datast1 => nxt_state<=datast2;
				 when datast2 => nxt_state<=memwrst1;
				 when memwrst1 => nxt_state<=memwrst2;
				 when memwrst2 => nxt_state<=memwrst3;
				 when memwrst3 => if extdfer='1' then nxt_state<=memwrst4;
				                                 else nxt_state<=memwrst3;
										end if;
				 when memwrst4 => nxt_state<=unsp1;
				 when memrdst1 => nxt_state<=memrdst2;
				 when memrdst2 => nxt_state<=memrdst3;
				 when memrdst3 => if memrdack='1' then nxt_state<=memrdst4;
				                                  else nxt_state<=memrdst3;
									   end if;
				 when memrdst4 => nxt_state<=unsp1;
				 when cpldwaitst1 => nxt_state<=cplddatast1;
				 when cplddatast1 => if rxeop='1' then nxt_state<=idle;
				                     elsif rxdw<"0000000100" or dmardfifodw>"011110000" 
											                       then nxt_state<=cpldwaitst6;
				                                            else nxt_state<=cplddatast1;
								         end if; 
				 when cpldwaitst6 => nxt_state<=cpldwaitst7;
				 when cpldwaitst7 => nxt_state<=cpldwaitst8;
				 when cpldwaitst8 => nxt_state<=cpldwaitst9;
				 when cpldwaitst9 => if dmardfifodw>"0111111000" 
				                     then nxt_state<=cpldwaitst9;
				                     else nxt_state<=cplddatast1;
											end if;
             when others=> nxt_state<=idle;
				 end case;
				 
				 if rst='0' then pre_state<=idle;
				 elsif rising_edge(clk) then pre_state<=nxt_state;
				 end if;
----------------------------------------------------------------------------------------------------------
				 
				 --RX包数据输出
				 if rising_edge(clk) then 
				        if pre_state=datast2 then 
						        if  addr(2)='1' and dw3sel='1' then extdqreg<=rxdata(63 downto 32);
								                                 else extdqreg<=rxdata(31 downto 0);
								  end if;
						  end if;
						  if pre_state=memwrst1 or pre_state=memwrst2 or pre_state=memwrst3 
						           then dqoen<='1';
									  else dqoen<='0';
							end if;
							
							--外部接口地址输出
							ext_add(21 downto 2)<=addr(21 downto 2);
						   ext_add(1 downto 0)<="00";	
							if pre_state=rdhead2 then 
							       memsel1<=rxbardec(1);
									 memsel2<=rxbardec(2);
							end if;
							if pre_state=memwrst2 or pre_state=memwrst3 then 
							     ext_wr<='1';
							 else ext_wr<='0';
							 end if;
							if pre_state=memrdst2 or pre_state=memrdst3 then 
							     ext_rd<='1';
								  else ext_rd<='0';
						   end if;		  
							if pre_state=memrdst3 then 
							     memrdrq<='1';
								  else memrdrq<='0';
						   end if;							
				 end if;
				 
				 --FIFO读写控制信号产生
				 if pre_state=rdhead1 or pre_state=datast1 or pre_state=unsp1 or pre_state=cpldwaitst1 
				     or pre_state=cplddatast1 
				         then fiford<='1';
							else fiford<='0';
				 end if;
				 if rising_edge(clk) then 
				     if pre_state=cplddatast1 then dmardfifowr<='1';
					                           else dmardfifowr<='0';
					  end if;
					  dmardfifodq<=rxdata;
				 end if;
             end process con_pro;
				 
				 --三态数据输出（条件代入语句）
             extdq<=extdqreg when dqoen='1'
                    else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
			   end beha;			

--architecture beha of rxproc is  
--type rxprost is (idle,rdhead1,headpro1,rdhead2,headpro2,waitst1,datast1,datast2,
--                 memwrst1,memwrst2,memwrst3,memwrst4,unsp1,unsp2,memrdst1,memrdst2,memrdst3,memrdst4
--					  ,cpldwaitst1,cplddatast1,cpldwaitst6
--					  ,cpldwaitst7,cpldwaitst8,cpldwaitst9
--					  
--					  --,iordst1,iordst2,iordst3,iordst4
--					  ,cplwaitst1,cpldatast1,cplwaitst6
--					  ,cplwaitst7,cplwaitst8,cplwaitst9
--					  ,iodatast1,iodatast2,iowrst1,iowrst2,iowrst3,iowrst4
--					  
--					  );
--signal pre_state,nxt_state : rxprost;
--signal rxdata,headrega,headregb : std_logic_vector(63 downto 0);
--signal rxbe,rxbardec : std_logic_vector(7 downto 0);
--signal rxvalid,rxerr,rxsop,rxeop,td,ep,dw3sel,rxen,tlpover,dqoen : std_logic;
--signal fmt : std_logic_vector(1 downto 0);
--signal tysel : std_logic_vector(4 downto 0);
--signal lenth,dwlength : std_logic_vector(9 downto 0);
--signal fbe : std_logic_vector(3 downto 0);
--signal addr,extdqreg : std_logic_vector(31 downto 0);
--signal memrdsel,memwrsel,iordsel,iowrsel,cfgrdsel,cfgwrsel,messrdsel,messwrsel,cplsel,cpldsel : std_logic;
--
--begin 
--    con_pro : process(clk,rst)
--	   begin  
--		       rxdata<=rxdq(63 downto 0);
--				 rxbe<=rxdq(71 downto 64);
--				 rxbardec<=rxdq(79 downto 72);
--				 rxvalid<=rxdq(80);
--				 rxerr<=rxdq(81);
--				 rxsop<=rxdq(82);
--				 rxeop<=rxdq(83);
--				 if rst='0' then led0<='0';
--				 elsif rising_edge(clk) then 
--				  if cpldsel='1' then led0<='1';
--				  end if;
--				  end if;
--				  led1<=cplsel;
--				  led2<=cplsel;
--				  led3<='0';
--				 if rst='0' then headrega<=(others=>'1');
--				 elsif rising_edge(clk) then 
--				      if pre_state=rdhead1 then headrega<=rxdata;
--				 end if;end if;
--				 if rst='0' then dwlength<=(others=>'0');
--				 elsif rising_edge(clk) then 
--				      if pre_state=rdhead1 then dwlength<=rxdata(9 downto 0);
--						elsif pre_state=cplddatast1 then 
--						          dwlength(9 downto 1)<=dwlength(9 downto 1)-1;
--				 end if;end if;
--				 tc<=headrega(21 downto 19);
--				 fmt<=headrega(30 downto 29);
--				 tysel<=headrega(28 downto 24);
--				 td<=headrega(15);
--				 ep<=headrega(14);
--				 attrib<=headrega(13 downto 12);
--				 lenth(9 downto 8)<=headrega(9 downto 8);
--				 lenth(7 downto 0)<=headrega(7 downto 0);
--				 reqid<=headrega(63 downto 48);
--				 tag<=headrega(47 downto 40);
--				 fbe<=headrega(35 downto 32);
--				 if rst='0' then headregb<=(others=>'0');
--				 elsif rising_edge(clk) then 
--				        if pre_state=rdhead2 then headregb<=rxdata;
--				 end if;end if;
--				 if rising_edge(clk) then 
--				        if dw3sel='1' then 
--						       addr(7 downto 2)<=headregb(7 downto 2);
--							    addr(15 downto 8)<=headregb(15 downto 8);
--							    addr(23 downto 16)<=headregb(23 downto 16);
--							    addr(31 downto 24)<=headregb(31 downto 24);
--							else 
--						       addr(7 downto 2)<=headregb(39 downto 34);
--							    addr(15 downto 8)<=headregb(47 downto 40);
--							    addr(23 downto 16)<=headregb(55 downto 48);
--							    addr(31 downto 24)<=headregb(63 downto 56);
--                     end if;
--             end if;			
--                 addr(1 downto 0)<="00";				
--				 if rising_edge(clk) then 
--				    if (headrega(28 downto 24)="00000" or headrega(28 downto 24)="00001") and headrega(30)='0'  
--					        then memrdsel<='1';
--							  else memrdsel<='0';
--					 end if;
--				    if (headrega(28 downto 24)="00000") and headrega(30)='1'  
--					        then memwrsel<='1';
--							  else memwrsel<='0';
--					 end if;
--				    if (headrega(28 downto 24)="00010") and headrega(30)='0'  
--					        then iordsel<='1';
--							  else iordsel<='0';
--					 end if;			
--				    if (headrega(28 downto 24)="00010") and headrega(30)='1'  
--					        then iowrsel<='1';
--							  else iowrsel<='0';
--					 end if;				
--				    if (headrega(28 downto 24)="00100" or headrega(28 downto 24)="00101") and headrega(30)='0'  
--					        then cfgrdsel<='1';
--							  else cfgrdsel<='0';
--					 end if;	 
--				    if (headrega(28 downto 24)="00100" or headrega(28 downto 24)="00101") and headrega(30)='1'  
--					        then cfgwrsel<='1';
--							  else cfgwrsel<='0';
--					 end if;
--				    if (headrega(28 downto 27)="10") and headrega(30)='0' 
--					        then messrdsel<='1';
--							  else messrdsel<='0';
--					 end if;
--				    if (headrega(28 downto 27)="10") and headrega(30)='1' 
--					        then messwrsel<='1';
--							  else messwrsel<='0';
--					 end if;				
--				    if (headrega(28 downto 24)="01010" or headrega(28 downto 24)="01011") and headrega(30)='0'  
--					        then cplsel<='1';
--							  else cplsel<='0';
--					 end if;
--				    if (headrega(28 downto 24)="01010" or headrega(28 downto 24)="01011") and headrega(30)='1' 
--					       and headrega(47 downto 45)="000"  
--					        then cpldsel<='1';
--							  else cpldsel<='0';
--					 end if;
--
--				 end if;
--					 if headrega(29)='0' then dw3sel<='1';
--					                    else dw3sel<='0';
--					 end if;
--				 
--				 if rising_edge(clk) then 
--			        if rxdw>="0000000010" then rxen<='1';
--					                      else rxen<='0';
--						end if;
--						if iordsel='1' or cfgrdsel='1' or messrdsel='1' or cplsel='1' then tlpover<='1';
--						                                                              else tlpover<='0';
--						end if;
--				 end if;		
--		       case pre_state is
--             when idle => if rxen='1' and rxsop='1' then nxt_state<=rdhead1;
--			                                  else nxt_state<=idle;
--								  end if;
--			    when rdhead1 => nxt_state<=headpro1;
--			    when headpro1 => nxt_state<=rdhead2;
--			    when rdhead2 => nxt_state<=headpro2;
--             when headpro2 => nxt_state<=waitst1;
--			    when waitst1 => if memwrsel='1' and addr(2)='1' and dw3sel='1' then nxt_state<=datast2;
--				                  elsif memwrsel='1' then nxt_state<=datast1;
--										elsif memrdsel='1' then nxt_state<=memrdst1;
--										elsif cpldsel='1' then nxt_state<=cpldwaitst1;
--										----------------------------------------------------------------------------------------
--										elsif iowrsel='1'  then nxt_state<=iodatast1;
--										elsif iowrsel='1' and addr(2)='1' and dw3sel='1' then nxt_state<=iodatast2;
--										elsif cplsel='1' then nxt_state<=cplwaitst1;
--										----------------------------------------------------------------------------------------
--				                  else nxt_state<=unsp1;
--							         end if;
--				 
--				----------------------------------------------------------------------------------------
--				 when iodatast1 => nxt_state<=iodatast2;
--				 when iodatast2 => nxt_state<=iowrst1;
--				 when iowrst1 => nxt_state<=iowrst2;
--				 when iowrst2 => nxt_state<=iowrst3;
--				 when iowrst3 => if extdfer='1' then nxt_state<=iowrst4;
--				                                 else nxt_state<=iowrst3;
--										end if;
--				 when iowrst4 => nxt_state<=unsp1;
--				----------------------------------------------------------------------------------------
--				 when cplwaitst1 => nxt_state<=cpldatast1;
--				 when cpldatast1 => if rxeop='1' then nxt_state<=idle;
--				                     elsif rxdw<"0000000100" or dmardfifodw>"011110000" 
--											                       then nxt_state<=cplwaitst6;
--				                                            else nxt_state<=cpldatast1;
--								         end if; 
--				 when cplwaitst6 => nxt_state<=cplwaitst7;
--				 when cplwaitst7 => nxt_state<=cplwaitst8;
--				 when cplwaitst8 => nxt_state<=cplwaitst9;
--				 when cplwaitst9 => if dmardfifodw>"0111111000" 
--				                     then nxt_state<=cplwaitst9;
--				                     else nxt_state<=cpldatast1;
--											end if;
--				----------------------------------------------------------------------------------------
--			    when unsp1 => if rxeop='1' then nxt_state<=idle;
--				                            else nxt_state<=unsp2;
--									end if;
--				 when unsp2 => nxt_state<=unsp1;
--				 when datast1 => nxt_state<=datast2;
--				 when datast2 => nxt_state<=memwrst1;
--				 when memwrst1 => nxt_state<=memwrst2;
--				 when memwrst2 => nxt_state<=memwrst3;
--				 when memwrst3 => if extdfer='1' then nxt_state<=memwrst4;
--				                                 else nxt_state<=memwrst3;
--										end if;
--				 when memwrst4 => nxt_state<=unsp1;
--				 when memrdst1 => nxt_state<=memrdst2;
--				 when memrdst2 => nxt_state<=memrdst3;
--				 when memrdst3 => if memrdack='1' then nxt_state<=memrdst4;
--				                                  else nxt_state<=memrdst3;
--									   end if;
--				 when memrdst4 => nxt_state<=unsp1;
--				 when cpldwaitst1 => nxt_state<=cplddatast1;
--				 when cplddatast1 => if rxeop='1' then nxt_state<=idle;
--				                     elsif rxdw<"0000000100" or dmardfifodw>"011110000" 
--											                       then nxt_state<=cpldwaitst6;
--				                                            else nxt_state<=cplddatast1;
--								         end if; 
--				 when cpldwaitst6 => nxt_state<=cpldwaitst7;
--				 when cpldwaitst7 => nxt_state<=cpldwaitst8;
--				 when cpldwaitst8 => nxt_state<=cpldwaitst9;
--				 when cpldwaitst9 => if dmardfifodw>"0111111000" 
--				                     then nxt_state<=cpldwaitst9;
--				                     else nxt_state<=cplddatast1;
--											end if;
--             when others=> nxt_state<=idle;
--				 end case;
--				 if rst='0' then pre_state<=idle;
--				 elsif rising_edge(clk) then pre_state<=nxt_state;
--				 end if;
--				 if rising_edge(clk) then 
--				        if pre_state=datast2 or pre_state=iodatast2 then 
--						        if  addr(2)='1' and dw3sel='1' then extdqreg<=rxdata(63 downto 32);
--								                                 else extdqreg<=rxdata(31 downto 0);
--								  end if;
--						  end if;
--						  if pre_state=memwrst1 or pre_state=memwrst2 or pre_state=memwrst3   -----
--						    or pre_state=iowrst1 or pre_state=iowrst2 or pre_state=iowrst3
--						           then dqoen<='1';
--									  else dqoen<='0';
--							end if;
--							ext_add(21 downto 2)<=addr(21 downto 2);
--						   ext_add(1 downto 0)<="00";	
--							if pre_state=rdhead2 then 
--							----------------------------------------------------------------------------------------
--							       iosel<=rxbardec(0);  --io
--							----------------------------------------------------------------------------------------		 
--									 memsel1<=rxbardec(1);
--									 memsel2<=rxbardec(2);
--							end if;
--							if pre_state=memwrst2 or pre_state=memwrst3 or pre_state=iowrst2 or pre_state=iowrst3 then ----
--							     ext_wr<='1';
--							 else ext_wr<='0';
--							 end if;
--							if pre_state=memrdst2 or pre_state=memrdst3 then 
--							     ext_rd<='1';
--								  else ext_rd<='0';
--						   end if;		  
--							if pre_state=memrdst3 then 
--							     memrdrq<='1';
--								  else memrdrq<='0';
--						   end if;							
--				 end if;
--				 if pre_state=rdhead1 or pre_state=datast1 or pre_state=unsp1 or pre_state=cpldwaitst1 ----
--				     or pre_state=cplddatast1 or pre_state=iodatast1
--				         then fiford<='1';           --从rxfifo缓冲中rdreq
--							else fiford<='0';
--				 end if;
--				 if rising_edge(clk) then 
--				     if pre_state=cplddatast1 then dmardfifowr<='1';
--					                           else dmardfifowr<='0';
--					  end if;
--					  dmardfifodq<=rxdata;
--				 end if;
--             end process;
--             extdq<=extdqreg when dqoen='1'
--                    else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
--			   end beha;			  
--										
--										
--			
--	
--
--	
