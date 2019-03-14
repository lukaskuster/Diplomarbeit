all: test_stringlib

test_stringlib: test_stringlib.o stringlib.o
	gcc -o test_stringlib test_stringlib.o stringlib.o

test_stringlib.o: test_stringlib.c
	gcc -I .. -c -Wall -fpic test_stringlib.c

stringlib.o: ../stringlib.c
	gcc -I .. -c -Wall -fpic ../stringlib.c

clean:
	rm stringlib.o test_stringlib test_stringlib.o
