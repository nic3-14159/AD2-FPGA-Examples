library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ft232h_tb is
end entity;

architecture Behavioral of ft232h_tb is
    -- FT232H interface signals
    signal data_s: std_logic_vector(7 downto 0) := (others => '0');
    -- rx from FT232
    signal rx_full_n_s: std_logic := '1';
    signal write_n_s: std_logic := '1';
    -- tx to ft232
    signal tx_empty_n_s: std_logic := '1';
    signal read_n_s: std_logic := '1';
    signal clk_s: std_logic := '0';
    signal output_en_n_s: std_logic := '0'; -- output from ft232 to fpga
    signal send_immediate_n_s: std_logic := '0';
    signal jtag_flag_s: std_logic := '1';
begin
    ft232h_inst: entity work.ft232h_fifo(Behavioral)
        port map (
             data => data_s,
             rx_full_n => rx_full_n_s,
             write_n => write_n_s,
             tx_empty_n => tx_empty_n_s,
             read_n => read_n_s,
             clk => clk_s,
             output_en_n => output_en_n_s,
             send_immediate_n => send_immediate_n_s,
             jtag_flag  => jtag_flag_s
        );
    process
    begin
        clk_s <= not clk_s;
        wait for 10 ns;
    end process;

    process
    begin
        wait for 20 ns;
        jtag_flag_s <= '0';
        wait for 20 ns;
        tx_empty_n_s <= '0';
        wait for 209 ns;
        tx_empty_n_s <= '1';
    end process;
end Behavioral;
