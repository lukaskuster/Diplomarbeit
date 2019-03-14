cdef extern from "../../../lib/pcmlib/pcmlib.h":
    int enable_pcm();
    int disable_pcm();
    size_t write_frame(char *);
    char *read_frame();

    void enable_clk();
    void disable_clk();

    int alloc_clk();
    int dealloc_clk();
