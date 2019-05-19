library ieee;
  use ieee.std_logic_1164.all;

package vunit_common_pkg is
  procedure clk_gen(signal clk : out std_logic; constant PERIOD : time);
end package vunit_common_pkg;

package body vunit_common_pkg is
  -- procedure for clock generation
  procedure clk_gen(signal clk : out std_logic; constant PERIOD : time) is
    constant HIGH_TIME : time := PERIOD / 2;
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;
  begin
    assert (HIGH_TIME /= 0 fs) report "clk: frequency is too high" severity FAILURE;
    loop
      clk <= '1';
      wait for HIGH_TIME;
      clk <= '0';
      wait for LOW_TIME;
    end loop;
  end procedure;
end package body;