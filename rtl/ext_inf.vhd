library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity ext_inf is port(
clk,rst,valid : in std_logic;
dq : inout std_logic_vector(31 downto 0);
data_rd_out,data_wr : in std_logic;
ext_add : in std_logic_vector(21 downto 0);

ext_rd,ext_wr : buffer std_logic;
led0,led1,led2,led3 : buffer std_logic;

empty,full,almost_empty,almost_full : in std_logic;
iosel,memsel1,memsel2 : in std_logic;
app_int_ack : in std_logic;
ext_int_req : buffer std_logic;
fifo_in : out std_logic_vector(31 downto 0);
fifo_out : in std_logic_vector(31 downto 0);
wrreq : out std_logic);

end ext_inf;


architecture beha of ext_inf is 

signal dqinreg : std_logic_vector(31 downto 0);
signal intregsel,pctocardregsel : std_logic;
signal intreg,pctocardreg : std_logic_vector(31 downto 0);
signal wr_flag : std_logic;
signal cnt: std_logic_vector(1 downto 0);

--signal ramcs : std_logic;
--signal led_reg : std_logic_vector(31 downto 0);
--signal seg_reg : std_logic_vector(7 downto 0);
--signal fifo_in_reg,fifo_out_reg: std_logic_vector(31 downto 0);
--signal led_sel,int_reg_sel,fifo_in_sel,fifo_out_sel,usedw_sel,wr_flag: std_logic;
--signal led_reg: std_logic_vector(2 downto 0);
--signal int_reg: std_logic_vector(31 downto 0);

--signal usedw_reg:std_logic_vector(10 downto 0);


--signal var1,var2,var3,var4,var5,var6,var7,var8 : std_logic_vector(31 downto 0);
--signal var1_sel,var2_sel,var3_sel,var4_sel,var5_sel,var6_sel,var7_sel,var8_sel : std_logic;
--type intstate is (idle,inten,intack1,intdisable,intack2);
--signal pre_state,nxt_state : intstate;


begin 
   con_pro : process(clk,rst)
     begin   

             
             if rising_edge(clk) then 
				 dqinreg<=dq;
             end if; 

				 
				 if rising_edge(clk) then 
	             if memsel1='1' and ext_add="0000000000000000000100" 
					            then intregsel<='1';
					 else intregsel<='0';
					 end if;
					 if memsel1='1' and ext_add="0000000000000000010100" 
					            then pctocardregsel<='1';
					 else pctocardregsel<='0';
					 end if;
				end if;
				
				 if rst='0' then pctocardreg<=(others=>'0');wr_flag<='0';
               elsif rising_edge(clk) then if (pctocardregsel='1' and data_wr='1') then 
               pctocardreg<=dqinreg;
					wr_flag<='1';
               else pctocardreg<=pctocardreg;wr_flag<='0';
               end if;
               end if;
					
				
     end process;	
	  
	  con_pro_check : process(clk,rst)
	    begin
		 
		 if rst='0' then wrreq<='0';cnt<="00";
              elsif rising_edge(clk)then if(wr_flag ='1'and cnt="00") then
              wrreq<='1';cnt<=cnt+"01";
               elsif(cnt="01") then wrreq<='0';cnt<="00";
               else wrreq<='0';cnt<="00";
               end if;
               end if;
		 end process;
--		 fifo_in<="11111000000100000010000001000000";
		 fifo_in <= pctocardreg;
		 
		 ext_int_req <= '1' when ((almost_empty = '1' ) and valid ='1') else '0';
--		 ext_int_req <= '1' when ((almost_empty = '1' or empty = '1') and valid ='1') else '0';
		 
	 end beha;