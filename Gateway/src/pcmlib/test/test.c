#include <stdio.h>
#include <signal.h>
#include <time.h>
#include "pcmlib.h"

// Comment this part if the raspberry is the slave
#define MASTER

// For running the for loop until an INT signal occoures
static volatile int is_running;

/* Callback for the SIGINT signal */
void SIGINT_handler(int v)
{
    // Disable running to finish the program
    is_running = 0;
}

int main()
{
    int e;

#ifdef MASTER
    /* Allocate PCM clock */
    if ((e = alloc_clk()) < 0)
    {
        printf("Error allocating clk: %d\n", e);
        exit(-1);
    }
    // Start the clock with 3.072MHz
    start_clk();
#endif

    /* Enable SIGINT callback */
    is_running = 1;
    signal(SIGINT, SIGINT_handler);

    /* Enable pcm hw */
    if ((e = start_call()) < 0)
    {
        printf("Error starting call: %d\n", e);
        exit(-1);
    }

    // Test frame that gets transmitted
    char frame[160];

    /* Get the samples some values */
    for (int i = 0; i < FRAME_SAMPLES; i++)
    {
        frame[i] = i;
    }

    int count = 0;

    /* Write the test frame and receive incoming frames until the SIGINT signal */
    while (is_running)
    {
        /* Wait so the buffer can hold up. 
        Simulates the time delay of the rtp packets. */
        int milisec = 15; // length of time to sleep, in miliseconds
        struct timespec req = {0};
        req.tv_sec = 0;
        req.tv_nsec = milisec * 1000000L;
        nanosleep(&req, (struct timespec *)NULL);

        /* Don't get higher than 8bit can hold */
        if (count > 255)
        {
            count = 0;
        }

        // Update the first sample
        frame[0] = count;

        // Send the frame via the pcm bus
        int e;
        if ((e = write_samples(&frame)) > 0)
        {
            // Only increment count if the frame was actually send
            count++;
        }
        else
        {
            printf("Could not write frame!\n");
        }

        /* Try to read a frame from the pcm bus */
        char *read_frame;
        if ((read_frame = read_samples()) == NULL)
        {
            printf("Could not read frame!\n");
        }
        else
        {
            printf("Got frame! First sample: %d\n", read_frame[0]);
        }
    }

    /* Disable pcm hw */
    if ((e = stop_call()) < 0)
    {
        printf("Error stoping call: %d\n", e);
        exit(-1);
    }

#ifdef MASTER
    // Stop the clock by clearing all registers
    stop_clk();

    /* Unmap the clk memory*/
    if ((e = dealloc_clk()) < 0)
    {
        printf("Error deallocating clk: %d\n", e);
        exit(-1);
    }
#endif

    return 0;
}