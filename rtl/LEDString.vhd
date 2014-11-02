library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.zpupkg.ALL;

entity LEDString is
	generic (
		sdram_rows : integer := 12;
		sdram_cols : integer := 8;
		
		sysclk_frequency : integer := 1000 -- Sysclk frequency * 10
	);
	port (
		clk 			: in std_logic;
		reset_in 	: in std_logic;

		-- SDRAM
		sdr_data		: inout std_logic_vector(15 downto 0);
		sdr_addr		: out std_logic_vector((sdram_rows-1) downto 0);
		sdr_dqm 		: out std_logic_vector(1 downto 0);
		sdr_we 		: out std_logic;
		sdr_cas 		: out std_logic;
		sdr_ras 		: out std_logic;
		sdr_cs		: out std_logic;
		sdr_ba		: out std_logic_vector(1 downto 0);
--		sdr_clk		: out std_logic;
		sdr_cke		: out std_logic;
		
		-- UART
		rxd	: in std_logic;
		txd	: out std_logic;
		
		led_tx : out std_logic
	);
end entity;

architecture rtl of LEDString is

constant sysclk_hz : integer := sysclk_frequency*1000;
constant uart_divisor : integer := sysclk_hz/1152;

signal reset : std_logic := '0';
signal reset_counter : unsigned(15 downto 0) := X"FFFF";

-- State machine
type SOCStates is (WAITING,READ1,WRITE1,PAUSE);
signal currentstate : SOCStates;

-- UART signals

signal ser_txdata : std_logic_vector(7 downto 0);
signal ser_txready : std_logic;
signal ser_rxdata : std_logic_vector(7 downto 0);
signal ser_rxrecv : std_logic;
signal ser_txgo : std_logic;
signal ser_rxint : std_logic;
signal ser_clock_divisor : unsigned(15 downto 0);

-- Millisecond counter
signal millisecond_counter : unsigned(31 downto 0) := X"00000000";
signal millisecond_tick : unsigned(19 downto 0);

-- ZPU signals

signal mem_busy           : std_logic;
signal mem_read             : std_logic_vector(wordSize-1 downto 0);
signal mem_write            : std_logic_vector(wordSize-1 downto 0);
signal mem_addr             : std_logic_vector(31 downto 0);
signal mem_writeEnable      : std_logic; 
signal mem_writeEnableh      : std_logic; 
signal mem_writeEnableb      : std_logic; 
signal mem_readEnable       : std_logic;
--signal mem_writeMask        : std_logic_vector(wordBytes-1 downto 0);
signal zpu_enable               : std_logic;
signal zpu_interrupt            : std_logic;
signal zpu_break                : std_logic;

signal zpu_to_rom : ZPU_ToROM;
signal zpu_from_rom : ZPU_FromROM;

signal cpu_uds	: std_logic;
signal cpu_lds : std_logic;


-- SDRAM signals

signal sdr_ready : std_logic;
signal sdram_write : std_logic_vector(31 downto 0); -- 32-bit width for ZPU
signal sdram_addr : std_logic_vector(31 downto 0);
signal sdram_req : std_logic;
signal sdram_wr : std_logic;
signal sdram_read : std_logic_vector(31 downto 0);
signal sdram_ack : std_logic;

signal sdram_wrL : std_logic;
signal sdram_wrU : std_logic;
signal sdram_wrU2 : std_logic;

type sdram_states is (read1, read2, read3, write1, writeb, write2, write3, idle);
signal sdram_state : sdram_states;


-- LED signals
signal led_red : std_logic_vector(7 downto 0);
signal led_green : std_logic_vector(7 downto 0);
signal led_blue : std_logic_vector(7 downto 0);
signal led_trigger : std_logic;
signal led_busy : std_logic;
signal led_send : std_logic;

begin

sdr_cke <='1';

-- Timer
process(clk)
begin
	if rising_edge(clk) then
		millisecond_tick<=millisecond_tick+1;
		if millisecond_tick=sysclk_frequency*100 then
			millisecond_counter<=millisecond_counter+1;
			millisecond_tick<=X"00000";
		end if;
	end if;
end process;


-- SDRAM
mysdram : entity work.sdram 
	generic map
	(
		rows => sdram_rows,
		cols => sdram_cols
	)
	port map
	(
	-- Physical connections to the SDRAM
		sdata => sdr_data,
		sdaddr => sdr_addr,
		sd_we	=> sdr_we,
		sd_ras => sdr_ras,
		sd_cas => sdr_cas,
		sd_cs	=> sdr_cs,
		dqm => sdr_dqm,
		ba	=> sdr_ba,

	-- Housekeeping
		sysclk => clk,
		reset => reset_in,  -- Contributes to reset, so have to use reset_in here.
		reset_out => sdr_ready,

		datawr1 => sdram_write,
		Addr1 => sdram_addr,
		req1 => sdram_req,
		wr1 => sdram_wr, -- active low
		wrL1 => sdram_wrL, -- lower byte
		wrU1 => sdram_wrU, -- upper byte
		wrU2 => sdram_wrU2, -- upper halfword, only written on longword accesses
		dataout1 => sdram_read,
		dtack1 => sdram_ack
	);


process(clk)
begin
	if reset_in='0' then
		reset_counter<=X"FFFF";
		reset<='0';
	elsif rising_edge(clk) then
		reset_counter<=reset_counter-1;
		if reset_counter=X"0000" then
			reset<='1' and sdr_ready;
		end if;
	end if;
end process;


-- UART

	myuart : entity work.simple_uart
		generic map(
			enable_tx=>true,
			enable_rx=>true
		)
		port map(
			clk => clk,
			reset => reset, -- active low
			txdata => ser_txdata,
			txready => ser_txready,
			txgo => ser_txgo,
			rxdata => ser_rxdata,
			rxint => ser_rxint,
			txint => open,
			clock_divisor => to_unsigned(uart_divisor,16), -- Hardcode to 115200 - was ser_clock_divisor,
			rxd => rxd,
			txd => txd
		);

-- Boot ROM

	myrom : entity work.WS2812B_ROM
	generic map (
		maxAddrBitBRAM => 11
	)
	port map (
		clk => clk,
		from_zpu => zpu_to_rom,
		to_zpu => zpu_from_rom
	);

	
myleds: entity work.WS2812B
generic map (
	sysclk_frequency => sysclk_frequency
	)
port map (
	reset_n => reset,
	clk => clk,
	red => led_red,
	green => led_green,
	blue => led_blue,
	trigger => led_trigger,
	tx => led_tx,
	busy => led_busy
);

-- Main CPU

	zpu: zpu_core_flex
	generic map (
		IMPL_MULTIPLY => true,
		IMPL_COMPARISON_SUB => true,
		IMPL_EQBRANCH => true,
		IMPL_STOREBH => true,
		IMPL_LOADBH => true,
		IMPL_CALL => true,
		IMPL_SHIFT => true,
		IMPL_XOR => true,
		REMAP_STACK => true,
		EXECUTE_RAM => true, -- We can save some LEs by omitting Execute from RAM support
		maxAddrBitBRAM => 11
	)
	port map (
		clk                 => clk,
		reset               => not reset,
		enable              => zpu_enable,
		in_mem_busy         => mem_busy,
		mem_read            => mem_read,
		mem_write           => mem_write,
		out_mem_addr        => mem_addr,
		out_mem_writeEnable => mem_writeEnable,
		out_mem_hEnable     => mem_writeEnableh,
		out_mem_bEnable     => mem_writeEnableb,
		out_mem_readEnable  => mem_readEnable,
		interrupt           => zpu_interrupt,
		break               => zpu_break,
		from_rom => zpu_from_rom,
		to_rom => zpu_to_rom
	);


process(clk)
begin
	zpu_enable<='1';
	zpu_interrupt<='0';

	if reset='0' then
		currentstate<=WAITING;
		sdram_state<=idle;
		led_send<='0';
	elsif rising_edge(clk) then
		mem_busy<='1';

		ser_txgo<='0';
		led_trigger<='0';
		
		-- Write from CPU
		if mem_writeEnable='1' then
			case mem_addr(31 downto 28) is

				when X"F" =>	-- Peripherals
					case mem_addr(7 downto 0) is
						when X"fc" => -- LED string
							led_send<='1';
							led_red<=mem_write(23 downto 16);
							led_green<=mem_write(15 downto 8);
							led_blue<=mem_write(7 downto 0);
							
						when X"84" => -- UART
							ser_txdata<=mem_write(7 downto 0);
							ser_txgo<='1';
							mem_busy<='0';

						when others =>
							mem_busy<='0'; -- FIXME - shouldn't need this
							null;
					end case;
				
				when others => -- SDRAM access
					sdram_wrL<=mem_writeEnableb and not mem_addr(0);
					sdram_wrU<=mem_writeEnableb and mem_addr(0);
					sdram_wrU2<=mem_writeEnableh or mem_writeEnableb; -- Halfword access
					if mem_writeEnableb='1' then
						sdram_state<=writeb;
					else
						sdram_state<=write1;
					end if;

			end case;

		elsif mem_readEnable='1' then
			case mem_addr(31 downto 28) is

				when X"F" =>	-- Peripherals
					case mem_addr(7 downto 0) is
						when X"84" => -- UART
							mem_read<=(others=>'X');
							mem_read(9 downto 0)<=ser_rxrecv&ser_txready&ser_rxdata;
							ser_rxrecv<='0';	-- Clear rx flag.
							mem_busy<='0';
							
--								when X"C0" => -- Millisecond counter
--									mem_read<=std_logic_vector(millisecond_counter);
--									mem_busy<='0';

						when others =>
							mem_busy<='0'; -- FIXME - shouldn't need this
							null;
					end case;

				when others =>
					sdram_state<=read1;
				
			end case;
		end if;

	-- SDRAM state machine
	
		case sdram_state is
			when read1 => -- read first word from RAM
				sdram_addr<=mem_Addr;
				sdram_wr<='1';
				sdram_req<='1';
				if sdram_ack='0' then
					if mem_WriteEnableh='1' then -- halfword read						
						mem_read(31 downto 16) <= (others=>'0');
						mem_read(15 downto 0)<=sdram_read(31 downto 16);
					elsif mem_WriteEnableb='1' then -- Byte read
						mem_read(31 downto 8) <= (others=>'0');
						if mem_Addr(0)='0' then -- even address
							mem_read(7 downto 0)<=sdram_read(31 downto 24);
						else
							mem_read(7 downto 0)<=sdram_read(23 downto 16);
						end if;
					else
						mem_read<=sdram_read;
					end if;
					sdram_req<='0';
					sdram_state<=idle;
					mem_busy<='0';
				end if;
			when write1 => -- write 32-bit word to SDRAM
				sdram_addr<=mem_Addr;
				sdram_wr<='0';
				sdram_req<='1';
				sdram_write<=mem_write; -- 32-bits now
				if sdram_ack='0' then -- done?
					sdram_req<='0';
					sdram_state<=idle;
					mem_busy<='0';
				end if;
			when writeb => -- write 8-bit value to SDRAM
				sdram_addr<=mem_Addr;
				sdram_wr<='0';
				sdram_req<='1';
				sdram_write<=mem_write; -- 32-bits now
				sdram_write(15 downto 8)<=mem_write(7 downto 0); -- 32-bits now
				if sdram_ack='0' then -- done?
					sdram_req<='0';
					sdram_state<=idle;
					mem_busy<='0';
				end if;
			when others =>
				null;

		end case;

		-- Trigger LED transmission
		if led_send='1' and led_busy='0' then
			led_trigger<='1';
			mem_busy<='0';
			led_send<='0';
		end if;

		
		-- Set this after the read operation has potentially cleared it.
		if ser_rxint='1' then
			ser_rxrecv<='1';
		end if;

	end if; -- rising-edge(clk)

end process;
	
end architecture;
