library ieee;
use ieee.std_logic_1164.all;
entity cfgspace is port(
clk,rst,wr : in std_logic;
add : in std_logic_vector(3 downto 0);
data : in std_logic_vector(31 downto 0);
err_rep_en : out std_logic_vector(3 downto 0);
maxp_size : out std_logic_vector(2 downto 0);
maxrq_size : out std_logic_vector(2 downto 0);
memen,ioen,dmaen : out std_logic;
busnum : out std_logic_vector(7 downto 0);
devnum : out std_logic_vector(4 downto 0));
end cfgspace;
architecture beha of cfgspace is 
signal devcsr,prmcsr,busdev : std_logic_vector(31 downto 0);
signal wr1,wr2,wr3 : std_logic;
begin  
   con_pro : process(clk,rst) 
	   begin if rising_edge(clk) then 
	             wr1<=wr;
					 wr2<=wr1;
					 wr3<=wr2;
				end if; 
	       	if rst='0' then devcsr<=(others=>'0');
		      elsif rising_edge(clk) then
			     if wr3/=wr2 then 	
				 if add="0000" then 
				      devcsr<=data;
			    end if;
				 end if;
				end if;
				err_rep_en<=devcsr(19 downto 16);
				maxp_size<=devcsr(23 downto 21);
				maxrq_size<=devcsr(30 downto 28);
            if rst='0' then prmcsr<=(others=>'0');
		      elsif rising_edge(clk) then 
				 if wr3/=wr2 then 
				 if add="0011" then 
				      prmcsr<=data;
			    end if;
				 end if;
				end if;  
            ioen<=prmcsr(8);
            memen<=prmcsr(9);
            dmaen<=prmcsr(10);
            if rst='0' then busdev<=(others=>'0');
		      elsif rising_edge(clk) then 
				 if wr3/=wr2 then 
				 if add="1111" then 
				      busdev<=data;
			    end if;
				end if;          
            end if;				
            busnum<=busdev(12 downto 5);
				devnum<=busdev(4 downto 0);
		 end process;
		 end beha;

