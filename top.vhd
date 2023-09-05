library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
	port (
		-- FT232H signals
		adbus : inout std_logic_vector(7 downto 0);
		acbus : inout std_logic_vector(9 downto 0)
	);
end top;

architecture Behavioral of top is
    signal data : std_logic_vector(7 downto 0) := (others => '0');
begin
    ft232h_inst: entity work.ft232h_fifo(Behavioral)
        port map (
             data => data,
             rx_full_n => acbus(0),
             read_n => acbus(2),
             tx_empty_n => acbus(1),
             write_n => acbus(3),
             ft232_clk => acbus(5),
             output_en_n => acbus(6),
             send_immediate_n => acbus(4)
        );
    process (acbus(7), data)
    begin
        if acbus(7) = '1' then
            adbus <= data;
        else
            adbus <= (others => 'Z');
        end if;
    end process;
end Behavioral;
