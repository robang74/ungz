LUAJ := LuaJIT/src/luajit
DASM := LuaJIT/dynasm
OPTS ?= -O2 -g0 -s

.PHONY: clean veryclean distclean

all: libungz.a ungz bencher ungz

LuaJIT/src:
	@echo "making $@"
	git submodule update --init --recursive --jobs $(shell nproc)

$(LUAJ): LuaJIT/src $(DASM)
	@echo "making $@"
	make -C LuaJIT -j

clean:
	rm -f ungz_s.h ungz_o.s *.o
	rm -f builder bencher bench.gz

veryclean: clean
	make -C LuaJIT -j clean

distclean: veryclean
	rm -f libungz.a ungz

ungz_s.h: ungz.s $(LUAJ)
	@echo "making $@"
	$(LUAJ) $(DASM)/dynasm.lua -o ungz_s.h -F ungz.s

test.o: test.c test.h ungz.h
	@echo "making $@"
	gcc $(OPTS) -c -o $@ test.c

builder: builder.c ungz_s.h test.o
	@echo "making $@"
	gcc $(OPTS) -o $@ -I$(DASM) builder.c test.o

ungz.o: builder
	@echo "making $@"
	./builder >/dev/null
	gcc $(OPTS) -c -o $@ ungz_o.s

libungz.a: ungz.o
	@echo "making $@"
	ar rcs $@ ungz.o

bencher: ungz.h bench.c ungz.o
	@echo "making $@"
	gcc $(OPTS) -o $@ bench.c ungz.o
	
ungz: ungz.h ungz.c ungz.o
	@echo "making $@"
	gcc $(OPTS) -o $@ ungz.c ungz.o
