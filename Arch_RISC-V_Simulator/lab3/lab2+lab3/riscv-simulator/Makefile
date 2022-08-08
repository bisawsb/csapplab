OBJECT = main.o machine_p.o riscvISA.o stage_pipe.o cache.o config.o utils.o
INCLUDE = ../inc
CPP_FLAGS = -O2 -std=c++11

sim : $(OBJECT)
	g++ -o sim $(OBJECT) -lboost_program_options $(CPP_FLAGS)
main.o : main.cpp machine_p.hpp
	g++ -c main.cpp -I$(INCLUDE) $(CPP_FLAGS)
riscvISA.o : riscvISA.cpp riscvISA.hpp 
	g++ -c riscvISA.cpp $(CPP_FLAGS)
stage_pipe.o : stage_pipe.cpp riscvISA.hpp machine_p.hpp
	g++ -c stage_pipe.cpp $(CPP_FLAGS)
cache.o : cache.cc cache.h storage.h
	g++ -c cache.cc $(CPP_FLAGS)
machine_p.o : machine_p.cpp machine_p.hpp riscvISA.hpp
	g++ -c machine_p.cpp $(CPP_FLAGS)
config.o : config.cpp config.hpp
	g++ -c config.cpp $(CPP_FLAGS)
utils.o : utils.cpp utils.hpp
	g++ -c utils.cpp $(CPP_FLAGS)
clean :
	rm sim $(OBJECT)
