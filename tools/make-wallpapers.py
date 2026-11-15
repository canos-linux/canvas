#!/usr/bin/env python3
# Generates the default Canvas wallpapers procedurally (no external assets).
# Output: <outdir>/<name>.ppm at low resolution; upscale with ImageMagick.
# The generated images are released under CC0.
import math, sys, os

W, H = 1280, 720


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def write(path, px):
    with open(path, "wb") as f:
        f.write(b"P6 %d %d 255\n" % (W, H))
        f.write(bytes(max(0, min(255, int(round(c)))) for p in px for c in p))


def canvas():
    bg1, bg2, acc = hexc("#0d0b14"), hexc("#1b1530"), hexc("#b9a4ff")
    cx, cy, r, w = W * 0.5, H * 0.5, H * 0.17, H * 0.022
    gap = math.radians(70)
    out = []
    for y in range(H):
        for x in range(W):
            dx, dy = x - cx, y - cy
            d = math.hypot(dx, dy)
            c = mix(bg2, bg1, smooth(d / (W * 0.6)))
            ang = math.atan2(dy, dx)
            m = smooth((abs(ang) - gap / 2) / 0.12)
            mg = smooth((abs(ang) - gap / 2 + 0.25) / 0.9)
            ring = m * math.exp(-((d - r) / w) ** 2)
            glow = mg * 0.25 * math.exp(-((d - r) / (w * 6)) ** 2)
            dot = math.hypot(x - (cx + r * 1.02), y - cy)
            dotv = math.exp(-(dot / (w * 1.3)) ** 2) + 0.35 * math.exp(-(dot / (w * 6)) ** 2)
            c = mix(c, acc, min(1.0, ring * 0.9 + glow + dotv))
            out.append(c)
    return out


def aurora():
    top, bot = hexc("#050914"), hexc("#0b1a2a")
    g1, g2 = hexc("#3ff2b0"), hexc("#3a8bff")
    out = []
    for y in range(H):
        for x in range(W):
            u, v = x / W, y / H
            c = mix(top, bot, v)
            for k, (amp, ph, base, col) in enumerate([(0.08, 0.0, 0.38, g1), (0.06, 2.1, 0.5, g2), (0.05, 4.0, 0.3, g1)]):
                center = base + amp * math.sin(u * 6.3 + ph) + 0.03 * math.sin(u * 17 + ph * 2)
                dist = v - center
                band = math.exp(-(dist / 0.035) ** 2) if dist < 0 else math.exp(-(dist / 0.16) ** 2)
                shimmer = 0.78 + 0.22 * math.sin(u * 37 + ph * 5) * math.sin(u * 11 - ph)
                c = mix(c, col, band * shimmer * (0.75 - k * 0.15))
            out.append(c)
    return out


def tide():
    sky1, sky2 = hexc("#0a1630"), hexc("#16325c")
    layers = [hexc("#1d4e89"), hexc("#17407a"), hexc("#11325f"), hexc("#0b2346"), hexc("#06152c")]
    out = []
    for y in range(H):
        for x in range(W):
            u, v = x / W, y / H
            c = mix(sky1, sky2, v)
            for i, col in enumerate(layers):
                base = 0.42 + i * 0.12
                yy = base + 0.035 * math.sin(u * (5 + i) * math.pi + i * 1.7) + 0.015 * math.sin(u * 23 + i)
                if v > yy:
                    edge = smooth((v - yy) / 0.004)
                    c = mix(c, col, edge)
            out.append(c)
    return out


def ember():
    bg, mid, hot = hexc("#0e0607"), hexc("#5a1a12"), hexc("#ff8a3d")
    out = []
    for y in range(H):
        for x in range(W):
            u, v = x / W, y / H
            d = math.hypot((u - 0.5) * 1.6, (v - 1.05))
            c = mix(hot, mid, smooth(d / 0.55))
            c = mix(c, bg, smooth((d - 0.35) / 0.6))
            for i in range(4):
                yy = 0.62 + i * 0.09 + 0.04 * math.sin(u * 7 + i * 1.3)
                line = math.exp(-((v - yy) / 0.004) ** 2)
                c = mix(c, hot, line * (0.55 - i * 0.1))
            out.append(c)
    return out


def dusk():
    s1, s2, s3 = hexc("#1a1033"), hexc("#7a3b7a"), hexc("#f2a07b")
    sun = hexc("#ffd3a8")
    ridges = [hexc("#5b2f63"), hexc("#3f2150"), hexc("#29163b"), hexc("#160c24")]
    out = []
    for y in range(H):
        for x in range(W):
            u, v = x / W, y / H
            c = mix(s1, s2, smooth(v / 0.55)) if v < 0.55 else mix(s2, s3, smooth((v - 0.55) / 0.2))
            sd = math.hypot((u - 0.62) * 1.78, v - 0.56)
            c = mix(c, sun, 1.0 if sd < 0.09 else math.exp(-((sd - 0.09) / 0.05) ** 2) * 0.6)
            for i, col in enumerate(ridges):
                base = 0.58 + i * 0.09
                yy = base - 0.07 * abs(math.sin(u * (2.2 + i * 0.7) + i)) - 0.025 * abs(math.sin(u * 11 + i * 3))
                if v > yy:
                    c = mix(c, col, smooth((v - yy) / 0.004))
            out.append(c)
    return out


THEMES = {"canvas": canvas, "aurora": aurora, "tide": tide, "ember": ember, "dusk": dusk}

if __name__ == "__main__":
    outdir = sys.argv[1] if len(sys.argv) > 1 else "."
    names = sys.argv[2:] or list(THEMES)
    os.makedirs(outdir, exist_ok=True)
    for n in names:
        write(os.path.join(outdir, n + ".ppm"), THEMES[n]())
        print(n)
