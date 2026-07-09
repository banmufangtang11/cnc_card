library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity dp_a is
port(
	rstn	:in std_logic;
	clk		:in std_logic;
	dir	    :in std_logic;
	puls       :in std_logic;
	renew : in std_logic;
	count   :out std_logic_vector( 31 downto 0)
	);
end dp_a;

architecture logic_dp of dp_a is

signal count1: std_logic_vector( 31 downto 0);
--signal count2: std_logic_vector( 31 downto 0);


begin
---------------------------
process(dir,puls,renew,rstn)
begin 
if(rstn='0')then
count1<="00000000000000000000000000000000";
elsif(renew='1')then
count1<="00000000000000000000000000000000";
--elsif(count1<="0000000000000001000110010100000")then
--count1<="00000000000000000000000000000001";
--elsif(count1<="1111111111111111111111111111111")then
--count1<="00000000000000001000110010011111";
elsif((puls'event)and(puls='1')and dir='0')then
count1<=count1-1;
elsif((puls'event)and(puls='1')and dir='1')then
count1<=count1+1;
else
null;
end if;
end process;


count<=count1;


end logic_dp;

