library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity test is
port(
	rstn	:in std_logic;
	clk		:in std_logic;
	dir	    :in std_logic;
	puls       :in std_logic;
	renew : in std_logic;
	count   :out std_logic_vector( 31 downto 0)	
	);
end test;


architecture logic_test of test is

signal count1: std_logic_vector( 31 downto 0);
signal count2: std_logic_vector( 31 downto 0);
signal count3: std_logic_vector( 31 downto 0);

begin

-----------count1----------------------
process(dir,puls,rstn)
begin 
if(rstn='0')then
count1<="00000000000000000000000000000000";
--elsif(renew='1')then
--count1<="00000000000000000000000000000000";
elsif((puls'event)and(puls='1')and dir='1')then
count1<=count1+1;
else
count1<=count1;
end if;
end process;

-----------count2----------------------
process(dir,puls,rstn)
begin 
if(rstn='0')then
count1<="00000000000000000000000000000000";
--elsif(renew='1')then
--count1<="00000000000000000000000000000000";
elsif((puls'event)and(puls='1')and dir='0')then
count2<=count2+1;
else
count2<=count2;
end if;
end process;

-----------count1，count2，count3，count4相加----------------------
process(clk,rstn)
begin 
if(rstn='0')then
count3<="00000000000000000000000000000000";
elsif((clk'event)and(clk='1'))then
count3<=count1-count2;
else
null;
end if; 
end process;

count<=count3;

end logic_test;
