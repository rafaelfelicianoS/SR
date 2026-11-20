#!/usr/bin/env python3
"""Plot edges found and saved crashes over time for both AFL++ runs.

Usage: plot.py <results_dir> <output.pdf>
Reads <results_dir>/afl-<version>/default/plot_data. Needs matplotlib.
"""
import csv
import os
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

RUNS = [("1.7.10", "#b2182b", "-"), ("1.7.19", "#2166ac", "--")]


def load(path):
    with open(path) as f:
        header = f.readline().lstrip("#").strip().split(", ")
        rows = [dict(zip(header, r)) for r in csv.reader(f, skipinitialspace=True) if r]
    return rows


def main():
    res, out = sys.argv[1], sys.argv[2]
    plt.rcParams.update({"font.size": 8, "font.family": "serif"})
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(7.0, 2.2))
    for ver, col, ls in RUNS:
        rows = load(os.path.join(res, f"afl-{ver}", "default", "plot_data"))
        t = [int(r["relative_time"]) / 60 for r in rows]
        ax1.plot(t, [int(r["edges_found"]) for r in rows], color=col, ls=ls, label=f"cJSON {ver}")
        ax2.plot(t, [int(r["saved_crashes"]) for r in rows], color=col, ls=ls, label=f"cJSON {ver}")
    ax1.set_title("Edges found")
    ax2.set_title("Saved crashes")
    for ax in (ax1, ax2):
        ax.set_xlabel("Time (min)")
        ax.grid(alpha=0.3)
        ax.set_xlim(0, 15)
    ax2.legend(loc="center right", frameon=False)
    fig.tight_layout()
    fig.savefig(out)
    fig.savefig(os.path.splitext(out)[0] + ".png", dpi=150)


if __name__ == "__main__":
    main()
