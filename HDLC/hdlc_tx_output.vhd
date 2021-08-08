-- this entity set the transfer rate
 
library ieee;
	use ieee.std_logic_1164.all;

entity hdlc_tx_output is
	generic
	( 
		WORK_EDGE	: string 	:= ""
	);
	
	port
	(
		i_rst		: in	std_logic;
		i_clk		: in	std_logic;
		i_data		: in	std_logic;
		i_en		: in	std_logic;
		i_duration	: in 	natural range 0 to 4;
		o_rdy		: out	std_logic;
		o_line		: out	std_logic
	);
end entity hdlc_tx_output;

architecture rtl of hdlc_tx_output is

	signal s_rst	:	std_logic;
	signal s_clk	:	std_logic;
	
	type   STATE_T is (ST_IDLE, ST_START, ST_OUTPUT);
	signal state_curr, state_next : STATE_T := ST_IDLE;
	signal s_data_out	: std_logic;

	impure function get_duration return positive is
	begin
		return 2 ** (1+i_duration);
	end function get_duration;
	
begin
	
	gen:
	if(WORK_EDGE = "falling") generate
		s_clk <= not i_clk;
	else generate
		s_clk <= i_clk;
	end generate;
	
	s_rst	<= i_rst;
	
	n_state:
	process (state_next)
	begin
		state_curr	<= state_next;
	end process n_state;
	
	s_state:
	process (s_clk, s_rst) 
		variable v_duration : natural := 0;

		impure function get_input return STATE_T is
		begin
		 if	i_en = '1' then
			s_data_out <= i_data;
			return ST_START;
		end if;
		 return ST_IDLE;
		end function get_input; 

	begin
		if(s_rst = '1') then
			state_next <= ST_IDLE;
			s_data_out <= '0';
			
		elsif rising_edge(s_clk) then
			case state_curr is
					
				when ST_IDLE 	=>
				   state_next <= get_input;
			
				when ST_START	=>
					v_duration  := get_duration;
					state_next	<= ST_OUTPUT;
					
				when ST_OUTPUT	=>
					v_duration := v_duration - 1;
					if v_duration = 1  then
				   		state_next <= get_input;
					end if;
			end case; 
		end if;
	end process s_state;
	
	with state_curr select o_rdy  <= '0' when ST_START,	not s_rst when others;
	with state_curr select o_line <= '0' when ST_IDLE ,	s_data_out when others;   


end architecture rtl;
