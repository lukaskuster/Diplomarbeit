//
// Created by Quentin Wendegass on 2018-12-31.
//

#ifndef PCM_LIB
#define PCM_LIB

#include <stdint.h>
#include <stdlib.h>

#define PERI_BASE 0x20000000 // Only for raspberry pi zero

/*Uncomment this for raspberry pi 3*/
//#define PERI_BASE 0x3F000000

#define FRAME_SAMPLES 160

/* ioctl commands copied from the driver header */
#define PCM_SET_EN _IOW('i', 0, char)
#define PCM_SET_TXON _IOW('i', 1, char)
#define PCM_SET_RXON _IOW('i', 2, char)
#define PCM_TX_BUFF_SPACE _IOR('i', 3, int)
#define PCM_RX_BUFF_ITEMS _IOR('i', 4, int)
#define PCM_CLEAR_TX_BUFF _IOW('i', 5, char)
#define PCM_CLEAR_RX_BUFF _IOW('i', 6, char)
#define PCM_CLR_TX_FIFO _IOW('i', 15, char)
#define PCM_CLR_RX_FIFO _IOW('i', 16, char)

int start_call(void);
int stop_call();

size_t write_samples(char *);
char *read_samples();

int alloc_clk(void);
int dealloc_clk(void);

void start_clk(void);
void stop_clk(void);

#endif
