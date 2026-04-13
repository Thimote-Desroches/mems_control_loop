
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interfaceWithMemory_tb is
end;

architecture bench of interfaceWithMemory_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  constant NumOfBit : integer := 16;
  constant baseAddr : std_logic_vector(15 downto 0) := x"4000";
  constant memory64k : boolean := true;
  constant memory128k : boolean := false;
  constant memory256k : boolean := false;
  -- Ports
  signal clk : std_logic :='0';
  signal rst : std_logic:='0';
  signal enable : std_logic:='0';
  signal enb : std_logic:='0';
  signal addrb : std_logic_vector(31 downto 0):= (others => '0');
  signal dinb : std_logic_vector(31 downto 0):= (others => '0');
  signal web : std_logic_vector(3 downto 0);
  signal doutB : std_logic_vector(31 downto 0);
  --signal mux_out : std_logic_vector(4 downto 0);
  signal Data : std_logic_vector(NumOfBit - 1 downto 0) := (others => '0');
begin

  interfaceWithMemory_inst : entity work.interfaceWithMemory
  generic map (
    NumOfBit => NumOfBit,
    baseAddr => baseAddr,
    memory64k => memory64k,
    memory128k => memory128k,
    memory256k => memory256k
  )
  port map (
    clk => clk,
    rst => rst,
    enable => enable,
    enb => enb,
    addrb => addrb,
    dinb => dinb,
    web => web,
    doutB => doutB,
    --mux_out => mux_out,
    Data => Data
  );
 clk <= not clk after clk_period/2;


 main_proc:process
 begin

  wait for 5*clk_period;
  rst<= '1';
  wait for 5*clk_period;
  enable <= '1';
  wait for 5*clk_period;
    rst<= '0';
  wait for 5*clk_period;

  wait;



  end process;

end;