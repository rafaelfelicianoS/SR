#!/bin/bash
# Replay every saved crash and hang on plain ASan/UBSan builds of both cJSON
# versions, record the sanitizer report and the root cause (scripts/classify.py),
# and minimise one input per root cause with afl-tmin.
set -u
E="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$E/results/triage"
rm -rf "$OUT"; mkdir -p "$OUT/asan" "$OUT/min"
export ASAN_OPTIONS=detect_leaks=0:symbolize=1 UBSAN_OPTIONS=print_stacktrace=1
CSV="$OUT/crashes.csv"
echo "crash,asan_type,access,frame,repro_1.7.10,repro_1.7.19,cause" > "$CSV"
for c in "$E"/results/afl-1.7.10/default/crashes/id:* "$E"/results/afl-1.7.10/default/hangs/id:*; do
  [ -f "$c" ] || continue
  id="$(basename "$(dirname "$c")")-$(basename "$c" | cut -d, -f1)"
  "$E/bin/repro-1.7.10" "$c" > /dev/null 2> "$OUT/asan/$id.txt"
  r10=$?
  "$E/bin/repro-1.7.19" "$c" > /dev/null 2> "$OUT/asan/$id-1.7.19.txt"
  r19=$?
  type="$(grep -m1 -oE 'ERROR: AddressSanitizer: [a-z-]+|runtime error: [^:]+' "$OUT/asan/$id.txt" | sed 's/ERROR: AddressSanitizer: //')"
  access="$(grep -m1 -oE '(READ|WRITE) of size [0-9]+' "$OUT/asan/$id.txt")"
  frame="$(grep -m1 -oE 'in [A-Za-z_]+ [^ ]*cJSON\.c:[0-9]+' "$OUT/asan/$id.txt" | sed -E 's#in ([A-Za-z_]+) .*/(cJSON\.c:[0-9]+)#\1 \2#')"
  cause="$(python3 -I "$E/scripts/classify.py" "$c" | awk -F, '{print $NF}')"
  echo "$id,${type:-none},${access:-},${frame:-},$r10,$r19,$cause" >> "$CSV"
done
# one representative per root cause
tail -n +2 "$CSV" | awk -F, '!seen[$7]++' > "$OUT/buckets.csv"
while IFS=, read -r id type access frame r10 r19 cause; do
  src="$(ls "$E"/results/afl-1.7.10/default/${id%%-*}/"${id#*-}",* | head -1)"
  "$E/tools/AFLplusplus/afl-tmin" -t 5000 -i "$src" -o "$OUT/min/$id.min" -- "$E/bin/fuzz-1.7.10" > "$OUT/min/$id.tmin.log" 2>&1
done < "$OUT/buckets.csv"
echo "inputs: $(($(wc -l < "$CSV") - 1))"
echo "by cause:"; tail -n +2 "$CSV" | awk -F, '{print $7}' | sort | uniq -c
echo "buckets:"; cat "$OUT/buckets.csv"
echo "crashing on 1.7.19: $(awk -F, 'NR>1 && $6!=0' "$CSV" | wc -l)"
