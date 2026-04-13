library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;
  use ieee.std_logic_textio.all;
  use ieee.math_real.all; 
entity averageToRam_tb is
  -- Define the generic to hold the environment variable value
  generic (
    inputfile          : string  := "dataAverage.txt";
    outputfile         : string  := "outAverage.txt";
    numofbit           : integer := 9;
    numofline          : integer := 20;
    accumulationnumber : integer := 2048;
    divisionprecision  : integer := 5
  );
end entity averageToRam_tb;

architecture bench of averageToRam_tb is

  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant baseaddr : std_logic_vector(15 downto 0) := x"A000";

  -- Ports
  signal clk_tb                 : std_logic                                           := '0';
  signal reset_tb               : std_logic                                           := '0';
  signal enable_tb              : std_logic                                           := '0';
  signal encoderdatain_tb       : std_logic_vector(numofbit * numofline - 1 downto 0) := (others => '0');
  signal addrb_tb               : std_logic_vector(31 downto 0)                       := (others => '0');
  signal enb_tb                 : std_logic                                           := '0';
  signal web_tb                 : std_logic_vector(3 downto 0)                        := (others => '0');
  signal outencodeddatatoram_tb : std_logic_vector(31 downto 0)                       := (others => '0');

  subtype t_data_vector is std_logic_vector(numOfBit - 1 downto 0);

  type t_accumulation_row is array (0 to accumulationNumber - 1) of t_data_vector;

  type t_regarrayaccumulation is array (0 to numOfLine - 1) of t_accumulation_row;

  type real_array is array(0 to numOfLine - 1) of real;

  signal expected_values : real_array;
  signal my_2d_array     : t_regarrayaccumulation;
    signal actualAcumulation : integer;
  -- Declaration du type

  type mem_type is array (0 to numOfLine - 1) of std_logic_vector(31 downto 0);

  signal ram_model : mem_type := (others => x"00000000");

  signal wholepartsent   : std_logic_vector(8 downto 0);
  signal decimalpartsent : std_logic_vector(19 downto 0);
 signal dbg_read_index_out : std_logic_vector(7 downto 0);
  procedure print_ram_fixed_to_file (
    constant file_path        : in string; -- NEW: The path to the file
    signal ram_data           : in mem_type;
    signal expected_valuesarr : in real_array;
    constant frac_width       : in integer
  ) is

    -- File handling variables
    file     file_handler : text;
    variable file_status  : file_open_status;

    -- Existing variables
    variable row_val        : real;
    variable scaling_factor : real;
    variable val            : std_logic_vector(31 downto 0);
    variable real_converted : real;
    variable wholepart      : integer;
    variable decimalpart    : integer;
    variable l              : line;
    variable header         : line;

  begin

    -- 1. Open the file in APPEND mode
    -- This keeps existing content and adds new content to the end.
    file_open(file_status, file_handler, file_path, append_mode);

    -- Safety check to ensure file opened correctly
    assert file_status = open_ok
      report "Error: Could not open file " & file_path
      severity failure;

    -- 2. Create the first line
    write(header, string'("--- RAM Content -- Expected values -- Difference"));
    writeline(file_handler, header); -- WRITELINE to file_handler, not output

    -- 3. Create the second line
    write(header, string'("Number of bits: "));
    write(header, numOfBit);
    writeline(file_handler, header);

    -- 4. Create the third line
    write(header, string'("Number of lines: "));
    write(header, numOfLine);
    writeline(file_handler, header);

    -- 5. Create the fourth line
    write(header, string'("Asked repetitions: "));
    write(header, accumulationNumber);
    writeline(file_handler, header);

    write(header, string'("Acutal repetitions: "));
    write(header, 2 ** integer(floor(log2(real(accumulationnumber)))));
    writeline(file_handler, header);
        -- 5. Create the fourth line
    write(header, string'("Precision :"));
    write(header, divisionprecision);
    writeline(file_handler, header);

    scaling_factor := 2.0 ** (divisionprecision);

    for i in 0 to numOfLine - 1 loop

      val         := ram_data(i);
      wholepart   := to_integer(unsigned(val(31 downto frac_width + 1)));
      decimalpart := to_integer(unsigned(val(frac_width downto 0)));

      -- Note: You are using 1000000.0 here, but calculating scaling_factor above.
      -- Ensure this math matches your fixed-point logic.
      real_converted := real(to_integer(unsigned(val))) / scaling_factor;

      -- Construction du message
      write(l, string'("Addr "));
      write(l, i);
      write(l, string'(": "));
      write(l, real_converted, right, 12, 6);

      write(l, string'(" -- Expected: "));
      write(l, expected_valuesarr(i), right, 12, 6);

      write(l, string'(" -- Diff: "));
      write(l, (real_converted - expected_valuesarr(i)), right, 12, 6);
      write(l, string'(" -- "));
      hwrite(l, ram_data(i));
      writeline(file_handler, l); -- Write line to file

    end loop;

    -- To print the separator to the file, use write/writeline (report only goes to console)
    write(l, string'("---------------------------------------"));
    writeline(file_handler, l);

    -- 6. Close the file
    file_close(file_handler);

  end procedure print_ram_fixed_to_file;

  procedure print_ram_fixed (
    signal ram_data           : in mem_type;
    signal expected_valuesarr : in real_array;
    constant frac_width       : in integer -- Number of bits after the comma
  ) is

    variable row_val        : real;
    variable scaling_factor : real;
    variable val            : std_logic_vector(31 downto 0);
    variable real_converted : real;
    variable wholepart      : integer;
    variable decimalpart    : integer;
    variable l              : line;
    variable header         : line;

  begin

    -- 1. Create the first line
    write(header, string'("--- RAM Content -- Expected values -- Difference"));
    writeline(output, header); -- This prints the line and clears the 'header' variable

    -- 2. Create the second line
    write(header, string'("Number of bits: ")); -- Note the space at the end for formatting
    write(header, numOfBit);
    writeline(output, header);                  -- Print and clear

    -- 3. Create the third line
    write(header, string'("Number of lines: "));
    write(header, numOfLine);
    writeline(output, header); -- Print and clear

    -- 4. Create the fourth line
    write(header, string'("Number of repetitions: "));
    write(header, accumulationNumber);
    writeline(output, header); -- Print and clear
    scaling_factor := 2.0 ** (frac_width + 1);

    for i in 0 to numOfLine - 1 loop

      val            := ram_data(i);
      wholepart      := to_integer(unsigned(val(31 downto frac_width + 1)));
      decimalpart    := to_integer(unsigned(val(frac_width downto 0)));
      real_converted := real(wholepart) + real(decimalpart) / 1000000.0;
      -- Construction du message
      write(l, string'("Addr "));
      write(l, i);
      write(l, string'(": "));
      write(l, real_converted, right, 12, 6);

      write(l, string'(" -- Expected: "));
      write(l, expected_valuesarr(i), right, 12, 6);

      write(l, string'(" -- Diff: "));
      write(l, (real_converted - expected_valuesarr(i)), right, 12, 6);

      writeline(output, l);

    end loop;

    report "---------------------------------------";

  end procedure print_ram_fixed;

begin

  uut : entity work.averagetoram
    generic map (
      numofbit           => numofbit,
      numofline          => numofline,
      baseaddr           => baseAddr,
      accumulationnumber => accumulationnumber,
      divisionprecision  => divisionPrecision
    )
    port map (
      clk                 => clk_tb,
      reset               => reset_tb,
      enable              => enable_tb,
      encoderdatain       => encoderdatain_tb,
      addrb               => addrb_tb,
      enb                 => enb_tb,
      web                 => web_tb,
      outencodeddatatoram => outencodeddatatoram_tb
    );

  clk_tb <= not clk_tb after clk_period / 2;

  wholepartsent   <= outencodeddatatoram_tb(28 downto 20);
  decimalpartsent <= outencodeddatatoram_tb(19 downto 0);

  -- Read/Write Process (RAM Model Simulation)
  ram_access_process : process (addrb_tb, enable_tb, clk_tb) is

    -- Local variable for address
    variable address_int : natural;

  begin

    -- Decode UUT address to access RAM model
    address_int := to_integer(unsigned(addrb_tb(15 downto 0)));
    address_int := address_int / 4;

    if rising_edge(clk_tb) then
      if (enb_tb = '1') then
        if (web_tb /= "0000") then -- Write condition (simplified)
          -- Simulate write
          ram_model(address_int) <= outencodeddatatoram_tb;
        else
        -- Simulate read (if needed)
        -- data_read_from_ram <= RAM_MODEL(address_int);
        end if;
      end if;
    end if;

  end process ram_access_process;

  mainproc : process is

    -- 1. Declare the file object
    file file_pointer : text;

    -- 2. Variables for reading
    variable line_content : line;
    variable v_delay      : integer;
    variable value        : integer;
    variable v_space      : character;
    variable real_v       : real;


  begin
    actualAcumulation <= 2 ** integer(floor(log2(real(accumulationnumber))));
    wait for clk_period * 5;
    file_open(file_pointer, inputfile, read_mode);

    readfile : for i in 0 to numofline - 1 loop

      readdata : for j in 0 to actualAcumulation - 1 loop

        readline(file_pointer, line_content);
        read(line_content, value);
        my_2d_array(i)(j) <= std_logic_vector(to_unsigned(value, my_2d_array(0)(0)'length));

      end loop readdata;

    end loop readfile;

    readexpected_values : for i in 0 to numofline - 1 loop

      readline(file_pointer, line_content);
      read(line_content, real_v);
      expected_values(i) <= real_v;

    end loop readexpected_values;

    wait for clk_period * 5;
    enable_tb <= '1';
    reset_tb  <= '1';
    wait for clk_period;

    for j in 0 to actualAcumulation - 1 loop

      for i in 0 to numofline - 1 loop

        encoderdatain_tb(i * numofbit + numofbit - 1 downto i * numofbit) <= my_2d_array(i)(j);

      end loop;

      wait for clk_period;

    end loop;

    wait for clk_period * (3 + numofline);

    print_ram_fixed(ram_model, expected_values, 19);
    print_ram_fixed_to_file(outputfile, ram_model, expected_values, 19);
    enable_tb <= '0';
    reset_tb  <= '0';
    wait;

  end process mainproc;

end architecture bench;
