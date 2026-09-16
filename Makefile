LUAJ ?= LuaJIT/src/luajit
DASM ?= LuaJIT/dynasm
OPTS ?= -O2 -g0 -s

all: bencher ungz libungz.a

LuaJIT/src:
	git submodule update --init --recursive --jobs $(shell nproc)

$(LUAJ): $(DASM)

$(DASM): LuaJIT/src
	cd LuaJIT/ && make -j

clean:
	rm -f ungz_s.h ungz_o.s *.o
	rm -f builder bencher bench.gz

distclean: clean
	rm -f libungz.a ungz

ungz_s.h: $(LUAJ) $(DASM) ungz.s
	$(LUAJ) $(DASM)/dynasm.lua -o ungz_s.h -F ungz.s

test.o: test.c test.h ungz.h
	gcc $(OPTS) -c -o $@ test.c

ungz.o: builder
	./builder >/dev/null
	gcc $(OPTS) -c -o $@ ungz_o.s

libungz.a: ungz.o
	ar rcs $@ ungz.o

builder: builder.c ungz_s.h test.o
	gcc $(OPTS) -o $@ -I $(DASM) builder.c test.o

bencher: ungz.o ungz.h bench.c
	gcc $(OPTS) -o $@ bench.c ungz.o
	
ungz: ungz.o ungz.h ungz.c
	gcc $(OPTS) -o $@ ungz.c ungz.o
