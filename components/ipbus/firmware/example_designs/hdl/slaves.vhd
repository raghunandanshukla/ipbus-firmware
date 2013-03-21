-- The ipbus slaves live in this entity - modify according to requirements
--
-- Ports can be added to give ipbus slaves access to the chip top level.
--
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.ALL;
use work.emac_hostbus_decl.all;

entity slaves is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		hostbus_out: out emac_hostbus_in;
		hostbus_in: in emac_hostbus_out;
		rst_out: out std_logic;
		eth_err_ctrl: out std_logic_vector(35 downto 0);
		eth_err_stat: in std_logic_vector(47 downto 0) := X"000000000000"
	);

end slaves;

architecture rtl of slaves is

	constant NSLV: positive := 4;
	signal ipbw: ipb_wbus_array(NSLV-1 downto 0);
	signal ipbr, ipbr_d: ipb_rbus_array(NSLV-1 downto 0);
	signal ctrl_reg: std_logic_vector(31 downto 0);
	signal inj_ctrl: std_logic_vector(63 downto 0);

begin

  fabric: entity work.ipbus_fabric
    generic map(NSLV => NSLV)
    port map(
      ipb_clk => ipb_clk,
      rst => ipb_rst,
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Slave 0: id / rst reg

	slave0: entity work.ipbus_ctrlreg
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(0),
			ipbus_out => ipbr(0),
			d => X"abcdfedc",
			q => ctrl_reg
		);
		
		rst_out <= ctrl_reg(0);

-- Slave 1: register

	slave1: entity work.ipbus_reg
		generic map(addr_width => 0)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(1),
			ipbus_out => ipbr(1),
			q => open
		);
			
-- Slave 2: 1kword RAM

	slave2: entity work.ipbus_ram
		generic map(addr_width => 10)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(2),
			ipbus_out => ipbr(2)
		);
			
-- Slave 3: ethernet error injection

	slave3: entity work.ipbus_ctrlreg
		generic map(
			ctrl_addr_width => 1,
			stat_addr_width => 1
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(3),
			ipbus_out => ipbr(3),
			d => X"00" & eth_err_stat(47 downto 24) & X"00" & eth_err_stat(23 downto 0),
			q => inj_ctrl
		);
		
	eth_err_ctrl <= inj_ctrl(49 downto 32) & inj_ctrl(17 downto 0);

-- Dummy ethernet MAC control signals

	hostbus_out.hostclk <= '0';
	hostbus_out.hostopcode <= (others => '0');
	hostbus_out.hostaddr <= (others => '0');
	hostbus_out.hostwrdata <= (others => '0');
	hostbus_out.hostmiimsel <= '0';
	hostbus_out.hostreq <= '0';
	hostbus_out.hostemac1sel <= '0';
			
end rtl;
