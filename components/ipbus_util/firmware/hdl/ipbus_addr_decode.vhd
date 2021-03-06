---------------------------------------------------------------------------------
--
--   Copyright 2017 - Rutherford Appleton Laboratory and University of Bristol
--
--   Licensed under the Apache License, Version 2.0 (the "License");
--   you may not use this file except in compliance with the License.
--   You may obtain a copy of the License at
--
--       http://www.apache.org/licenses/LICENSE-2.0
--
--   Unless required by applicable law or agreed to in writing, software
--   distributed under the License is distributed on an "AS IS" BASIS,
--   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--   See the License for the specific language governing permissions and
--   limitations under the License.
--
--                                     - - -
--
--   Additional information about ipbus-firmare and the list of ipbus-firmware
--   contacts are available at
--
--       https://ipbus.web.cern.ch/ipbus
--
---------------------------------------------------------------------------------


-- Address decode logic for ipbus fabric
--
-- This file has been AUTOGENERATED from the address table - do not hand edit
--
-- We assume the synthesis tool is clever enough to recognise exclusive conditions
-- in the if statement.
--
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.ipbus.all;

package ipbus_addr_decode is

  function ipbus_addr_sel(signal addr : in std_logic_vector(31 downto 0)) return integer;

end ipbus_addr_decode;

package body ipbus_addr_decode is
  
  function ipbus_addr_sel(signal addr : in std_logic_vector(31 downto 0)) return integer is
    variable sel : integer;
  begin
                -- START automatically  generated VHDL the Tue Jul  9 16:49:55 2013 
		if    std_match(addr, "------------------00--------000-") then
			sel := 0; -- ctrl_reg / base 0x00000000 / mask 0x0000300e
		elsif std_match(addr, "------------------00--------001-") then
			sel := 1; -- reg / base 0x00000002 / mask 0x0000300e
		elsif std_match(addr, "------------------00--------01--") then
			sel := 2; -- err_inject / base 0x00000004 / mask 0x0000300e
		elsif std_match(addr, "------------------00--------100-") then
			sel := 3; -- pkt_ctr / base 0x00000008 / mask 0x0000300e
		elsif std_match(addr, "------------------01------------") then
			sel := 4; -- ram / base 0x00001000 / mask 0x0000300e
		elsif std_match(addr, "------------------10--------000-") then
			sel := 5; -- pram / base 0x00002000 / mask 0x0000300e
		-- END automatic generated VHDL

                else
                        sel := 6;
                end if;
                return sel;
  end ipbus_addr_sel;
                
end ipbus_addr_decode;

