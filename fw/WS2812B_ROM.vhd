-- ZPU
--
-- Copyright 2004-2008 oharboe - �yvind Harboe - oyvind.harboe@zylin.com
-- Modified by Alastair M. Robinson for the ZPUFlex project.
--
-- The FreeBSD license
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above
--    copyright notice, this list of conditions and the following
--    disclaimer in the documentation and/or other materials
--    provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE ZPU PROJECT ``AS IS'' AND ANY
-- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
-- PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
-- ZPU PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
-- INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
-- STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- The views and conclusions contained in the software and documentation
-- are those of the authors and should not be interpreted as representing
-- official policies, either expressed or implied, of the ZPU Project.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library work;
use work.zpupkg.all;

entity WS2812B_ROM is
generic
	(
		maxAddrBitBRAM : integer := maxAddrBitBRAMLimit -- Specify your actual ROM size to save LEs and unnecessary block RAM usage.
	);
port (
	clk : in std_logic;
	areset : in std_logic := '0';
	from_zpu : in ZPU_ToROM;
	to_zpu : out ZPU_FromROM
);
end WS2812B_ROM;

architecture arch of WS2812B_ROM is

type ram_type is array(natural range 0 to ((2**(maxAddrBitBRAM+1))/4)-1) of std_logic_vector(wordSize-1 downto 0);

shared variable ram : ram_type :=
(
     0 => x"84808080",
     1 => x"8c0b8480",
     2 => x"8081e004",
     3 => x"84808080",
     4 => x"8c04ff0d",
     5 => x"80040400",
     6 => x"40000016",
     7 => x"00000000",
     8 => x"8480808a",
     9 => x"ac088480",
    10 => x"808ab008",
    11 => x"8480808a",
    12 => x"b4088480",
    13 => x"80809808",
    14 => x"2d848080",
    15 => x"8ab40c84",
    16 => x"80808ab0",
    17 => x"0c848080",
    18 => x"8aac0c04",
    19 => x"00000000",
    20 => x"00000000",
    21 => x"00000000",
    22 => x"00000000",
    23 => x"00000000",
    24 => x"71fd0608",
    25 => x"72830609",
    26 => x"81058205",
    27 => x"832b2a83",
    28 => x"ffff0652",
    29 => x"0471fc06",
    30 => x"08728306",
    31 => x"09810583",
    32 => x"05101010",
    33 => x"2a81ff06",
    34 => x"520471fd",
    35 => x"060883ff",
    36 => x"ff738306",
    37 => x"09810582",
    38 => x"05832b2b",
    39 => x"09067383",
    40 => x"ffff0673",
    41 => x"83060981",
    42 => x"05820583",
    43 => x"2b0b2b07",
    44 => x"72fc060c",
    45 => x"51510471",
    46 => x"fc060884",
    47 => x"80808a9c",
    48 => x"73830610",
    49 => x"10050806",
    50 => x"7381ff06",
    51 => x"73830609",
    52 => x"81058305",
    53 => x"1010102b",
    54 => x"0772fc06",
    55 => x"0c515104",
    56 => x"8480808a",
    57 => x"ac708480",
    58 => x"809d8827",
    59 => x"8e388071",
    60 => x"70840553",
    61 => x"0c848080",
    62 => x"81e50484",
    63 => x"8080808c",
    64 => x"51848080",
    65 => x"86fb0402",
    66 => x"f8050d73",
    67 => x"52ff8408",
    68 => x"70882a70",
    69 => x"81065151",
    70 => x"5170802e",
    71 => x"f03871ff",
    72 => x"840c7184",
    73 => x"80808aac",
    74 => x"0c028805",
    75 => x"0d0402f0",
    76 => x"050d7553",
    77 => x"80738480",
    78 => x"8080f52d",
    79 => x"7081ff06",
    80 => x"53535470",
    81 => x"742eb138",
    82 => x"7181ff06",
    83 => x"81145452",
    84 => x"ff840870",
    85 => x"882a7081",
    86 => x"06515151",
    87 => x"70802ef0",
    88 => x"3871ff84",
    89 => x"0c811473",
    90 => x"84808080",
    91 => x"f52d7081",
    92 => x"ff065353",
    93 => x"5470d138",
    94 => x"73848080",
    95 => x"8aac0c02",
    96 => x"90050d04",
    97 => x"02f8050d",
    98 => x"ff840870",
    99 => x"892a7081",
   100 => x"06515252",
   101 => x"70802ef0",
   102 => x"387181ff",
   103 => x"06848080",
   104 => x"8aac0c02",
   105 => x"88050d04",
   106 => x"02c4050d",
   107 => x"0280c005",
   108 => x"8480808b",
   109 => x"8c5b5680",
   110 => x"76708405",
   111 => x"5808715e",
   112 => x"5e577c70",
   113 => x"84055e08",
   114 => x"58805b77",
   115 => x"982a7888",
   116 => x"2b595372",
   117 => x"8938765e",
   118 => x"84808085",
   119 => x"e3047b80",
   120 => x"2e81d838",
   121 => x"805c7280",
   122 => x"e42ea138",
   123 => x"7280e426",
   124 => x"8e387280",
   125 => x"e32e80f5",
   126 => x"38848080",
   127 => x"84fb0472",
   128 => x"80f32e80",
   129 => x"d0388480",
   130 => x"8084fb04",
   131 => x"75841771",
   132 => x"087e5c56",
   133 => x"57528755",
   134 => x"739c2a74",
   135 => x"842b5552",
   136 => x"71802e83",
   137 => x"38815989",
   138 => x"72258a38",
   139 => x"b7125284",
   140 => x"808084b8",
   141 => x"04b01252",
   142 => x"78802e89",
   143 => x"38715184",
   144 => x"80808287",
   145 => x"2dff1555",
   146 => x"748025cc",
   147 => x"38805484",
   148 => x"80808594",
   149 => x"04758417",
   150 => x"71087054",
   151 => x"5c575284",
   152 => x"808082ae",
   153 => x"2d7b5484",
   154 => x"80808594",
   155 => x"04758417",
   156 => x"71085557",
   157 => x"52848080",
   158 => x"85cb04a5",
   159 => x"51848080",
   160 => x"82872d72",
   161 => x"51848080",
   162 => x"82872d82",
   163 => x"17578480",
   164 => x"8085d604",
   165 => x"73ff1555",
   166 => x"52807225",
   167 => x"b9387970",
   168 => x"81055b84",
   169 => x"808080f5",
   170 => x"2d705253",
   171 => x"84808082",
   172 => x"872d8117",
   173 => x"57848080",
   174 => x"85940472",
   175 => x"a52e0981",
   176 => x"06893881",
   177 => x"5c848080",
   178 => x"85d60472",
   179 => x"51848080",
   180 => x"82872d81",
   181 => x"1757811b",
   182 => x"5b837b25",
   183 => x"fded3872",
   184 => x"fde0387d",
   185 => x"8480808a",
   186 => x"ac0c02bc",
   187 => x"050d0402",
   188 => x"f8050d73",
   189 => x"51bd5280",
   190 => x"710c800b",
   191 => x"81f8120c",
   192 => x"800b83f0",
   193 => x"120cff12",
   194 => x"84125252",
   195 => x"718025e7",
   196 => x"38028805",
   197 => x"0d0402e8",
   198 => x"050d7756",
   199 => x"81557484",
   200 => x"29167070",
   201 => x"70840552",
   202 => x"087010fc",
   203 => x"14080572",
   204 => x"0811822c",
   205 => x"70733182",
   206 => x"2b81f816",
   207 => x"70089029",
   208 => x"71083170",
   209 => x"842c7384",
   210 => x"2c05720c",
   211 => x"56565151",
   212 => x"56811858",
   213 => x"565351bc",
   214 => x"7525c338",
   215 => x"841652bb",
   216 => x"55710881",
   217 => x"f8130805",
   218 => x"72708405",
   219 => x"540cff15",
   220 => x"55748025",
   221 => x"ec380298",
   222 => x"050d0402",
   223 => x"e4050d84",
   224 => x"80808bcc",
   225 => x"51848080",
   226 => x"85ef2d84",
   227 => x"808091b4",
   228 => x"51848080",
   229 => x"85ef2d84",
   230 => x"808097a0",
   231 => x"51848080",
   232 => x"85ef2db3",
   233 => x"5781c2e6",
   234 => x"0b848080",
   235 => x"979c0c76",
   236 => x"802e8a38",
   237 => x"ff175784",
   238 => x"808088d0",
   239 => x"04848080",
   240 => x"979c0870",
   241 => x"80ff0671",
   242 => x"10708480",
   243 => x"80979c0c",
   244 => x"70962a70",
   245 => x"81065153",
   246 => x"56545271",
   247 => x"802e8a38",
   248 => x"73810784",
   249 => x"8080979c",
   250 => x"0c848080",
   251 => x"979c0870",
   252 => x"952a7081",
   253 => x"06515354",
   254 => x"71802e8a",
   255 => x"38738132",
   256 => x"84808097",
   257 => x"9c0c7284",
   258 => x"29848080",
   259 => x"8bd00552",
   260 => x"b97325ab",
   261 => x"38728429",
   262 => x"8480808f",
   263 => x"d0055280",
   264 => x"f373259b",
   265 => x"38848080",
   266 => x"979c08bf",
   267 => x"0653ba73",
   268 => x"258338ba",
   269 => x"53728429",
   270 => x"84808097",
   271 => x"a4055283",
   272 => x"ffff720c",
   273 => x"84808097",
   274 => x"9c08a005",
   275 => x"80ff0657",
   276 => x"9fff56ff",
   277 => x"8408ff17",
   278 => x"57527580",
   279 => x"25f53881",
   280 => x"5675822b",
   281 => x"8480808b",
   282 => x"cc11089f",
   283 => x"2c848080",
   284 => x"8bcc1208",
   285 => x"882c8480",
   286 => x"808bcc13",
   287 => x"089f2c32",
   288 => x"70723184",
   289 => x"808091b4",
   290 => x"14089f2c",
   291 => x"84808091",
   292 => x"b4150888",
   293 => x"2c848080",
   294 => x"91b41608",
   295 => x"9f2c3270",
   296 => x"72318480",
   297 => x"8097a017",
   298 => x"089f2c84",
   299 => x"808097a0",
   300 => x"1808882c",
   301 => x"84808097",
   302 => x"a019089f",
   303 => x"2c327072",
   304 => x"317081ff",
   305 => x"0677902b",
   306 => x"87fc8080",
   307 => x"0675882b",
   308 => x"83fe8006",
   309 => x"71077207",
   310 => x"fc0c5860",
   311 => x"81054151",
   312 => x"51585351",
   313 => x"54595155",
   314 => x"5552bc76",
   315 => x"25fef238",
   316 => x"8480808b",
   317 => x"cc518480",
   318 => x"8086962d",
   319 => x"84808091",
   320 => x"b4518480",
   321 => x"8086962d",
   322 => x"84808097",
   323 => x"a0518480",
   324 => x"8086962d",
   325 => x"84808087",
   326 => x"af040000",
   327 => x"00ffffff",
   328 => x"ff00ffff",
   329 => x"ffff00ff",
   330 => x"ffffff00",
	others => x"00000000"
);

begin

process (clk)
begin
	if (clk'event and clk = '1') then
		if (from_zpu.memAWriteEnable = '1') and (from_zpu.memBWriteEnable = '1') and (from_zpu.memAAddr=from_zpu.memBAddr) and (from_zpu.memAWrite/=from_zpu.memBWrite) then
			report "write collision" severity failure;
		end if;
	
		if (from_zpu.memAWriteEnable = '1') then
			ram(to_integer(unsigned(from_zpu.memAAddr(maxAddrBitBRAM downto 2)))) := from_zpu.memAWrite;
			to_zpu.memARead <= from_zpu.memAWrite;
		else
			to_zpu.memARead <= ram(to_integer(unsigned(from_zpu.memAAddr(maxAddrBitBRAM downto 2))));
		end if;
	end if;
end process;

process (clk)
begin
	if (clk'event and clk = '1') then
		if (from_zpu.memBWriteEnable = '1') then
			ram(to_integer(unsigned(from_zpu.memBAddr(maxAddrBitBRAM downto 2)))) := from_zpu.memBWrite;
			to_zpu.memBRead <= from_zpu.memBWrite;
		else
			to_zpu.memBRead <= ram(to_integer(unsigned(from_zpu.memBAddr(maxAddrBitBRAM downto 2))));
		end if;
	end if;
end process;


end arch;

