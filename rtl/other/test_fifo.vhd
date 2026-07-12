library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity test_fifo is port(
clk,rst,rdempty : in std_logic;
rddw : in std_logic_vector(8 downto 0);
dw : in std_logic_vector(10 downto 0);
fifo31_inwr,fiford : buffer std_logic);
end test_fifo;

architecture beha of test_fifo is 
signal fifowrsel,fifordsel : std_logic;
signal fifowrreg,fifowrrega : std_logic_vector(63 downto 0);
type rdwrstate is (idle,rdwrst,waitst1,waitst2,waitst3,waitst4,waitst5,waitst6);
signal pre_state,nxt_state : rdwrstate;

begin 
  con_pro : process(clk,rst)
   begin  case pre_state is 
	       when idle => if rdempty='0' and dw<="011111010000" then nxt_state<=rdwrst;  --pcie输出fifo没有读空且fifo31没有写满
			                                                   else nxt_state<=idle;
							   end if;
			 when rdwrst => if rddw<="000000100" or dw>"011111010000" then nxt_state<=waitst1;  --pcie输出fifo即将读空或者fifo31即将写满
			                                                         else nxt_state<=rdwrst;
								 end if;
		    when waitst1 => nxt_state<=waitst2;
		    when waitst2 => nxt_state<=waitst3;
		    when waitst3 => nxt_state<=waitst4;
		    when waitst4 => nxt_state<=waitst5;
		    when waitst5 => nxt_state<=waitst6;
		    when waitst6 => nxt_state<=idle;	
	       when others => nxt_state<=idle;
	       end case;
	       if rising_edge(clk) then 
	           if pre_state=rdwrst then fifo31_inwr<='1';     --往fifo31写请求
			                              fiford<='1';        --往pcie输出fifo的读请求
									       else fifo31_inwr<='0';
									            fiford<='0';
				  end if;
			 end if;
	       if rst='0' then pre_state<=idle;
	       elsif rising_edge(clk) then pre_state<=nxt_state;
	       end if;		 

    end process;
    end beha; 