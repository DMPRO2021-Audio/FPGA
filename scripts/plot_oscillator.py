import matplotlib.pyplot as plt
import numpy as np

y = np.genfromtxt("./test_output/oscillator.txt", delimiter=",", unpack=True)
x = np.linspace(0, len(y), len(y))

fig = plt.figure(figsize=(12,6))
plt.plot(x,y,'-')

plt.show()
