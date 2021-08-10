library ieee, work;
	use ieee.std_logic_1164.all;
	use work.hdlc_tx_output;

entity hdlc_transmitter is
	generic
	(
		DATA_WIDTH		: positive := 8;
		FLAG_WIDTH		: positive := 6
	);

	port
	(
		i_rst		: in	std_logic;
		i_clk		: in 	std_logic;
		i_duration	: in	natural range 0 to 4;
		i_data		: in	std_logic_vector(DATA_WIDTH - 1 downto 0);
		i_write 	: in	std_logic;
		
		o_rdy		: out	std_logic;
		o_line		: out	std_logic
	);
	
	constant END_FLAG_WIDTH : positive := FLAG_WIDTH + 1;
	
end entity hdlc_transmitter;

architecture rtl of hdlc_transmitter is

	type HDLC_TX_STATE_T IS (ST_RST ,ST_IDLE, ST_BEG_FLAG, ST_GET_DATA ,ST_DATA, ST_BIT_STAFFING,ST_END_FLAG );
	signal state_current, state_next : HDLC_TX_STATE_T := ST_IDLE;
	signal s_out_rdy, s_out_en	: std_logic;
	signal s_out_data	: std_logic_vector(i_data'range);
	signal s_rst : std_logic := '1';
	signal s_clk : std_logic;
	signal s_rdy : std_logic;
	

begin
	s_clk <= i_clk;
	o_rdy <= s_rdy;
	
	rst:	process(s_clk)	begin
		if rising_edge(s_clk) then
			s_rst	<=	i_rst;
		end if;
	end process rst;
	
	
	tx_out : entity work.hdlc_tx_output
	generic map (WORK_EDGE => "")
	port	map
	(
		i_rst		=> s_rst,
		i_clk		=> s_clk,
		i_duration	=> i_duration,
		i_data		=> s_out_data(s_out_data'high),
		i_en		=> s_out_en,
		o_rdy		=> s_out_rdy,
		o_line		=> o_line
	);
	
	n_state: 
	process(state_next) begin
		state_current <= state_next;
	end process n_state;
	
	s_state: 
	process(s_clk, s_rst) 
	variable v_flag_counter : natural;
	variable v_bit_counter	: natural;
	variable v_bit_staff	: natural;	
	
	begin
		if(s_rst = '1') then
			state_next <= ST_RST;
			
		elsif(rising_edge(s_clk)) then
			
			case state_current is
				when ST_RST	=>
					s_out_data(s_out_data'high)	<= '0';	
					if(s_out_rdy = '1') then
						state_next <= ST_IDLE;
					end if;
				
				when ST_IDLE	=>
					s_out_data(s_out_data'high)	<= '0';						
					if i_write = '1' then
						s_out_data(s_out_data'high)	<= '1';	
						state_next		<= ST_BEG_FLAG;
						v_flag_counter	:= 0;
					end if;
				
				when ST_BEG_FLAG	=>
				
					if(s_out_rdy = '0') then
						v_flag_counter := v_flag_counter + 1;
						if v_flag_counter = FLAG_WIDTH then
							state_next <= ST_GET_DATA; -- get data to write
							s_out_data(s_out_data'high)  <= '0';
							v_bit_staff := 0;
						end if;
					end if;
					
				when ST_GET_DATA	=>
				
					if(s_out_rdy = '0') then
						if i_write = '1' then
							state_next	<= ST_DATA; 
							s_out_data  <= i_data;
							v_bit_counter := i_data'length;
						else
							state_next	<= ST_END_FLAG; 
							s_out_data(s_out_data'high)  <= '1';
							v_flag_counter	:= 0;
							
						end if;
					end if;
					
				when ST_END_FLAG	=>	
					if(s_out_rdy = '0') then
						v_flag_counter := v_flag_counter + 1;
						if v_flag_counter = END_FLAG_WIDTH then
							state_next <= ST_IDLE;
						end if;
					end if;
				when others =>
					state_next <= ST_RST;
			end case;
			
		end if;
	end process s_state;
	
	
	with state_current  select s_rdy	<= '1' when ST_IDLE | ST_DATA,	'0' when others;
	
	with state_current  select s_out_en	<= '0' when ST_RST	| ST_IDLE,	'1' when others;
		
	

end architecture rtl;
