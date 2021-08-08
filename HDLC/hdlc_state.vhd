library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_misc.all;

entity hdlc_state is 
    generic (FLAG_WIDTH : positive := 6);
    port
    (
        i_rst, i_wr, i_data : in std_logic;
        o_bstaf,o_bstaf_expect, o_start, o_finish : out  std_logic
    );
end entity hdlc_state;

architecture rtl of hdlc_state is
 signal s_data  : std_logic_vector(FLAG_WIDTH downto 0) := (others => '0');
 signal s_bstaf, s_bstaf_expect, s_start, s_finish : std_logic;
   
begin
  process (i_rst, i_wr) 
  begin
    if i_rst = '1' then
        s_data <= (others => '0');
    elsif rising_edge(i_wr)  then
        s_data <= s_data(s_data'high -1 downto 0) & i_data;
    end if;
  end process;
  
  s_bstaf_expect<= and_reduce(s_data(FLAG_WIDTH-2 downto 0)) and not s_data(FLAG_WIDTH-1);
  s_bstaf       <= and_reduce(s_data(FLAG_WIDTH-1 downto 1)) and not (s_data(0) or s_data(FLAG_WIDTH));
  s_start       <= and_reduce(s_data(FLAG_WIDTH downto 1)) and not s_data(0);
  o_start       <= s_start;
  s_finish      <= and_reduce(s_data);
  o_finish      <= s_finish;
  o_bstaf       <= s_bstaf ;
  o_bstaf_expect<= s_bstaf_expect;


end architecture;

