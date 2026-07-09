library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity co_assign is port(
clk,rst : in std_logic;
co1,co2,co3,co4,co5,co6,co7,co8 :in std_logic;
px_in,py_in,pz_in,pa_in : in std_logic;
dx_in,dy_in,dz_in,da_in :in std_logic;
mag_sel:in std_logic;    --magazine select signal, I use axis 8  --v5.0
md,mp:in std_logic;  --v5.0,  m:tool magazine,d:direction,p:pulse

p1,p2,p3,p4,p5,p6,p7,p8 : out std_logic;
d1,d2,d3,d4,d5,d6,d7,d8 : out std_logic);
end co_assign;

architecture beha of co_assign is 
signal coreg : std_logic_vector(7 downto 0);

signal mag:std_logic;--v5.0


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
			mag<=mag_sel;  --v5.0
	       
     ----v5.8.3.2---------------------------------			
			  if mag ='1' then      
				            d1<='0';p1<='0';
			               d2<='0';p2<='0';
							   d3<='0';p3<='0';
							   d4<='0';p4<='0';
								d5<='0';p5<='0';
								d6<='0';p6<='0';
								d7<='0';p7<='0';
								--d8<=md;p8<='1';  --v5.8.3.2
								d8<=md;p8<=mp;
			  else  -----v5832 
			  
			case coreg is 
---------------------------C84-------------------------------
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
			
			when "01010011" => d1<=dx_in; p1<=px_in;--11
			                   d2<=dy_in; p2<=py_in;
									 d3<='0'; p3<='0';
									 d4<='0';   p4<='0';
									 d5<=dz_in;   p5<=pz_in;
									 d6<='0'; p6<='0';
									 d7<=da_in;   p7<=pa_in;
									 d8<='0';   p8<='0';	
			
			when "10010011" => d1<=dx_in; p1<=px_in;--12
			                   d2<=dy_in; p2<=py_in;
									 d3<='0'; p3<='0';
									 d4<='0';   p4<='0';
									 d5<=dz_in;   p5<=pz_in;
									 d6<='0'; p6<='0';
									 d7<='0';   p7<='0';
									 d8<=da_in;   p8<=pa_in;	
			
			when "01100011" => d1<=dx_in; p1<=px_in;--13
			                   d2<=dy_in; p2<=py_in;
									 d3<='0'; p3<='0';
									 d4<='0';   p4<='0';
									 d5<='0';   p5<='0';
									 d6<=dz_in; p6<=pz_in;
									 d7<=da_in;   p7<=pa_in;
									 d8<='0';   p8<='0';
			
			when "10100011" => d1<=dx_in; p1<=px_in;--14
			                   d2<=dy_in; p2<=py_in;
									 d3<='0'; p3<='0';
									 d4<='0';   p4<='0';
									 d5<='0';   p5<='0';
									 d6<=dz_in; p6<=pz_in;
									 d7<='0';   p7<='0';
									 d8<=da_in;   p8<=pa_in;
									 
			when "11000011" => d1<=dx_in; p1<=px_in;--15
			                   d2<=dy_in; p2<=py_in;
									 d3<='0'; p3<='0';
									 d4<='0';   p4<='0';
									 d5<='0';   p5<='0';
									 d6<='0'; p6<='0';
									 d7<=dz_in;   p7<=pz_in;
									 d8<=da_in;   p8<=pa_in;						 
			
			when "00011101" => d1<=dx_in; p1<=px_in;--16
			                   d2<='0'; p2<='0';
									 d3<=dy_in; p3<=py_in;
									 d4<=dz_in;   p4<=pz_in;
									 d5<=da_in;   p5<=pa_in;
									 d6<='0'; p6<='0';
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';
			
			when "00101101" => d1<=dx_in; p1<=px_in;--17
			                   d2<='0'; p2<='0';
									 d3<=dy_in; p3<=py_in;
									 d4<=dz_in;   p4<=pz_in;
									 d5<='0';   p5<='0';
									 d6<=da_in; p6<=pa_in;
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';
			
			when "01001101" => d1<=dx_in; p1<=px_in;--18
			                   d2<='0'; p2<='0';
									 d3<=dy_in; p3<=py_in;
									 d4<=dz_in;   p4<=pz_in;
									 d5<='0';   p5<='0';
									 d6<='0'; p6<='0';
									 d7<=da_in;   p7<=pa_in;
									 d8<='0';   p8<='0';
			
			when "10001101" => d1<=dx_in; p1<=px_in;--19
			                   d2<='0'; p2<='0';
									 d3<=dy_in; p3<=py_in;
									 d4<=dz_in;   p4<=pz_in;
									 d5<='0';   p5<='0';
									 d6<='0'; p6<='0';
									 d7<='0';   p7<='0';
									 d8<=da_in;   p8<=pa_in;
			
			when "00110101" => d1<=dx_in; p1<=px_in;--20
			                   d2<='0'; p2<='0';
									 d3<=dy_in; p3<=py_in;
									 d4<='0';   p4<='0';
									 d5<=dz_in;   p5<=pz_in;
									 d6<=da_in; p6<=pa_in;
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';
			
			when "01010101" => d1<=dx_in; p1<=px_in;--21
			                   d2<='0'; p2<='0';
									 d3<=dy_in; p3<=py_in;
									 d4<='0';   p4<='0';
									 d5<=dz_in;   p5<=pz_in;
									 d6<='0'; p6<='0';
									 d7<=da_in;   p7<=pa_in;
									 d8<='0';   p8<='0';
			
			when "10010101" => d1<=dx_in; p1<=px_in;--22
			                   d2<='0'; p2<='0';
									 d3<=dy_in; p3<=py_in;
									 d4<='0';   p4<='0';
									 d5<=dz_in;   p5<=pz_in;
									 d6<='0'; p6<='0';
									 d7<='0';   p7<='0';
									 d8<=da_in;   p8<=pa_in;
						
			when "01100101" => d1<=dx_in; p1<=px_in;--23
			                   d2<='0'; p2<='0';
									 d3<=dy_in; p3<=py_in;
									 d4<='0';   p4<='0';
									 d5<='0';   p5<='0';
									 d6<=dz_in; p6<=pz_in;
									 d7<=da_in;   p7<=pa_in;
									 d8<='0';   p8<='0';
			
			when "10100101" => d1<=dx_in; p1<=px_in;--24
			                   d2<='0'; p2<='0';
									 d3<=dy_in; p3<=py_in;
									 d4<='0';   p4<='0';
									 d5<='0';   p5<='0';
									 d6<=dz_in; p6<=pz_in;
									 d7<='0';   p7<='0';
									 d8<=da_in;   p8<=pa_in;
									 
			when "11000101" => d1<=dx_in; p1<=px_in;--25
			                   d2<='0'; p2<='0';
									 d3<=dy_in; p3<=py_in;
									 d4<='0';   p4<='0';
									 d5<='0';   p5<='0';
									 d6<='0'; p6<='0';
									 d7<=dz_in;   p7<=pz_in;
									 d8<=da_in;   p8<=pa_in;						 
			
			when "00111001" => d1<=dx_in; p1<=px_in;--26
			                   d2<='0'; p2<='0';
									 d3<='0'; p3<='0';
									 d4<=dy_in;   p4<=py_in;
									 d5<=dz_in;   p5<=pz_in;
									 d6<=da_in; p6<=pa_in;
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';
			
			when "01011001" => d1<=dx_in;p1<=px_in;--27
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10011001" => d1<=dx_in;p1<=px_in;--28
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "01101001" => d1<=dx_in;p1<=px_in;--29
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10101001" => d1<=dx_in;p1<=px_in;--30
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "11001001" => d1<=dx_in;p1<=px_in;--31
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "01110001" => d1<=dx_in;p1<=px_in;--32
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10110001" => d1<=dx_in;p1<=px_in;--33
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;

			when "11010001" => d1<=dx_in;p1<=px_in;--34
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "11100001" => d1<=dx_in;p1<=px_in;--35
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "00011110" => d1<='0';p1<='0';--36
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<=dz_in;p4<=pz_in;
									 d5<=da_in;p5<=pa_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
			
			when "00101110" => d1<='0';p1<='0';--37
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<=dz_in;p4<=pz_in;
									 d5<='0';p5<='0';
									 d6<=da_in;p6<=pa_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
			
			when "01001110" => d1<='0';p1<='0';--38
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<=dz_in;p4<=pz_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10001110" => d1<='0';p1<='0';--39
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<=dz_in;p4<=pz_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "00110110" => d1<='0';p1<='0';--40
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<=dz_in;p5<=pz_in;
									 d6<=da_in;p6<=pa_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
			
			when "01010110" => d1<='0';p1<='0';--41
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10010110" => d1<='0';p1<='0';--42
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "01100110" => d1<='0';p1<='0';--43
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10100110" => d1<='0';p1<='0';--44
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "11000110" => d1<='0';p1<='0';--45
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "00111010" => d1<='0';p1<='0';--46
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<=da_in;p6<=pa_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
			
			when "01011010" => d1<='0';p1<='0';--47
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10011010" => d1<='0';p1<='0';--48
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "01101010" => d1<='0';p1<='0';--49
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10101010" => d1<='0';p1<='0';--50
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "11001010" => d1<='0';p1<='0';--51
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "01110010" => d1<='0';p1<='0';--52
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10110010" => d1<='0';p1<='0';--53
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "11010010" => d1<='0';p1<='0';--54
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "11100010" => d1<='0';p1<='0';--55
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "00111100" => d1<='0';p1<='0';--56
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<=da_in;p6<=pa_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
			
			when "01011100" => d1<='0';p1<='0';--57
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10011100" => d1<='0';p1<='0';--58
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "01101100" => d1<='0';p1<='0';--59
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10101100" => d1<='0';p1<='0';--60
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "11001100" => d1<='0';p1<='0';--61
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "01110100" => d1<='0';p1<='0';--62
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10110100" => d1<='0';p1<='0';--63
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "11010100" => d1<='0';p1<='0';--64
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "11100100" => d1<='0';p1<='0';--65
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "01111000" => d1<='0';p1<='0';--66
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<=da_in;p7<=pa_in;
									 d8<='0';p8<='0';
			
			when "10111000" => d1<='0';p1<='0';--67
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<=da_in;p8<=pa_in;
			
			when "11011000" => d1<='0';p1<='0';--68
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "11101000" => d1<='0';p1<='0';--69
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
			
			when "11110000" => d1<='0';p1<='0';--70
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dx_in;p5<=px_in;
									 d6<=dy_in;p6<=py_in;
									 d7<=dz_in;p7<=pz_in;
									 d8<=da_in;p8<=pa_in;
									 
---------------------------C83-------------------------------	
		
			when "00000111" => d1<=dx_in;p1<=px_in;--1
			                   d2<=dy_in;p2<=py_in;
									 d3<=dz_in;p3<=pz_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
			
			when "00001011" => d1<=dx_in;p1<=px_in;--2
			                   d2<=dy_in;p2<=py_in;
									 d3<='0';p3<='0';
									 d4<=dz_in;p4<=pz_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
									 
			when "00010011" => d1<=dx_in;p1<=px_in;--3
			                   d2<=dy_in;p2<=py_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
			
			when "00100011" => d1<=dx_in;p1<=px_in;--4
			                   d2<=dy_in;p2<=py_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
									 
			when "01000011" => d1<=dx_in;p1<=px_in;--5
			                   d2<=dy_in;p2<=py_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';	
			
			when "10000011" => d1<=dx_in;p1<=px_in;--6
			                   d2<=dy_in;p2<=py_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;
									
			when "00001101" => d1<=dx_in;p1<=px_in;--7
			                   d2<='0';p2<='0';
									 d3<=dy_in;p3<=py_in;
									 d4<=dz_in;p4<=pz_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';						

			when "00010101" => d1<=dx_in;p1<=px_in;--8
			                   d2<='0';p2<='0';
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
			
			when "00100101" => d1<=dx_in;p1<=px_in;--9
			                   d2<='0';p2<='0';
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
									 
			when "01000101" => d1<=dx_in;p1<=px_in;--10
			                   d2<='0';p2<='0';
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';
			
			when "10000101" => d1<=dx_in;p1<=px_in;--11
			                   d2<='0';p2<='0';
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;
									 
			when "00011001" => d1<=dx_in;p1<=px_in;--12
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
				
			when "00101001" => d1<=dx_in;p1<=px_in;--13
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
									 
			when "01001001" => d1<=dx_in;p1<=px_in;--14
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';	
			
			when "10001001" => d1<=dx_in;p1<=px_in;--15
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;
									
			when "00110001" => d1<=dx_in;p1<=px_in;--16
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
					
			when "01010001" => d1<=dx_in;p1<=px_in;--17
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';	
								
			when "10010001" => d1<=dx_in;p1<=px_in;--18
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;
				
			when "01100001" => d1<=dx_in;p1<=px_in;--19
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';	
									 
			when "10100001" => d1<=dx_in;p1<=px_in;--20
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;
		
		   when "11000001" => d1<=dx_in;p1<=px_in;--21
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dy_in;p7<=py_in;
									 d8<=dz_in;p8<=pz_in;
			
			when "00001110" => d1<='0';p1<='0';--22
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<=dz_in;p4<=pz_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
									 
			when "00010110" => d1<='0';p1<='0';--23
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';						 
			
			when "00100110" => d1<='0';p1<='0';--24
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
									 
			when "01000110" => d1<='0';p1<='0';--25
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';						 
			
			when "10000110" => d1<='0';p1<='0';--26
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;
									
			when "00011010" => d1<='0';p1<='0';--27
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';					
			
			when "00101010" => d1<='0';p1<='0';--28
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
									 
			when "01001010" => d1<='0';p1<='0';--29
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';	
				
			when "10001010" => d1<='0';p1<='0';--30
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;
									
			when "00110010" => d1<='0';p1<='0';--31
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
					
			when "01010010" => d1<='0';p1<='0';--32
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';	
									
			when "10010010" => d1<='0';p1<='0';--33
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;	
					
			when "01100010" => d1<='0';p1<='0';--34
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';	
									
			when "10100010" => d1<='0';p1<='0';--35
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;							

			when "11000010" => d1<='0';p1<='0';--36
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dy_in;p7<=py_in;
									 d8<=dz_in;p8<=pz_in;
									 
			when "00011100" => d1<='0';p1<='0';--37
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<=dz_in;p5<=pz_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
				
			when "00101100" => d1<='0';p1<='0';--38
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
									 
			when "01001100" => d1<='0';p1<='0';--39
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';		
									 
			when "10001100" => d1<='0';p1<='0';--40
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;		

			when "00110100" => d1<='0';p1<='0';--41
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';		
									 
			when "01010100" => d1<='0';p1<='0';--42
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';							 
			
			when "10010100" => d1<='0';p1<='0';--43
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;
									
			when "01100100" => d1<='0';p1<='0';--44
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';	
				
			when "10100100" => d1<='0';p1<='0';--45
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;	
									 
			when "11000100" => d1<='0';p1<='0';--46
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dy_in;p7<=py_in;
									 d8<=dz_in;p8<=pz_in;
			
			when "00111000" => d1<='0';p1<='0';--47
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<=dy_in;p5<=py_in;
									 d6<=dz_in;p6<=pz_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
									 
			when "01011000" => d1<='0';p1<='0';--48
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';	
				
			when "10011000" => d1<='0';p1<='0';--49
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;	
									 
			when "01101000" => d1<='0';p1<='0';--50
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';
									 
			when "10101000" => d1<='0';p1<='0';--51
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;	
									 
			when "11001000" => d1<='0';p1<='0';--52
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dy_in;p7<=py_in;
									 d8<=dz_in;p8<=pz_in;
									 
			when "01110000" => d1<='0';p1<='0';--53
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dx_in;p5<=px_in;
									 d6<=dy_in;p6<=py_in;
									 d7<=dz_in;p7<=pz_in;
									 d8<='0';p8<='0';		
									 
			when "10110000" => d1<='0';p1<='0';--54
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dx_in;p5<=px_in;
									 d6<=dy_in;p6<=py_in;
									 d7<='0';p7<='0';
									 d8<=dz_in;p8<=pz_in;
			
			when "11010000" => d1<='0';p1<='0';--55
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dx_in;p5<=px_in;
									 d6<='0';p6<='0';
									 d7<=dy_in;p7<=py_in;
									 d8<=dz_in;p8<=pz_in;
									 
			when "11100000" => d1<='0';p1<='0';--56
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dx_in;p6<=px_in;
									 d7<=dy_in;p7<=py_in;
									 d8<=dz_in;p8<=pz_in;						 
												 
---------------------------C82-------------------------------

         when "00000011" => d1<=dx_in;p1<=px_in;--1
			                   d2<=dy_in;p2<=py_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
									 
			when "00000101" => d1<=dx_in;p1<=px_in;--2
			                   d2<='0';p2<='0';
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';		
					
			when "00001001" => d1<=dx_in;p1<=px_in;--3
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';		
									
			when "00010001" => d1<=dx_in;p1<=px_in;--4
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';		
					
			when "00100001" => d1<=dx_in;p1<=px_in;--5
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';		
									
			when "01000001" => d1<=dx_in;p1<=px_in;--6
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dy_in;p7<=py_in;
									 d8<='0';p8<='0';		
						
			when "10000001" => d1<=dx_in;p1<=px_in;--7
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dy_in;p8<=py_in;	
								
			when "00000110" => d1<='0';p1<='0';--8
			                   d2<=dx_in;p2<=px_in;
									 d3<=dy_in;p3<=py_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
						
			when "00001010" => d1<='0';p1<='0';--9
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
							
			when "00010010" => d1<='0';p1<='0';--10
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
							
			when "00100010" => d1<='0';p1<='0';--11
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
						
			when "01000010" => d1<='0';p1<='0';--12
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dy_in;p7<=py_in;
									 d8<='0';p8<='0';		
									
			when "10000010" => d1<='0';p1<='0';--13
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dy_in;p8<=py_in;
			
			when "00001100" => d1<='0';p1<='0';--14
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<=dy_in;p4<=py_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
									 
			when "00010100" => d1<='0';p1<='0';--15
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
				
			when "00100100" => d1<='0';p1<='0';--16
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
									
			when "01000100" => d1<='0';p1<='0';--17
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dy_in;p7<=py_in;
									 d8<='0';p8<='0';	
					
			when "10000100" => d1<='0';p1<='0';--18
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dy_in;p8<=py_in;
								
			when "00011000" => d1<='0';p1<='0';--19
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<=dy_in;p5<=py_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
						
			when "00101000" => d1<='0';p1<='0';--20
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<='0';p5<='0';
									 d6<=dy_in;p6<=py_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
							
			when "01001000" => d1<='0';p1<='0';--21
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dy_in;p7<=py_in;
									 d8<='0';p8<='0';	
							
			when "10001000" => d1<='0';p1<='0';--22
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dy_in;p8<=py_in;	
							
			when "00110000" => d1<='0';p1<='0';--23
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dx_in;p5<=px_in;
									 d6<=dy_in;p6<=py_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
							
			when "01010000" => d1<='0';p1<='0';--24
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dx_in;p5<=px_in;
									 d6<='0';p6<='0';
									 d7<=dy_in;p7<=py_in;
									 d8<='0';p8<='0';	
							
			when "10010000" => d1<='0';p1<='0';--25
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dx_in;p5<=px_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dy_in;p8<=py_in;	
						
			when "01100000" => d1<='0';p1<='0';--26
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dx_in;p6<=px_in;
									 d7<=dy_in;p7<=py_in;
									 d8<='0';p8<='0';	
								
			when "10100000" => d1<='0';p1<='0';--27
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dx_in;p6<=px_in;
									 d7<='0';p7<='0';
									 d8<=dy_in;p8<=py_in;
					
			when "11000000" => d1<='0';p1<='0';--28
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dx_in;p7<=px_in;
									 d8<=dy_in;p8<=py_in;		

---------------------------C81-------------------------------

         when "00000001" => d1<=dx_in;p1<=px_in;--1
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';
									 
			when "00000010" => d1<='0';p1<='0';--2
			                   d2<=dx_in;p2<=px_in;
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
									 
			when "00000100" => d1<='0';p1<='0';--3
			                   d2<='0';p2<='0';
									 d3<=dx_in;p3<=px_in;
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
									 
			when "00001000" => d1<='0';p1<='0';--4
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<=dx_in;p4<=px_in;
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
									 
			when "00010000" => d1<='0';p1<='0';--5
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<=dx_in;p5<=px_in;
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';						 
				
			when "00100000" => d1<='0';p1<='0';--6
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<=dx_in;p6<=px_in;
									 d7<='0';p7<='0';
									 d8<='0';p8<='0';	
									 
			when "01000000" => d1<='0';p1<='0';--7
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<=dx_in;p7<=px_in;
									 d8<='0';p8<='0';		
					
			when "10000000" => d1<='0';p1<='0';--8
			                   d2<='0';p2<='0';
									 d3<='0';p3<='0';
									 d4<='0';p4<='0';
									 d5<='0';p5<='0';
									 d6<='0';p6<='0';
									 d7<='0';p7<='0';
									 d8<=dx_in;p8<=px_in;
								 
---------------------------XXX-------------------------------
									 
			when others =>     d1<=dx_in; p1<=px_in;--others
			                   d2<=dy_in; p2<=py_in;
									 d3<=dz_in; p3<=pz_in;
									 d4<=da_in; p4<=pa_in;
									 d5<='0';   p5<='0';
									 d6<='0';   p6<='0';
									 d7<='0';   p7<='0';
									 d8<='0';   p8<='0';
			end case;			 
			  
			  end if; --v5.8.3.2--------------------------------------------
			


end if; 
end process;	

end beha;