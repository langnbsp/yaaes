
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity INPUT_CONVERSION is
  generic (
    G_BITWIDTH_IF   : integer range 8 to 128   := 128;
    G_BITWIDTH_KEY  : integer range 128 to 256 := 128;
    G_BITWIDTH_IV   : integer range 0 to 128   := 128
  );
  port (
    isl_clk         : in    std_logic;
    isl_valid       : in    std_logic;
    islv_data       : in    std_logic_vector(G_BITWIDTH_IF - 1 downto 0);
    isl_new_key_iv  : in    std_logic;
    oa_iv           : out   st_state;
    oa_key          : out   t_key(0 to G_BITWIDTH_KEY / 32 - 1);
	 oa_subkeys		  : out 	 t_key_expansion_array;
    oa_data         : out   st_state;
    osl_valid       : out   std_logic
  );
end entity INPUT_CONVERSION;

architecture RTL of INPUT_CONVERSION is

  constant C_KEY_WORDS   	: integer := G_BITWIDTH_KEY / 32;
  constant C_KEY_DATUMS    : integer := G_BITWIDTH_KEY / G_BITWIDTH_IF;
  constant C_KEY_IV_DATUMS : integer := C_KEY_DATUMS + G_BITWIDTH_IV / G_BITWIDTH_IF;
  constant C_TOTAL_DATUMS  : integer := C_KEY_IV_DATUMS + 128 / G_BITWIDTH_IF;
  signal int_input_cnt            : integer range 0 to C_TOTAL_DATUMS := 0;

  signal sl_output_valid          : std_logic := '0';

  signal slv_data,         slv_iv : std_logic_vector(127 downto 0) := (others => '0');
  signal slv_key                  : std_logic_vector(G_BITWIDTH_KEY - 1 downto 0) := (others => '0');
  
  signal a_data_added  				 : st_state;
  signal a_round_keys  				 : st_state;
  signal int_round_cnt 				 : integer range 0 to 13 := 0;
  signal sl_output_key_iv_valid	 : std_logic := '0';
  signal subkeys_array				 : t_key_expansion_array;
  signal key							 : t_key(0 to G_BITWIDTH_KEY / 32 - 1);
  
    -- states
  signal slv_stage     : std_logic_vector(1 to 2) := (others => '0');
  signal sl_valid_out  : std_logic := '0';
  signal sl_last_round : std_logic := '0';
  signal sl_next_round : std_logic := '0';

begin

  PROC_INPUT_CONVERSION : process (isl_clk) is
  begin

    if (isl_clk'event and isl_clk = '1') then
      if (isl_new_key_iv = '1') then
        int_input_cnt <= 0;
      end if;

      if (isl_valid = '1') then
        int_input_cnt <= int_input_cnt + 1;
        if (int_input_cnt < C_KEY_DATUMS) then
          slv_key <= slv_key(slv_key'HIGH - G_BITWIDTH_IF downto slv_key'LOW) & islv_data;
        elsif (int_input_cnt < C_KEY_IV_DATUMS) then
          slv_iv <= slv_iv(slv_iv'HIGH - G_BITWIDTH_IF downto slv_iv'LOW) & islv_data;
        elsif (int_input_cnt < C_TOTAL_DATUMS) then
          slv_data <= slv_data(slv_data'HIGH - G_BITWIDTH_IF downto slv_data'LOW) & islv_data;
        end if;
      end if;

      if (int_input_cnt >= C_TOTAL_DATUMS AND sl_valid_out = '1') then
		  int_input_cnt   <= C_KEY_IV_DATUMS;
        sl_output_valid <= '1';
      else
        sl_output_valid <= '0';
      end if;
		
		if (int_input_cnt < C_KEY_IV_DATUMS) then
        sl_output_key_iv_valid <= '0';
      else
        sl_output_key_iv_valid <= '1';
      end if;
		
    end if;

  end process PROC_INPUT_CONVERSION;
  

  sl_next_round <= slv_stage(2) and not sl_last_round;
  
  PROC_KEY_EXPANSION : process (isl_clk) is

    variable v_new_col    : integer range 0 to C_STATE_COLS - 1;
    variable v_data_sbox  : st_state;
    variable v_data_mcols : st_state;

  begin
    if (rising_edge(isl_clk) AND sl_output_key_iv_valid = '1') then
      slv_stage <= (isl_valid or sl_next_round) & slv_stage(1);

      if (isl_valid = '1') then
        int_round_cnt <= 0;
		end if;

      if (slv_stage(1) = '1') then
        if (int_round_cnt < 6 + C_KEY_WORDS - 1) then
          int_round_cnt <= int_round_cnt + 1;
        else
          sl_last_round <= '1';
        end if;
      end if;
		
		if (slv_stage = "01" AND int_round_cnt >= 6 + C_KEY_WORDS - 1) then
					subkeys_array(int_round_cnt+1) <= a_round_keys;
			elsif (slv_stage /= "00") then
					subkeys_array(int_round_cnt) <= a_round_keys;
		end if;
      sl_valid_out <= sl_last_round;
    end if;

  end process PROC_KEY_EXPANSION;
  
  key <= slv_to_key_array(slv_key);

  oa_data   	<= transpose(slv_to_state_array(slv_data));
  oa_key    	<= key; -- don't transpose key, since it's needed like this by the key expansion
  oa_iv     	<= transpose(slv_to_state_array(slv_iv));
  oa_subkeys 	<= subkeys_array;
  osl_valid 	<= sl_output_valid;
  
 
 i_key_expansion : entity aes_lib.KEY_EXPANSION
 generic map (
	G_KEY_WORDS   => C_KEY_WORDS
 )
 port map (
	isl_clk       => isl_clk,
	isl_next_key  => sl_next_round,
	isl_valid     => isl_valid,
	ia_data       => key, --TODO: optimize
	oa_data       => a_round_keys
 );

end architecture RTL;
