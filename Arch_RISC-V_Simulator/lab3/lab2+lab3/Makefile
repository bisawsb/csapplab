INCLUDE = ./inc
LIBRARY = ./lib
GCC = riscv64-unknown-elf-gcc
C_FLAGS = -lecall -Wa,-march=rv64i

simulator :
	make -C riscv-simulator
	mv ./riscv-simulator/sim .

libcall :
	$(GCC) ./inc/syscall.c -c -o ./inc/syscall.o -I$(INCLUDE) -Wa,-march=rv64i
	ar -cr ./riscv-simulator/libecall.a ./inc/syscall.o
	mv ./riscv-simulator/libecall.a $(LIBRARY)

testp :
	$(GCC) ./testbench/add.c -o ./test/add -I$(INCLUDE) -L$(LIBRARY) $(C_FLAGS)
	$(GCC) ./testbench/mul-div.c -o ./test/mul-div -I$(INCLUDE) -L$(LIBRARY) $(C_FLAGS)
	$(GCC) ./testbench/double.c -o ./test/double -I$(INCLUDE) -L$(LIBRARY) $(C_FLAGS)
	$(GCC) ./testbench/n!.c -o ./test/n! -I$(INCLUDE) -L$(LIBRARY) $(C_FLAGS)
	$(GCC) ./testbench/qsort.c -o ./test/qsort -I$(INCLUDE) -L$(LIBRARY) $(C_FLAGS)
	$(GCC) ./testbench/matmul.c -o ./test/matmul -I$(INCLUDE) -L$(LIBRARY) $(C_FLAGS)
	$(GCC) ./testbench/ackermann.c -o ./test/ackermann -I$(INCLUDE) -L$(LIBRARY) $(C_FLAGS)

cache: simulator libcall testp

clean :
	find . -name "*.o"  | xargs rm -f
	rm -f sim
	rm -f ./lib/libecall.a
	rm -f test/*
