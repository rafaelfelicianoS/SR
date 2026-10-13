#!/bin/bash
# Full build of the paper: figures, LaTeX, BibTeX and the final PDF.
# Usage: ./compile.sh        build and clean auxiliary files
#        ./compile.sh -k     build and keep auxiliary files (useful for debugging)
set -e

KEEP_AUX=0
[ "$1" = "-k" ] && KEEP_AUX=1

# Determine directory containing the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target directory containing the LaTeX document
if [ -d "$SCRIPT_DIR/paper" ]; then
    PAPER_DIR="$SCRIPT_DIR/paper"
else
    PAPER_DIR="$SCRIPT_DIR"
fi

AUX_EXT="aux log out toc lof lot bbl blg synctex.gz fls fdb_latexmk nav snm vrb"

clean_aux() {
    for ext in $AUX_EXT; do
        rm -f "$1"/*."$ext"
    done
}

# Run a LaTeX/BibTeX step and stop with the relevant errors if it fails
run() {
    local log="$1"; shift
    if ! "$@" >/dev/null 2>&1; then
        echo "!! Failed: $*"
        if [ -f "$log" ]; then
            grep -A3 -E "^!|Error" "$log" | head -40
        fi
        exit 1
    fi
}

cd "$PAPER_DIR"

# 1. Figures written in LaTeX/TikZ (figures/*.tex -> figures/*.pdf)
if ls figures/*.tex >/dev/null 2>&1; then
    echo "==> Compiling figures..."
    for fig in figures/*.tex; do
        name="$(basename "$fig" .tex)"
        echo "    $name"
        (cd figures && run "$name.log" pdflatex -interaction=nonstopmode -halt-on-error "$name.tex")
    done
fi

# 2. Paper: pdflatex -> bibtex -> pdflatex -> pdflatex
echo "==> Compiling main.tex..."
run main.log pdflatex -interaction=nonstopmode -halt-on-error main.tex
if grep -q '\\bibdata' main.aux; then
    echo "==> Running BibTeX..."
    run main.blg bibtex main
fi
run main.log pdflatex -interaction=nonstopmode -halt-on-error main.tex
run main.log pdflatex -interaction=nonstopmode -halt-on-error main.tex

# 3. Report problems that do not stop the build
if grep -q -E "Citation .* undefined|Reference .* undefined" main.log; then
    echo "!! Warning: undefined citations or references:"
    grep -E "Citation .* undefined|Reference .* undefined" main.log | sort -u
fi
if [ -f main.blg ] && grep -q "^Warning--" main.blg; then
    echo "!! BibTeX warnings:"
    grep "^Warning--" main.blg
fi

PAGES=""
if command -v pdfinfo >/dev/null 2>&1; then
    PAGES="$(pdfinfo main.pdf | awk '/^Pages:/ {print $2}')"
fi

# 4. Clean auxiliary files, keeping the PDFs
if [ "$KEEP_AUX" -eq 0 ]; then
    echo "==> Cleaning auxiliary build files..."
    clean_aux .
    clean_aux figures
fi

echo "==> Done! Output PDF: $PAPER_DIR/main.pdf${PAGES:+ ($PAGES pages)}"
if [ -n "$PAGES" ] && [ "$PAGES" -gt 4 ]; then
    echo "!! Warning: the paper has more than 4 pages (limit of the assignment)."
fi
