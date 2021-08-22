library ieee, vunit_lib, work;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use work.hdlc_transmitter;
	use work.tbench_helper.all;
	
	context vunit_lib.vunit_context;


entity tb_hdlc_transmitter is
	generic
	(
		duration	: natural	:= 0;
		data_width	: positive	:= 8;
		flag_width	: positive	:= 6;
		runner_cfg	: string
	);
	
	constant C_BIT_OUTPUT_CLOCKS	: positive	:= (2 ** (1+duration));
	
	
end entity tb_hdlc_transmitter;

architecture tb of tb_hdlc_transmitter is
	signal test_active : boolean := true;
	
	signal i_clk,	i_rst	:	std_logic;
	signal i_write	: std_logic;
	signal i_data	: std_logic_vector(data_width-1 downto 0) := (others => '0');
	signal i_count	: positive range 1 to data_width := data_width;
	signal i_duration : natural range 0 to 6;
	signal o_line,	o_rdy, o_active	:	std_logic;

begin
	i_duration <= duration;
	dut : entity  work.hdlc_transmitter
	generic map (DATA_WIDTH => data_width, FLAG_WIDTH => flag_width)
	port map
	(
		i_clk	=>	i_clk,
		i_rst	=>	i_rst,
		i_data	=>	i_data,
		i_count	=>	i_count,
		i_write	=>	i_write,
		i_duration	=> i_duration,
		o_rdy	=>	o_rdy,
		o_line	=>	o_line,
		o_active => o_active
	);
	
test_main:
	process 
	
	variable v_counter		: natural; 	
	variable wait_result	: boolean;
	
		procedure reset is
		 variable wait_result	: boolean;
		begin
			i_write <= '0';
			i_rst 	<= '1';
			delay_clock(i_clk,1);
			i_rst <= '0';
			wait_logic(wait_result, i_clk, o_rdy, '1', 5);
		end procedure reset;

		procedure wait_ready(
			variable wait_result : inout boolean; 
			constant wait_clocks : in positive  ;
			constant ready_state : in std_logic := '1'
			) 
		is
		begin
			wait_logic(wait_result,i_clk,o_rdy,ready_state,wait_clocks);
		end procedure  wait_ready;

		
		procedure write_data(constant data : std_logic_vector(i_data'range)) is
			variable wait_result	: boolean;
		begin
				i_write <= '1';
				--wait_logic(wait_result,i_clk,o_rdy,'1',C_BIT_OUTPUT_CLOCKS*data_width);
				 wait_ready(wait_result,C_BIT_OUTPUT_CLOCKS*data_width,'1');
				check_true(wait_result,"Timeout to wait ready to transmit");
				if wait_result then
					i_data	<= data;
					 wait_ready(wait_result ,C_BIT_OUTPUT_CLOCKS*data_width,'0');

					--check_true(wait_result,"Timeout to confirm latch input data");
				end if;
				i_write <= '0';
		end procedure write_data;

		procedure write_any_data(constant data : std_logic_vector) is
		begin end procedure;

		
		procedure test_start_transmit is
		begin
				reset;
				write_data(i_data);
				delay_clock(i_clk,1);
				v_counter := 0;
				while(o_line = '1') loop
					v_counter := v_counter + 1;
					delay_clock(i_clk,1);
				end loop;
				check_equal(v_counter/C_BIT_OUTPUT_CLOCKS, flag_width);
		end procedure test_start_transmit;

	variable wres : boolean;	
	
	begin
		test_runner_setup(runner, runner_cfg);
		
		while(test_suite) loop
			if run("afert reset o_ready=1 o_line = 0 and o_active = 0") then
				reset;
				check(o_rdy		= '1', "Expected RDY active after reset");
				check(o_line	= '0', "Expected line output passive");
				check(o_active	= '0', "Expected o_active is low");
			elsif run("start transmit rise up o_active and then to confirm latch data fall down o_rdy") then
				reset;
				write_data("10101010");
				check(o_active = '1',"Expected o_active became '1'");
				check(o_rdy = '0', "Expected confirm data latch by zero level of o_rdy");
				
			elsif run("transmit one data portion may set o_active to zero at finish") then
				reset;
				write_data("10101010");
				check(o_active = '1',"Expected o_active became '1'");
				check(o_rdy = '0', "Expected confirm data latch by zero level of o_rdy");
				wait_logic(wres,i_clk,o_active,'0',C_BIT_OUTPUT_CLOCKS*data_width*3);
				check_true(wres, "Timeout end of transmit");
				
			elsif run("transmit two data portion may set o_active at finish") then
				reset;
				write_data("10101010");
				write_data("00111100");
				wait_logic(wres,i_clk,o_active,'0',C_BIT_OUTPUT_CLOCKS*data_width*3);
				check_true(wres, "Timeout end of transmit");
			
			elsif run("transmit two frames by three bytes") then
				reset;
				write_data("10101010");
				write_data("11111111");
				write_data("00111100");
				wait_logic(wres,i_clk,o_active,'0',C_BIT_OUTPUT_CLOCKS*data_width*3);
				check_true(wres, "Timeout end of transmit frame-1");
				write_data("10101010");
				write_data("11111111");
				write_data("00111100");
				wait_logic(wres,i_clk,o_active,'0',C_BIT_OUTPUT_CLOCKS*data_width*3);
				check_true(wres, "Timeout end of transmit frame-2");
			end if;

		end loop;
		
		test_runner_cleanup(runner);
		test_active <= false;
		WAIT;
	end process test_main;
	
	clk : process 
	begin
		generate_clock(i_clk,test_active,20 ns);
		WAIT;
	end process;
	
	
end architecture tb;

