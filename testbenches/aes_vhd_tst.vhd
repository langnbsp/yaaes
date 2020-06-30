-- https://gchq.github.io/CyberChef/?recipe=%5B%7B%22op%22%3A%22AES%20Encrypt%22%2C%22args%22%3A%5B%7B%22option%22%3A%22UTF8%22%2C%22string%22%3A%22hello%22%7D%2C%7B%22option%22%3A%22Hex%22%2C%22string%22%3A%22%22%7D%2C%7B%22option%22%3A%22Hex%22%2C%22string%22%3A%22%22%7D%2C%22CBC%22%2C%22Pkcs7%22%2C%22Ciphertext%22%2C%22Hex%22%5D%7D%2C%7B%22op%22%3A%22AES%20Decrypt%22%2C%22args%22%3A%5B%7B%22option%22%3A%22UTF8%22%2C%22string%22%3A%22hello%22%7D%2C%7B%22option%22%3A%22Hex%22%2C%22string%22%3A%22%22%7D%2C%7B%22option%22%3A%22Hex%22%2C%22string%22%3A%22%22%7D%2C%22CBC%22%2C%22Pkcs7%22%2C%22Hex%22%2C%22UTF8%22%5D%7D%5D&input=VGVzdA
LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                
  use ieee.numeric_std.all;
  
library aes_lib;
  use aes_lib.aes_pkg.all;

ENTITY aes_vhd_tst IS
END aes_vhd_tst;
ARCHITECTURE aes_arch OF aes_vhd_tst IS
-- constants   
constant C_CLK_PERIOD : time := 10 ns;
constant G_ENCRYPTION : integer := 1;
constant G_BITWIDTH_IF : integer := 128;
constant G_BITWIDTH_IV : integer := 128;
constant G_BITWIDTH_KEY : integer := 256;

                                              
-- signals  
signal clk : std_logic := '0';    
signal G_KEY : STD_LOGIC_VECTOR(255 DOWNTO 0);
signal G_IV : STD_LOGIC_VECTOR(127 DOWNTO 0);
signal G_PLAINTEXT1 : STD_LOGIC_VECTOR(127 DOWNTO 0);
signal G_PLAINTEXT2 : STD_LOGIC_VECTOR(127 DOWNTO 0);
signal G_CIPHERTEXT1 : STD_LOGIC_VECTOR(127 DOWNTO 0);
signal G_CIPHERTEXT2 : STD_LOGIC_VECTOR(127 DOWNTO 0);
constant G_MODE : t_mode := ECB;

  signal sl_valid_in : std_logic := '0';
  signal sl_new_key_in : std_logic := '0';

  signal slv_data_in : std_logic_vector(G_BITWIDTH_IF-1 downto 0) := (others => '0');
  signal slv_data_out : std_logic_vector(G_BITWIDTH_IF-1 downto 0);
  signal sl_valid_out : std_logic;

BEGIN
	i1 : entity work.aes
	generic map (
    G_BITWIDTH_IF => G_BITWIDTH_IF,

    G_ENCRYPTION => G_ENCRYPTION,
    G_MODE => G_MODE,
    G_BITWIDTH_KEY => G_BITWIDTH_KEY
  )
	PORT MAP (
-- list connections between master ports and signals
	isl_clk   => clk,
    isl_valid => sl_valid_in,
    islv_plaintext => slv_data_in,
    isl_new_key_iv => sl_new_key_in,
    oslv_ciphertext => slv_data_out,
    osl_valid => sl_valid_out
	);
init : PROCESS                                               
-- variable declarations                                     
BEGIN                                                        
        -- code that executes only once                      
WAIT;                                                       
END PROCESS init;     

G_KEY <= x"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
		   
G_IV <= x"71776572747975696f70617364666768";
G_PLAINTEXT1 <= X"00112233445566778899aabbccddeeff";
G_PLAINTEXT2 <= X"536f6d6520746f207265737420616c6c";

G_CIPHERTEXT1 <= X"8ea2b7ca516745bfeafc49904b496089";
G_CIPHERTEXT2 <= X"2c2056774b44bf7c716337b57a5f1399";
                                      
always : PROCESS                                              
                                     
BEGIN      
    sl_valid_in <= '0';
    sl_new_key_in <= '0';	
		wait until rising_edge(clk);
		wait until rising_edge(clk);
    sl_valid_in <= '1';
    sl_new_key_in <= '1';
    -- key
    for i in G_BITWIDTH_KEY / G_BITWIDTH_IF - 1 downto 0 loop
      slv_data_in <= G_KEY((i+1)*G_BITWIDTH_IF-1 downto i*G_BITWIDTH_IF);
      wait until rising_edge(clk);
    end loop;
	 
    -- -- iv
    -- for i in G_BITWIDTH_IV / G_BITWIDTH_IF - 1 downto 0 loop
      -- slv_data_in <= G_IV((i+1)*G_BITWIDTH_IF-1 downto i*G_BITWIDTH_IF);
      -- wait until rising_edge(clk);
    -- end loop;
    sl_new_key_in <= '0';
    sl_valid_in <= '0';
	wait until rising_edge(clk);
	sl_valid_in <= '1';
    -- actual data
    for i in 128 / G_BITWIDTH_IF - 1 downto 0 loop
      slv_data_in <= G_CIPHERTEXT1((i+1)*G_BITWIDTH_IF-1 downto i*G_BITWIDTH_IF);
      wait until rising_edge(clk);
    end loop;

	sl_valid_in <= '0';
    wait until rising_edge(clk) and sl_valid_out = '1';
    wait until rising_edge(clk) and sl_valid_out = '0';
    -- next input can be started only after the output is fully done

    sl_valid_in <= '1';
    for i in 128/G_BITWIDTH_IF-1 downto 0 loop
      slv_data_in <= G_CIPHERTEXT2((i+1)*G_BITWIDTH_IF-1 downto i*G_BITWIDTH_IF);
      -- no new key and iv needed
      wait until rising_edge(clk);
    end loop;

    sl_valid_in <= '0';
	
	
WAIT;                                                        
END PROCESS always;   

  data_check_proc : process
  begin
    wait until rising_edge(clk);

    for i in 128/G_BITWIDTH_IF-1 downto 0 loop
      wait until rising_edge(clk) and sl_valid_out = '1';
      assert(slv_data_out = G_PLAINTEXT1((i+1)*G_BITWIDTH_IF-1 downto i*G_BITWIDTH_IF));
    end loop;

    for i in 128/G_BITWIDTH_IF-1 downto 0 loop
      wait until rising_edge(clk) and sl_valid_out = '1';
      assert(slv_data_out = G_PLAINTEXT2((i+1)*G_BITWIDTH_IF-1 downto i*G_BITWIDTH_IF));
    end loop;

    report ("Done checking");
  end process;

    -- clock
    p_clk : process
        variable tmpclk : std_logic := '0';
    begin
        while true loop
            clk   <= tmpclk;
            tmpclk := not tmpclk;
            wait for C_CLK_PERIOD/2;
            end loop;
    end process p_clk;
                                       
END aes_arch;
