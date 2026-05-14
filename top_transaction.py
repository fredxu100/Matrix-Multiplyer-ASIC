import random
 
 
class Transaction:
    # Number of words driven per transaction (one per buffer)
    NUM_WORDS = 8
 
    # Bit-width of each word
    WORD_BITS = 32
    WORD_MASK = (1 << WORD_BITS) - 1
 
    def __init__(self):
        # Raw 32-bit words driven onto `data` with cpu_store_signal
        # data_words[0] → buffer_0 (LSB of total_bus), …, data_words[7] → buffer_7
        self.data_words: list[int] = [0] * self.NUM_WORDS

 
    def randomize(self, max_val: int = 0xFF):
        """Fill every word with an independent random value in [0, max_val]."""
        self.data_words = [random.randint(0, max_val) for _ in range(self.NUM_WORDS)]
 
 
    def get_pe_inputs(self) -> tuple[list[int], list[int]]:

        a_in = [int(w) & self.WORD_MASK for w in self.data_words[0:4]]
        b_in = [int(w) & self.WORD_MASK for w in self.data_words[4:8]]
        return a_in, b_in
 
    def __repr__(self) -> str:
        a, b = self.get_pe_inputs()
        return (
            f"Transaction(\n"
            f"  data_words = {[hex(w) for w in self.data_words]}\n"
            f"  bus_a (a_in) = {[hex(v) for v in a]}\n"
            f"  bus_b (b_in) = {[hex(v) for v in b]}\n"
            f")"
        )