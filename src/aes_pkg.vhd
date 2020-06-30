
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package AES_PKG is

  type t_mode is (ECB, CBC, CFB, OFB, CTR);

  type t_usig_1d is array(natural range <>) of unsigned(7 downto 0);

  type t_usig_2d is array(natural range <>, natural range <>) of unsigned(7 downto 0);
  

  constant C_STATE_ROWS : integer := 4;
  constant C_STATE_COLS : integer := 4;

  subtype st_word is t_usig_1d(0 to C_STATE_COLS - 1);
  subtype st_state is t_usig_2d(0 to C_STATE_ROWS - 1, 0 to C_STATE_COLS - 1);
  subtype st_sbox is t_usig_1d(0 to 255);

  type t_key is array(natural range <>) of st_word;
  type t_key_expansion_array is array(0 to 14) of st_state;

  -- substitution box, as defined in: "FIPS 197, Figure 7. S-box"
  constant C_SBOX : st_sbox := (
    x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76",
    x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0",
    x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15",
    x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75",
    x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84",
    x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf",
    x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8",
    x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2",
    x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73",
    x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db",
    x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79",
    x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08",
    x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a",
    x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e",
    x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df",
	 x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16");
  
  -- inverted substitution box, as defined in: "FIPS 197, Figure 14. Inverted S-box"
  constant C_INV_SBOX : st_sbox := (
	  x"52", x"09", x"6a", x"d5", x"30", x"36", x"a5", x"38", x"bf", x"40", x"a3", x"9e", x"81", x"f3", x"d7", x"fb",
	  x"7c", x"e3", x"39", x"82", x"9b", x"2f", x"ff", x"87", x"34", x"8e", x"43", x"44", x"c4", x"de", x"e9", x"cb",
	  x"54", x"7b", x"94", x"32", x"a6", x"c2", x"23", x"3d", x"ee", x"4c", x"95", x"0b", x"42", x"fa", x"c3", x"4e",
	  x"08", x"2e", x"a1", x"66", x"28", x"d9", x"24", x"b2", x"76", x"5b", x"a2", x"49", x"6d", x"8b", x"d1", x"25",
	  x"72", x"f8", x"f6", x"64", x"86", x"68", x"98", x"16", x"d4", x"a4", x"5c", x"cc", x"5d", x"65", x"b6", x"92",
	  x"6c", x"70", x"48", x"50", x"fd", x"ed", x"b9", x"da", x"5e", x"15", x"46", x"57", x"a7", x"8d", x"9d", x"84",
	  x"90", x"d8", x"ab", x"00", x"8c", x"bc", x"d3", x"0a", x"f7", x"e4", x"58", x"05", x"b8", x"b3", x"45", x"06",
	  x"d0", x"2c", x"1e", x"8f", x"ca", x"3f", x"0f", x"02", x"c1", x"af", x"bd", x"03", x"01", x"13", x"8a", x"6b",
	  x"3a", x"91", x"11", x"41", x"4f", x"67", x"dc", x"ea", x"97", x"f2", x"cf", x"ce", x"f0", x"b4", x"e6", x"73",
	  x"96", x"ac", x"74", x"22", x"e7", x"ad", x"35", x"85", x"e2", x"f9", x"37", x"e8", x"1c", x"75", x"df", x"6e",
	  x"47", x"f1", x"1a", x"71", x"1d", x"29", x"c5", x"89", x"6f", x"b7", x"62", x"0e", x"aa", x"18", x"be", x"1b",
	  x"fc", x"56", x"3e", x"4b", x"c6", x"d2", x"79", x"20", x"9a", x"db", x"c0", x"fe", x"78", x"cd", x"5a", x"f4",
	  x"1f", x"dd", x"a8", x"33", x"88", x"07", x"c7", x"31", x"b1", x"12", x"10", x"59", x"27", x"80", x"ec", x"5f",
	  x"60", x"51", x"7f", x"a9", x"19", x"b5", x"4a", x"0d", x"2d", x"e5", x"7a", x"9f", x"93", x"c9", x"9c", x"ef",
	  x"a0", x"e0", x"3b", x"4d", x"ae", x"2a", x"f5", x"b0", x"c8", x"eb", x"bb", x"3c", x"83", x"53", x"99", x"61",
	  x"17", x"2b", x"04", x"7e", x"ba", x"77", x"d6", x"26", x"e1", x"69", x"14", x"63", x"55", x"21", x"0c", x"7d");

  function double (value : unsigned(7 downto 0)) return unsigned;

  function triple (value : unsigned(7 downto 0)) return unsigned;

  function xor_array (a, b : st_state) return st_state;

  function calculate_bw_iv (mode : t_mode) return integer;

  function type_state_to_key (arr_in : st_state) return t_key;

  function type_key_to_state (arr_in : t_key(0 to 3)) return st_state;

  function transpose (arr_in : st_state) return st_state;

  function transpose (arr_in : t_key(0 to 3)) return st_state;

  function slv_to_state_array (vec : std_logic_vector(127 downto 0)) return st_state;

  function slv_to_key_array (vec : std_logic_vector) return t_key;

  function array_to_slv (arr : st_state) return std_logic_vector;

end package AES_PKG;

package body aes_pkg is

  -- calculate the double of a value, as described in: "FIPS 197, 4.2.1 Multiplication by x"

  function double (value : unsigned(7 downto 0)) return unsigned is
    variable doubled_value : unsigned(7 downto 0);

  begin
    doubled_value := value(6 downto 0) & '0';

    if (value(7) = '1') then
      doubled_value := doubled_value xor x"1b";
    end if;

    return doubled_value;
  end double;

  -- calculate the triple of a value, as described in: "FIPS 197, 4.2.1 Multiplication by x"

  function triple (value : unsigned(7 downto 0)) return unsigned is
  begin
    return value xor double(value);
  end triple;

  -- xor two arrays

  function xor_array (a, b : st_state) return st_state is
    variable c : st_state;
  begin
    assert a'LENGTH(1) = b'LENGTH(1);
    assert a'LENGTH(2) = b'LENGTH(2);
    for row in a'RANGE(1) loop
      for col in a'RANGE(2) loop
        c(row, col) := a(row, col) xor b(row, col);
      end loop;
    end loop;
    return c;
  end xor_array;

  -- calculate the bitwidth of the initialization vector
  -- i. e. whether it is present or not

  function calculate_bw_iv (mode : t_mode) return integer is
    variable bw_iv : integer range 0 to 128;
  begin

    if (mode = ECB) then
      bw_iv := 0;
    else
      bw_iv := 128;
    end if;

    return bw_iv;
  end function;

  -- convert an array of type "state" to type "key"

  function type_state_to_key (arr_in : st_state) return t_key is
    variable arr_out : t_key(0 to 3);
  begin
    for row in arr_in'RANGE(1) loop
      for col in arr_in'RANGE(2) loop
        arr_out(row)(col) := arr_in(row, col);
      end loop;
    end loop;
    return arr_out;
  end function;

  -- convert an array of type "key" to type "state"

  function type_key_to_state (arr_in : t_key(0 to 3)) return st_state is
    variable arr_out : st_state;
  begin
    for row in arr_out'RANGE(1) loop
      for col in arr_out'RANGE(2) loop
        arr_out(row, col) := arr_in(row)(col);
      end loop;
    end loop;
    return arr_out;
  end function;

  -- transpose an array

  function transpose (arr_in : st_state) return st_state is
    variable arr_out : st_state;
  begin
    for row in arr_in'RANGE(1) loop
      for col in arr_in'RANGE(2) loop
        arr_out(row, col) := arr_in(col, row);
      end loop;
    end loop;
    return arr_out;
  end function;

  function transpose (arr_in : t_key(0 to 3)) return st_state is
    variable arr_out : st_state;
  begin
    for row in arr_out'RANGE(1) loop
      for col in arr_out'RANGE(2) loop
        arr_out(row, col) := arr_in(col)(row);
      end loop;
    end loop;
    return arr_out;
  end function;

  -- convert a std_logic_vector to an array

  function slv_to_state_array (vec : std_logic_vector(127 downto 0)) return st_state is
    variable arr : st_state;
    variable vec_high : integer;
    variable vec_low : integer;
  begin
    for row in arr'RANGE(1) loop
      for col in arr'RANGE(2) loop
        vec_high                                            := (col + C_STATE_ROWS * row + 1) * 8 - 1;
        vec_low                                             := (col + C_STATE_ROWS * row) * 8;
        arr(C_STATE_ROWS - 1 - row, C_STATE_COLS - 1 - col) := unsigned(vec(vec_high downto vec_low));
      end loop;
    end loop;
    return arr;
  end function;

  function slv_to_key_array (vec : std_logic_vector) return t_key is
    variable arr : t_key(0 to vec'LENGTH / 32 - 1);
    variable vec_high : integer;
    variable vec_low : integer;
  begin
    for row in arr'RANGE loop
      for col in 0 to 3 loop
        vec_high                                          := (col + C_STATE_ROWS * row + 1) * 8 - 1;
        vec_low                                           := (col + C_STATE_ROWS * row) * 8;
        arr(arr'LENGTH - 1 - row)(C_STATE_COLS - 1 - col) := unsigned(vec(vec_high downto vec_low));
      end loop;
    end loop;
    return arr;
  end function;

  -- convert an array to a std_logic_vector

  function array_to_slv (arr : st_state) return std_logic_vector is
    variable vec : std_logic_vector(127 downto 0);
    variable vec_high : integer;
    variable vec_low : integer;
  begin
    for row in arr'RANGE(1) loop
      for col in arr'RANGE(2) loop
        vec_high                     := (col + C_STATE_ROWS * row + 1) * 8 - 1;
        vec_low                      := (col + C_STATE_ROWS * row) * 8;
        vec(vec_high downto vec_low) := std_logic_vector(arr(C_STATE_ROWS - 1 - row, C_STATE_COLS - 1 - col));
      end loop;
    end loop;
    return vec;
  end function array_to_slv;

end package body;
