//
// Created by Quentin Wendegass on 2018-12-31.
//

#ifndef PCM_LIB
#define PCM_LIB

#include <stdint.h>
#include <stdlib.h>

#ifdef RPIZERO
    #define PERI_BASE 0x20000000 // Only for raspberry pi zero
#else
    #define PERI_BASE 0x3F000000 // Raspberry 3
#endif

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

/**
 * Open the pcm device.
 *
 * :return: file descriptor on success, non-zero error code on error.
 * :since: v0.1.1
 */
int enable_pcm(void);

/**
 * Close the pcm device.
 *
 * :return: 0 on success, non-zero error code on error.
 * :since: v0.1.1
 */
int disable_pcm(void);

/**
 * Write multiple samples to the pcm buffer.
 *
 * :param samples: pointer of 8bit samples
 * :return: number of written bytes, non-zero error code on error.
 * :since: v0.1.1
 */
size_t write_frame(char * samples);

/**
 * Read multiple samples from the pcm buffer.
 *
 * :return: pointer of 8bit samples on success, NULL on error (Error message can be accessed with errno).
 * :since: v0.1.1
 */
char *read_frame(void);

/**
 * Allocate memory for the master clock.
 *
 * :return: 0 on success, non-zero error code on error.
 * :since: v0.1.1
 */
int alloc_clk(void);

/**
 * Free memory for the master clock.
 *
 * :return: 0 on success, non-zero error code on error.
 * :since: v0.1.1
 */
int dealloc_clk(void);

/**
 * Start the master clock.
 *
 * :return: 0 on success, non-zero error code on error.
 * :since: v0.1.1
 */
void enable_clk(void);

/**
 * Stop the master clock.
 *
 * :return: 0 on success, non-zero error code on error.
 * :since: v0.1.1
 */
void disable_clk(void);

#endif
