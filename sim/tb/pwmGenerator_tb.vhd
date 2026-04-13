library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_PWM_Dynamic is
-- Testbench entities do not have ports
end tb_PWM_Dynamic;

architecture Behavioral of tb_PWM_Dynamic is

    -- 1. Component Declaration for the Unit Under Test (UUT)
    component PWM_Dynamic
        Generic (
            BIT_DEPTH : integer := 32 
        );
        Port (
            clk           : in  STD_LOGIC;
            reset         : in  STD_LOGIC;
            period_cycles : in  STD_LOGIC_VECTOR(BIT_DEPTH - 1 downto 0); 
            duty_cycles   : in  STD_LOGIC_VECTOR(BIT_DEPTH - 1 downto 0); 
            pwm_out       : out STD_LOGIC
        );
    end component;

    -- 2. Constants Configuration
    constant C_BIT_DEPTH : integer := 32;
    constant CLK_PERIOD  : time := 10 ns; -- Simulating a 100 MHz clock

    -- 3. Signal Declarations (Mapped to UUT ports)
    signal clk_tb           : std_logic := '0';
    signal reset_tb         : std_logic := '1'; -- Start in reset
    signal period_cycles_tb : std_logic_vector(C_BIT_DEPTH - 1 downto 0) := (others => '0');
    signal duty_cycles_tb   : std_logic_vector(C_BIT_DEPTH - 1 downto 0) := (others => '0');
    signal pwm_out_tb       : std_logic;

begin

    -- 4. Instantiate the Unit Under Test (UUT)
    uut: PWM_Dynamic 
        Generic map (
            BIT_DEPTH => C_BIT_DEPTH
        )
        Port map (
            clk           => clk_tb,
            reset         => reset_tb,
            period_cycles => period_cycles_tb,
            duty_cycles   => duty_cycles_tb,
            pwm_out       => pwm_out_tb
        );

    -- 5. Clock Generation Process
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;
        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- 6. Stimulus Process (The actual tests)
    stimulus_process: process
    begin       
        -- --- INITIALIZATION & RESET ---
        -- Hold reset for a few clock cycles
        reset_tb <= '1';
        
        -- Pre-load inputs: Period = 100 cycles, Duty = 25 cycles (25% Duty Cycle) (100 *1/100Mhz) = 
        period_cycles_tb <= std_logic_vector(to_unsigned(100, C_BIT_DEPTH)); 
        duty_cycles_tb   <= std_logic_vector(to_unsigned(25, C_BIT_DEPTH));  
        wait for CLK_PERIOD * 5;  
        
        -- Release reset
        reset_tb <= '0';
        
        -- --- TEST CASE 1: Baseline (25% Duty Cycle) ---
        -- Wait for 2.5 full PWM periods to observe stable operation
        wait for CLK_PERIOD * 250; 

        -- --- TEST CASE 2: Dynamic Duty Cycle Change (75%) ---
        -- Change duty cycle on the fly while keeping the period the same
        duty_cycles_tb <= std_logic_vector(to_unsigned(75, C_BIT_DEPTH));
        wait for CLK_PERIOD * 200;

        -- --- TEST CASE 3: Dynamic Frequency & Duty Cycle Change ---
        -- Cut the period in half (faster frequency) and set to 50% duty cycle
        period_cycles_tb <= std_logic_vector(to_unsigned(50, C_BIT_DEPTH));
        duty_cycles_tb   <= std_logic_vector(to_unsigned(25, C_BIT_DEPTH));
        wait for CLK_PERIOD * 150;

        -- --- TEST CASE 4: 0% Duty Cycle (Always Low) ---
        duty_cycles_tb <= std_logic_vector(to_unsigned(0, C_BIT_DEPTH));
        wait for CLK_PERIOD * 100;

        -- --- TEST CASE 5: 100% Duty Cycle (Always High) ---
        -- Setting duty cycles >= period cycles should result in a constant high output
        duty_cycles_tb <= std_logic_vector(to_unsigned(50, C_BIT_DEPTH));
        wait for CLK_PERIOD * 150;
        
        -- End of simulation. This wait statement stops the process from looping.
        wait;
    end process;

end Behavioral;