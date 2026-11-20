# SR Ex3: execução real de AFL++ (cJSON 1.7.10 vs 1.7.19)

Evidência da secção "Fuzzing Run with AFL++" do paper (`../../Projeto/SR/paper/sections/fuzzrun.tex`).

## Estrutura
| Pasta | Conteúdo |
|---|---|
| `tools/AFLplusplus` | AFL++ 5.04a compilado a partir do código-fonte (commit `d798677`), clang 23.1.4 |
| `targets/cjson-src` | clone de `DaveGamble/cJSON`; `cjson-1.7.10/` e `cjson-1.7.19/` têm só `cJSON.c/.h` de cada tag |
| `harness/` | `cjson_read_fuzzer.c` e `fuzz_main.c` (harness OSS-Fuzz do próprio projeto) e `json.dict` |
| `bin/` | `fuzz-<v>` (afl-clang-fast + ASan + UBSan + libAFLDriver) e `repro-<v>` (clang + ASan + UBSan, sem AFL) |
| `seeds/` | 11 ficheiros de exemplo do cJSON convertidos para o formato do harness + 2 ordens de transferência sintéticas |
| `results/afl-<v>/` | saída do afl-fuzz (`fuzzer_stats`, `plot_data`, `crashes/`) |
| `results/triage/` | relatórios ASan por crash, `crashes.csv`, `buckets.csv`, inputs minimizados (`min/`) |
| `screenshots/` | ecrã de estado do AFL++ capturado do terminal (PNG e texto) e gráfico de cobertura e crashes |
| `scripts/` | `run_campaign.sh`, `run_afl_capture.py`, `triage.sh`, `plot.py` |

## Reproduzir
```bash
# 1. AFL++
(cd tools/AFLplusplus && make -j16 all)
# 2. alvos (ver comandos no paper ou no histórico): fuzz-<v> e repro-<v> em bin/
# 3. campanha de 15 min nas duas versões, em paralelo (precisa de pyte e pillow no python indicado)
PY=/caminho/para/venv/bin/python ./scripts/run_campaign.sh
# 4. triagem e minimização
./scripts/triage.sh
# 5. gráfico
/caminho/para/venv/bin/python scripts/plot.py results screenshots/afl-progress.pdf
```

Formato do input do harness: 4 bytes de flags (`0`/`1`: minify, require_termination, formatted, buffered), depois o JSON, terminado com um byte NUL.
