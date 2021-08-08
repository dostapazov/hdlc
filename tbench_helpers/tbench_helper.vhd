
library ieee;
	use ieee.std_logic_1164.all;
library work;
	
package tbench_helper is

	procedure generate_clock(signal clk :inout std_logic;signal run : in boolean ; constant half_period : time) ;
	procedure delay_clock(signal clk : in std_logic; constant count : in positive := 1; constant rising : in boolean := true);
	procedure wait_logic_clocks
						(	variable	v_res 				: inout boolean;
							variable    v_counter			: inout natural;
							signal 		clock, wait_signal	: in std_logic;
							constant	expect_value		: in std_logic; 
							constant	clock_count			: in positive := 1;
							constant	clock_edge			: boolean := true 
						) ;
						
	procedure wait_logic(	variable	v_res 				: inout boolean;
							signal 		clock, wait_signal	: in std_logic;
							constant	expect_value		: in std_logic; 
							constant	clock_count			: in positive := 1;
							constant	clock_edge			: boolean := true 
						) ;
						
	procedure wait_logic_vec
						(	variable	v_res 				: inout boolean;
							signal 		clock : in std_logic;
							signal wait_signal	: in std_logic_vector;
							constant	expect_value		: in std_logic_vector; 
							constant	clock_count			: in positive := 1;
							constant	clock_edge			: boolean := true 
						) ;
	
	
end package tbench_helper;

package body tbench_helper is

--!  clock generetor
--!  example :
--! pclk : process
--! begin
--! 	generate_clock(i_clk, SIM_ACTIVE, CLOCK_PERIOD/2);
--! 	wait;
--! end process pclk;

procedure generate_clock(signal clk :inout std_logic;signal run : in boolean ; constant half_period : time) is
begin
	clk<= '0';
	while run loop
		wait for half_period;
		clk <= not clk;
	end loop;
end procedure generate_clock;


--! delay count clocks wait rising or falling edge

procedure delay_clock(signal clk : in std_logic; constant count : in positive := 1; constant rising : in boolean := true) is
variable v_counter : natural := 0;
begin
	while v_counter < count loop
		v_counter := v_counter +1;
		if(rising) then
			wait until rising_edge(clk);
		else
			wait until falling_edge(clk);
		end if;
	end loop;
end procedure delay_clock;


-- wait logic to become expected value
-- uses  a clock signal to switch between processes while waiting

procedure wait_logic_clocks
					(	variable	v_res 				: inout boolean;
						variable	v_counter			: inout natural;
						signal 		clock, wait_signal	: in std_logic;
						constant	expect_value		: in std_logic; 
						constant	clock_count			: in positive := 1;
						constant	clock_edge			: boolean := true 
					) is

begin
	v_res := false;
	v_counter := 0;
	
	while v_res = false and v_counter < clock_count loop
		
		if ( wait_signal = expect_value ) then
			v_res := true;
			--report "Wait success ! counter =" & natural'image(v_counter);
		else
			v_counter := v_counter + 1;
			delay_clock(clock, 1, clock_edge);
		end if;
	end loop;
end procedure wait_logic_clocks;

procedure wait_logic
					(	variable	v_res 				: inout boolean;
						signal 		clock, wait_signal	: in std_logic;
						constant	expect_value		: in std_logic; 
						constant	clock_count			: in positive := 1;
						constant	clock_edge			: boolean := true 
					) is
variable v_counter :natural := 0;
begin
	wait_logic_clocks(v_res, v_counter, clock, wait_signal,expect_value,clock_count,clock_edge);
end procedure wait_logic;


procedure wait_logic_vec(	variable	v_res 				: inout boolean;
						signal 		clock				: in std_logic; 
						signal wait_signal			: in std_logic_vector;
						constant	expect_value		: in std_logic_vector; 
						constant	clock_count			: in positive := 1;
						constant	clock_edge			: boolean := true 
						) is
variable v_counter : natural := 0;
begin
	v_res := false;
	while v_res = false and v_counter < clock_count loop
		
		if ( wait_signal = expect_value ) then
			v_res := true;
			--report "Wait success ! counter =" & natural'image(v_counter);
		else
			v_counter := v_counter + 1;
			delay_clock(clock, 1, clock_edge);
			--report "Wait NOT success ! counter =" & natural'image(v_counter);
		end if;
	end loop;
end procedure wait_logic_vec;


end package body tbench_helper;
