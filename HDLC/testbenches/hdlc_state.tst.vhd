library ieee, vunit_lib, work;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use work.hdlc_state;
	use work.tbench_helper.all;
	
	context vunit_lib.vunit_context;


entity tb_hdlc_state is
	generic
	(
		flag_width  : positive := 6;
        runner_cfg	: string
	);

end entity tb_hdlc_state;

architecture tb of tb_hdlc_state is
    signal i_rst,   i_wr,   i_data : std_logic;
    signal o_start, o_finish,   o_bstaf, o_bstaf_expect : std_logic;
	constant SIGNAL_DURATION : time := 1 ms;
begin
    dut : entity work.hdlc_state
    generic map    (FLAG_WIDTH => flag_width)
    port map
    (
        i_rst           => i_rst,
        i_wr	        => i_wr,
        i_data	        => i_data,
        o_bstaf	        => o_bstaf,
        o_bstaf_expect  => o_bstaf_expect,
        o_start	        => o_start,
        o_finish        => o_finish
    );

	test_main : process 
		procedure reset is
		begin
			i_data	<= 'Z';
			i_wr	<= '0';
			i_rst	<= '1';
			wait for 2*SIGNAL_DURATION;
			i_rst	<= '0';
		end procedure reset;
		procedure write_data(constant s: std_logic ; constant cnt : positive := 1) is
		variable counter : natural :=0;
		begin
			i_data <= s;
			while counter < cnt loop
				i_wr <= '1';
				wait for SIGNAL_DURATION;	
				i_wr <= '0';
				wait for SIGNAL_DURATION;	
				counter := counter +1;
			end loop;

		end procedure write_data;
		
		procedure write_data(constant vect : std_logic_vector ) is
		 variable index : natural := 0;
		begin
			while index < vect'length loop
				write_data(vect(index),1);
				index := index + 1;
			end loop; 
		
		end procedure write_data;
	begin
		test_runner_setup(runner, runner_cfg);
		
		
		while(test_suite) loop
			if run("reset") then
				reset;
				check(o_start = '0', "Expected o_start inactive");
				check(o_finish = '0', "Expected o_finish inactive");
				check(o_bstaf  = '0', "Expected o_bstaf inactive");
                check(o_bstaf_expect  = '0', "Expected o_bstaf_expect inactive");
			elsif run("pre_bitstaffing") then
				reset;
			 	write_data("0011111");
				check(o_start = '0', "Expected o_start inactive");
				check(o_finish = '0', "Expected o_finish inactive");
				check(o_bstaf  = '0', "Expected o_bstaf inactive");
                check(o_bstaf_expect  = '1', "Expected o_bstaf_expect active");
			elsif run("bitstaffing") then
				reset;
			 	write_data("0111110");
				check(o_start = '0', "Expected o_start inactive");
				check(o_finish = '0', "Expected o_finish inactive");
				check(o_bstaf  = '1', "Expected o_bstaf active");
                check(o_bstaf_expect  = '0', "Expected o_bstaf_expect inactive");
			elsif run("start") then
				reset;
			 	write_data("01111110");
				check(o_start = '1', "Expected o_start active");
				check(o_finish = '0', "Expected o_finish inactive");
				check(o_bstaf  = '0', "Expected o_bstaf inactive");
			elsif run("finish") then
				reset;
			 	write_data("01111111");
				check(o_start = '0', "Expected o_start inactive");
				check(o_finish = '1', "Expected o_finish active");
				check(o_bstaf  = '0', "Expected o_bstaf inactive");
                check(o_bstaf_expect  = '0', "Expected o_bstaf_expect inactive");
			elsif run("data_no_bitstaffing") then
				reset;
                for i in 0 to 10 loop
                    write_data("01111");
                    check(o_start = '0', "Expected o_start inactive");
                    check(o_finish = '0', "Expected o_finish inactive");
                    check(o_bstaf  = '0', "Expected o_bstaf inactive");
                    check(o_bstaf_expect  = '0', "Expected o_bstaf_expect inactive");
                end loop;
			elsif run("no_tested_data") then
				reset;
                for i in 0 to 10 loop
                    write_data("01111101111100011111110");
                end loop;

			end if;

		end loop;
		test_runner_cleanup(runner);

	end process test_main;

end architecture;
