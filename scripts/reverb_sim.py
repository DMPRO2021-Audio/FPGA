from typing import List
import numpy as np
import matplotlib.pyplot as plt

SAMPLE_RATE = 48000
SAMPLE_PERIOD = 1 / SAMPLE_RATE

tau =  [1463 , 1597 , 1836 , 2123 , 249, 143]
gain = [0.902, 0.891, 0.882, 0.871, 0.7, 0.7, 0.5]

def gen_reverb_values(time, t1, amount=0.5):
    """Generate reverb configuration
    
    :param time: Total reverberation time in ms
    :param t1: Initial delay in ms
    """

    tau = np.array([t1, t1*1.19, t1*1.35, t1*1.51, 5.105, 1.5134]) * SAMPLE_RATE / 1000
    tau = list([int(t) for t in tau])
    gain = [10**(-3 * t * 1000 / time / SAMPLE_RATE) for t in tau[0:4]]
    gain.extend([0.7, 0.7, amount])
    gain = list([float(g) for g in gain])
    print("tau", tau, "gain", gain)
    return (tau, gain)


def plot_envelope(envelope):
    x, y = 0, 0
    x_axis = [0]
    y_axis = [0]
    for (r, d) in envelope:
        for i in range(d):
            y += 1
            x = min(2**16-1, x+r) if r > 0 else max(0, x+r)
            x_axis.append(x)
            y_axis.append(y)
    if (r:=envelope[-1][0]) < 0:
        while x > 0:
            x = max(0, x + r)
            y += 1
            x_axis.append(x)
            y_axis.append(y)
    plt.plot(x_axis)
    plt.show()

# tau = t * SAMPLE_RATE
# gains 1-4 = 10 ^ (-3 * tn / T)

# # Reverb for "large room"
# #      30ms   35ms  40ms  45ms  5ms  1.7ms
# tau = [1441 , 1683, 1921, 2159, 241, 83]
# # T = 2000ms
# gain =[0.899, 0.886, 0.871, 0.856, 0.7, 0.7, 0.5]

if __name__ == "__main__":
    plot_envelope([(700, 180), (-130, 250), (-45, 255), (-20, 255), (-10, 255), (-5, 255), (-5, 255), (-20, 255)])
    exit()
    # Reverb for "hall"
    #      62.5ms 70.9ms 81.3ms 93.75ms 5ms 1.7ms
    #tau = [3003, 3403, 3905, 4495, 241, 83]
    # T = 4000ms
    #gain =[0.895, 0.883, 0.867, 0.853, 0.7, 0.7, 0.5]
    tau, gain = gen_reverb_values(1000, 6.3, 0.7)

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

    sig = np.concatenate((np.genfromtxt("./test_output/oscillator-mixer.txt", delimiter=",", unpack=True), np.zeros(SAMPLE_RATE*2)))
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

