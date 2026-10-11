#!/bin/bash
set -e

# Determine directory containing the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target directory containing the LaTeX document
if [ -d "$SCRIPT_DIR/paper" ]; then
    PAPER_DIR="$SCRIPT_DIR/paper"
else
    PAPER_DIR="$SCRIPT_DIR"
fi

cd "$PAPER_DIR"

echo "==> Compiling LaTeX document in $PAPER_DIR..."

# Use latexmk if available, otherwise fallback to pdflatex
if command -v latexmk >/dev/null 2>&1; then
    latexmk -pdf -interaction=nonstopmode main.tex
    echo "==> Cleaning auxiliary build files..."
    latexmk -c main.tex
else
    pdflatex -interaction=nonstopmode main.tex
    pdflatex -interaction=nonstopmode main.tex
    echo "==> Cleaning auxiliary build files..."
fi

# Ensure all auxiliary files are removed, keeping the generated PDF
rm -f *.aux *.log *.out *.toc *.lof *.lot *.bbl *.blg *.synctex.gz *.fls *.fdb_latexmk *.nav *.snm *.vrb

echo "==> Done! Output PDF: $PAPER_DIR/main.pdf"
