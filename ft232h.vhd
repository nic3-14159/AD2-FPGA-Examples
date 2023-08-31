library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ft232h_fifo is
	port (
		-- FT232H interface signals
		data: inout std_logic_vector(7 downto 0);
		-- rx from FT232
		rx_full_n: in std_logic;
		write_n: out std_logic;
		-- tx to ft232
		tx_empty_n: in std_logic;
		read_n: out std_logic;
		clk : in std_logic;
		output_en_n: out std_logic; -- output from ft232 to fpga
		send_immediate_n: out std_logic;
		jtag_flag : in std_logic
	);
end ft232h_fifo;

architecture Behavioral of ft232h_fifo is
	signal bus_turnaround : std_logic := '0';
	signal data_byte : unsigned(7 downto 0) := (others => '0');
	signal write_n_s : std_logic := '0';
begin
	output_en_n <= '1';
	send_immediate_n <= '1';
	write_n_s <= not (bus_turnaround and not tx_empty_n);
	write_n <= write_n_s;
	read_n <= '1';
	process (jtag_flag, data_byte)
	begin
		if jtag_flag='1' then
			data <= (others => 'Z');
		else
			data <= std_logic_vector(data_byte);
		end if;
	end process;
	process (clk)
	begin
		if rising_edge(clk) then
			if bus_turnaround = '0' then
				bus_turnaround <= '1';
			else
				bus_turnaround <= bus_turnaround;
			end if;
			if write_n_s='0' and tx_empty_n='0' then
				data_byte <= data_byte + 1;
			else
				data_byte <= data_byte;
			end if;
		end if;
	end process;
end Behavioral;

