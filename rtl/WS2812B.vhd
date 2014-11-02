library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity WS2812B is
generic (
	sysclk_frequency : integer := 1000 -- Sysclk frequency * 10
	);
port (
	reset_n : in std_logic;
	clk : in std_logic;
	red : in std_logic_vector(7 downto 0);
	green : in std_logic_vector(7 downto 0);
	blue : in std_logic_vector(7 downto 0);
	trigger : in std_logic;
	tx : out std_logic;
	busy : out std_logic
);
end entity;

architecture rtl of WS2812B is

signal shift : std_logic_vector(31 downto 0);
signal counter : unsigned(15 downto 0);

type txstates is (idle, transmit, zerohigh, zerolow, onehigh, onelow, count, reset);
signal txstate : txstates:=idle;
signal nextstate : txstates;
constant clocks_per_microsecond : integer := sysclk_frequency/10;
constant zerohightime : integer := (40*clocks_per_microsecond)/100;
constant zerolowtime : integer := (85*clocks_per_microsecond)/100;
constant onehightime : integer := (80*clocks_per_microsecond)/100;
constant onelowtime : integer := (45*clocks_per_microsecond)/100;
constant resettime  : integer := (55*clocks_per_microsecond)/1;
begin

process(clk)
begin
	if reset_n='0' then
		txstate<=reset;
		nextstate<=idle;
		busy<='0';
		tx<='0';
	elsif rising_edge(clk) then
	
		case txstate is
			when idle =>
				tx<='0';
				busy<='0';
				if trigger='1' then
					shift<=green & red & blue & X"FF";
					txstate<=transmit;
					busy<='1';
				end if;
			
			when transmit =>
				if shift(23 downto 0)=X"000000" then
					txstate<=idle;
				else
					if shift(31)='1' then
						counter<=to_unsigned(onehightime,16);
						nextstate<=onelow;
					else
						counter<=to_unsigned(zerohightime,16);
						nextstate<=zerolow;
					end if;
					tx<='1';
					txstate<=count;
					shift<=shift(30 downto 0)&"0";
				end if;
				
			when count =>
				if counter=X"0000" then
					txstate<=nextstate;
				else
					counter <= counter-1;
				end if;

			when onelow =>
				tx<='0';
				counter<=to_unsigned(onelowtime,16);
				txstate<=count;
				nextstate<=transmit;

			when zerolow =>
				tx<='0';
				counter<=to_unsigned(zerolowtime,16);
				txstate<=count;
				nextstate<=transmit;
				
			when reset =>
				tx<='0';
				counter<=to_unsigned(resettime,16);
				txstate<=count;
				nextstate<=idle;
				
			when others =>
				txstate<=idle;
				
		end case;
	end if;
end process;

end architecture;