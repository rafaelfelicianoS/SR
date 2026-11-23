#!/bin/bash
# Builds bin/fuzz-<v> (afl-clang-fast + ASan + UBSan + AFL++ driver, persistent mode)
# and bin/repro-<v> (clang + ASan + UBSan, no AFL) for cJSON 1.7.10 and 1.7.19.
# Requires tools/AFLplusplus built first: (cd tools/AFLplusplus && make -j16 all)
set -eu
E="$(cd "$(dirname "$0")/.." && pwd)"
cd "$E"
mkdir -p bin
for v in 1.7.10 1.7.19; do
  # cJSON.c/.h of each release tag, taken from the cjson-src submodule
  mkdir -p "targets/cjson-$v"
  for f in cJSON.c cJSON.h; do
    git -C targets/cjson-src show "v$v:$f" > "targets/cjson-$v/$f"
  done
  AFL_USE_ASAN=1 AFL_USE_UBSAN=1 tools/AFLplusplus/afl-clang-fast -g -O1 -fsanitize=fuzzer \
    -I "targets/cjson-$v" harness/cjson_read_fuzzer.c "targets/cjson-$v/cJSON.c" -o "bin/fuzz-$v"
  clang -g -O1 -fsanitize=address,undefined \
    -I "targets/cjson-$v" harness/cjson_read_fuzzer.c harness/fuzz_main.c "targets/cjson-$v/cJSON.c" -o "bin/repro-$v"
done
