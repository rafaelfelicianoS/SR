#!/bin/bash
# 15-minute AFL++ campaign on cJSON 1.7.10 (vulnerable) and 1.7.19 (current), run in parallel.
# Same seeds, dictionary, harness and sanitizers for both builds.
set -u
E="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PY:-python3}"
export AFL_SKIP_CPUFREQ=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
DUR="${DUR:-900}"
for v in 1.7.10 1.7.19; do
  rm -rf "$E/results/afl-$v"
  "$PY" "$E/scripts/run_afl_capture.py" "cjson-$v" "$E/screenshots" -- \
    "$E/tools/AFLplusplus/afl-fuzz" -i "$E/seeds" -o "$E/results/afl-$v" \
    -x "$E/harness/json.dict" -V "$DUR" -- "$E/bin/fuzz-$v" &
done
wait
date -Is > "$E/results/campaign_end.txt"
