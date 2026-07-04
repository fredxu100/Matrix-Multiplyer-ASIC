import random

class Transaction:

    def __init__(self):
        self.rst = 0
        self.en = 0
        self.a = [0] * 16
        self.b = [0] * 16

        self.results = [[0 for _ in range(16)] for _ in range(16)]

    def randomize(self):
        corner_cases = [0, 1, 244, 255]

        for i in range(16):
            if random.random() < 0.05:
                self.a[i] = random.choice(corner_cases)
                self.b[i] = random.choice(corner_cases)
            else:
                self.a[i] = random.randint(0, 255)
                self.b[i] = random.randint(0, 255)

        self.en = random.choices([0, 1], weights=[0.25, 0.75])[0]
        self.rst = random.choices([0, 1], weights=[0.95, 0.05])[0]
   
    def display(self):
        print(f"Inputs:  rst={self.rst} | en={self.en}")
        print(f"a: {self.a}")
        print(f"b: {self.b}")
        print(f"Results (Partial 2x2): {[row[:2] for row in self.results[:2]]}")