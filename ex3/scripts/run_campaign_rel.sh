#!/bin/bash
# 15-minute AFL++ campaign on cJSON 1.7.10 (vulnerable) and 1.7.19 (current), run in parallel.
# Same seeds, dictionary, harness and sanitizers for both builds.
set -u
E="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PY:-python3}"
export AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
DUR="${DUR:-900}"
cd "$E"   # relative paths, so the status screen shows no home directory
for v in 1.7.10 1.7.19; do
  rm -rf "results/afl-$v"
  "$PY" scripts/run_afl_capture.py "cjson-$v" screenshots -- \
    tools/AFLplusplus/afl-fuzz -i seeds -o "results/afl-$v" \
    -x harness/json.dict -V "$DUR" -- "bin/fuzz-$v" &
done
wait
date -Is > "$E/results/campaign_end.txt"
