all: test

test: test.o pcmlib.o
	gcc -o test test.o pcmlib.o

test.o: test.c
	gcc -I ../inc -c -Wall -fpic test.c

pcmlib.o: ../pcmlib.c
	gcc -I ../inc -c -Wall -fpic ../pcmlib.c

clean:
	rm pcmlib.o test test.o
