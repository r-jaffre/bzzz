import zlib, struct, math, os

# Renders a mock of the Bzzz main screen at a given size/state.
# The icon geometry mirrors drawButtonIcons() in source/StopwatchView.mc:
# keep the two in sync when changing layout.
#
# Renders at 2x device resolution so small glyphs stay crisp when viewed on GitHub.
# Usage: python3 tools/preview.py   -> writes docs/preview-*.png

OUT = os.path.join(os.path.dirname(__file__), '..', 'docs')

STATUS_Y = 18
TIME_Y = 46
TICKS_Y = 74
D_FRAC = 78
S_FRAC = 9
C_FRAC = 7071
DOT_ANGLES = [(-4226, 9063), (-7071, 7071), (-9063, 4226)]


def render(path, W, running):
    H = W
    px = [[(0, 0, 0, 255) for _ in range(W)] for _ in range(H)]

    def put(x, y, col):
        if 0 <= x < W and 0 <= y < H:
            px[y][x] = col

    def disc(cx, cy, r, col):
        for y in range(H):
            for x in range(W):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    px[y][x] = col

    def rect(x0, y0, w, h, col):
        for y in range(max(0, int(y0)), min(H, int(y0 + h))):
            for x in range(max(0, int(x0)), min(W, int(x0 + w))):
                px[y][x] = col

    def line(x0, y0, x1, y1, col, wd=2):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n):
            x = x0 + (x1 - x0) * i / n
            y = y0 + (y1 - y0) * i / n
            for dx in range(wd):
                for dy in range(wd):
                    put(int(x) + dx, int(y) + dy, col)

    def arc(cx, cy, r, a0, a1, col, wd=2):
        a = a0
        while a <= a1:
            rad = math.radians(a)
            x = cx + r * math.cos(rad)
            y = cy + r * math.sin(rad)
            for dx in range(wd):
                for dy in range(wd):
                    put(int(x) + dx, int(y) + dy, col)
            a += 1

    def tri(x, y, s, col):
        for yy in range(-s, s + 1):
            for xx in range(-s // 2, s + 1):
                if abs(yy) <= s - (xx + s // 2):
                    put(int(x) + xx, int(y) + yy, col)

    cx = cy = W // 2
    r = W // 2
    arc(cx, cy, r - 1, 0, 360, (40, 40, 40, 255), 1)
    white = (255, 255, 255, 255)
    gray = (85, 85, 85, 255)
    green = (0, 255, 0, 255)
    rect(cx - 30, int(H * STATUS_Y / 100) - 8, 60, 16, green if running else white)
    rect(cx - 55, int(H * TIME_Y / 100) - 28, 110, 56, white)
    rect(cx - 40, int(H * TICKS_Y / 100) - 12, 80, 24, white)

    # Button hints at the real FR255 button angles (measured from the
    # simulator rendering): START ~ -60deg, UP 180deg, DOWN ~145deg.
    d = int(r * 0.90)
    gs = int(W * 0.05)

    def hint_point(deg):
        rad = math.radians(deg)
        return int(cx + d * math.cos(rad)), int(cy + d * math.sin(rad))

    x, y = hint_point(-60)
    if running:
        rect(x - gs // 2, y - gs // 2, max(1, gs // 3), gs, gray)
        rect(x + gs // 6, y - gs // 2, max(1, gs // 3), gs, gray)
    else:
        tri(x, y, gs // 2, gray)

    for ang in (174, 180, 186):
        x, y = hint_point(ang)
        disc(x, y, max(2, gs // 6), gray)

    x, y = hint_point(145)
    rr = gs // 2
    arc(x, y, rr, 30, 330, gray)
    rad = math.radians(330)
    tipx = x + rr * math.cos(rad); tipy = y + rr * math.sin(rad)
    tx, ty = -math.sin(rad), math.cos(rad)
    nx, ny = math.cos(rad), math.sin(rad)
    a = rr * 0.7; b = rr * 0.5
    tri3 = [(tipx, tipy),
            (tipx - a * tx + b * nx, tipy - a * ty + b * ny),
            (tipx - a * tx - b * nx, tipy - a * ty - b * ny)]
    for i in range(3):
        x0, y0 = tri3[i]; x1, y1 = tri3[(i + 1) % 3]
        line(x0, y0, x1, y1, gray, 2)
    for yy in range(int(min(p[1] for p in tri3)), int(max(p[1] for p in tri3)) + 1):
        xs = [p[0] for p in tri3 if abs(p[1] - yy) < 1]
        if len(xs) >= 2:
            for xx in range(int(min(xs)), int(max(xs)) + 1):
                put(xx, yy, gray)

    raw = b''
    for y in range(H):
        raw += b'\x00' + b''.join(bytes(px[y][x]) for x in range(W))

    def chunk(t, data):
        return struct.pack('>I', len(data)) + t + data + struct.pack('>I', zlib.crc32(t + data) & 0xffffffff)

    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(raw))
    png += chunk(b'IEND', b'')
    open(path, 'wb').write(png)
    print('wrote', os.path.normpath(path))


os.makedirs(OUT, exist_ok=True)
render(os.path.join(OUT, 'preview-fr255-ready.png'), 520, False)
render(os.path.join(OUT, 'preview-fr255-running.png'), 520, True)
render(os.path.join(OUT, 'preview-fr255s-ready.png'), 436, False)
