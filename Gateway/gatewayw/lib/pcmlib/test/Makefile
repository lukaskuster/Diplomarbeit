all: test_pcmlib

test_pcmlib: test_pcmlib.o pcmlib.o
	gcc -o test_pcmlib test_pcmlib.o pcmlib.o

test_pcmlib.o: test_pcmlib.c
	gcc -I .. -c -Wall -fpic test_pcmlib.c

pcmlib.o: ../pcmlib.c
	gcc -I .. -c -Wall -fpic ../pcmlib.c

clean:
	rm pcmlib.o test_pcmlib test_pcmlib.o
