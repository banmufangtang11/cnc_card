library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity encode is
port(
	rstn	:in std_logic;
	clk		:in std_logic;
	a	    :in std_logic;--编码器A相脉冲
	b       :in std_logic;--编码器B相脉冲
	renew : in std_logic;--set count1 2 3 4 =0
	count   :out std_logic_vector( 31 downto 0)  --编码器计数输出
	
	);
end encode;

architecture logic_encode of encode is

signal count1: std_logic_vector( 31 downto 0);
signal count2: std_logic_vector( 31 downto 0);
signal count3: std_logic_vector( 31 downto 0);
signal count4: std_logic_vector( 31 downto 0);
signal count5: std_logic_vector( 31 downto 0);

begin
----------------------------A相上升沿时，B相为低电平减计数或高电平进行加计数----------------
process(a,b,rstn)
begin 
if(rstn='0')then
count1<="00000000000000000000000000000000";
elsif(renew='1')then
count1<="00000000000000000000000000000000";
elsif((a'event)and(a='1')and b='0')then
count1<=count1+1;
elsif((a'event)and(a='1')and b='1')then
count1<=count1-1;
else
null;
end if;
end process;
----------------A相下降沿时，B相为低电平减计数或高电平进行加计数-------------
process(a,b,rstn)
begin 
if(rstn='0')then
count2<="00000000000000000000000000000000";
elsif(renew='1')then
count2<="00000000000000000000000000000000";
elsif((a'event)and(a='0')and b='0')then
count2<=count2-1;
elsif((a'event)and(a='0')and b='1')then
count2<=count2+1;
else
null;
end if;
end process;
---------------B相上升沿时，A相为低电平减计数或高电平进行加计数------------
process(a,b,rstn)
begin 
if(rstn='0')then
count3<="00000000000000000000000000000000";
elsif(renew='1')then
count3<="00000000000000000000000000000000";
elsif((b'event)and(b='1')and a='0')then
count3<=count3-1;
elsif((b'event)and(b='1')and a='1')then
count3<=count3+1;
else
null;
end if;
end process;
--------------B相下降沿时，A相为低电平减计数或高电平进行加计数-----------
process(a,b,rstn)
begin 
if(rstn='0')then
count4<="00000000000000000000000000000000";
elsif(renew='1')then
count4<="00000000000000000000000000000000";
elsif((b'event)and(b='0')and a='0')then
count4<=count4+1;
elsif((b'event)and(b='0')and a='1')then
count4<=count4-1;
else
null;
end if;
end process;
-----------count1，count2，count3，count4相加----------------------
process(clk,rstn)
begin 
if(rstn='0')then
count5<="00000000000000000000000000000000";
elsif((clk'event)and(clk='1'))then
count5<=count1+count2+count3+count4;
else
null;
end if; 
end process;

count<=count5;


end logic_encode;

