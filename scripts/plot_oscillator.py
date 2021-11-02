import matplotlib.pyplot as plt
import numpy as np
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "./test_output/oscillator.txt"
y = np.genfromtxt(path, delimiter=",", unpack=True)
x = np.linspace(0, len(y), len(y))

fig = plt.figure(figsize=(12,6))
plt.plot(x,y,'-')

plt.show()
