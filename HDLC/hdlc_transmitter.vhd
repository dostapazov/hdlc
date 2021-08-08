library ieee, work;
	use ieee.std_logic_1164.all;
	use work.hdlc_tx_output, work.hdlc_tx_data;
	

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
	
	constant C_FLAG_WIDTH	: positive := FLAG_WIDTH + 1;
	constant c_start_flag	: std_logic_vector(FLAG_WIDTH downto 0) := (FLAG_WIDTH downto 1 => '1') & '0';
	constant c_end_flag		: std_logic_vector(FLAG_WIDTH downto 0) := (others => '1');
	
end entity hdlc_transmitter;

architecture rtl of hdlc_transmitter is

	type TX_STATE_T IS (ST_RST ,ST_IDLE, ST_START_FLAG,ST_START_FLAG_TX, ST_START_DATA ,ST_TX_DATA, ST_END_FLAG,ST_END_FLAG_TX );
	signal state_current, state_next : TX_STATE_T := ST_IDLE;
	signal s_rst : std_logic := '1';
	signal s_clk : std_logic;
	signal s_rdy : std_logic;
	signal s_out_rdy : std_logic;
	signal s_out_bit, s_out_data ,s_out_start_flag, s_out_end_flag : std_logic;
	signal s_out_en, s_out_en_data, s_out_en_start_flag, s_out_en_end_flag : std_logic;
	signal s_tx_data : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal s_start_flag , s_start_flag_rdy : std_logic;

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
		i_data		=> s_out_bit,
		i_en		=> s_out_en,
		o_rdy		=> s_out_rdy,
		o_line		=> o_line
	);

	start_flag: entity work.hdlc_tx_data
	  generic map (
		DATA_WIDTH => C_FLAG_WIDTH,
		FLAG_WIDTH => FLAG_WIDTH
	  )
	  port map (
		i_rst       => s_rst,
		i_clk       => s_clk,
		i_data      => c_start_flag,
		i_no_bstaff => '1',
		i_en        => s_start_flag,
		i_rdy_out   => s_out_rdy,
		o_out_en    => s_out_en_start_flag,
		o_rdy       => s_start_flag_rdy,
		o_tx_data   => s_out_start_flag,
		o_bstaf     => open,
		o_bstaf_cnt => open
	  );	

    --   end_flag: entity work.hdlc_tx_data
	-- 	generic map (
	-- 	  DATA_WIDTH => C_FLAG_WIDTH,
	-- 	  FLAG_WIDTH => FLAG_WIDTH
	-- 	)
	-- 	port map (
	-- 	  i_rst       => s_rst,
	-- 	  i_clk       => s_clk,
	-- 	  i_data      => c_end_flag,
	-- 	  i_no_bstaff => '1',
	-- 	  i_en        => s_end_flag_en,
	-- 	  i_rdy_out   => s_out_rdy,
	-- 	  o_out_en    => s_end_flag_out_en,
	-- 	  o_rdy       => s_end_flag_rdy,
	-- 	  o_tx_data   => s_end_flag_tx_data,
	-- 	  o_bstaf     => open,
	-- 	  o_bstaf_cnt => open
	-- 	);

		-- hdlc_tx_data_inst: entity work.hdlc_tx_data
		--   generic map (
		-- 	DATA_WIDTH => DATA_WIDTH,
		-- 	FLAG_WIDTH => FLAG_WIDTH
		--   )
		--   port map (
		-- 	i_rst       => s_rst,
		-- 	i_clk       => s_clk,
		-- 	i_data      => s_data,
		-- 	i_no_bstaff => '0',
		-- 	i_en        => s_data_en,
		-- 	i_rdy_out   => s_data_rdy_out,
		-- 	o_out_en    => s_data_out_en,
		-- 	o_rdy       => s_data_rdy,
		-- 	o_tx_data   => s_data_tx_data,
		-- 	o_bstaf     => s_data_bstaf,
		-- 	o_bstaf_cnt => s_data_bstaf_cnt
		--   );

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
					state_next <= ST_IDLE;
				
				when ST_IDLE	=>
					if i_write = '1' then
						s_tx_data <= i_data;	
						state_next		<= ST_START_FLAG;
					end if;
				
				when ST_START_FLAG	=>
					if(s_out_en_start_flag = '0') then
						state_next <= ST_START_FLAG_TX;
					end if;

				when ST_START_FLAG_TX	=>
					if(s_out_en_start_flag = '1') then
						state_next <= ST_START_DATA;
					end if;
					
				when ST_START_DATA	=>

				when ST_TX_DATA	=>

				when ST_END_FLAG	=>	

				when others =>
					state_next <= ST_IDLE;
			end case;
			
		end if;
	end process s_state;

		
	with state_current select s_rdy <= '1' when ST_IDLE|ST_TX_DATA,	'0' when others;
	with state_current select s_start_flag <= '1' when ST_START_FLAG,	'0' when others;

	with state_current select s_out_en <= 
		s_out_en_start_flag		when ST_START_FLAG,
		'0'	when others;
	with state_current select s_out_bit	<= 
		s_out_start_flag 	when ST_START_FLAG,
		'0' when others;


end architecture rtl;
