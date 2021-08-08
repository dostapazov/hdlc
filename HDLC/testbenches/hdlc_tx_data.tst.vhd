library ieee, vunit_lib, work;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use work.hdlc_tx_data;
	use work.hdlc_tx_output;
	use work.tbench_helper.all;
	
	context vunit_lib.vunit_context;


entity tb_hdlc_tx_data is
	generic
	(
		duration 	: natural :=0;
		runner_cfg	: string
	);
	constant DATA_WIDTH	: positive := 8;
	constant FLAG_WIDTH	: positive := 6;
	constant FLAGS_LENGTH : positive := FLAG_WIDTH + 2;
	
end entity tb_hdlc_tx_data;

architecture tb of tb_hdlc_tx_data is
	
	signal test_active : boolean := true;
	signal test_result_start, test_result_done  : boolean := false;
	
	signal	i_rst		: std_logic;
	signal	i_clk		: std_logic;
	signal	i_data		: std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal	i_no_bstaff	: std_logic := '1';
	signal	i_en		: std_logic;
	signal	i_rdy_out	: std_logic;

	signal	o_rdy		: std_logic;
	signal	o_tx_data	: std_logic;
	signal	o_out_en	: std_logic;
	signal	o_bstaf		: std_logic;
	signal	o_bstaf_cnt	: natural range 0 to 16#FFFF#;

	signal	tmp_line	: std_logic;
	
	constant c_bit_output_clocks : positive := 2**(1+duration);
	constant c_output_clocks	 : positive := (DATA_WIDTH+4+(DATA_WIDTH/FLAG_WIDTH)) * c_bit_output_clocks;
	

begin
	
	txo : entity work.hdlc_tx_output port map (i_rst => i_rst,i_en => o_out_en, i_clk => i_clk, i_data => o_tx_data,i_duration => duration ,o_rdy => i_rdy_out,o_line => tmp_line );

	dut : entity work.hdlc_tx_data
	generic map ( DATA_WIDTH => DATA_WIDTH, FLAG_WIDTH => FLAG_WIDTH )
	port map
	(
		i_rst		=> i_rst,
		i_clk		=> i_clk,
		i_data		=> i_data,
		i_no_bstaff	=> i_no_bstaff,
		i_en		=> i_en,
		i_rdy_out	=> i_rdy_out,
		o_out_en	=> o_out_en, 
		o_rdy		=> o_rdy,
		o_tx_data	=> o_tx_data,
		o_bstaf		=> o_bstaf,
		o_bstaf_cnt	=> o_bstaf_cnt
	
	);
	
test_main:
	process 
	variable v_res : boolean := false;
	variable v_count : integer;
	
	procedure set_data(constant data : in std_logic_vector) is
	variable v_data :std_logic_vector(i_data'range) := (others => '0');
	begin
		if(data'length > v_data'length) then
			v_data := data(v_data'low to v_data'high);
		else
			v_data(data'high downto data'low) := data;
		end if;
		i_data <= v_data;
	
	end procedure set_data;
	
    procedure reset(constant data : in std_logic_vector:=""  ) is
	begin
		set_data(data);
		i_en <= '0';
		i_rst <= '1';
--		i_rdy_out <= '1';
		i_no_bstaff <= '0';
		
		delay_clock(i_clk,2);
		i_rst <= '0';
		delay_clock(i_clk,1);
	end procedure reset;
	
	procedure check_confirm is 
	variable v_res : boolean;
	variable v_clocks : natural;
	begin
		wait_logic_clocks(v_res, v_clocks, i_clk,o_rdy, '0',c_output_clocks*2);
		check_true(v_res,"O_RDY low timeout");
		info("Low value wait take " & integer'image(v_clocks)& " clocks");
		
		wait_logic_clocks(v_res ,v_clocks, i_clk,o_rdy, '1',c_output_clocks*2);
		check_true(v_res,"O_RDY hi timeout");
		info("Hi value wait take " & integer'image(v_clocks)& " clocks");
	end procedure check_confirm;

	procedure check_result(constant hi_count,lo_count, bstaf_count : in integer := -1) is
	variable v_res : boolean;
	variable v_clocks : natural;
	begin
		wait_logic_clocks(v_res,v_clocks, i_clk, o_out_en, '0',c_output_clocks*2);
		check_true(v_res,"Finish timeout");
		info("Wait finish take "&integer'image(v_clocks)& " clocks [ "&integer'image(c_output_clocks) &" ]" );

		-- if(hi_count >= 0) then
		-- 	check(o_cnt_hi = hi_count, "Expected hi bit count = " & integer'image(hi_count) & " actual " & integer'image(o_cnt_hi));
		-- end if;

		-- if(lo_count >= 0) then
		-- 	check(o_cnt_lo = lo_count, "Expected lo bit count = " & integer'image(lo_count) & " actual " & integer'image(o_cnt_lo));
		-- end if;

		 if(bstaf_count >= 0) then
		 	check(o_bstaf_cnt = bstaf_count, "Expected bit staffings count = " & integer'image(bstaf_count) & " actual " & integer'image(o_bstaf_cnt));
		 end if;
		delay_clock(i_clk,1);
		
	end procedure check_result;

	procedure transmit_data(constant data : in std_logic_vector; constant count : in positive := 1) is
	variable v_counter , v_clocks: natural := 0;
	variable v_res	: boolean;
	begin
		i_en <= '1';
		set_data(data);
		while v_counter < count loop
			v_counter := v_counter +1;
			check_confirm;
		end loop;
		i_en<= '0';
		check_result;

	end procedure transmit_data;
	
	begin
		test_runner_setup(runner, runner_cfg);
		
		while(test_suite) loop
			if run("test_reset") then
				reset;
				check(o_rdy		= '1', "Expected RDY active after reset");
				check(o_tx_data	= '0', "Expected line output passive");
				check(o_out_en  = '0', "Expected output enable passive");
				
			elsif run("test_ready") then
				reset;
--				i_rdy_out <= '0';
				wait_logic(v_res,i_clk,o_rdy,'1',c_bit_output_clocks);
				check_true(v_res, "Expected RDY not active when outside not ready");
				
			elsif run("test_transmit_single") then
				i_no_bstaff <= '0';
				reset ("10101010");
				i_en <= '1';
				
				check_confirm;
				i_en <= '0';
				check_result(5,3,0);
				
			elsif run("test_transmit_continue") then
				i_no_bstaff <= '0';
				reset ("10101010");
				i_en <= '1';
				check_confirm;
				
				--set_data("11001100");
				check_confirm;
				
				--set_data("00110011");
				check_confirm;
				i_en <= '0';
				check_result(12,12,0);

				
			elsif run("test_transmit_bitstaff_11111111")  then --( TESTCASE_TRANSMIT_BITSTAFF ) then
				
				i_no_bstaff <= '0';
				reset ("11111111");
				i_en <= '1';
				check_confirm;
				i_en <= '0';
				check_result(bstaf_count=>1);

			elsif run("test_transmit_bitstaff_01111101")  then				
				reset ("01111101");
				i_en <= '1';
				check_confirm;
				i_en <= '0';
				check_result(bstaf_count=>1);

			elsif run("test_transmit_bitstaff_11111101")  then				
				reset ("01111101");
				i_en <= '1';
				check_confirm;
				i_en <= '0';
				check_result(bstaf_count=>1);
				
			elsif run("test_transmit_bitstaff_off") then
				reset ("11111111");
				i_no_bstaff <= '1';
				i_en <= '1';
				check_confirm;
				i_en <= '0';
				check_result(bstaf_count=>0);				
			elsif run("test_bitstaffing_longmsg") then
				i_no_bstaff <= '0';
				reset ;
				transmit_data("11111111",32);
				check_result(bstaf_count => 51);

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

