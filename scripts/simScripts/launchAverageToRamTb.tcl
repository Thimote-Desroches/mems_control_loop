set numberOfLines 4
set numberOfBit 9
set numberOfRepetions 8
set precision 5

# Get the absolute path of the directory containing THIS script
set scriptDir [file normalize [file dirname [info script]]]

# If your script is inside /simScripts, go up one level to reach the root
set projectRoot [file normalize [file join $scriptDir "../.."]]

puts "Project Root: $projectRoot"

# Define your paths based on the project root
set fullPath   [file join $projectRoot "scripts/customTCL" "simScriptAverageToRam.tcl"]
set scriptPython [file join $projectRoot "scripts/pythonScript" "averageGeneration.py"]
set intputFile  [file join $projectRoot "outputs/dataIn" "dataAverage.txt"]
set outPutFile  [file join $projectRoot "outputs/dataOut" "Report.txt"]


# Normalize paths (fixes slashes for Windows/Tcl compatibility)
set fullPath [file normalize $fullPath]
set scriptPython [file normalize $scriptPython]
set intputFile [file normalize $intputFile]
#clear the output file
set outPutFile [file normalize $outPutFile]
set fileId [open $outPutFile "w"]
close $fileId



# 2. Find Python (Ignoring Vivado/Xilinx versions)
set myPython ""
if { [catch {exec where python} locations] } {
    puts "CRITICAL ERROR: Could not find python on this system."
} else {
    set pathList [split $locations "\n"]
    
    foreach p $pathList {
        set p [string trim $p]
        if { $p eq "" } { continue }
        
        # Convert path to lowercase for checking
        set p_lower [string tolower $p]

        # FIX: Search for "vivado" (lowercase) because p_lower is lowercase
        if { [string first "vivado" $p_lower] == -1 && \
             [string first "xilinx" $p_lower] == -1 } {
            
            # Found a clean Python!
            set myPython $p
            break
        }
    }
}
if { [info exists ::env(PYTHONPATH)] } { 
    unset ::env(PYTHONPATH) 
}

if { [info exists ::env(PYTHONHOME)] } { 
    unset ::env(PYTHONHOME) 
}
# 3. Verify and Run Python
if { $myPython eq "" } {
    puts "ERROR: No suitable Python found (skipping Vivado/Xilinx versions)."
} else {
    set myPython [file normalize $myPython]
    puts "Using Python: $myPython"
    puts "Running Script: $scriptPython"

    # EXECUTE PYTHON
    # We catch errors to see output if it fails
    if { [catch { exec "$myPython" "$scriptPython" $numberOfLines $numberOfBit $numberOfRepetions "$intputFile" >@stdout } err] } {
        puts "Python Error/Output: $err"
    } else {
        puts "Python finished successfully."
    }
}


# --- PROCEDURE: wraps one full execution cycle ---
proc run_test_case {lines bits reps prec} {
    # Import global variables so we can use them inside the function
    global myPython scriptPython intputFile outPutFile fullPath

    puts "\n========================================================"
    puts " STARTING RUN: Lines=$lines | Bits=$bits | Reps=$reps"
    puts "========================================================"

    # 2. EXECUTE PYTHON
    # We pass the dynamic filenames to Python so it generates the right data
    if { [catch { exec "$myPython" "$scriptPython" $lines $bits $reps "$intputFile" >@stdout } err] } {
        puts "Python Error: $err"
        return -code error "Python script failed"
    } else {
        puts "Python finished successfully."
    }

    # 3. CLEANUP PREVIOUS SIMULATION
    # The 'catch' allows this to fail silently if no simulation is running
    
    catch { close_sim -force }

    set_property top averageToRam_tb [get_filesets sim_1]
    set_property -name {xsim.simulate.custom_tcl} -value $fullPath -objects [get_filesets sim_1]

    # 5. SET GENERICS
    puts "Setting Simulation Generics..."
    puts $outPutFile
    set_property generic " \
        numofbit=$bits \
        numOfLine=$lines \
        accumulationNumber=$reps \
        inputFile=\"$intputFile\" \
        outputfile=\"$outPutFile\" \
        divisionprecision=\"$prec\" \
    " [get_filesets sim_1]

    launch_simulation 

    # Cleanup property after launch so it doesn't stick forever
    set_property -name {xsim.simulate.custom_tcl} -value {} -objects [get_filesets sim_1]
    
    puts "Run Complete for: Lines=$lines, Bits=$bits"
}


# # Define your scenarios here: { Lines Bits Repetitions }
set test_scenarios {
    {1  16  16 6}
    {1  15  256 6}
    {1  15  256 6}
    {1  15  256 6}}
foreach test $test_scenarios {
    # Unpack the list into variables
    lassign $test l b r p
    
    # Call the function
    run_test_case $l $b $r $p
    after 500
}

after 500
puts "All test cases finished."