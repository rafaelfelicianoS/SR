# SR Ex3: execução real de AFL++ (cJSON 1.7.10 vs 1.7.19)

Evidência da secção "Fuzzing Run with AFL++" do paper (`../paper/sections/fuzzrun.tex`).

## Estrutura
| Pasta | Conteúdo |
|---|---|
| `tools/AFLplusplus` | submódulo git: AFL++ 5.04a, commit `d798677`, compilado com clang 23.1.4 (`tools/afl-build.log`) |
| `targets/cjson-src` | submódulo git: `DaveGamble/cJSON`, commit `6d9f244` |
| `targets/cjson-1.7.10/`, `targets/cjson-1.7.19/` | só `cJSON.c/.h` de cada tag, extraídos de `cjson-src` |
| `harness/` | `cjson_read_fuzzer.c` e `fuzz_main.c` (harness OSS-Fuzz do próprio projeto) e `json.dict` |
| `bin/` | `fuzz-<v>` (afl-clang-fast + ASan + UBSan + libAFLDriver) e `repro-<v>` (clang + ASan + UBSan, sem AFL), x86-64 Linux |
| `seeds/` | 11 ficheiros de exemplo do cJSON convertidos para o formato do harness + 2 ordens de transferência sintéticas |
| `results/afl-<v>/` | saída do afl-fuzz (`fuzzer_stats`, `plot_data`, `queue/`, `crashes/`, `hangs/`) e hora de início/fim da campanha |
| `results/triage/` | relatórios ASan por crash (`asan/`), `crashes.csv`, `buckets.csv`, inputs minimizados (`min/`) |
| `screenshots/` | ecrã de estado do AFL++ capturado do terminal (PNG e texto), saída bruta do terminal (`cjson-<v>.log.gz`) e gráfico de cobertura e crashes (`afl-progress.pdf/.png`) |
| `scripts/` | `build_targets.sh`, `run_campaign.sh` (`run_campaign_rel.sh` usa caminhos relativos no ecrã de estado), `run_afl_capture.py`, `triage.sh`, `classify.py`, `plot.py` |

## Requisitos
- Linux x86-64 (ou WSL2 com o repositório clonado dentro do sistema de ficheiros do WSL: os nomes dos crashes têm `:` e `,`, que o Windows não aceita)
- `clang`/LLVM com `llvm-config` e `make`, para compilar o AFL++ em modo LLVM
- Python 3 com `pyte`, `pillow` e `matplotlib` (`python3 -m venv venv && venv/bin/pip install pyte pillow matplotlib`)
- Os binários de `bin/` foram compilados em Arch Linux: os `fuzz-<v>` precisam de glibc ≥ 2.38 (Ubuntu 24.04 serve, Ubuntu 22.04 e Debian 12 não) e os `repro-<v>` de glibc ≥ 2.34. Se não arrancarem, recompila com `./scripts/build_targets.sh`.

## Reproduzir
Atenção: `run_campaign*.sh` e `triage.sh` apagam e reescrevem `results/afl-<v>/`, `results/triage/` e os ecrãs em `screenshots/`. Para voltar à evidência da campanha original: `git restore results screenshots bin`.

```bash
# 0. submódulos (AFL++ e cJSON); ou clonar com git clone --recursive
git submodule update --init
# 1. AFL++
(cd tools/AFLplusplus && make -j16 all)
# 2. alvos: targets/cjson-<v>/ e bin/fuzz-<v>, bin/repro-<v>
./scripts/build_targets.sh
# 3. campanha de 15 min nas duas versões, em paralelo (precisa de pyte e pillow no python indicado)
PY=/caminho/para/venv/bin/python ./scripts/run_campaign_rel.sh
# 4. triagem e minimização
./scripts/triage.sh
# 5. gráfico
/caminho/para/venv/bin/python scripts/plot.py results screenshots/afl-progress.pdf
```

Para só confirmar um crash com os binários incluídos:
```bash
bin/repro-1.7.10 results/triage/min/crashes-id:000000.min   # heap-buffer-overflow
bin/repro-1.7.19 results/triage/min/crashes-id:000000.min   # sem crash
```

Formato do input do harness: 4 bytes de flags (`0`/`1`: minify, require_termination, formatted, buffered), depois o JSON, terminado com um byte NUL.
