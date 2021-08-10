
library ieee, work;
	use ieee.std_logic_1164.all;
	use work.hdlc_state;

entity hdlc_tx_data is
	generic
	(
		DATA_WIDTH	: positive := 8;
		FLAG_WIDTH	: positive := 6
	);
	port
	(
		i_rst		: in	std_logic;
		i_clk		: in	std_logic;
		i_data		: in	std_logic_vector(DATA_WIDTH - 1 downto 0);
		i_count		: in	positive range 1 to DATA_WIDTH := DATA_WIDTH;
		i_no_bstaff	: in	std_logic := '0';
		i_en		: in	std_logic;
		i_rdy_out	: in	std_logic;
		o_out_en	: out	std_logic;
		o_rdy		: out	std_logic;
		o_tx_data	: out	std_logic;
		o_bstaf		: out	std_logic;
		o_bstaf_cnt : out	natural range 0 to 16#FFFF#
	);
end entity hdlc_tx_data;

architecture rtl of hdlc_tx_data is
 type STATE_T is (ST_IDLE, ST_START, ST_SHIFT,ST_BTSF);
 signal state_curr, state_next : STATE_T := ST_IDLE;
 
 signal s_clk, s_rst, s_en,s_rdy_out, s_rdy_in, s_out_en, s_no_bitstaf	: std_logic := '0'; 
 signal s_data	: std_logic_vector(i_data'range);
 signal s_tx_bit: std_logic;
 signal s_state_rst, s_state_wr, s_bstaf_expect : std_logic;
 signal s_bstaf_cnt	: natural range 0 to 16#FFFF# :=0;
 signal s_count	: natural range 0 to DATA_WIDTH;
 
begin

	s_rst			<= i_rst;
	s_clk			<= i_clk;
	s_en			<= i_en;
	s_rdy_out		<= i_rdy_out;
	s_no_bitstaf	<= i_no_bstaff;
	s_count			<= i_count;

	o_rdy			<= s_rdy_in;
	o_out_en		<= s_out_en;
	o_tx_data		<= s_tx_bit;
	o_bstaf_cnt		<= s_bstaf_cnt;

	hdlc_state : entity work.hdlc_state
	generic map (FLAG_WIDTH => FLAG_WIDTH)
	port map
	(
		i_rst			=> s_state_rst  ,
		i_wr			=> s_state_wr,
		i_data			=> s_tx_bit,
		o_bstaf_expect	=> s_bstaf_expect,
		o_bstaf			=> o_bstaf,
		o_start			=> open,
		o_finish		=> open
	);
		
	
	n_state : 
	process(state_next)
	begin
		state_curr <= state_next;
	end process n_state;
	
	s_state :
	process( s_rst, s_clk) 
    variable v_bit_count : natural range 0 to s_data'length := 0;
	impure function get_input return STATE_T is
	begin
		
		if i_en = '1' then
			s_data <= i_data;
			v_bit_count := s_count;
			return ST_START;
		end if;
		return ST_IDLE;
	end function get_input;

	impure function next_bit return STATE_T is
	begin

		if s_rdy_out = '0'  then
			
			if s_bstaf_expect = '1' then
				s_data(s_data'high) <='0';
				s_bstaf_cnt <= s_bstaf_cnt + 1;
				return ST_BTSF;
			else
				s_data <= s_data(s_data'high -1 downto 0) & '0';
				v_bit_count := v_bit_count - 1;
				if(v_bit_count = 0) then
					return get_input;
				end if;
			end if;
		end if;
		return ST_SHIFT;
	end function next_bit;



	begin
		if(s_rst = '1' ) then
			state_next <= ST_IDLE;
			
		elsif (rising_edge(s_clk)) then
		    
			case state_curr is
				when ST_IDLE	=>
					state_next 	<= get_input;
					s_bstaf_cnt <= 0;
					
				when ST_START | ST_SHIFT | ST_BTSF	=>
					state_next <= next_bit;

				-- when ST_START	=>
				-- 	state_next <= next_bit;
					
				-- when ST_SHIFT	=>
				-- 	state_next <= next_bit;
				
				-- when ST_BTSF	=>
 				-- 	state_next <= next_bit;
				
				when others => state_next <= ST_IDLE;
			end case;
		end if;
		
	end process s_state;
	
	s_state_rst <=  not s_out_en or s_no_bitstaf ;
	s_state_wr  <=  s_out_en and not s_rdy_out;
	
	with state_curr select s_out_en		<=  '0' when ST_IDLE, '1' when others;
	with state_curr select s_rdy_in		<=  s_rdy_out when ST_IDLE , '0' when ST_START, '1' when others;
	with state_curr select s_tx_bit		<=  s_data(s_data'high) when ST_START|ST_SHIFT , '0' when others;
	

end architecture rtl;