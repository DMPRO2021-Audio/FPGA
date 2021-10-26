import math

min_frequency = 16
sample_frequency = 48000
width = 24 + 8

max_samples_per_period = int(sample_frequency / min_frequency)
max_amplitude = 2**(width-1) - 1

with open("../lookup_tables/sin_lut.txt", 'w+') as file:
    for i in range(max_samples_per_period):
        sample = (math.sin(i * math.pi * 2 / max_samples_per_period)) * max_amplitude
        if(sample < 0):
            file.write(hex(((abs(int(sample)) ^ 0xffffffff) + 1) & 0xffffffff)[2:] + " ")
        else:
            file.write(hex(int(sample))[2:] + " ")

    
    print(f"Generated {max_samples_per_period} samples in '../lookup_tables/sin_lut.txt'")