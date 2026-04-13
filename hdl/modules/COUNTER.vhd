library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;
--Date: 2025-04-28
--Simple generic counter
--Author fpga4student.com - Modified by Thimote to make it generic

entity UP_COUNTER is
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
end UP_COUNTER;

architecture Behavioral of UP_COUNTER is
  signal counter_up : integer := 0;
begin
  -- up counter
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1') then
        counter_up <= startOfCounter;
      else
        if counter_up >= endCount then
          counter_up <= startOfCounter;
        else
          counter_up <= counter_up + increment;
        end if;

      end if;
    end if;
  end process;
  
  counter <= std_logic_vector(to_unsigned(counter_up, N));

end Behavioral;