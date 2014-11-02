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
     9 => x"c0088480",
    10 => x"808ac408",
    11 => x"8480808a",
    12 => x"c8088480",
    13 => x"80809808",
    14 => x"2d848080",
    15 => x"8ac80c84",
    16 => x"80808ac4",
    17 => x"0c848080",
    18 => x"8ac00c04",
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
    47 => x"80808ab0",
    48 => x"73830610",
    49 => x"10050806",
    50 => x"7381ff06",
    51 => x"73830609",
    52 => x"81058305",
    53 => x"1010102b",
    54 => x"0772fc06",
    55 => x"0c515104",
    56 => x"8480808a",
    57 => x"c0708480",
    58 => x"809d9c27",
    59 => x"8e388071",
    60 => x"70840553",
    61 => x"0c848080",
    62 => x"81e50484",
    63 => x"8080808c",
    64 => x"51848080",
    65 => x"87820402",
    66 => x"f8050d73",
    67 => x"52ff8408",
    68 => x"70882a70",
    69 => x"81065151",
    70 => x"5170802e",
    71 => x"f03871ff",
    72 => x"840c7184",
    73 => x"80808ac0",
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
    95 => x"8ac00c02",
    96 => x"90050d04",
    97 => x"02f8050d",
    98 => x"ff840870",
    99 => x"892a7081",
   100 => x"06515252",
   101 => x"70802ef0",
   102 => x"387181ff",
   103 => x"06848080",
   104 => x"8ac00c02",
   105 => x"88050d04",
   106 => x"02c4050d",
   107 => x"0280c005",
   108 => x"8480808b",
   109 => x"a05b5680",
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
   186 => x"c00c02bc",
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
   202 => x"08701011",
   203 => x"fc140810",
   204 => x"11730810",
   205 => x"1170832c",
   206 => x"74317083",
   207 => x"2b81f818",
   208 => x"70089029",
   209 => x"71083170",
   210 => x"842c7384",
   211 => x"2c05720c",
   212 => x"58585151",
   213 => x"51515481",
   214 => x"18585654",
   215 => x"52bc7525",
   216 => x"ffbc3884",
   217 => x"1652bb55",
   218 => x"710881f8",
   219 => x"13080572",
   220 => x"70840554",
   221 => x"0cff1555",
   222 => x"748025ec",
   223 => x"38029805",
   224 => x"0d0402e4",
   225 => x"050d8480",
   226 => x"808be051",
   227 => x"84808085",
   228 => x"ef2d8480",
   229 => x"8091c851",
   230 => x"84808085",
   231 => x"ef2d8480",
   232 => x"8097b451",
   233 => x"84808085",
   234 => x"ef2db357",
   235 => x"81c2e60b",
   236 => x"84808097",
   237 => x"b00c7680",
   238 => x"2e8a38ff",
   239 => x"17578480",
   240 => x"8088e604",
   241 => x"84808097",
   242 => x"b0087080",
   243 => x"ff067110",
   244 => x"70848080",
   245 => x"97b00c70",
   246 => x"962a7081",
   247 => x"06515355",
   248 => x"55527180",
   249 => x"2e8a3872",
   250 => x"81078480",
   251 => x"8097b00c",
   252 => x"84808097",
   253 => x"b0087095",
   254 => x"2a708106",
   255 => x"51535371",
   256 => x"802e8a38",
   257 => x"72813284",
   258 => x"808097b0",
   259 => x"0c848080",
   260 => x"97b00870",
   261 => x"bf068105",
   262 => x"5353bb72",
   263 => x"258338bb",
   264 => x"5273a924",
   265 => x"96387184",
   266 => x"29848080",
   267 => x"8be00552",
   268 => x"83ffff72",
   269 => x"0c848080",
   270 => x"88e10471",
   271 => x"822b5273",
   272 => x"80d42492",
   273 => x"3883ffff",
   274 => x"0b848080",
   275 => x"91c8130c",
   276 => x"84808088",
   277 => x"e10483ff",
   278 => x"ff0b8480",
   279 => x"8097b413",
   280 => x"0c7281ff",
   281 => x"06579fff",
   282 => x"56ff8408",
   283 => x"ff175752",
   284 => x"758025f5",
   285 => x"38815675",
   286 => x"822b8480",
   287 => x"808be011",
   288 => x"089f2c84",
   289 => x"80808be0",
   290 => x"1208882c",
   291 => x"8480808b",
   292 => x"e013089f",
   293 => x"2c327072",
   294 => x"31848080",
   295 => x"91c81408",
   296 => x"9f2c8480",
   297 => x"8091c815",
   298 => x"08882c84",
   299 => x"808091c8",
   300 => x"16089f2c",
   301 => x"32707231",
   302 => x"84808097",
   303 => x"b417089f",
   304 => x"2c848080",
   305 => x"97b41808",
   306 => x"882c8480",
   307 => x"8097b419",
   308 => x"089f2c32",
   309 => x"70723170",
   310 => x"81ff0677",
   311 => x"902b87fc",
   312 => x"80800675",
   313 => x"882b83fe",
   314 => x"80067107",
   315 => x"7207fc0c",
   316 => x"58608105",
   317 => x"41515158",
   318 => x"53515459",
   319 => x"51555552",
   320 => x"bc7625fe",
   321 => x"f2388480",
   322 => x"808be051",
   323 => x"84808086",
   324 => x"962d8480",
   325 => x"8091c851",
   326 => x"84808086",
   327 => x"962d8480",
   328 => x"8097b451",
   329 => x"84808086",
   330 => x"962d8480",
   331 => x"8087b604",
   332 => x"00ffffff",
   333 => x"ff00ffff",
   334 => x"ffff00ff",
   335 => x"ffffff00",
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

