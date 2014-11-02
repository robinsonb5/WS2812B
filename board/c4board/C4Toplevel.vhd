library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity C4Toplevel is
port(
	CLK50M : in std_logic;
	KEY0 : in std_logic;
	KEY1 : in std_logic;
	LED : out std_logic_vector(1 downto 0);
	CK : in std_logic_vector(3 downto 0); -- Alias SW(3 downto 0)
	-- SDRAM interface
	SDRAM_Addr : out std_logic_vector(12 downto 0);
	SDRAM_BA : out std_logic_vector(1 downto 0);
	SDRAM_CAS_N : out std_logic;
	SDRAM_CKE : out std_logic;
	SDRAM_CLK : out std_logic;
	SDRAM_CS_N : out std_logic;
	SDRAM_DQ : inout std_logic_vector(15 downto 0);
	SDRAM_DQM : out std_logic_vector(1 downto 0);
	SDRAM_RAS_N : out std_logic;
	SDRAM_WE_N : out std_logic;
	-- GPIO
	IO_D : inout std_logic_vector(40 downto 1)
);
end entity;

architecture rtl of C4Toplevel is

signal sysclk : std_logic;
signal reset : std_logic;
signal UART_TXD : std_logic;
signal UART_RXD : std_logic;
signal LED_TX : std_logic;
begin

IO_D <= (others => 'Z');

-- UART mapping
IO_D(40) <= UART_TXD;
UART_RXD <= IO_D(39);
IO_D(38) <= LED_TX;

-- Other IO mappings

process(sysclk)
begin
	if rising_edge(sysclk) then
		reset <= KEY0;
	end if;
end process;


-- PLL

MyPLL : entity work.PLL
port map(
	inclk0 => CLK50M,
	c0 => sysclk,
	c1 => SDRAM_CLK
);

-- Main project instance.

myproject : entity work.LEDString
		generic map(
			sdram_rows => 13,
			sdram_cols => 9,
			sysclk_frequency => 1000
		)
		port map(
			clk => sysclk,
			reset_in => reset,

			-- SDRAM - presenting a single interface to both chips.
			sdr_addr => SDRAM_Addr,
			sdr_data => SDRAM_DQ,
			sdr_ba => SDRAM_BA,
			sdr_cke => SDRAM_CKE,
			sdr_dqm => SDRAM_DQM,
			sdr_cs => SDRAM_CS_N,
			sdr_we => SDRAM_WE_N,
			sdr_cas => SDRAM_CAS_N,
			sdr_ras => SDRAM_RAS_N,
			
			-- UART
			rxd => UART_RXD,
			txd => UART_TXD,
			
			led_tx => LED_TX
		);


end architecture;
