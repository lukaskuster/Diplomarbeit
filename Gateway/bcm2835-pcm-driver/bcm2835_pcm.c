//
// Created by Quentin Wendegass on 2018-12-28.
//

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/uaccess.h>
#include <asm/io.h>
#include <linux/ioport.h>
#include <asm/barrier.h>
#include <linux/slab.h>
#include <linux/sched.h>
#include <linux/interrupt.h>
#include <linux/fs.h>

#include "bcm2835_pcm.h"

//In the io functions one sample is 8bit long
#define BYTES_PER_SAMPLE 1

//Rx and Tx buffer length
#define SAMPLE_BUFF_LEN 16000

/* Struct pointer to the PCM base address after remapping.
 * Volatile is recommended for memory mapped peripherals */
volatile pcm_map_t *pcm_map;

/* Variables for driver's major number and usage indication */
static int major;
static int device_in_use = 0;

/* Buffers to hold samples for the hw fifo */
static pcm_buffer_t rx_buf;
static pcm_buffer_t tx_buf;
static uint32_t rx_buffer[SAMPLE_BUFF_LEN];
static uint32_t tx_buffer[SAMPLE_BUFF_LEN];

/* Keep track of the number of interrupts where an error occurs */
static int tx_error_count = 0;
static int rx_error_count = 0;

static struct file_operations fops = {
    .read = device_read,
    .write = device_write,
    .open = device_open,
    .release = device_release,
    .unlocked_ioctl = device_ioctl};

/*
 *
 *  Functions for the PCM interface.
 *
 */

static int pcm_init_default(void)
{
    /* Make sure memory isn't being used by something else */
    if (request_mem_region(PCM_BASE, PCM_SIZE, DEVICE_NAME) == NULL)
    {
        printk(KERN_ALERT "Failed to request PCM memory.");
        return -EBUSY;
    }

    /* Convert physical addresses into virtual addresses for the kernel to use */
    pcm_map = (volatile pcm_map_t *)ioremap(PCM_BASE, PCM_SIZE);

    printk(KERN_INFO "PCM memory acquired successfully.");

    // Initialize software buffers
    buffer_init(&rx_buf, rx_buffer, SAMPLE_BUFF_LEN);
    buffer_init(&tx_buf, tx_buffer, SAMPLE_BUFF_LEN);

    wmb();

    // Clear control registers
    pcm_map->CS_A = 0;
    pcm_map->MODE_A = 0;
    pcm_map->TXC_A = 0;
    pcm_map->RXC_A = 0;
    pcm_map->GRAY = 0;

    printk(KERN_INFO "PCM registers reset.");

    /* Begin register configuration */

#ifdef MASTER
    printk(KERN_INFO "Configuring Raspberry Pi as PCM master...");
    // Set frame length and frame sync length
    pcm_map->MODE_A = I2S_MODE_A_FLEN(383) | I2S_MODE_A_FSLEN(1);
#endif

#ifdef SLAVE
    printk(KERN_INFO "Configuring Raspberry Pi as PCM slave...");
    // Set clk and fs to listen on the inputs
    pcm_map->MODE_A = I2S_MODE_A_CLKM | I2S_MODE_A_FSM;
#endif

    /* Configure channels and frame width
     * Gives a channel width of 8 bits,
     * First bit of channel 1 is received on the first clock cycle,
     * */
    printk(KERN_INFO "Setting channel width...");
    pcm_map->RXC_A = I2S_RXC_A_CH1EN | I2S_RXC_A_CH1POS(0) | I2S_RXC_A_CH1WID(0);
    pcm_map->TXC_A = I2S_TXC_A_CH1EN | I2S_TXC_A_CH1POS(0) | I2S_TXC_A_CH1WID(0);

    // Disable Standby
    printk(KERN_INFO "Disabling standby...");
    pcm_map->CS_A |= I2S_CS_A_STBY;

    // Reset FIFOs
    printk(KERN_INFO "Clearing FIFOs...");
    pcm_map->CS_A |= I2S_CS_A_TXCLR | I2S_CS_A_RXCLR;

    /* Interrupt driven mode */
    /* Interrupt when TX fifo is less than full and RX fifo is full */
    pcm_map->CS_A |= I2S_CS_A_TXTHR(0x1) | I2S_CS_A_RXTHR(0x3);

    // Enable TXW and RXR interrupts
    pcm_map->INTEN_A = I2S_INTEN_A_TXW | I2S_INTEN_A_RXR;

    // Enable the PCM module
    printk(KERN_INFO "Enabling PCM...");
    pcm_map->CS_A |= I2S_CS_A_EN;

    printk(KERN_INFO "PCM configuration Complete.");

    /* PCM driver is now configured, but TX and RX will need to be turned on before data is transferred */

    return 0;
}

static void inline pcm_enable(void)
{
    wmb();
    pcm_map->CS_A |= I2S_CS_A_EN;
    printk(KERN_INFO "PCM interface enabled.");
}

static void inline pcm_disable(void)
{
    wmb();
    pcm_map->CS_A &= (~I2S_CS_A_EN);
    printk(KERN_INFO "PCM interface disabled.");
}

static void inline pcm_enable_tx(void)
{
    wmb();
    pcm_map->CS_A |= I2S_CS_A_TXON;
    printk(KERN_INFO "TX enabled.");
}

static void inline pcm_disable_tx(void)
{
    wmb();
    pcm_map->CS_A &= ~I2S_CS_A_TXON;
    printk(KERN_INFO "TX disabled.");
}

static void inline pcm_enable_rx(void)
{
    wmb();
    pcm_map->CS_A |= I2S_CS_A_RXON;
    printk(KERN_INFO "RX enabled.");
}

static void inline pcm_disable_rx(void)
{
    wmb();
    pcm_map->CS_A &= ~I2S_CS_A_RXON;
    printk(KERN_INFO "RX disabled.");
}

static void inline pcm_clear_tx_fifo(void)
{
    pcm_map->CS_A &= ~(I2S_CS_A_EN); // Has to be disabled to clear
    wmb();
    pcm_map->CS_A |= I2S_CS_A_TXCLR; // Will take two PCM clock cycles to actually clear
    wmb();
    pcm_map->CS_A |= I2S_CS_A_EN;
}

static void inline pcm_clear_rx_fifo(void)
{
    pcm_map->CS_A &= ~(I2S_CS_A_EN); // Has to be disabled to clear
    wmb();
    pcm_map->CS_A |= I2S_CS_A_RXCLR; // Will take two PCM clock cycles to actually clear
    wmb();
    pcm_map->CS_A |= I2S_CS_A_EN;
}

static void pcm_reset(void)
{
    /* Return everything to default */
    wmb();
    // Clear control registers
    pcm_map->CS_A = 0;
    pcm_map->MODE_A = 0;
    pcm_map->TXC_A = 0;
    pcm_map->RXC_A = 0;
    pcm_map->INTEN_A = 0;
    pcm_map->INTSTC_A = 0;
    pcm_map->GRAY = 0;
}

/*
 *
 * Read / write functions for the circular FIFO buffers
 *
 */

/* Create a buffer */
static void buffer_init(pcm_buffer_t *b, uint32_t *data, int size)
{
    b->head = 0;
    b->tail = 0;
    b->size = size;
    b->buffer = data;
}

/* Read a single sample from a buffer */
static uint32_t buffer_read(pcm_buffer_t *b)
{
    uint32_t temp;

    if (b->tail != b->head)
    {
        temp = b->buffer[b->tail];  // Read sample from the buffer
        b->tail++;                  // Increment tail
        if (b->tail == b->size + 1) // Wrap around condition
        {
            b->tail = 0;
        }
    }
    else
    {
        return 0;
    }
    return temp;
}

/* Write a sample to a buffer */
static int buffer_write(pcm_buffer_t *b, uint32_t data)
{
    if ((b->head + 1 == b->tail) || ((b->head + 1 == b->size + 1) && (b->tail == 0)))
    {
        return -1; //No room
    }
    else
    {
        b->buffer[b->head] = data;
        b->head++;
        if (b->head == b->size + 1) // Wraparound condition
        {
            b->head = 0;
        }
    }
    return 0;
}

/* Return the space left in the buffer */
static int buffer_remaining(pcm_buffer_t *b)
{
    if (b->head == b->tail)
    {
        /* Buffer is empty */
        return b->size;
    }
    else if (b->head > b->tail)
    {
        return ((b->size - b->head) + b->tail);
    }
    else if (b->head < b->tail)
    {
        return (b->tail - b->head - 1);
    }

    /* Something is very wrong */
    return -1;
}

/* Return number of items currently in the buffer */
static inline int buffer_items(pcm_buffer_t *b)
{
    return (b->size - buffer_remaining(b));
}

/* Delete contents of buffer */
static inline void buffer_clear(pcm_buffer_t *b)
{
    b->head = 0;
    b->tail = 0;
}

/*
 *
 * Interrupt handler
 *
 */

static irq_handler_t pcm_interrupt_handler(int irq, void *dev_id, struct pt_regs *regs)
{
    int i;
    unsigned long irq_flags = 0;
    uint32_t data, temp;

    local_irq_save(irq_flags);

    /* Check TXW to see if the buffer is empty and samples can be written */
    if ((pcm_map->INTSTC_A & I2S_INTSTC_A_TXW))
    {
        for (i = 0; i < 64; i++)
        {
            /* Fill buffer until it is full or until the kernel buffer is empty */
            if (!(pcm_map->CS_A & I2S_CS_A_TXD_MASK))
            {
                break;
            }

            data = buffer_read(&tx_buf);
            wmb();

            pcm_map->FIFO_A = data;

            if (buffer_items(&tx_buf) == 0)
            {
                tx_error_count++;
                if (tx_error_count > 1000000)
                {
                    /* Shut down to keep from hanging */
                    printk(KERN_ALERT "Buffer underflow limit reached. Disabling TX...");
                    tx_error_count = 0;
                    pcm_disable_tx();

                    /* Write a set of samples to stop interrupts */
                    pcm_map->FIFO_A = 0;
                    wmb();
                    pcm_map->FIFO_A = 0;
                }
                break;
            }
        }
    }

    /* Check RXR to see if samples have been received and copy them */
    if ((pcm_map->INTSTC_A & I2S_INTSTC_A_RXR))
    {
        /* Read from the FIFO until it is empty */
        for (i = 0; i < 64; i++)
        {
            if (!(pcm_map->CS_A & I2S_CS_A_RXD_MASK))
            {
                /* No more data to read */
                break;
            }
            else if (buffer_remaining(&rx_buf) == 0)
            {
                rx_error_count++;
                if (rx_error_count > 1000000)
                {
                    /* Shut it down to keep from hanging forever */
                    printk(KERN_ALERT "Buffer overflow limit reached. Disabling RX...");
                    rx_error_count = 0;
                    pcm_disable_rx();

                    /* Read a pair of samples to stop the interrupts */
                    wmb();
                    temp = pcm_map->FIFO_A;
                    wmb();
                    temp = pcm_map->FIFO_A;
                }
                break;
            }

            rmb();
            buffer_write(&rx_buf, pcm_map->FIFO_A);
        }
    }

    // Clear all flags
    pcm_map->INTSTC_A = 0x0F;

    local_irq_restore(irq_flags);

    // Announce IRQ has been correctly handled
    return (irq_handler_t)IRQ_HANDLED;
}

/*
 *
 * File operation functions for character driver.
 *
 */

/* Function to read from the hardware FIFO and transfer data to user space */
static ssize_t device_read(struct file *file, char *buffer, size_t length, loff_t *offset)
{
    int samples_read = 0;
    uint32_t rx_temp;
    unsigned long ret;

    /* Copy data from the PCM FIFO into a user provided buffer*/

    if (buffer_items(&rx_buf) == 0)
    {
        return 0;
    }

    // Loop until out of samples or length is 0
    while (buffer_items(&rx_buf) && length)
    {
        rx_temp = buffer_read(&rx_buf);

        // Copy 8 bits at a time
        ret = copy_to_user(buffer + (BYTES_PER_SAMPLE * samples_read), &rx_temp, BYTES_PER_SAMPLE);

        // Make sure to decrement by the right amount for 8 bit transfers
        length -= BYTES_PER_SAMPLE;
        samples_read++;
    }

    return BYTES_PER_SAMPLE * samples_read; // Number of bytes transferred
}

/* Function to write data from user space to the hardware FIFO */
static ssize_t device_write(struct file *file, const char *buffer, size_t length, loff_t *offset)
{
    /* Copy data from user input into the PCM FIFO */

    int i;
    int index = 0;
    unsigned long ret;
    uint32_t tx_temp = 0;

    if (buffer_remaining(&tx_buf) == 0)
    {
        // No space available right now
        return -EAGAIN;
    }

    /* Need to convert length from bytes to samples */
    for (i = 0; i < (length / BYTES_PER_SAMPLE); i++)
    {

        ret = copy_from_user(&tx_temp, buffer + index, BYTES_PER_SAMPLE);

        if (buffer_write(&tx_buf, tx_temp) < 0)
        {
            //printk(KERN_INFO "TX buffer overflow.");
        }

        index += BYTES_PER_SAMPLE;
    }

    return BYTES_PER_SAMPLE * index; // Return the number of bytes transferred
}

/* Called when a process attemps to open the device file */
static int device_open(struct inode *inode, struct file *file)
{
    int result;

    /* Only allow one connection to the device */
    if (device_in_use)
    {
        return -EBUSY;
    }

    device_in_use++;

    /* Make sure errors are cleared from any previous use */
    tx_error_count = 0;
    rx_error_count = 0;

    /* Activate interrupts when file is opened */
    result = request_irq(PCM_INTERRUPT, (irq_handler_t)pcm_interrupt_handler, IRQF_TRIGGER_RISING, DEVICE_NAME, NULL);
    if (result < 0)
    {
        printk(KERN_ALERT "Failed to acquire PCM interrupt %d. Returned %d", PCM_INTERRUPT, result);
        return -EBUSY;
    }

    printk(KERN_INFO "PCM interrupts enabled.");

    /* Increment usage count to be able to properly close the module. */
    try_module_get(THIS_MODULE);

    return 0;
}

/* Called when the a process closes the device file */
static int device_release(struct inode *inode, struct file *file)
{

    // Make this device available again
    device_in_use--;

    // Release the interrupt when the file is closed
    free_irq(PCM_INTERRUPT, NULL);

    /* Reset errors */
    tx_error_count = 0;
    rx_error_count = 0;

    //Decrement usage count to be able to properly close the module.
    module_put(THIS_MODULE);

    return 0;
}

/*
 *
 * IOCTL function
 *
 */
static long device_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    switch (cmd)
    {
    case PCM_TX_BUFF_SPACE:
        /* Return the number of open spaces left in the buffer */
        return buffer_remaining(&tx_buf);

    case PCM_RX_BUFF_ITEMS:
        /* Return number of samples in the buffer */
        return buffer_items(&rx_buf);

    case PCM_CLR_RX_FIFO:
        pcm_clear_rx_fifo();
        break;

    case PCM_CLR_TX_FIFO:
        pcm_clear_tx_fifo();
        break;

    case PCM_SET_EN:
        if (arg == 0)
        {
            pcm_disable();
        }
        else if (arg == 1)
        {
            pcm_enable();
        }
        else
        {
            return -EINVAL;
        }
        break;

    case PCM_SET_TXON:
        if (arg == 0)
        {
            pcm_disable_tx();
        }
        else if (arg == 1)
        {
            pcm_enable_tx();
        }
        else
        {
            return -EINVAL;
        }
        break;

    case PCM_SET_RXON:
        if (arg == 0)
        {
            pcm_disable_rx();
        }
        else if (arg == 1)
        {
            pcm_enable_rx();
        }
        else
        {
            return -EINVAL;
        }
        break;

    case PCM_CLEAR_TX_BUFF:
        buffer_clear(&tx_buf);
        break;

    case PCM_CLEAR_RX_BUFF:
        buffer_clear(&rx_buf);
        break;

    default:
        return -EINVAL;
    }

    return 0;
}

/*
 *
 * Required module functions
 *
 */

/* Function called upon loading module */
int init_module(void)
{
    int status = 1;
    printk(KERN_INFO "Installing PCM driver...");

    //Temporarily use my default settings.
    status = pcm_init_default();

    /* Hardware should now be set up and ready to go */
    if (status < 0)
    {
        printk(KERN_ALERT "Hardware configuration failed. Driver not installed.");
        return -1;
    }

    major = register_chrdev(0, DEVICE_NAME, &fops);
    if (major < 0)
    {
        printk(KERN_ALERT "register_chrdev failed with major = %d\n", major);
        return major;
    }

    printk(KERN_INFO "PCM driver successfully assigned to major number %d.", major);

    return 0;
}

/* Function called upon uninstalling module */
void cleanup_module(void)
{
    pcm_disable_tx();
    pcm_reset();
    printk(KERN_INFO "PCM interface disabled and reset.");

    /* Unmap all memory regions used */
    printk(KERN_INFO "Unmapping memory regions used.");
    iounmap(pcm_map);
    release_mem_region(PCM_BASE, PCM_SIZE);

    unregister_chrdev(major, DEVICE_NAME);

    printk(KERN_INFO "Unmapping memory regions used.");

    printk(KERN_INFO "PCM driver removed.");
}