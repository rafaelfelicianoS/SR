#!/usr/bin/env python3
"""Run afl-fuzz inside a pseudo-terminal and keep images of its status screen.

Usage: run_afl_capture.py <label> <snapshot_dir> -- <afl-fuzz command ...>

The status screen is emulated with pyte, saved as text every 30 s and
rendered to PNG (last frame before afl-fuzz exits). Needs: pyte, pillow.
"""
import fcntl
import os
import pty
import select
import struct
import sys
import termios
import time

import pyte
from PIL import Image, ImageDraw, ImageFont

COLS, ROWS = 100, 34
FONT = "/usr/share/fonts/TTF/JetBrainsMono-Regular.ttf"
FONT_B = "/usr/share/fonts/TTF/JetBrainsMono-Bold.ttf"
PALETTE = {
    "default": (220, 220, 220), "black": (30, 30, 30), "red": (230, 80, 80),
    "green": (110, 210, 110), "brown": (220, 190, 80), "yellow": (240, 220, 90),
    "blue": (110, 150, 240), "magenta": (210, 120, 210), "cyan": (100, 210, 220),
    "white": (235, 235, 235), "brightblack": (130, 130, 130),
    "brightred": (255, 110, 110), "brightgreen": (140, 240, 140),
    "brightyellow": (255, 240, 120), "brightblue": (140, 180, 255),
    "brightmagenta": (240, 150, 240), "brightcyan": (140, 240, 250),
    "brightwhite": (255, 255, 255),
}
BG = (18, 18, 18)


def colour(name, bold):
    if name.startswith("bright") or not bold:
        return PALETTE.get(name, PALETTE["default"])
    return PALETTE.get("bright" + name, PALETTE.get(name, PALETTE["default"]))


def render(screen, path):
    size = 15
    font = ImageFont.truetype(FONT, size)
    font_b = ImageFont.truetype(FONT_B, size)
    cw = int(font.getlength("M"))
    ch = size + 4
    used = [y for y in range(ROWS) if screen.display[y].strip()]
    rows = (max(used) + 1) if used else ROWS
    cols = max((len(screen.display[y].rstrip()) for y in range(ROWS)), default=COLS)
    img = Image.new("RGB", (cw * cols + 20, ch * rows + 20), BG)
    draw = ImageDraw.Draw(img)
    for y in range(rows):
        line = screen.buffer[y]
        for x in range(cols):
            c = line[x]
            if c.data in ("", " "):
                continue
            draw.text((10 + x * cw, 10 + y * ch), c.data,
                      font=font_b if c.bold else font, fill=colour(c.fg, c.bold))
    img.save(path)


def main():
    label, outdir = sys.argv[1], sys.argv[2]
    cmd = sys.argv[sys.argv.index("--") + 1:]
    os.makedirs(outdir, exist_ok=True)
    screen = pyte.Screen(COLS, ROWS)
    stream = pyte.ByteStream(screen)
    pid, fd = pty.fork()
    if pid == 0:
        os.environ["TERM"] = "xterm-256color"
        os.environ["COLUMNS"], os.environ["LINES"] = str(COLS), str(ROWS)
        fcntl.ioctl(1, termios.TIOCSWINSZ, struct.pack("HHHH", ROWS, COLS, 0, 0))
        os.execvp(cmd[0], cmd)
    last = time.time()
    frames = []
    with open(os.path.join(outdir, f"{label}.log"), "wb") as raw:
        while True:
            r, _, _ = select.select([fd], [], [], 1.0)
            if r:
                try:
                    data = os.read(fd, 65536)
                except OSError:
                    break
                if not data:
                    break
                raw.write(data)
                stream.feed(data)
            if time.time() - last >= 30:
                last = time.time()
                text = "\n".join(screen.display)
                if "total execs" in text or "exec speed" in text:
                    frames.append(text)
                    with open(os.path.join(outdir, f"{label}-status.txt"), "w") as f:
                        f.write(text + "\n")
                    render(screen, os.path.join(outdir, f"{label}-status.png"))
    os.waitpid(pid, 0)
    print(f"{label}: {len(frames)} frames captured")


if __name__ == "__main__":
    main()
