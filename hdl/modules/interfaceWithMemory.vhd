----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/13/2025 11:37:25 AM
-- Design Name: 
-- Module Name: interfaceWithMemory - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interfaceWithMemory is
  generic (
    NumOfBit   : integer                       := 15; -- Width of the input and output vectors
    baseAddr   : std_logic_vector(15 downto 0) := x"4000";
    memory64k  : boolean                       := true;
    memory128k : boolean                       := false;
    memory256k : boolean                       := false
  );
  port (
    clk     : in std_logic; --good
    rst     : in std_logic; --good
    enable  : in std_logic;
    enb     : out std_logic;
    addrb   : out std_logic_vector(31 downto 0); -- good
    dinb    : out std_logic_vector(31 downto 0); --good
    web     : out std_logic_vector(3 downto 0);
    doutB   : in std_logic_vector(31 downto 0);
    --mux_out : out std_logic_vector(4 downto 0);
    Data    : in std_logic_vector(NumOfBit - 1 downto 0)

  );
end interfaceWithMemory;

architecture Behavioral of interfaceWithMemory is
  constant N : integer := 16;
  component UP_COUNTER
    generic (
      N              : integer := 8; -- Width of the input and output vectors
      startOfCounter : integer := 0;
      increment      : integer := 1;
      endCount       : integer := 100
    );
    port (
      clk     : in std_logic; -- clock input
      reset   : in std_logic; -- reset input 
      counter : out std_logic_vector(N - 1 downto 0) -- output 4-bit counter
    );
  end component;
  signal counterAddr : std_logic_vector(20 downto 0);

  signal mux : std_logic_vector(4 downto 0);

  signal clk_sig : std_logic;
begin


  dinb(31 downto NumOfBit) <= (others => '1'); 
  dinb(NumOfBit-1 downto 0) <= data;

  clk_sig <= clk and enable;

  gen64k : if memory64k generate
    addr : UP_COUNTER
    generic map(
      N              => 16,
      startOfCounter => 0,
      increment      => 4,
      endCount       => 65535)
    port map
    (
      clk     => clk_sig,
      reset   => '0',
      counter => counterAddr(15 downto 0)
    );
    addrb <= baseAddr & counterAddr(15 downto 0);
  end generate;
  gen128k : if memory128k generate
    addr : UP_COUNTER
    generic map(
      N              => 17,
      startOfCounter => 0,
      increment      => 4,
      endCount       => 131071)
    port map
    (
      clk     => clk_sig,
      reset   => '0',
      counter => counterAddr(16 downto 0)
    );
    addrb <= baseAddr(15 downto 1) & counterAddr(16 downto 0);
  end generate;
  gen256k : if memory256k generate
    addr : UP_COUNTER
    generic map(
      N              => 18,
      startOfCounter => 0,
      increment      => 4,
      endCount       => 262143)
    port map
    (
      clk     => clk_sig,
      reset   => '0',
      counter => counterAddr(17 downto 0)
    );
    addrb <= baseAddr(15 downto 2) & counterAddr(17 downto 0);
  end generate;

  
  process (enable)
  begin
    if (enable = '1') then
      web <= "1111";
    else
      web <= "0000";
    end if;
  end process;
  enb <= enable;


end Behavioral;