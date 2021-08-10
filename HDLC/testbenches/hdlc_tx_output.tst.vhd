library ieee, vunit_lib, work;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use work.hdlc_tx_output;
	use work.tbench_helper.all;
	
	context vunit_lib.vunit_context;


entity tb_hdlc_tx_output is
	generic
	(
		duration	: natural	:= 2;
		work_edge	: string	:= "";
		runner_cfg	: string
	);
	
	constant C_TRANSMIT_CLOCKS : positive := 2 ** (1+duration);
	
end entity tb_hdlc_tx_output;

architecture tb of tb_hdlc_tx_output is
	signal test_active : boolean := true;
	
	signal i_clk,	i_rst	:	std_logic;
	signal i_data,	i_en	:	std_logic;
	signal o_line,	o_rdy	:	std_logic;

begin
	
	dut : entity  work.hdlc_tx_output
	generic map ( WORK_EDGE => work_edge )
	port map
	(
		i_clk	=>	i_clk,
		i_rst	=>	i_rst,
		i_data	=>	i_data,
		i_en	=>	i_en,
		i_duration	=> duration,
		o_rdy	=>	o_rdy,
		o_line	=>	o_line
	);
	
test_main:
	process 
	variable v_res : boolean := false;
	variable v_count : integer;
	
    procedure reset is
	begin
		i_en <= '0';
		i_rst <= '1';
		delay_clock(i_clk,2);
		i_rst <= '0';
		delay_clock(i_clk,1);
	end procedure reset;
	
	procedure transmit( constant tx_value: in std_logic  ) is
	variable wres : boolean := false;
	begin
		wait_logic(wres, i_clk, o_rdy,'1',C_TRANSMIT_CLOCKS );
		check(wres = true,"Expect O_RDY active");
		i_data	<= tx_value;
		i_en	<= '1';
		wait_logic(wres, i_clk, o_rdy,'0',C_TRANSMIT_CLOCKS*2 );
		check(wres = true,"Expect O_RDY inactive to confirm tx start");
		delay_clock(i_clk,1);
		check(o_rdy = '1', "Expect rdy ");
		check(o_line = tx_value, "Expect line value is same as data");
		i_en	<= '0';
		
	end procedure transmit;

	procedure transmit(constant tx_data : in std_logic_vector) is
	variable index : natural := 0;
	begin
		while index < tx_data'length loop
			transmit(tx_data(index));
			index := index + 1;
		end loop;
		
	end procedure transmit;
	
	begin
		test_runner_setup(runner, runner_cfg);
		
		while(test_suite) loop
			if run("reset") then
				reset;
				check(o_rdy		= '1', "Expected RDY active after reset");
				check(o_line	= '0', "Expected line output passive");
				
			elsif run("enable-passive") then
				
				i_data <='1';
				reset;
				wait_logic(v_res,i_clk,o_rdy,'0',16);
				check(v_res = false,"i_en passive READY not changed ");
				
			elsif run("transmit") then
				reset;
				transmit('1');
			
			elsif run("duration") then
				reset;
				i_data <= '1';
				i_en   <= '1';	
				delay_clock(i_clk,1);
				check(o_rdy = '0', "Expect O_RDY deassert to confirm TX start");
				i_en   <= '0';	
				v_count:=0;
				while o_line = '1' and v_count < 10*C_TRANSMIT_CLOCKS loop
					delay_clock(i_clk,1);
					v_count := v_count + 1;
				end loop;
				check(v_count = C_TRANSMIT_CLOCKS, "Expected length =  " & integer'image(C_TRANSMIT_CLOCKS) & " but length is " & integer'image(v_count) );
				
			elsif run("transmit_101") then
				reset;
				transmit('1');
				transmit('0');
				transmit('1');
				wait_logic(v_res,i_clk,o_line,'0',C_TRANSMIT_CLOCKS);
				check(v_res = true, "Expect o_line became low after transmit finish" );

			elsif run ("transmit_11111111") then
				reset;
				transmit("11111111");
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

