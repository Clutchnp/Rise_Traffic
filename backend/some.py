import time
from sim import TrafficSimulator

sim = TrafficSimulator()

while True:
    data = sim.update()

    print("\n-------------------")

    for item in data:
        print(item)

    time.sleep(5)
