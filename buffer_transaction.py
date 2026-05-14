import random

class Transaction:

    def __init__(self):
        self.rst = 0
        self.r_en = 1
        self.w_en = 1
        self.reg_in = 0

        self.buffer = 0
        self.reg_out = 0

    def randomize(self):
        corner_cases = [0, 1, 0xFF, 0xFFFF, 0xFFFFFF, 0xFFFFFFFF]

        if random.random() < 0.05:
            self.reg_in = random.choice(corner_cases)
        else:
            self.reg_in = random.randint(0, 0xFFFFFFFF)

        self.r_en = random.choices([0, 1], weights=[0.25, 0.75])[0]
        self.w_en = random.choices([0, 1], weights=[0.25, 0.75])[0]
        self.rst = random.choices([0, 1], weights=[0.95, 0.05])[0]

    def display(self):
        """Prints the current state of the transaction."""
        print(f"  Inputs:  rst={self.rst} | r_en={self.r_en} | w_en={self.w_en} | reg_in=0x{self.reg_in:08X}")
        print(f"  Outputs: buffer=0x{self.buffer:08X} | reg_out=0x{self.reg_out:08X}")
        