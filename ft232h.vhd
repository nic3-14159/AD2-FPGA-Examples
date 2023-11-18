-- Async FIFO wrapper for the FT232H synchronous FIFO interface allowing
-- other logic to push data to the FT232H at an arbitrary clock speed

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ft232h_fifo is
	port (
		-- FT232H interface signals
		data: inout std_logic_vector(7 downto 0);
		rx_full_n: in std_logic; -- low when data available to read
		read_n: out std_logic; -- low to read from FT232H FIFO
		tx_empty_n: in std_logic; -- low when space available to write
		write_n: out std_logic; -- low to write to FT232H FIFO
		ft232_clk : in std_logic; -- Fixed at 60 MHz
		output_en_n: out std_logic; -- low to read from ft232
		send_immediate_n: out std_logic;

		-- async buffer write channel signals
		wr_data : in std_logic_vector(7 downto 0);
		wr_clk : in std_logic; -- arbitrary
		wr_en : in std_logic;
		full : out std_logic;

		reset_fifo : in std_logic
	);
end ft232h_fifo;

architecture Behavioral of ft232h_fifo is
	signal bus_turnaround : std_logic := '0';
	signal write_n_s : std_logic := '0';
	signal fifo_empty : std_logic := '0';
	signal fifo_read : std_logic := '0';
begin
	async_fifo_inst: entity work.async_fifo(Behavioral)
		generic map (
			data_width => 8,
			addr_bits => 10 -- 2^10 = 1024 bytes
		)
		port map (
			write_clk => wr_clk, -- in std_logic;
			write_en => wr_en, -- in std_logic;
			write_data => wr_data, -- in std_logic_vector(data_width-1 downto 0);
			write_reset_n => reset_fifo, -- in std_logic;
			full => full, -- out std_logic;
			read_clk => ft232_clk, -- in std_logic;
			read_en => fifo_read, -- in std_logic;
			read_data => data, -- out std_logic_vector(data_width-1 downto 0);
			read_reset_n => reset_fifo, -- in std_logic;
			empty => fifo_empty -- out std_logic
		);
	output_en_n <= '1';
	send_immediate_n <= '1';
	write_n_s <= not (bus_turnaround and not tx_empty_n and not fifo_empty);
	write_n <= write_n_s;
	fifo_read <= not write_n_s;
	read_n <= '1';
	process (ft232_clk)
	begin
		if rising_edge(ft232_clk) then
			if bus_turnaround = '0' then
				bus_turnaround <= '1';
			else
				bus_turnaround <= bus_turnaround;
			end if;
		end if;
	end process;
end Behavioral;

