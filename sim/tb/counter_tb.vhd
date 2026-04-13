library IEEE;
use IEEE.STD_LOGIC_1164.all;
--Date: 2025-04-28
--Simple generic counter
--Author fpga4student.com - Modified by Thimote to make it generic
entity tb_counters is
end tb_counters;

architecture Behavioral of tb_counters is

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
  signal reset, clk : std_logic;
  signal counter    : std_logic_vector(15 downto 0);
  signal counter2   : std_logic_vector(5 downto 0);
begin
  dut : UP_COUNTER
  generic map(
    N              => 16,
    startOfCounter => 0,
    increment      => 1,
    endCount       => 65535)
  port map
  (
    clk     => clk,
    reset   => reset,
    counter => counter);
  dut2 : UP_COUNTER
  generic map(
    N              => 6,
    startOfCounter => 0,
    increment      => 1,
    endCount       => 25)
  port map
  (
    clk     => clk,
    reset   => reset,
    counter => counter2);
  -- Clock process definitions
  clock_process : process
  begin
    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;
  end process;
  -- Stimulus process
  stim_proc : process
  begin
    -- hold reset state for 100 ns.
    reset <= '1';
    wait for 20 ns;
    reset <= '0';
    wait for 100 ns;

    reset <= '1';
    wait for 50 ns;
    reset <= '0';
    wait for 100 ns;
    reset <= '1';
    wait for 100 ns;
    reset <= '0';
    wait;
  end process;
end Behavioral;