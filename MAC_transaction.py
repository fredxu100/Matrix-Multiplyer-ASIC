import random
class Transaction: 

    def __init__(self):
        #INPUTS
        self.ain = 0
        self.bin = 0
        self.rst = 0
        self.en = 1
        #OUTPUTS
        self.a = 0
        self.b = 0
        self.accumulator = 0

    def randomize(self):
        corner_cases = [0, 255] #edge/interesting values
        
        # 40% chance of a corner case, 60% chance of a purely random value
        if random.random() < 0.4:
            self.ain = random.choice(corner_cases)
            self.bin = random.choice(corner_cases)
        else:
            self.ain = random.randint(0, 255)
            self.bin = random.randint(0, 255)

        self.en = random.choices([0, 1], weights=[0.1, 0.9])[0]
        self.rst = random.choices([0, 1], weights=[0.9, 0.1])[0]

    def __str__(self):
        return f"ain={self.ain}, bin={self.bin}, en={self.en}, rst={self.rst}, accumulator={self.accumulator}"