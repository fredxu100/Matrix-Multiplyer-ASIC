class Coverage:
    def __init__(self):
        self.sampled_count = 0
        self.goal = 50 

    def sample(self, tx):
        self.sampled_count += 1

    def get_percentage(self):
        return min(100, (self.sampled_count / self.goal) * 100)