class MAC_coverage:
    def __init__(self):
        self.ain = [0, 1, 254, 255]
        self.bin = [0, 1, 254, 255]
        self.en = [0, 1]
        self.rst = [0, 1]
        self.acc = [0, 65025]

        self.initial_coverage = len(self.ain) + len(self.bin) + len(self.en) + len(self.rst) + len(self.acc)

    def sample(self, ain, bin, en, rst, acc):
        if ain in self.ain:
            self.ain.remove(ain)
        if bin in self.bin:
            self.bin.remove(bin)
        if en in self.en:
            self.en.remove(en)
        if rst in self.rst:
            self.rst.remove(rst)
        if acc in self.acc:
            self.acc.remove(acc)
    
    def coverage(self):
        self.bins_left = len(self.ain) + len(self.bin) + len(self.en) + len(self.rst) + len(self.acc)
        self.coverage_percent = (self.initial_coverage - self.bins_left)/ self.initial_coverage * 100
        print(f"Coverage {self.coverage_percent:.2f}%")
        #print(f"Acc {self.acc}")
        return self.coverage_percent

        