library ieee;
use ieee.std_logic_1164.all;
entity txstinf is port(
clk,rst,tx_st_eop : in std_logic;
tx_cred : in std_logic_vector(35 downto 0);
txfifoempty,txfifoalempty,tx_st_ready : in std_logic;
tx_st_err,tx_st_valid,txfiford,led1,led2,led3,led4 : out std_logic);
end txstinf;
architecture beha of txstinf is 
type txstate is (idle,txst1,txwaitst1,txwaitst2,txwaitst3,txwaitst4,txwaitst5,txwaitst6,txwaitst7);
signal pre_state,nxt_state : txstate;
signal postheaden,postdataen,npheaden,npdataen,cpheaden,cpdataen : std_logic;
begin 
   con_pro : process(clk,rst)
	   begin  if rising_edge(clk) then
	                if tx_cred(2 downto 0)>="100" then postheaden<='1';
						                               else postheaden<='0';
						 end if;
						 if tx_cred(14 downto 3)>="000000100000" then postdataen<='1';
						                                         else postdataen<='0';
						 end if;		
                   if tx_cred(17 downto 15)>="100" then npheaden<='1';
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
			          if  postheaden='1' and postdataen='1' and npheaden='1'
								  and npdataen='1' and cpheaden='1' and cpdataen='1'
						    then led1<='1';
				          else led1<='0';
				       end if;		

					 
		       end if;
				 if rst='0' then led2<='0';
				 elsif rising_edge(clk) then 
				       if tx_st_ready='1' then led2<='1';
						                    else led2<='0';
				 end if;
				 end if;
               led3<='0';
               led4<='0';
		       case pre_state is 
		       when idle => if txfifoempty='0' and tx_st_ready='1' 
				              and postheaden='1' and postdataen='1' and npheaden='1'
								  and npdataen='1' and cpheaden='1' and cpdataen='1'
				                   then nxt_state<=txst1;
				                                                     else nxt_state<=idle;
						        end if;
				 when txst1 => if tx_st_ready='0' or txfifoalempty='1' or tx_st_eop='1'
				                                                       then nxt_state<=txwaitst1;
				                                                       else nxt_state<=txst1;
									end if;
				 when txwaitst1 => nxt_state<=txwaitst2; 
				 when txwaitst2 => nxt_state<=txwaitst3; 
				 when txwaitst3 => nxt_state<=txwaitst4; 
				 when txwaitst4 => nxt_state<=txwaitst5; 
				 when txwaitst5 => nxt_state<=txwaitst6; 
				 when txwaitst6 => nxt_state<=txwaitst7; 
				 when txwaitst7 => nxt_state<=idle;              
				 when others => nxt_state<=idle;
				 end case;
				 tx_st_err<='0';
				 if rising_edge(clk) then 
				       if pre_state=txst1 then tx_st_valid<='1';
						                    else tx_st_valid<='0';
						 end if;
				       if pre_state=txst1 then txfiford<='1';
						                    else txfiford<='0';
						 end if;		
		       end if;
             if rst='0' then pre_state<=idle;
             elsif rising_edge(clk) then pre_state<=nxt_state;
             end if;
      end process;
      end beha;		
