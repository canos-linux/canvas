#!/usr/bin/env python3
# Generates the Canvas UI sounds (soft, glassy) -> sounds/*.wav
import math, struct, wave, os, sys

RATE = 44100
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "sounds")
os.makedirs(out, exist_ok=True)


def tone(freq, start, length, amp, decay, buf):
    a = int(start * RATE)
    n = int(length * RATE)
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / 0.004) * math.exp(-t * decay)
        s = math.sin(2 * math.pi * freq * t) + 0.35 * math.sin(2 * math.pi * freq * 2.01 * t) + 0.12 * math.sin(2 * math.pi * freq * 3.98 * t)
        if a + i < len(buf):
            buf[a + i] += amp * env * s


def save(name, length, notes):
    buf = [0.0] * int(length * RATE)
    for n in notes:
        tone(*n, buf)
    # tiny echo for a glassy room feel
    d = int(0.045 * RATE)
    for i in range(len(buf) - 1, d - 1, -1):
        buf[i] += 0.22 * buf[i - d]
    peak = max(abs(x) for x in buf) or 1
    scale = 0.7 / peak
    with wave.open(os.path.join(out, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * scale)) * 32767)) for x in buf))


C5, E5, G5, A5, B5, C6, E6, G6, B6 = 523.25, 659.25, 783.99, 880.0, 987.77, 1046.5, 1318.5, 1568.0, 1975.5

save("click", 0.08, [(2400, 0, 0.06, 0.6, 90), (4800, 0, 0.03, 0.2, 160)])
save("open", 0.3, [(E6, 0, 0.2, 0.5, 22), (G6, 0.06, 0.22, 0.5, 20)])
save("close", 0.3, [(G6, 0, 0.2, 0.5, 22), (E6, 0.06, 0.22, 0.45, 20)])
save("notif", 0.7, [(B5, 0, 0.5, 0.5, 9), (E6, 0.09, 0.55, 0.55, 8)])
save("login", 1.6, [(C5, 0, 1.2, 0.4, 3.5), (E5, 0.12, 1.2, 0.4, 3.5), (G5, 0.24, 1.2, 0.4, 3.5), (C6, 0.36, 1.2, 0.45, 3.2)])
save("shutdown", 1.4, [(G5, 0, 1.0, 0.45, 4), (E5, 0.16, 1.0, 0.45, 4), (C5, 0.32, 1.0, 0.45, 3.5)])
save("shot", 0.15, [(3200, 0, 0.05, 0.5, 120), (1600, 0.04, 0.08, 0.4, 70)])
save("record", 0.35, [(A5, 0, 0.25, 0.5, 14), (A5, 0.14, 0.2, 0.5, 14)])
save("error", 0.4, [(E5, 0, 0.3, 0.5, 12), (C5, 0.1, 0.3, 0.5, 12)])
