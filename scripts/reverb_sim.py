from typing import List
import numpy as np
import matplotlib.pyplot as plt

SAMPLE_RATE = 48000
SAMPLE_PERIOD = 1 / SAMPLE_RATE

tau = [1440, 1600, 1760, 1920, 240, 80]
gain = [0.902, 0.891, 0.882, 0.871, 0.7, 0.7, 0.3]

print(f"Sample rate = {SAMPLE_RATE}Hz (period = {SAMPLE_PERIOD*1000:.2f}ms)")
print("tau values: ", end='')
[print(f"{t} ({t*SAMPLE_PERIOD*1000:.2f} ms) ", end='') for t in tau]
print("")


class CombFilter:
    def __init__(self, tau: int, gain: float) -> None:
        self.fifo: List[float] = [0]*tau
        self.out = 0
        self.gain = gain

    def cycle(self, sigin: float) -> float:
        self.out = self.fifo.pop()
        self.fifo.insert(0, sigin + self.gain * self.out)
        return self.out

class AllpassFilter:
    def __init__(self, tau: int, gain: float) -> None:
        self.fifo: List[float] = [0]*tau
        self.out = 0
        self.gain = gain

    def cycle(self, sigin: float) -> float:
        x = self.fifo.pop()
        self.fifo.insert(0, sigin + self.gain * x)
        self.out = -self.gain * sigin + (1-self.gain**2) * x
        return self.out

combs = list([CombFilter(tau[i], gain[i]) for i in range(4)])
allp0 = AllpassFilter(tau[4], gain[4])
allp1 = AllpassFilter(tau[5], gain[5])

sig = np.concatenate((np.genfromtxt("./test_output/oscillator-mixer.txt", delimiter=",", unpack=True), np.zeros(SAMPLE_RATE*5)))
y = []

for sigin in sig:

    out = allp1.cycle(allp0.cycle(sum(c.cycle(sigin) for c in combs))) * gain[6] + sigin
    y.append(out)

with open("./test_output/oscillator-reverb-py.txt", "w") as f:
	for s in y:
		f.write(f"{s}\n")
x = np.linspace(0, len(y), len(y))
fig = plt.figure(figsize=(12,6))
plt.plot(x,np.array(y),'-')

plt.show()

