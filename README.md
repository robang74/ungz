# ungz

> [!NOTE]
> 
> In original, the project was named **pigz** but this name was colling with the parallel version of `gzip`, and it is confusing because already used by `pigz`.

## Inflater for gzip files

This is a library for decompressing (inflating) gzipped data. It is written in x86-64 assembly, and intended for use by C/C++ programs. It is generally faster than zlib, however unlike zlib:

  * it is not portable (only x86-64)
  * it does not do any kind of compression (only decompresssion)
  * it cannot operate on raw deflate streams (only gzip streams)
  * it is not API compatible with zlib

## Performance tests

The "hot cache" is relevant in the tests below, because the disk I/O doesn't enter in the scene anymore but just the decompressing time:

| x10 hot cache (MB/s)    | min | avg     | max | R%  | times |
|-------------------------|-----|---------|-----|----:|-------|
| `ng/minigzip -d -c <$f` | 391 | 427     | 441 | 142 | 0.70x |
| `ungz <$f`              | 291 | **300** | 307 | 100 |       |
| `cat $f : ungz`         | 292 | 298     | 304 |  99 |       |
| `cat $f : pigz -dc`     | 256 | 262     | 268 |  87 | 1.15x |
| `cat $f : gzip -dc`     | 236 | 240     | 243 |  80 | 1.25x |
| `busybox gzip -dc <$f`  | 118 | 120     | 122 |  40 | 2.50x |

The unavoidable tests, *the ones should be listed and cannot be missed*, are about [zlib-ng](https://github.com/zlib-ng/zlib-ng) which outperforms the CloudFlare x86-64 optimisations for zlib provided by an old unmaintained fork for AWS Graviton (cfr. [here](https://aws.amazon.com/it/blogs/opensource/improving-zlib-cloudflare-and-comparing-performance-with-other-zlib-forks/)).

## The API

The API is fully described in [ungz.h](ungz.h), but the quick synopsis is:

```c
typedef struct pigz_state {
  ...
  int8_t status;
  ...
} pigz_state;

typedef const char* (*pigz_reader)(void* opaque, uint64_t* len);
void pigz_init(pigz_state* state, void* opaque, pigz_reader reader);

uint64_t pigz_available(pigz_state* state);

const char* pigz_consume(pigz_state* state, uint64_t len);

// Error values for pigz_state::status
#define PIGZ_STATUS_BAD_BITS -5
#define PIGZ_STATUS_BAD_CRC -4
#define PIGZ_STATUS_BAD_HEADER -3
#define PIGZ_STATUS_UNEXPECTED_EOF -2
#define PIGZ_STATUS_EOF -1
```

To begin, call `ungz_init`, passing a callback which will provide a gzip stream. Then call `ungz_available` and `ungz_consume` in a loop until `ungz_available` returns zero. Finally, check the `status` field to determine why decompression stopped. 

A complete example is provided in [ungz.c](ungz.c).

## Building & using ungz

Clone the repository and build with `make`

To use ungz in your project, include `ungz.h` and link against `ungz.o`.

## The code

If the x86-64 assembly code is your thing, look at [ungz.s](ungz.s).

The syntax is explained by [DynASM](https://corsix.github.io/dynasm-doc/index.html) documentation.
