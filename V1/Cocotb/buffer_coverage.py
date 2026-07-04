class buffer_coverage:
    
    def __init__(self):
        self.r_en = [0, 1]
        self.w_en = [0, 1]
        self.reg_in = [0, 0xFFFFFFFF]

        self.initial_coverage = len(self.r_en) + len(self.w_en) + len(self.reg_in)

    def sample(self, r_en, w_en, reg_in):
        if r_en in self.r_en:
            self.r_en.remove(r_en)
        if w_en in self.w_en:
            self.w_en.remove(w_en)
        if reg_in in self.reg_in:
            self.reg_in.remove(reg_in)

    def coverage(self):
        self.bins_left = len(self.r_en) + len(self.w_en) + len(self.reg_in)
        self.coverage_percent = (self.initial_coverage - self.bins_left) / self.initial_coverage * 100
        print(f"Coverage {self.coverage_percent:.2f}%")
        #print(f"r_en {self.r_en} | w_en {self.w_en} | reg_in {self.reg_in}")
        return self.coverage_percent
