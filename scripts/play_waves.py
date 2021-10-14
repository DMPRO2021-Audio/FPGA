import numpy as np
import simpleaudio as sa

sample_rate = 48000 # Hz

# Import generated waves
y = np.genfromtxt("../testbenches/test_output/oscillator.txt", delimiter=",", unpack=True)
x = np.linspace(0, len(y), len(y))
# normalize to 16-bit range
y *= 32767 / np.max(np.abs(y))
# convert to 16-bit data
audio = y.astype(np.int16)

# start playback
play_obj = sa.play_buffer(audio, 1, 2, sample_rate)

# wait for playback to finish before exiting
play_obj.wait_done()