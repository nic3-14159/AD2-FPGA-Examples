library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
	port (
		-- FT232H signals
		adbus : inout std_logic_vector(7 downto 0);
		acbus : inout std_logic_vector(7 downto 0);
		led : out std_logic
	);
end top;

architecture Behavioral of top is
	signal fifo_data : std_logic_vector(7 downto 0) := (others => '0');
	signal ft232h_data : std_logic_vector(7 downto 0) := (others => '0');
	signal counter : integer range 0 to 255 := 0;
	signal wr_en : std_logic := '0';
	signal fifo_full : std_logic := '0';
	signal wr_clk : std_logic := '0';
	signal clk_div : integer range 0 to 60000000 := 0;
begin
	ft232h_inst: entity work.ft232h_fifo(Behavioral)
	port map (
		data => ft232h_data,
		rx_full_n => acbus(0), -- in
		read_n => acbus(2), -- out
		tx_empty_n => acbus(1), -- in
		write_n => acbus(3), -- out
		ft232_clk => acbus(5), -- in
		output_en_n => acbus(6), -- out
		send_immediate_n => acbus(4), -- out
		wr_data => fifo_data, -- in
		wr_clk => acbus(5), -- in
		wr_en => wr_en, -- in
		full => fifo_full, -- out
		reset_fifo => '0' -- in
	);

	process (acbus(5))
	begin
		if falling_edge(acbus(5)) then
                        clk_div <= clk_div + 1;
                        if clk_div = 15000000 then
                                clk_div <= 0;
				wr_en <= not fifo_full;
				counter <= counter + 1;
                        else
				wr_en <= '0';
                        end if;
                end if;
	end process;

	led <= fifo_full;
	fifo_data <= std_logic_vector(to_unsigned(counter, 8));

	-- JTAG switch handling
	process (acbus(7), ft232h_data)
	begin
		if acbus(7) = '1' then
			adbus <= (others => 'Z');
		else
			adbus <= ft232h_data;
		end if;
	end process;
end Behavioral;
