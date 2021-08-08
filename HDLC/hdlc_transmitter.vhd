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

	type HDLC_TX_STATE_T IS (ST_RST ,ST_IDLE, ST_BEG_FLAG, ST_GET_DATA ,ST_DATA, ST_BIT_STAFFING,ST_END_FLAG );
	signal state_current, state_next : HDLC_TX_STATE_T := ST_IDLE;
	signal s_rst : std_logic := '1';
	signal s_clk : std_logic;

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
		i_en        => s_en_start_flag,
		i_rdy_out   => s_start_flag_rdy_out,
		o_out_en    => s_start_flag_en,
		o_rdy       => s_start_flag_rdy,
		o_tx_data   => s_start_flag_tx_data,
		o_active    => o_start_flag_active,
		o_bstaf     => open,
		o_bstaf_cnt => open
	  );	

      end_flag: entity work.hdlc_tx_data
		generic map (
		  DATA_WIDTH => C_FLAG_WIDTH,
		  FLAG_WIDTH => FLAG_WIDTH
		)
		port map (
		  i_rst       => s_rst,
		  i_clk       => s_clk,
		  i_data      => c_end_flag,
		  i_no_bstaff => '1',
		  i_en        => s_end_flag_en,
		  i_rdy_out   => s_end_flag__rdy_out,
		  o_out_en    => s_end_flag_out_en,
		  o_rdy       => s_end_flag_rdy,
		  o_tx_data   => s_end_flag_tx_data,
		  o_active    => s_end_flag_active,
		  o_bstaf     => open,
		  o_bstaf_cnt => open
		);

		hdlc_tx_data_inst: entity work.hdlc_tx_data
		  generic map (
			DATA_WIDTH => DATA_WIDTH,
			FLAG_WIDTH => FLAG_WIDTH
		  )
		  port map (
			i_rst       => s_rst,
			i_clk       => s_clk,
			i_data      => s_data,
			i_no_bstaff => '0',
			i_en        => s_data_en,
			i_rdy_out   => s_data_rdy_out,
			o_out_en    => s_data_out_en,
			o_rdy       => s_data_rdy,
			o_tx_data   => s_data_tx_data,
			o_active    => s_data_active,
			o_bstaf     => s_data_bstaf,
			o_bstaf_cnt => s_data_bstaf_cnt
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
				
					
				when ST_GET_DATA	=>
				
					
				when ST_END_FLAG	=>	

				when others =>
					state_next <= ST_IDLE;
			end case;
			
		end if;
	end process s_state;
	

end architecture rtl;
