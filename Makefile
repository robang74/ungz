LUAJ ?= LuaJIT/src/luajit
DASM ?= LuaJIT/dynasm
OPTS ?= -O2 -g0 -s

all: bencher ungz

LuaJIT/src:
	git submodule update --init --recursive

$(LUAJ): $(DASM)

$(DASM): LuaJIT/src
	cd LuaJIT/ && make -j

clean:
	rm -f ungz_s.h ungz_o.s *.o
	rm -f builder bencher ungz

distclean: clean
	rm -f bench.gz

ungz_s.h: $(LUAJ) $(DASM) ungz.s
	$(LUAJ) $(DASM)/dynasm.lua -o ungz_s.h -F ungz.s

test.o: test.c test.h ungz.h
	gcc $(OPTS) -c -o test.o test.c

ungz.o: builder
	./builder >/dev/null
	gcc $(OPTS) -c -o ungz.o ungz_o.s

builder: builder.c ungz_s.h test.o
	gcc $(OPTS) -o builder -I $(DASM) builder.c test.o

bencher: ungz.o ungz.h bench.c
	gcc $(OPTS) -o $@ bench.c ungz.o
	
ungz: ungz.o ungz.h ungz.c
	gcc $(OPTS) -o $@ ungz.c ungz.o
