
----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 11/21/2025 11:26:18 AM
-- Design Name:
-- Module Name: thermoToRam - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created Thimote
-- Additional Comments:
-- Le code est pretty trash, jai trop essayer de recycler mais pour 1 ligne cela fonctionne bien avec 15-16 bits
-- Run tb 
-- cd C:\repo\mems_control_loop\scripts\simScripts
-- source launchAverageToRamTb.tcl
-- cree le Report.txt dans outputs
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all; -- Required for log2 and ceil

entity averageToRam is
  generic (
    numofbit           : integer                       := 9;
    numofline          : integer                       := 20;
    baseaddr           : std_logic_vector(15 downto 0) := x"A000";
    accumulationnumber : integer                       := 2048;
    divisionprecision  : integer                       := 6
  );
  port (
    clk                 : in    std_logic;
    reset               : in    std_logic;
    enable              : in    std_logic;
    encoderdatain       : in    std_logic_vector(numofbit * numofline - 1 downto 0);
    addrb               : out   std_logic_vector(31 downto 0);
    enb                 : out   std_logic;
    web                 : out   std_logic_vector(3 downto 0);
    outencodeddatatoram : out   std_logic_vector(31 downto 0)
  );
end entity averageToRam;

architecture behavioral of averageToRam is

  component up_counter is
    generic (
      n              : integer := 8;
      startofcounter : integer := 0;
      increment      : integer := 1;
      endcount       : integer := 100
    );
    port (
      clk     : in    std_logic;
      reset   : in    std_logic;
      counter : out   std_logic_vector(N - 1 downto 0)
    );
  end component up_counter;

  type statetype is (idle, accumulation, divide, preparetowrite, writetoram);

  signal enable_sig                : std_logic;
  signal present_state, next_state : statetype := idle;

  constant counter_width                  : integer                                      := integer(floor(log2(real(accumulationnumber))));
  constant accumulationnumber_const                  : integer                                      := 2**counter_width;
  signal   accumulationcounter            : std_logic_vector(counter_width - 1 downto 0) := (others => '0');
  signal   accumulation_counter_reset_sig : std_logic                                    := '0';
  signal   enable_accureg                 : std_logic                                    := '0';

  constant addr_max              : integer                      := (numofline - 1) * 4;
  signal   addrcounter           : std_logic_vector(7 downto 0) := (others => '0');
  signal   addrcounter_reset_sig : std_logic                    := '0';

  constant accumulation_reg_width : integer := integer(ceil(log2(real(accumulationnumber)))) + numofbit + 1;

  type regarrayaccumulation is array (0 to numOfLine - 1) of std_logic_vector(accumulation_reg_width - 1 downto 0);

  signal accreg : regarrayaccumulation := (others => (others => '0'));

  constant divide_reg_width : integer := numofbit + divisionprecision;

  type dividereg_type is array (0 to numOfLine - 1) of std_logic_vector(divide_reg_width - 1 downto 0);

  signal divide_reg        : dividereg_type := (others => (others => '0'));
  signal enable_divide_sig : std_logic      := '0';
  signal reset_divide_sig  : std_logic      := '0';
  -- TODO make it cleaner one day

  type decimalinintout is array (0 to numOfLine - 1) of std_logic_vector(19 downto 0);

  signal arrayofdec     : decimalinintout := (others => (others => '0'));
  signal dbg_read_index : integer range 0 to 255;
  -- max number of line 128
  signal read_index_s : integer range 0 to 255;
  signal counterAddr : std_logic_vector(15 downto 0) := (others =>'0');
  signal clk_sig : STD_LOGIC;
begin

  -- State Machine Process (Combinatorial)
  -- Handles Next State Logic and Output Logic
  comb_process : process (present_state, enable, accumulationcounter, addrcounter) is
  begin

    ---------------------------------------------------------
    -- 1. Default Assignments (Prevents Latches)
    ---------------------------------------------------------
    -- Set default next state to stay current (unless overwritten below)
    next_state <= present_state;

    -- Set all control signals to their default/inactive state
    enable_accureg    <= '0';
    enable_sig        <= '0';
    enable_divide_sig <= '0';
clk_sig <= '0';
    -- Default Reset states (Active High based on your logic)
    accumulation_counter_reset_sig <= '1';
    addrcounter_reset_sig          <= '1';
    reset_divide_sig               <= '1';

    ---------------------------------------------------------
    -- 2. State Logic
    ---------------------------------------------------------
    case present_state is

      when idle =>

        -- Wait for toggle to start
        if (enable = '1') then
          next_state <= accumulation;
        end if;

      -- Signals use defaults (All resets active, enables off)

      when accumulation =>

        -- Override defaults for this state
        enable_accureg                 <= '1';
        accumulation_counter_reset_sig <= '0';

        -- Transition Logic
        if (enable = '0') then
          next_state <= idle;
        elsif (unsigned(accumulationcounter) = accumulationnumber_const - 1) then
          next_state <= divide;
        end if;

      when divide =>

        -- Override defaults
        enable_divide_sig              <= '1';
        reset_divide_sig               <= '0';
        accumulation_counter_reset_sig <= '0';
        enable_accureg                 <= '0';
        -- Transition Logic
        next_state <= preparetowrite;

      when preparetowrite =>

        -- Override defaults
        enable_sig <= '1';
        -- addrCounter_reset_sig <= '0';
        reset_divide_sig      <= '0'; -- Kept low from previous state?
        addrcounter_reset_sig <= '0';
        -- Transition Logic
        next_state <= writetoram;

      when writetoram =>

        -- Override defaults
        enable_sig            <= '0';
        addrcounter_reset_sig <= '0';
        reset_divide_sig      <= '0';
        clk_sig <='1';

        -- Transition Logic
        if (enable = '0') then
          next_state <= idle;
        elsif (unsigned(addrcounter) = addr_max) then
          next_state <= idle;
        end if;

      when others =>

        next_state <= idle;

    end case;

  end process comb_process;

  -- State Register Process (Sequential)
  -- Handles clocking and asynchronous reset
  stateprocess : process (clk, reset) is
  begin

    if (reset = '1') then
      present_state <= idle;
    elsif rising_edge(clk) then
      present_state <= next_state;
    end if;

  end process stateprocess;

  -- enable out
  enb <= enable_sig;

  -- counter pour RAM

  -- addr : component up_counter
  --   generic map (
  --     n              => 8,
  --     startofcounter => 0,
  --     increment      => 4,
  --     endcount       => (numofline - 1) * 4
  --   )
  --   port map (
  --     clk     => clk,
  --     reset   => addrcounter_reset_sig,
  --     counter => addrcounter
  --   );

  -- addrb <= baseaddr & (7 downto 0 => '0') & addrcounter;

   -- clk_sig <= enable_sig and clk;
    addr_true : UP_COUNTER
    generic map(
      N              => 16,
      startOfCounter => 0,
      increment      => 4,
      endCount       => 65535)
    port map
    (
      clk     => clk_sig,
      reset   => reset,
      counter => counterAddr(15 downto 0)
    );
    addrb <= baseAddr & counterAddr(15 downto 0);

  data : component up_counter
    generic map (
      n              => COUNTER_WIDTH,
      startofcounter => 0,
      increment      => 1,
      endcount       => accumulationnumber
    )
    port map (
      clk     => clk,
      reset   => accumulation_counter_reset_sig,
      counter => accumulationcounter
    );

  process (enable_sig) is
  begin

    if (enable_sig = '1') then
      web <= "1111";
    else
      web <= "0000";
    end if;

  end process;

  accumproc : process (clk, accumulation_counter_reset_sig) is
  begin

    if (accumulation_counter_reset_sig = '1') then
      accreg <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if (enable_accureg = '1') then

        for i in 0 to numofline - 1 loop

          accreg(i) <= std_logic_vector(resize(unsigned(accreg(i)) +
                                               unsigned(encoderdatain((i * numofbit) + numofbit - 1 downto (i * numofbit))), accreg(i)'length));

        end loop;

      end if;
    end if;

  end process accumproc;

  divideproc : process (clk, reset_divide_sig, enable_divide_sig) is

    -- Define a variable large enough to hold accReg + the added padding
    variable temp_concat : unsigned(accumulation_reg_width + divisionprecision - 1 downto 0);

  begin

    if rising_edge(clk) then
      if (reset_divide_sig = '1') then
        divide_reg <= (others => (others => '0'));
      elsif (enable_divide_sig = '1') then

        for i in 0 to numofline - 1 loop

          temp_concat   := unsigned(accreg(i)) & (divisionprecision - 1 downto 0 => '0');
          divide_reg(i) <= std_logic_vector(resize(
                                                   temp_concat(temp_concat'high downto counter_width),
                                                   divide_reg_width
                                                 ));

        end loop;

      end if;
    end if;

  end process divideproc;

  -- 2. Compute the index continuously (outside any process)
 read_index_s <= TO_INTEGER(unsigned(std_logic_vector'("00" & addrcounter(7 downto 2))));

  -- 3. Assign the debug signal continuously
  dbg_read_index <= read_index_s;


  -- 4. Conditional assignment for the data output
outencodeddatatoram <= (31 downto divide_reg_width => '0') & divide_reg(read_index_s)
                       when enable_sig = '1' else
                       (others => '0');

end architecture behavioral;