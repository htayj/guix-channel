#!/usr/bin/env python3
"""Render the final 80x24 screen of an ANSI/VT terminal byte stream."""
from __future__ import annotations

import re
import sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("usage: render-terminal-screenshot.py INPUT OUTPUT")

raw = Path(sys.argv[1]).read_bytes().decode("utf-8", "replace")
rows, columns = 24, 80
screen = [[" "] * columns for _ in range(rows)]
row = column = 0

def param_list(text: str) -> list[int]:
    return [int(part) if part else 0 for part in text.split(";")] if text else []

index = 0
while index < len(raw):
    char = raw[index]
    if char == "\x1b" and index + 1 < len(raw):
        if raw[index + 1] == "[":
            match = re.match(r"\x1b\[([0-9;?]*)([@-~])", raw[index:])
            if match:
                params, command = param_list(match.group(1).lstrip("?")), match.group(2)
                amount = (params[0] or 1) if params else 1
                if command in "Hf":
                    row = min(rows - 1, max(0, (params[0] if params else 1) - 1))
                    column = min(columns - 1, max(0, (params[1] if len(params) > 1 else 1) - 1))
                elif command == "A": row = max(0, row - amount)
                elif command == "B": row = min(rows - 1, row + amount)
                elif command == "C": column = min(columns - 1, column + amount)
                elif command == "D": column = max(0, column - amount)
                elif command == "G": column = min(columns - 1, max(0, amount - 1))
                elif command == "J":
                    if not params or params[0] in (0, 2, 3):
                        start = 0 if params and params[0] in (2, 3) else row
                        for clear_row in range(start, rows): screen[clear_row] = [" "] * columns
                elif command == "K":
                    start = 0 if params and params[0] == 1 else column
                    end = columns if not params or params[0] != 1 else column + 1
                    screen[row][start:end] = [" "] * (end - start)
                index += len(match.group(0))
                continue
        elif raw[index + 1] == "]":
            end = re.search(r"(?:\x07|\x1b\\)", raw[index + 2:])
            index += 2 + (end.end() if end else 0)
            continue
        index += 2
        continue
    if char == "\r": column = 0
    elif char == "\n": row = min(rows - 1, row + 1)
    elif char == "\b": column = max(0, column - 1)
    elif char >= " ":
        if column < columns: screen[row][column] = char
        column += 1
        if column >= columns:
            column = 0
            row = min(rows - 1, row + 1)
    index += 1

Path(sys.argv[2]).write_text("\n".join("".join(line).rstrip() for line in screen) + "\n", encoding="utf-8")
