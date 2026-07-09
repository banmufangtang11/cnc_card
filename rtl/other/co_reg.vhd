library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity co_model is port(
clk,rst : in std_logic;
co1,co2,co3,co4,co5,co6,co7,co8 :in std_logic;
px_in,py_in,pz_in,pa_in : in std_logic;
dx_in,dy_in,dz_in,da_in :in std_logic;

p1,p2,p3,p4,p5,p6,p7,p8 : out std_logic;
d1,d2,d3,d4,d5,d6,d7,d8 : out std_logic);
end co_model;

architecture beha of co_model is 
signal coreg : std_logic_vector(7 downto 0);




begin 
   con_pro : process(clk)
     begin 
	      if rising_edge(clk) then 
			
			coreg(0)<=co1;
			coreg(1)<=co2;
			coreg(2)<=co3;
			coreg(3)<=co4;
			coreg(4)<=co5;
			coreg(5)<=co6;
			coreg(6)<=co7;
			coreg(7)<=co8;
			
			case coreg is 
			when "00001111" => d1<=dx_in; p1<=px_in;--1
			                   d2<=dy_in; p2<=py_in;
									 d3<=dz_in; p3<=pz_in;
									 d4<=da_in; p4<=pa_in;
									 d5<='0';   p5<='0';
									 d6<='0';   p6<='0';
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';
									 
			when "00010111" => d1<=dx_in; p1<=px_in;--2
			                   d2<=dy_in; p2<=py_in;
									 d3<=dz_in; p3<=pz_in;
									 d4<='0';   p4<='0';
									 d5<=da_in; p5<=pa_in;
									 d6<='0';   p6<='0';
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';
			
			when "00100111" => d1<=dx_in; p1<=px_in;--3
			                   d2<=dy_in; p2<=py_in;
									 d3<=dz_in; p3<=pz_in;
									 d4<='0';   p4<='0';
									 d5<='0';   p5<='0';
									 d6<=da_in; p6<=pa_in;
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';
			
			when "01000111" => d1<=dx_in; p1<=px_in;--4
			                   d2<=dy_in; p2<=py_in;
									 d3<=dz_in; p3<=pz_in;
									 d4<='0';   p4<='0';
									 d5<='0';   p5<='0';
									 d6<='0'; p6<='0';
									 d7<=da_in;   p7<=pa_in;
									 d8<='0';   p8<='0';
									 
			when "10000111" => d1<=dx_in; p1<=px_in;--5
			                   d2<=dy_in; p2<=py_in;
									 d3<=dz_in; p3<=pz_in;
									 d4<='0';   p4<='0';
									 d5<='0';   p5<='0';
									 d6<='0'; p6<='0';
									 d7<='0';   p7<='0';
									 d8<=da_in;   p8<=pa_in;
			
			when "00011011" => d1<=dx_in; p1<=px_in;--6
			                   d2<=dy_in; p2<=py_in;
									 d3<='0'; p3<='0';
									 d4<=dz_in;   p4<=pz_in;
									 d5<=da_in;   p5<=pa_in;
									 d6<='0'; p6<='0';
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';
									 
			when "00101011" => d1<=dx_in; p1<=px_in;--7
			                   d2<=dy_in; p2<=py_in;
									 d3<='0'; p3<='0';
									 d4<=dz_in;   p4<=pz_in;
									 d5<='0';   p5<='0';
									 d6<=da_in; p6<=pa_in;
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';						 

			when "01001011" => d1<=dx_in; p1<=px_in;--8
			                   d2<=dy_in; p2<=py_in;
									 d3<='0'; p3<='0';
									 d4<=dz_in;   p4<=pz_in;
									 d5<='0';   p5<='0';
									 d6<='0'; p6<='0';
									 d7<=da_in;   p7<=pa_in;
									 d8<='0';   p8<='0';
									 
			when "10001011" => d1<=dx_in; p1<=px_in;--9
			                   d2<=dy_in; p2<=py_in;
									 d3<='0'; p3<='0';
									 d4<=dz_in;   p4<=pz_in;
									 d5<='0';   p5<='0';
									 d6<='0'; p6<='0';
									 d7<='0';   p7<='0';
									 d8<=da_in;   p8<=pa_in;
									 
			when "00110011" => d1<=dx_in; p1<=px_in;--10
			                   d2<=dy_in; p2<=py_in;
									 d3<='0'; p3<='0';
									 d4<='0';   p4<='0';
									 d5<=dz_in;   p5<=pz_in;
									 d6<=da_in; p6<=pa_in;
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';						 
			
			when others =>     d1<=dx_in; p1<=px_in;--others
			                   d2<=dy_in; p2<=py_in;
									 d3<=dz_in; p3<=pz_in;
									 d4<=da_in; p4<=pa_in;
									 d5<='0';   p5<='0';
									 d6<='0';   p6<='0';
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';
			end case;
			
			
			


end if; 
end process;	

end beha;