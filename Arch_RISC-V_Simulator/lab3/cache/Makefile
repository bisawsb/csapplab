CC = g++ -std=c++11

all: sim 

sim: main.o cache.o memory.o
	$(CC) -o $@ $^

main.o: cache.h
	$(CC) -c main.cc

cache.o: cache.h def.h
	$(CC) -c cache.cc

memory.o: memory.h
	$(CC) -c memory.cc 

.PHONY: clean

clean:
	rm -rf sim *.o
