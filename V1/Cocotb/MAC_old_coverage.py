from cocotb_coverage.coverage import CoverPoint, CoverCross, coverage_db

class MAC_coverage:
    def __init__(self):
        # We don't need to define anything in __init__ for decorators!
        pass

    # --- Cover Points ---

    @CoverPoint("top.ain", 
                #xf = lambda self, ain: ain, 
                bins = [0, 255])
    def _sample_ain(self, ain):
        pass

    @CoverPoint("top.bin", 
                #xf = lambda self, bin: bin, 
                bins = [0, 255])
    def _sample_bin(self, bin):
        pass

    @CoverPoint("top.acc", 
                #xf = lambda self, acc: acc, 
                bins = [0, 510])
    def _sample_acc(self, acc):
        pass

    @CoverPoint("top.en", 
                #xf = lambda self, en: en, 
                bins = [0, 1])
    def _sample_en(self, en):
        pass

    @CoverPoint("top.rst", 
                #xf = lambda self, rst: rst, 
                bins = [0, 1])
    def _sample_rst(self, rst):
        pass

    # --- Cross Coverage ---
    # Decorators handle crosses by referencing the string names of the points
    '''@CoverCross("top.inputs_max", 
                items = ["top.ain", "top.bin", "top.en", "top.rst"])
    def _sample_cross(self, ain, bin, en, rst):
        pass'''

    def sample(self, ain, bin, acc, en, rst):
        """ This method triggers all the decorated functions """
        # Cast to int once here for all points
        a, b, ac, e, r = int(ain), int(bin), int(acc), int(en), int(rst)
        
        self._sample_ain(a)
        self._sample_bin(b)
        self._sample_acc(ac)
        self._sample_en(e)
        self._sample_rst(r)
        
        # Trigger the cross
        #self._sample_cross(a, b, e, r)
        
        print(f"Total Coverage: {self.get_coverage()}%")

    def get_coverage(self):
        if "top" in coverage_db:
            # Instead of drilling down through .nodes, we access points
            # directly from the database using their full path names.
            
            # We use .get() to return None if the point hasn't been hit yet 
            # to prevent "KeyError" crashes.
            acc_node = coverage_db.get("top.acc")
            ain_node = coverage_db.get("top.ain")
            bin_node = coverage_db.get("top.bin")
            rst_node = coverage_db.get("top.rst")
            en_node  = coverage_db.get("top.en")

            # Extract coverage % if node exists, else 0
            acc_cov = acc_node.coverage if acc_node else 0
            ain_cov = ain_node.coverage if ain_node else 0
            bin_cov = bin_node.coverage if bin_node else 0
            rst_cov = rst_node.coverage if rst_node else 0
            en_cov  = en_node.coverage  if en_node  else 0

            print(f"ACC {acc_cov}% | Ain {ain_cov}% | Bin {bin_cov}% | Rst {rst_cov}% | En {en_cov}%")
            
            return coverage_db["top"].coverage
        
        return 0