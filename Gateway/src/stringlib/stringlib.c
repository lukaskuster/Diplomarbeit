//
// Created by Quentin Wendegass on 2018-12-13.
//

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "stringlib.h"

/* Free the allocated memory for the args struct. 
   Call this after using the struct.*/
void dealloc_args(args_t *args)
{
    free(args->arg_str);
    free(args->args);
    free(args);
}

/* Returns all args in a string after a ':' that are seperatet with ','.
   The args struct must be freed with dealloc_args() after using it. */
args_t *split_command(char *command, short buffer_size)
{
    size_t arg_index;

    for (arg_index = 0; command[arg_index] != '\0' && command[arg_index] != ':'; arg_index++)
        ;

    char *args_start = command + arg_index + 1;

    args_t *ret = malloc(sizeof(args_t));
    ret->arg_str = malloc((strlen(args_start) + 1) * sizeof(char));
    ret->args = malloc(buffer_size * sizeof(char *));

    strcpy(ret->arg_str, args_start);
    char *arg_str = ret->arg_str;

    char *current_pos = arg_str;

    char **args = ret->args;
    char **current_args = args;

    *current_args = current_pos;
    current_args++;

    size_t len = strlen(arg_str);

    size_t arg_count = 1;

    for (int k = 0; k < len; k++)
    {
        current_pos++;
        if (arg_str[k] == ',')
        {
            arg_count++;
            arg_str[k] = '\0';
            *current_args = current_pos;
            current_args++;
        }
    }

    ret->size = (short)arg_count;

    return ret;
}
