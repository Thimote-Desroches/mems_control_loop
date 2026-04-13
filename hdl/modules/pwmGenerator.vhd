library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--gemini le goat
entity PWM_Dynamic is
    Generic (

        BIT_DEPTH : integer := 32 
    );
    Port (
        clk           : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        
        -- DYNAMIC INPUTS: Driven by other logic, a processor, or switches
        -- Total clock cycles for one PWM period
        period_cycles : in  STD_LOGIC_VECTOR(BIT_DEPTH - 1 downto 0); 
        
        -- Number of clock cycles the signal should stay HIGH
        duty_cycles   : in  STD_LOGIC_VECTOR(BIT_DEPTH - 1 downto 0); 
        
        pwm_out       : out STD_LOGIC
    );
end PWM_Dynamic;

architecture Behavioral of PWM_Dynamic is

    signal counter : unsigned(BIT_DEPTH - 1 downto 0) := (others => '0');

begin

    process(clk, reset)
    begin
        if reset = '0' then
            counter <= (others => '0');
            pwm_out <= '0';
            
        elsif rising_edge(clk) then

            if counter >= unsigned(period_cycles) - 1 then
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;

            if counter < unsigned(duty_cycles) then
                pwm_out <= '1';
            else
                pwm_out <= '0';
            end if;
            
        end if;
    end process;

end Behavioral;