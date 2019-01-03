//
// Created by Quentin Wendegass on 2018-12-13.
//

/**
  * I created this library to experiment with Cython and refresh my C knowledge.
  * It is not necessary to use this implementation in this project,
  * because the python implementation is fast enough for our use case.
  **/

#ifndef STRING_LIB
#define STRING_LIB

#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>

/* Is used for the function split_command() as return value. 
   This holds a char pointer of all args terminated with \0. 
   The args attribute points to the right memory adresses in the args char *. */
typedef struct args_t
{
     short size;
     char **args;
     char *arg_str;
} args_t;

args_t *split_command(char *command, short buffer_size);

void dealloc_args(args_t *args);

#endif