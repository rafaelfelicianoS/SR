#!/usr/bin/env python3
"""Classify cJSON 1.7.10 crash inputs by the branch of cJSON_Minify that
first moves the read pointer past the terminating NUL.

The loop below follows cJSON.c:2633-2701 of release 1.7.10 line by line.
Usage: classify.py <file> [<file> ...]   (prints file,class per line)
"""
import sys

OFFSET = 4  # harness: 4 flag bytes before the JSON text


def classify(buf):
    end = buf.index(0) if 0 in buf else len(buf)
    j = 0

    def past(branch):
        return branch if j > end else None

    while j < len(buf) and buf[j] != 0:
        c = buf[j]
        nxt = buf[j + 1] if j + 1 < len(buf) else None
        if c in b" \t\r\n":
            j += 1
        elif c == ord("/") and nxt == ord("/"):
            while j < len(buf) and buf[j] != 0 and buf[j] != ord("\n"):
                j += 1
        elif c == ord("/") and nxt == ord("*"):
            while j < len(buf) and buf[j] != 0 and not (
                    buf[j] == ord("*") and j + 1 < len(buf) and buf[j + 1] == ord("/")):
                j += 1
            j += 2
            if past("unterminated multiline comment"):
                return "unterminated multiline comment"
        elif c == ord('"'):
            j += 1
            while j < len(buf) and buf[j] != 0 and buf[j] != ord('"'):
                if buf[j] == ord("\\"):
                    j += 1
                j += 1
                if j > end:
                    return "backslash before the terminator in a string"
            j += 1
            if past("x"):
                return "unterminated string literal"
        else:
            j += 1
    return "no overflow in model"


def main():
    for path in sys.argv[1:]:
        data = open(path, "rb").read()
        print(f"{path},{classify(data[OFFSET:])}")


if __name__ == "__main__":
    main()
