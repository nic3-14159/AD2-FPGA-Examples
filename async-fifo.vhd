-- Based on Clifford Cummings async FIFO design in his paper
-- "Simulation and Synthesis Techniques for Asynchronous FIFO Design"
-- http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity async_fifo is
	generic (
		data_width : natural := 8;
		addr_bits : natural := 10
	);
	port (
		write_clk : in std_logic;
		write_en : in std_logic;
		write_data : in std_logic_vector(data_width-1 downto 0);
		write_reset_n : in std_logic;
		full : out std_logic;
		read_clk : in std_logic;
		read_en : in std_logic;
		read_data : out std_logic_vector(data_width-1 downto 0);
		read_reset_n : in std_logic;
		empty : out std_logic
	);
end async_fifo;

architecture Behavioral of async_fifo is
	type data_array is array (0 to 2**addr_bits - 1) of std_logic_vector(data_width-1 downto 0);
	signal RAM : data_array := (others => (others => '0'));
	-- Bits addr_bits-1:0 used to address memory, bit addr_bits (msb)
	-- used to for address comparison to generate full and empty
	signal raddr_bin : unsigned(addr_bits downto 0) := (others => '0');
	signal raddr_gray : unsigned(addr_bits downto 0) := (others => '0');
	signal raddr_bin_next : unsigned(addr_bits downto 0) := (others => '0');
	signal raddr_gray_next : unsigned(addr_bits downto 0) := (others => '0');

	signal waddr_bin : unsigned(addr_bits downto 0) := (others => '0');
	signal waddr_gray : unsigned(addr_bits downto 0) := (others => '0');
	signal waddr_bin_next : unsigned(addr_bits downto 0) := (others => '0');
	signal waddr_gray_next : unsigned(addr_bits downto 0) := (others => '0');

	signal full_next : std_logic := '0';
	signal full_out : std_logic := '0';
	signal empty_next : std_logic := '0';
	signal empty_out : std_logic := '0';

	-- read_clk domain to write_clk domain synchronizer registers
	signal r2w_sync_1 : unsigned(addr_bits downto 0) := (others => '0');
	signal r2w_sync_2 : unsigned(addr_bits downto 0) := (others => '0');
	-- write_clk domain to read_clk domain synchronizer registers
	signal w2r_sync_1 : unsigned(addr_bits downto 0) := (others => '0');
	signal w2r_sync_2 : unsigned(addr_bits downto 0) := (others => '0');
begin
	empty <= empty_out;
	full <= full_out;

	-- read_clk domain to write_clk domain synchronizer
	process (write_clk, write_reset_n)
	begin
		if write_reset_n = '0' then
			r2w_sync_2 <= (others => '0');
			r2w_sync_1 <= (others => '0');
		elsif rising_edge(write_clk) then
			r2w_sync_2 <= r2w_sync_1;
			r2w_sync_1 <= raddr_gray;
		end if;
	end process;

	-- write_clk domain to read_clk domain synchronizer
	process (read_clk, read_reset_n)
	begin
		if read_reset_n = '0' then
			w2r_sync_2 <= (others => '0');
			w2r_sync_1 <= (others => '0');
		elsif rising_edge(read_clk) then
			w2r_sync_2 <= w2r_sync_1;
			w2r_sync_1 <= waddr_gray;
		end if;
	end process;

	-- empty flag generation
	empty_next <= '1' when (raddr_gray_next = w2r_sync_2) else '0';
	-- read pointer generation
	raddr_bin_next <= raddr_bin + 1 when (read_en and not empty_out) = '1' else raddr_bin;
	raddr_gray_next <= raddr_bin_next xor shift_right(unsigned(raddr_bin_next), 1);
	process (read_clk, read_reset_n)
	begin
		if read_reset_n = '0' then
			empty_out <= '0';
			raddr_bin <= (others => '0');
			raddr_gray <= (others => '0');
		elsif rising_edge(read_clk) then
			empty_out <= empty_next;
			raddr_bin <= raddr_bin_next;
			raddr_gray <= raddr_gray_next;
		end if;
	end process;

	-- full flag generation
	process (waddr_gray_next, r2w_sync_2)
	begin
		if waddr_gray_next(addr_bits) /= r2w_sync_2(addr_bits)
		   and waddr_gray_next(addr_bits-1) /= r2w_sync_2(addr_bits-1)
		   and waddr_gray_next(addr_bits-2 downto 0) = r2w_sync_2(addr_bits-1 downto 0)
		then
			full_next <= '1';
		else
			full_next <= '0';
		end if;
	end process;
	-- write pointer generation
	waddr_bin_next <= waddr_bin + 1 when (write_en and not full_out) = '1' else waddr_bin;
	waddr_gray_next <= waddr_bin_next xor shift_right(unsigned(waddr_bin_next), 1);
	process (write_clk, write_reset_n)
	begin
		if write_reset_n = '0' then
			full_out <= '0';
			waddr_bin <= (others => '0');
			waddr_gray <= (others => '0');
		elsif rising_edge(write_clk) then
			full_out <= full_next;
			waddr_bin <= waddr_bin_next;
			waddr_gray <= waddr_gray_next;
		end if;
	end process;

	-- write data handling
	process (write_clk)
	begin
		if rising_edge(write_clk) then
			if write_en = '1' and full_out = '0' then
				RAM(to_integer(waddr_bin(addr_bits-1 downto 0))) <= write_data;
			end if;
		end if;
	end process;

	-- read data handling
	read_data <= RAM(to_integer(raddr_bin(addr_bits-1 downto 0)));
end Behavioral;
