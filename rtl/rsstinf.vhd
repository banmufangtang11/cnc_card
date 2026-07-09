 library ieee;
use ieee.std_logic_1164.all;
entity rsstinf is port(
clk,rst : in std_logic;
rx_st_bardec,rx_st_be : in std_logic_vector(7 downto 0);						--bar空间选择
rx_st_data : in std_logic_vector(63 downto 0);									--64位Avalon数据
rx_st_eop,rx_st_err,rx_st_sop,rx_st_valid : in std_logic;					--Avalon控制信号
rx_st_mask,rx_st_ready : out std_logic;

fifodq : out std_logic_vector(95 downto 0);										--封装输出 96位-3DW
fifowr,led : out std_logic;															--缓冲FIFO写入信号
fifoalfull : in std_logic);															--FIFO满信号
end rsstinf;

architecture beha of rsstinf is
 
signal fifodqreg : std_logic_vector(95 downto 0);

begin 
   con_pro : process(clk,rst)
	   begin  if rising_edge(clk) then 
		       rx_st_mask<='0';
		       rx_st_ready<=not(fifoalfull);
				 end if;
				 
				 fifodqreg(63 downto 0)<=rx_st_data(63 downto 0);
				 fifodqreg(71 downto 64)<=rx_st_be;
				 fifodqreg(79 downto 72)<=rx_st_bardec;
				 fifodqreg(80)<=rx_st_valid;
				 fifodqreg(81)<=rx_st_err;
				 fifodqreg(82)<=rx_st_sop;
				 fifodqreg(83)<=rx_st_eop;
				 fifodqreg(95 downto 84)<="000000000000";
				 
				 if rst='0' then led<='0';
				 elsif rising_edge(clk) then 
				     if rx_st_valid='1' then led<='1';
				 end if;end if;
	--			 if rising_edge(clk) then 
				     fifodq<=fifodqreg;
					  fifowr<=rx_st_valid;
	--			 end if;
		end process con_pro;
end beha;
		
			    