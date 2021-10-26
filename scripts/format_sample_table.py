import matplotlib.pyplot as plt
import numpy as np
import math

"""
    Input is a file of samples for example exported from
    audacity. The input file contains signed values representing the wave
    This script upsacales the sample to 3000 samples using linea interpolation
    and scales the amplitude of the wave to fit in 32 signed bits
"""

input_file = "../lookup_tables/sample-data2.txt"
output_file = "../lookup_tables/piano_lut.txt"

width = 24 + 8
max_amplitude = 2**(width-1) - 1
n_target_samples = 3000

y = np.genfromtxt(input_file, delimiter=",", unpack=True)

n_samples = len(y)

y = y * max_amplitude / max(abs(y))

with open(output_file, 'w+') as file:
    for i in range(n_target_samples):
        # Upscaling the sample and using linear interpolation
        s1 = int(y[math.floor(i * n_samples / n_target_samples)])
        
        # Select the next sample differently if it is the last sample
        if(math.floor(i * n_samples / n_target_samples) < n_samples-1):
            s2 = int(y[math.floor(i * n_samples / n_target_samples) + 1])
        else:
            s2 = int(y[0])
        
        weight = (i * n_samples / n_target_samples) % 1
        sample = s1 * (1 - weight) + s2 * weight
        print(sample)
        if(sample < 0):
            file.write(hex(((abs(int(sample)) ^ 0xffffffff) + 1) & 0xffffffff)[2:] + " ")
        else:
            file.write(hex(int(sample))[2:] + " ")