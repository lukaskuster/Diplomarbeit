//
// Created by Quentin Wendegass on 2018-12-28.
//

#ifndef BCM2835_PCM_DRIVER
#define BCM2835_PCM_DRIVER

#include <linux/ioctl.h>

/*
 * Declarations for ioctl macros
 * */
#define PCM_SET_EN _IOW('i', 0, char)
#define PCM_SET_TXON _IOW('i', 1, char)
#define PCM_SET_RXON _IOW('i', 2, char)
#define PCM_TX_BUFF_SPACE _IOR('i', 3, int)
#define PCM_RX_BUFF_ITEMS _IOR('i', 4, int)
#define PCM_CLEAR_TX_BUFF _IOW('i', 5, char)
#define PCM_CLEAR_RX_BUFF _IOW('i', 6, char)
#define PCM_CLR_TX_FIFO _IOW('i', 15, char)
#define PCM_CLR_RX_FIFO _IOW('i', 16, char)

#define DEVICE_NAME "bcm2835_pcm"

/*
 * Switch these depending on which version of the Raspberry you are using .
 */
#define RPIZERO // For Raspberry Pi Zero
// #define RPITHREE   // For Raspberry Pi 3

/*
 * Switch this to the desired mode.
 * In master mode the pcm clock must be configured separately.
 */
#define MASTER
//#define SLAVE

/*
 * Defines Address and the interrupt number associated with the I2S interface.
 * Address and the interrupt number is different for rpi zero and 3.
 * */
#ifdef RPIZERO
#define PCM_INTERRUPT 79
#define PI_PERIPHERAL_BASE 0x20000000
#endif

#ifdef RPITHREE
#define PI_PERIPHERAL_BASE 0x3F000000
#define PCM_INTERRUPT 85
#endif

// PCM Register
#define PCM_OFFSET 0x00203000
#define PCM_BASE PI_PERIPHERAL_BASE + PCM_OFFSET
#define PCM_SIZE 0x24 // Number of bytes used by the I2S registers

/* For memory mapping the pcm register */
typedef struct pcm_map
{
    uint32_t CS_A;     // Control and status
    uint32_t FIFO_A;   // FIFO data
    uint32_t MODE_A;   // Mode control
    uint32_t RXC_A;    // Receive config
    uint32_t TXC_A;    // Transmit config
    uint32_t DREQ_A;   // DMA request level
    uint32_t INTEN_A;  // Interrupt enables
    uint32_t INTSTC_A; // Interrupt status and clear
    uint32_t GRAY;     // Gray mode control
} pcm_map_t;

/* Buffer for holding pcm data in the kernel space */
typedef struct pcm_buffer
{
    uint32_t *buffer;
    int head;
    int tail;
    int size;
} pcm_buffer_t;

/* Bits for CS_A Register */
#define I2S_CS_A_STBY (0x1u << 25)
#define I2S_CS_A_SYNC (0x1u << 24)
#define I2S_CS_A_RXSEX (0x1u << 23)
#define I2S_CS_A_RXF_MASK (0x1u << 22)
#define I2S_CS_A_TXE_MASK (0x1u << 21)
#define I2S_CS_A_RXD_MASK (0x1u << 20)
#define I2S_CS_A_TXD_MASK (0x1u << 19)
#define I2S_CS_A_RXR_MASK (0x1u << 18)
#define I2S_CS_A_TXW_MASK (0x1u << 17)
#define I2S_CS_A_RXERR (0x1u << 16)
#define I2S_CS_A_TXERR (0x1u << 15)
#define I2S_CS_A_RXSYNC_MASK (0x1u << 14)
#define I2S_CS_A_TXSYNC_MASK (0x1u << 13)
#define I2S_CS_A_DMAEN (0x1u << 9)
#define I2S_CS_A_RXTHR(val) ((val << 7) & (0x3 << 7))
#define I2S_CS_A_TXTHR(val) ((val << 5) & (0x3 << 5))
#define I2S_CS_A_RXCLR (0x1u << 4)
#define I2S_CS_A_TXCLR (0x1u << 3)
#define I2S_CS_A_TXON (0x1u << 2)
#define I2S_CS_A_RXON (0x1u << 1)
#define I2S_CS_A_EN (0x1u << 0)

/* Bits for MODE_A Register */
#define I2S_MODE_A_CLK_DIS (0x1u << 28)
#define I2S_MODE_A_PDMN (0x1u << 27)
#define I2S_MODE_A_PDME (0x1u << 26)
#define I2S_MODE_A_FRXP (0x1u << 25)
#define I2S_MODE_A_FTXP (0x1u << 24)
#define I2S_MODE_A_CLKM (0x1u << 23)
#define I2S_MODE_A_CLKI (0x1u << 22)
#define I2S_MODE_A_FSM (0x1u << 21)
#define I2S_MODE_A_FSI (0x1u << 20)
#define I2S_MODE_A_FLEN_POS (10)
#define I2S_MODE_A_FLEN_MASK (0x3FF << I2S_MODE_A_FLEN_POS)
#define I2S_MODE_A_FLEN(val) (I2S_MODE_A_FLEN_MASK & (val << I2S_MODE_A_FLEN_POS))
#define I2S_MODE_A_FSLEN_POS (0)
#define I2S_MODE_A_FSLEN_MASK (0x3FF << I2S_MODE_A_FSLEN_POS)
#define I2S_MODE_A_FSLEN(val) (I2S_MODE_A_FSLEN_MASK & (val << I2S_MODE_A_FSLEN_POS))

/* Bits for RXC_A Register */
#define I2S_RXC_A_CH1WEX (0x1u << 31)
#define I2S_RXC_A_CH1EN (0x1u << 30)
#define I2S_RXC_A_CH1POS_POS (20)
#define I2S_RXC_A_CH1POS_MASK (0x3FF << I2S_RXC_A_CH1POS_POS)
#define I2S_RXC_A_CH1POS(val) (I2S_RXC_A_CH1POS_MASK & (val << I2S_RXC_A_CH1POS_POS))
#define I2S_RXC_A_CH1WID_POS (16)
#define I2S_RXC_A_CH1WID_MASK (0xFu << I2S_RXC_A_CH1WID_POS)
#define I2S_RXC_A_CH1WID(val) (I2S_TXC_A_CH1WID_MASK & (val << I2S_RXC_A_CH1WID_POS))
#define I2S_RXC_A_CH2WEX (0x1u << 15)
#define I2S_RXC_A_CH2EN (0x1u << 14)
#define I2S_RXC_A_CH2POS_POS (4)
#define I2S_RXC_A_CH2POS_MASK (0x3FFu << I2S_RXC_A_CH2POS_POS)
#define I2S_RXC_A_CH2POS(val) (I2S_RXC_A_CH2POS_MASK & (val << I2S_RXC_A_CH2POS_POS))
#define I2S_RXC_A_CH2WID_POS (0)
#define I2S_RXC_A_CH2WID_MASK (0xFu << I2S_RXC_A_CH2WID_POS)
#define I2S_RXC_A_CH2WID(val) (I2S_RXC_A_CH2WID_MASK & (val << I2S_RXC_A_CH2WID_POS))

/* Bits for TXC_A Register */
#define I2S_TXC_A_CH1WEX (0x1u << 31)
#define I2S_TXC_A_CH1EN (0x1u << 30)
#define I2S_TXC_A_CH1POS_POS (20)
#define I2S_TXC_A_CH1POS_MASK (0x3FF << I2S_TXC_A_CH1POS_POS)
#define I2S_TXC_A_CH1POS(val) (I2S_TXC_A_CH1POS_MASK & (val << I2S_TXC_A_CH1POS_POS))
#define I2S_TXC_A_CH1WID_POS (16)
#define I2S_TXC_A_CH1WID_MASK (0xFu << I2S_TXC_A_CH1WID_POS)
#define I2S_TXC_A_CH1WID(val) (I2S_TXC_A_CH1WID_MASK & (val << I2S_TXC_A_CH1WID_POS))
#define I2S_TXC_A_CH2WEX (0x1u << 15)
#define I2S_TXC_A_CH2EN (0x1u << 14)
#define I2S_TXC_A_CH2POS_POS (4)
#define I2S_TXC_A_CH2POS_MASK (0x3FFu << I2S_TXC_A_CH2POS_POS)
#define I2S_TXC_A_CH2POS(val) (I2S_TXC_A_CH2POS_MASK & (val << I2S_TXC_A_CH2POS_POS))
#define I2S_TXC_A_CH2WID_POS (0)
#define I2S_TXC_A_CH2WID_MASK (0xFu << I2S_TXC_A_CH2WID_POS)
#define I2S_TXC_A_CH2WID(val) (I2S_TXC_A_CH2WID_MASK & (val << I2S_TXC_A_CH2WID_POS))

/* Bits for DREQ_A Register */
#define I2S_DREQ_A_TX_PANIC_POS (24)
#define I2S_DREQ_A_TX_PANIC_MASK (0x7Fu << I2S_DREQ_A_TX_PANIC_POS)
#define I2S_DREQ_A_TX_PANIC(val) (I2S_DREQ_A_TX_PANIC_MASK & (val << I2S_DREQ_A_TX_PANIC_POS))
#define I2S_DREQ_A_RX_PANIC_POS (16)
#define I2S_DREQ_A_RX_PANIC_MASK (0x7Fu << I2S_DREQ_A_RX_PANIC_POS)
#define I2S_DREQ_A_RX_PANIC(val) (I2S_DREQ_A_RX_PANIC_MASK & (val << I2S_DREQ_A_RX_PANIC_POS))
#define I2S_DREQ_A_TX_POS (8)
#define I2S_DREQ_A_TX_MASK (0x7Fu << I2S_DREQ_A_TX_POS)
#define I2S_DREQ_A_TX(val) (I2S_DREQ_A_TX_MASK & (val << I2S_DREQ_A_TX_POS))
#define I2S_DREQ_A_RX_POS (0)
#define I2S_DREQ_A_RX_MASK (0x7Fu << I2S_DREQ_A_RX_POS)
#define I2S_DREQ_A_RX(val) (I2S_DREQ_A_RX_MASK & (val << I2S_DREQ_A_RX_POS))

/* Bits for INTEN_A Register */
#define I2S_INTEN_A_RXERR (0x1u << 3)
#define I2S_INTEN_A_TXERR (0x1u << 2)
#define I2S_INTEN_A_RXR (0x1u << 1)
#define I2S_INTEN_A_TXW (0x1u << 0)

/* Bits for INTSTC_A Register */
#define I2S_INTSTC_A_RXERR (0x1u << 3)
#define I2S_INTSTC_A_TXERR (0x1u << 2)
#define I2S_INTSTC_A_RXR (0x1u << 1)
#define I2S_INTSTC_A_TXW (0x1u << 0)

/* Bits for GRAY Register */
#define I2S_GRAY_RXFIFOLEVEL_POS (16)
#define I2S_GRAY_RXFIFOLEVEL_MASK (0x3Fu << I2S_GRAY_RXFIFOLEVEL_POS)
#define I2S_GRAY_FLUSHED_POS (10)
#define I2S_GRAY_FLUSHED_MASK (0x3Fu << I2S_GRAY_FLUSHED_POS)
#define I2S_GRAY_RXLEVEL_POS (4)
#define I2S_GRAY_RXLEVEL_MASK (0x3Fu << I2S_GRAY_RXLEVEL_POS)
#define I2S_GRAY_FLUSH (0x1u << 2)
#define I2S_GRAY_CLR (0x1u << 1)
#define I2S_GRAY_EN (0x1u << 0)

/* Char driver functions */
int init_module(void);
void cleanup_module(void);
static int device_open(struct inode *, struct file *);
static int device_release(struct inode *, struct file *);
static ssize_t device_read(struct file *, char *, size_t, loff_t *);
static ssize_t device_write(struct file *, const char *, size_t, loff_t *);
static long device_ioctl(struct file *file, unsigned int cmd, unsigned long arg);

/* Software buffer functions for holding the samples */
static void buffer_init(pcm_buffer_t *b, uint32_t *data, int size);
static uint32_t buffer_read(pcm_buffer_t *b);
static int buffer_write(pcm_buffer_t *b, uint32_t data);
static int buffer_remaining(pcm_buffer_t *b);
static inline int buffer_items(pcm_buffer_t *b);
static inline void buffer_clear(pcm_buffer_t *b);

/* PCM control functions */
static int pcm_init_default(void);
static void inline pcm_enable(void);
static void inline pcm_disable(void);
static void inline pcm_enable_tx(void);
static void inline pcm_disable_tx(void);
static void inline pcm_enable_rx(void);
static void inline pcm_disable_rx(void);
static void inline pcm_clear_tx_fifo(void);
static void inline pcm_clear_rx_fifo(void);
static void pcm_reset(void);

static irq_handler_t pcm_interrupt_handler(int irq, void *dev_id, struct pt_regs *regs);

#endif