-- clocks_us_serdes
--
-- Input is a free-running crystal clock
--
-- Dave Newbold, October 2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

entity clocks_us_serdes is
	generic(
		CLK_FR_FREQ: real := 125.0;
		CLK_VCO_FREQ: real := 1000.0
	);
	port(
		clki_fr: in std_logic; -- Input free-running clock (125MHz default)
		clki_125: in std_logic; -- Ethernet domain clk125
		clko_ipb: out std_logic; -- ipbus domain clock (31MHz)
		clko_p40: out std_logic; -- pseudo-40MHz clock
		clko_200: out std_logic; -- 200MHz clock for idelayctrl
		eth_locked: in std_logic; -- ethernet locked signal
		locked: out std_logic; -- global locked signal
		nuke: in std_logic; -- hard reset input
		soft_rst: in std_logic; -- soft reset input
		rsto_125: out std_logic; -- clk125 domain reset (held until ethernet locked)
		rsto_ipb: out std_logic; -- ipbus domain reset
		rsto_eth: out std_logic; -- ethernet startup reset (required!)
		rsto_ipb_ctrl: out std_logic; -- ipbus domain reset for controller
		rsto_fr: out std_logic; -- free-running clock domain reset
		onehz: out std_logic -- blinkenlights output
	);

end clocks_us_serdes;

architecture rtl of clocks_us_serdes is
	
	signal dcm_locked, sysclk, clk_ipb_i, clk_ipb_b, clkfb, clk200: std_logic;
	signal clk_p40_i, clk_p40_b: std_logic;
	signal d17, d17_d: std_logic;
	signal nuke_i, nuke_d, nuke_d2, eth_done: std_logic := '0';
	signal rst, srst, rst_ipb, rst_125, rst_ipb_ctrl: std_logic := '1';
	signal rctr: unsigned(3 downto 0) := "0000";
	
begin
	
	sysclk <= clki_fr;

	bufgipb: BUFG port map(
		i => clk_ipb_i,
		o => clk_ipb_b
	);
	
	clko_ipb <= clk_ipb_b;
	
	bufgp40: BUFG port map(
		i => clk_p40_i,
		o => clk_p40_b
	);
	
	clko_p40 <= clk_p40_b;
	
	bufg200: BUFG port map(
		i => clk200,
		o => clko_200
	);
	
	mmcm: MMCME3_BASE
		generic map(
			clkin1_period => CLK_VCO_FREQ / CLK_FR_FREQ,
			clkfbout_mult_f => CLK_VCO_FREQ / CLK_FR_FREQ,
			clkout1_divide => integer(CLK_VCO_FREQ / 31.25),
			clkout2_divide => integer(CLK_VCO_FREQ / 40.00),
			clkout3_divide => integer(CLK_VCO_FREQ / 200.00)
		)
		port map(
			clkin1 => sysclk,
			clkfbin => clkfb,
			clkfbout => clkfb,
			clkout1 => clk_ipb_i,
			clkout2 => clk_p40_i,
			clkout3 => clk200,
			locked => dcm_locked,
			rst => '0',
			pwrdwn => '0'
		);
	
	clkdiv: entity work.ipbus_clock_div
		port map(
			clk => sysclk,
			d17 => d17,
			d28 => onehz
		);
	
	process(sysclk)
	begin
		if rising_edge(sysclk) then
			d17_d <= d17;
			if d17='1' and d17_d='0' then
				rst <= nuke_d2 or not dcm_locked;
				nuke_d <= nuke_i; -- ~1ms time bomb (allows return packet to be sent)
				nuke_d2 <= nuke_d;
				eth_done <= (eth_done or eth_locked) and not rst;
				rsto_eth <= rst; -- delayed reset for ethernet block to avoid startup issues
			end if;
		end if;
	end process;
	
	locked <= dcm_locked;
	srst <= '1' when rctr /= "0000" else '0';
	
	process(clk_ipb_b)
	begin
		if rising_edge(clk_ipb_b) then
			rst_ipb <= rst or srst;
			nuke_i <= nuke;
			if srst = '1' or soft_rst = '1' then
				rctr <= rctr + 1;
			end if;
		end if;
	end process;
	
	rsto_ipb <= rst_ipb;
	
	process(clk_ipb_b)
	begin
		if rising_edge(clk_ipb_b) then
			rst_ipb_ctrl <= rst;
		end if;
	end process;
	
	rsto_ipb_ctrl <= rst_ipb_ctrl;
	
	process(clki_125)
	begin
		if rising_edge(clki_125) then
			rst_125 <= rst or not eth_done;
		end if;
	end process;
	
	rsto_125 <= rst_125;
	
	rsto_fr <= rst;
		
end rtl;