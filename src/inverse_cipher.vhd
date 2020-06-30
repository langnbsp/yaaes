-- inverse cipher module, as described in: "FIPS 197, 5.3 Cipher"

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library aes_lib;
  use aes_lib.aes_pkg.all;

entity INVERSE_CIPHER is
  generic (
    G_KEY_WORDS : integer := 4
  );
  port (
    isl_clk   					: in    std_logic;
    isl_valid 					: in    std_logic;
    ia_data   					: in    st_state;
    ia_key    					: in    t_key(0 to G_KEY_WORDS - 1);
	 ia_key_expansion_array : in 	  t_key_expansion_array;
    oa_data   					: out   st_state;
    osl_valid 					: out   std_logic
  );
end entity INVERSE_CIPHER;

architecture RTL of INVERSE_CIPHER is

  -- states
  signal slv_stage     : std_logic_vector(1 to 2) := (others => '0');
  signal sl_valid_out  : std_logic := '0';
  signal sl_last_round : std_logic := '0';
  signal sl_next_round : std_logic := '0';

  -- data container
  -- data format in key expansion: words are rows
  -- data format in cipher: words are columns
  -- conversion: transpose matrix
  signal a_data_in     : st_state;
  signal a_data_added  : st_state;
  signal a_data_sbox   : st_state;

  -- keys
  signal int_round_cnt : integer range 0 to 13 := 0;

begin

  sl_next_round <= slv_stage(2) and not sl_last_round;

  PROC_INV_CIPHER_FUNC : process (isl_clk) is

    variable v_new_col, v_col, v_row    : integer range 0 to C_STATE_COLS - 1;
    variable V_data_srows    : st_state;
    variable v_data_mcols, tmp_state : st_state;

  begin

    if (isl_clk'event and isl_clk = '1') then
      slv_stage <= (isl_valid or sl_next_round) & slv_stage(1);

      -- initial add key
      if (isl_valid = '1') then
        int_round_cnt <= 6 + G_KEY_WORDS - 1;
		  tmp_state := xor_array(transpose(ia_key_expansion_array(6 + G_KEY_WORDS)), ia_data);
		  a_data_added <= xor_array(transpose(ia_key_expansion_array(6 + G_KEY_WORDS)), ia_data);
      end if;

      -- substitute bytes and shift rows
      if (slv_stage(1) = '1') then
		  for row in C_STATE_ROWS - 1 downto 0 loop
			 for col in C_STATE_COLS - 1 downto 0 loop
				-- shift rows
            -- avoid modulo by using unsigned overflow
            v_new_col := to_integer(to_unsigned(col, 2) + row);
				v_data_srows(row, v_new_col) := a_data_added(row, col);
				
            -- substitute bytes
				a_data_sbox(row, v_new_col) <= C_INV_SBOX(to_integer(v_data_srows(row, v_new_col)));
          end loop;
        end loop;

        -- if the second last round is finished, mix columns step could be skipped,
        -- but like this, the pipeline doesn't branch
        if (int_round_cnt > 0) then
          int_round_cnt <= int_round_cnt - 1;
        else
          sl_last_round <= '1';
        end if;
      end if;

      -- mix columns and add key
      if (slv_stage(2) = '1') then
        for col in 0 to C_STATE_COLS - 1 loop
          v_data_mcols(0, col) := double(v_data_srows(0, col)) xor
                                  triple(v_data_srows(1, col)) xor
                                  v_data_srows(2, col) xor
                                  v_data_srows(3, col);
          v_data_mcols(1, col) := v_data_srows(0, col) xor
                                  double(v_data_srows(1, col)) xor
                                  triple(v_data_srows(2, col)) xor
                                  v_data_srows(3, col);
          v_data_mcols(2, col) := v_data_srows(0, col) xor
                                  v_data_srows(1, col) xor
                                  double(v_data_srows(2, col)) xor
                                  triple(v_data_srows(3, col));
          v_data_mcols(3, col) := triple(v_data_srows(0, col)) xor
                                  v_data_srows(1, col) xor
                                  v_data_srows(2, col) xor
                                  double(v_data_srows(3, col));
        end loop;

        -- add key
        if (sl_last_round = '0') then
			 a_data_added <= xor_array(transpose(ia_key_expansion_array(int_round_cnt)), v_data_mcols);
        else
          -- final add key
			 a_data_added  <= xor_array(transpose(ia_key_expansion_array(int_round_cnt)), v_data_srows);
          sl_last_round <= '0';
			 int_round_cnt <= 6 + G_KEY_WORDS - 1;
        end if;
      end if;

      sl_valid_out <= sl_last_round;
    end if;

  end process PROC_INV_CIPHER_FUNC;

  oa_data   <= a_data_added;
  osl_valid <= sl_valid_out;

end architecture RTL;
