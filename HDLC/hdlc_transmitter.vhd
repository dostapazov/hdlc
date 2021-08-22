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
		i_duration	: in	natural range 0 to 6;
		i_data		: in	std_logic_vector(DATA_WIDTH - 1 downto 0);
		i_count		: in	positive  range 1 to DATA_WIDTH := DATA_WIDTH;
		i_write 	: in	std_logic;
		
		o_rdy		: out	std_logic;
		o_line		: out	std_logic;
		o_active	: out	std_logic
	);
	
	
end entity hdlc_transmitter;

architecture rtl of hdlc_transmitter is

	constant C_FLAG_BIT_COUNT	: positive   := FLAG_WIDTH+1;
	type HDLC_TX_STATE_T IS (ST_RST ,ST_IDLE, ST_BEG_FLAG , ST_GET_DATA ,ST_DATA, ST_BIT_STAFFING,ST_END_FLAG );
	signal state_current, state_next : HDLC_TX_STATE_T := ST_IDLE;
	
	signal s_active		: std_logic;
	signal s_write		: std_logic;
	signal s_flag		: std_logic_vector(i_data'range) := ( others => '1');
	signal s_data		: std_logic_vector(i_data'range);
	signal s_tx_data	: std_logic_vector(i_data'range);
	signal s_tx_count	: positive  range 1 to DATA_WIDTH := DATA_WIDTH;
	signal s_tx_en		: std_logic;
	signal s_tx_rdy		: std_logic;
	signal s_duration	: natural range 0 to 6;
	signal s_no_bstaff	: std_logic;

	signal s_rst : std_logic := '1';
	signal s_clk : std_logic;
	signal s_rdy : std_logic;
	

	signal s_out_rdy, s_out_en, s_out_bit	: std_logic; --  output signals
	

begin
	s_clk		<= i_clk;
	o_rdy		<= s_rdy;
	o_active	<= s_active;
	s_duration	<= i_duration;
	s_write		<= i_write;


	
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
		i_duration	=> s_duration,
		i_data		=> s_out_bit,
		i_en		=> s_out_en,
		o_rdy		=> s_out_rdy,
		o_line		=> o_line
	);

	tx_data: entity work.hdlc_tx_data
	  generic map (
		DATA_WIDTH => DATA_WIDTH,
		FLAG_WIDTH => FLAG_WIDTH
	  )
	  port map (
		i_rst       => s_rst,
		i_clk       => s_clk,
		i_data      => s_tx_data,
		i_count     => s_tx_count,
		i_no_bstaff => s_no_bstaff,
		i_en        => s_tx_en,
		i_rdy_out   => s_out_rdy,
		o_out_en    => s_out_en,
		o_rdy       => s_tx_rdy,
		o_tx_data   => s_out_bit,
		o_bstaf     => open,
		o_bstaf_cnt => open
	  );
	
	n_state: 
	process(state_next) begin
		state_current <= state_next;
	end process n_state;
	
	s_state: 
	process(s_clk, s_rst) 
	
	begin
		if(s_rst = '1') then
			state_next <= ST_RST;
			
		elsif(rising_edge(s_clk)) then
			
			case state_current is
				when ST_RST	=>
					if(s_out_rdy = '1') then
						state_next <= ST_IDLE;
					end if;
				
				when ST_IDLE		=>
					if(s_write = '1') then
						state_next	<= ST_BEG_FLAG;
					end if;
				when ST_BEG_FLAG	=>
					if(s_tx_rdy = '0') then
						state_next <= ST_GET_DATA;
					end if;

				when ST_GET_DATA	=>
					if(s_tx_rdy = '1') then
						if(s_write = '1') then
							s_data <= i_data;
							state_next	<= ST_DATA;
						else
							state_next	<= ST_END_FLAG;
						end if;
						
					end if;
				when ST_DATA		=>
					if(s_tx_rdy = '0') then
						state_next <= ST_GET_DATA;
					end if;
				when ST_END_FLAG	=>	
					if(s_tx_rdy = '0') then
						state_next <= ST_IDLE;
					end if;
				when others =>
					state_next <= ST_RST;
			end case;
			
		end if;
	end process s_state;
	
	
	with state_current select s_rdy			<= '0' when ST_RST | ST_GET_DATA,	'1' when others;

	with state_current select s_tx_en		<= '0' when ST_RST	| ST_IDLE,	'1' when others;

	with state_current select s_no_bstaff	<= '0' when ST_GET_DATA, '1' when others;
	with state_current select s_active		<= '0' when ST_RST	| ST_IDLE , '1' when others;
	with state_current select s_tx_data		<= s_data when ST_GET_DATA | ST_DATA, s_flag when others;
	with state_current select s_flag(s_flag'high-FLAG_WIDTH) <= '0' when  ST_BEG_FLAG , '1' when others;

	with state_current select s_tx_count	<= i_count	when ST_GET_DATA | ST_DATA, C_FLAG_BIT_COUNT when others;
		
	

end architecture rtl;
