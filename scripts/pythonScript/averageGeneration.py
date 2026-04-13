import sys
import random
import numpy as np
import math
# 1. Validate argument count (Script name + 4 args = 5 items total)
if len(sys.argv) < 5:
    print("Error: Missing arguments.")
    print("Usage: python generate_data.py <num_lines> <bits_per_line> <repetitions> <file_path>")
    sys.exit(1)


try:
    num_lines = int(sys.argv[1])
    num_bits = int(sys.argv[2])
    num_repetitions = int(sys.argv[3])
    file_path = sys.argv[4]
except ValueError:
    print("Error: The first three arguments must be integers.")
    sys.exit(1)
exponent = math.floor(math.log2(num_repetitions))
# Raise 2 to that exponent

num_repetitions = 2 ** exponent
print(f"Generating file at: {file_path}")
print(f"Configuration: {num_lines} lines x {num_bits} bits, repeated {num_repetitions} times.")
maxValue = 2**num_bits - 1
sigma = 15


mu = random.randint(50-sigma, 2**num_bits-1-50)



values = np.random.normal(mu, sigma, size=(num_lines, num_repetitions)).astype(np.int32)
ave = np.zeros(num_lines)
for i in range(0,len(ave),1):
    ave[i] = np.average(values[i])


clean_data= (values.flatten()).astype(np.float32)

# 'w' means write mode (overwrites file)
with open(file_path, 'w') as f:
    np.savetxt(f, clean_data, fmt='%d')
    np.savetxt(f, ave, fmt='%.6f')

        
