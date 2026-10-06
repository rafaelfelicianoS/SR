# SR — Robust Software · Exercise 1

**Caso prático:** Online Banking App (Caso 7)  
**Cadeira:** Robust Software (41779) · Mestrado em Cibersegurança · UA  
**Template:** IEEE Conference (A4)

## Estrutura

```
paper/
  main.tex        ← ficheiro principal (editar aqui)
  IEEEtran.cls    ← classe IEEE (não tocar)
```

## Como compilar localmente

Precisas de uma distribuição LaTeX (TeX Live ou MiKTeX) + `latexmk`:

```bash
cd paper
latexmk -pdf main.tex
```

Ou com `pdflatex` diretamente:

```bash
cd paper
pdflatex main.tex
pdflatex main.tex   # segunda vez para referências cruzadas
```

## Secções e responsabilidades

| Secção | Peso | Responsável |
|--------|------|-------------|
| Abstract | ~10% | |
| Introduction (sistema + contexto regulatório) | ~30% | |
| Lifecycle (Training → Operations) | ~50% | |
| NFRs (3 atributos × 2 NFRs) | (incluso no lifecycle) | |
| Design Principles Checklist (tabela) | ~10% | |
| Conclusion + Referências | | |

## O que falta preencher (TODO no .tex)

1. **Autores** — nomes e emails do grupo (no topo do main.tex)
2. **Abstract** — 1 parágrafo com sistema + abordagem + conclusão
3. **Introduction** — contexto diagram, 5-8 funções, interfaces, regulação
4. **Lifecycle** — cada subsecção tem um `% TODO` com o que desenvolver
5. **NFRs** — ajustar/completar os 6 NFRs ao vosso caso concreto
6. **Tabela de princípios** — confirmar os 10 princípios da S01 e preencher H/V
7. **Conclusion** — resumo dos riscos e próximos passos

## Workflow Git sugerido

```bash
git pull                    # antes de editar
# ... editar main.tex ...
git add paper/main.tex
git commit -m "feat: descrição do que fizeste"
git push
```
