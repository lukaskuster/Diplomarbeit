//
// Created by Quentin Wendegass on 2018-12-31.
//

#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <pcmlib.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <inttypes.h>

#define CLOCK_BASE (PERI_BASE + 0x101000) /* Clocks */

#define PAGE_SIZE (4 * 1024)
#define BLOCK_SIZE (4 * 1024)

// Pcm char device file
int pcm_fd;

/* Used for clock memory mapping */
int mem_fd;
char *clk_mem, *clk_map;

// clk access
volatile unsigned *clk;

int start_call()
{
    /* Open pcm dev file */
    pcm_fd = open("/dev/pcm", O_RDWR);

    if (pcm_fd < 0)
    {
        printf("Can not open device! Error code: %d\n", errno);
        return -errno;
    }

    /* Clear software buffers */
    ioctl(pcm_fd, PCM_CLEAR_RX_BUFF, 0);
    ioctl(pcm_fd, PCM_CLEAR_TX_BUFF, 0);

    /* Clear hardware FIFOs */
    ioctl(pcm_fd, PCM_CLR_TX_FIFO, 0);
    ioctl(pcm_fd, PCM_CLR_RX_FIFO, 0);

    // Wait for two clock signals
    usleep(5);

    // Enable Rx
    ioctl(pcm_fd, PCM_SET_RXON, 1);

    /* Fill Tx buffer */
    while (ioctl(pcm_fd, PCM_TX_BUFF_SPACE) > 0)
    {
        uint32_t buf = 0;
        write(pcm_fd, &buf, 4);
    }

    // Enable Tx after the buffer is filled
    ioctl(pcm_fd, PCM_SET_TXON, 1);

    return pcm_fd;
}

int stop_call()
{
    /* Disable Tx and Rx */
    ioctl(pcm_fd, PCM_SET_RXON, 0);
    ioctl(pcm_fd, PCM_SET_TXON, 0);

    // Close the device
    int ret = close(pcm_fd);
    pcm_fd = -1;

    return ret;
}

size_t write_samples(char *samples)
{
    /* Check if enough space is availabe */
    if (ioctl(pcm_fd, PCM_TX_BUFF_SPACE) > FRAME_SAMPLES)
    {
        // Write the samples to the device driver
        return write(pcm_fd, samples, FRAME_SAMPLES);
    }

    return -EAGAIN;
}

char *read_samples()
{
    // Samples from the device driver
    static char buffer[FRAME_SAMPLES];

    /* Check if enough samples are in the device buffer */
    if (ioctl(pcm_fd, PCM_RX_BUFF_ITEMS) > FRAME_SAMPLES)
    {
        size_t bytes_read = read(pcm_fd, buffer, FRAME_SAMPLES);

        /* Check if the right amount of samples was transfered */
        if (bytes_read != FRAME_SAMPLES)
        {
            printf("Got wrong amount of bytes! Bytes: %zu\n", bytes_read);
            errno = EINVAL;
            return NULL;
        }

        return buffer;
    }

    errno = EAGAIN;
    return NULL;
}

void start_clk()
{
    printf("Start PCM clock!\n");

    /* Setup the clock to output 3.072Mhz */
    *(clk + 0x26) = 0x5A000000 | (1 << 9);
    *(clk + 0x27) = 0x5A006400;

    usleep(5);

    //Enable the pcm clock
    *(clk + 0x26) = 0x5A000011 | (1 << 9);
}

void stop_clk()
{
    printf("Stop PCM clock!\n");

    /* Clear all register to disable the clocks */
    *(clk + 0x26) = 0x5A000000;
    *(clk + 0x27) = 0x5A000000;
}

int alloc_clk()
{
    printf("Setup CLK...\n");

    /* open /dev/mem */
    if ((mem_fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0)
    {
        printf("Can't open /dev/mem\n");
        return mem_fd;
    }

    // Allocate MAP block
    if ((clk_mem = malloc(BLOCK_SIZE + (PAGE_SIZE - 1))) == NULL)
    {
        printf("CLK memory allocation error!\n");
        return -ENOMEM;
    }

    // Make sure pointer is on 4K boundary
    if ((unsigned long)clk_mem % PAGE_SIZE)
        clk_mem += PAGE_SIZE - ((unsigned long)clk_mem % PAGE_SIZE);

    clk_map = (char *)mmap(
        (caddr_t)clk_mem,
        BLOCK_SIZE,
        PROT_READ | PROT_WRITE,
        MAP_SHARED | MAP_FIXED,
        mem_fd,
        CLOCK_BASE);

    if ((long)clk_map < 0)
    {
        printf("Clock mmap error!%d\n", (int)clk_map);
        return (int)clk_map;
    }

    // Use volatile pointer for memory mapping
    clk = (volatile unsigned *)clk_map;

    return 0;
}

int dealloc_clk()
{
    printf("Deinitialize CLK...");

    int e;

    /* Unmap the memory region */
    if ((e = munmap(clk_mem, BLOCK_SIZE)) < 0)
    {
        printf("Failed to unmap CLK memory!\n");
        return e;
    }

    /* Close /dev/mem */
    if ((e = close(mem_fd)) < 0)
    {
        printf("Failed to close /dev/mem!\n");
        return e;
    }

    return 0;
}
