//
// Created by Quentin Wendegass on 2018-12-14.
//

#include <time.h>
#include "stringlib.h"

void test_split_command()
{
    clock_t start, end;
    double cpu_time_used;

    char *str = "Some+ATCMD:arg1,arg2,,arg4";

    printf("Testing with string: %s\n", str);

    args_t *args = split_command(str, 3);

    printf("Size of args: %d\n", args->size);

    for (int i = 0; i < args->size; i++)
    {
        printf("Arg [%d]; %s\n", i, args->args[i]);
    }

    dealloc_args(args);

    start = clock();
    for (size_t i = 0; i < 1000000; i++)
    {
        args = split_command(str, 3);
        dealloc_args(args);
    }
    end = clock();
    cpu_time_used = ((double)(end - start)) / CLOCKS_PER_SEC;
    printf("CPU time used for one million executions: %.10f\n", cpu_time_used);
}


int main()
{
    printf("Testing split commands...\n");
    test_split_command();
}
