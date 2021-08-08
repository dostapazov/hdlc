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
	constant C_END_FLAG_WIDTH		: positive	:= flag_width + 1;
	
	
end entity tb_hdlc_transmitter;

architecture tb of tb_hdlc_transmitter is
	signal test_active : boolean := true;
	
	signal i_clk,	i_rst	:	std_logic;
	signal i_write	: std_logic;
	signal i_data	: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal o_line,	o_rdy	:	std_logic;

begin
	
	dut : entity  work.hdlc_transmitter
	generic map (DATA_WIDTH => data_width, FLAG_WIDTH => flag_width)
	port map
	(
		i_clk	=>	i_clk,
		i_rst	=>	i_rst,
		i_data	=>	i_data,
		i_write	=>	i_write,
		i_duration	=> duration,
		o_rdy	=>	o_rdy,
		o_line	=>	o_line
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
		
		procedure write_data(constant data : std_logic_vector(i_data'range)) is
			variable wait_result	: boolean;
		begin
				wait_logic(wait_result,i_clk,o_rdy,'1',10);
				if wait_result then
					i_write <= '1';
					i_data	<= data;
					delay_clock(i_clk,1);
				end if;
				i_write <= '0';
		end procedure write_data;
		
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
		
	
	
	begin
		test_runner_setup(runner, runner_cfg);
		
		while(test_suite) loop
			if run("reset") then
				reset;
				check(o_rdy		= '1', "Expected RDY active after reset");
				check(o_line	= '0', "Expected line output passive");
				
			elsif run("start_transmitt") then
				test_start_transmit;
				
			elsif run ("end_flag") then
				test_start_transmit;
				wait_logic(wait_result, i_clk, o_line, '0', 10+flag_width*C_BIT_OUTPUT_CLOCKS);
				report "wr "& boolean'image(wait_result) ;
				wait_logic(wait_result, i_clk, o_line, '1', 10+flag_width*C_BIT_OUTPUT_CLOCKS);
				report "wr "& boolean'image(wait_result) ;
				v_counter := 0;
				while(o_line = '1') loop
					v_counter := v_counter + 1;
					delay_clock(i_clk,1);
				end loop;
				check_equal(v_counter/C_BIT_OUTPUT_CLOCKS, C_END_FLAG_WIDTH  );
				
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

