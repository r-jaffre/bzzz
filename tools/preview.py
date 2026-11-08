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


def render(path, W, running, paused_state=False):
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
    timeY = int(H * 47 / 100)
    th, mh = 120, 28
    dotR = int(H * 45 / 1000)
    gap = int(H * 4 / 100)
    dotY = timeY - th // 2 - gap - dotR
    ticksY = timeY + th // 2 + gap + mh // 2
    orange = (255, 255, 0, 255)
    if running:
        disc(cx, dotY, dotR, green)
    elif paused_state:
        disc(cx, dotY, dotR, orange)
        disc(cx - dotR // 2, dotY, dotR // 2, white)
        disc(cx - dotR // 5, dotY, int(dotR * 0.45), orange)
    else:
        arc(cx, dotY, dotR, 0, 360, white, 2)
    rect(cx - 55, timeY - th // 2, 110, th, white)
    rect(cx - 20, ticksY - mh // 2, 40, mh, white)

    # Button hints at the real FR255 button angles: START ~ -30deg,
    # UP 180deg (dots), DOWN ~150deg (reset circle+arrow, drawn as
    # line segments). Same geometry as drawButtonHints().
    d = int(r * 0.85)
    gs = int(W * 0.05)

    re = int(r * 0.97)
    for za in (-30, 150, 180):
        a = za - 10
        while a <= za + 10:
            cxp = int(cx + re * math.cos(math.radians(a)))
            cyp = int(cy + re * math.sin(math.radians(a)))
            disc(cxp, cyp, 1, gray)
            a += 1

    def hint_point(deg):
        rad = math.radians(deg)
        return int(cx + d * math.cos(rad)), int(cy + d * math.sin(rad))

    x, y = hint_point(-30)
    if running:
        rect(x - gs // 2, y - gs // 2, max(1, gs // 3), gs, gray)
        rect(x + gs // 6, y - gs // 2, max(1, gs // 3), gs, gray)
    else:
        tri(x, y, gs // 2, gray)

    for ang in (176, 180, 184):
        x, y = hint_point(ang)
        disc(x, y, max(2, gs // 6), gray)

    x, y = hint_point(150)
    rr = gs // 2
    prev = (x + rr * math.cos(math.radians(20)), y + rr * math.sin(math.radians(20)))
    for i in range(1, 33):
        a = math.radians(20 + i * 10)
        cur = (x + rr * math.cos(a), y + rr * math.sin(a))
        line(prev[0], prev[1], cur[0], cur[1], gray, 2)
        prev = cur
    ta = math.radians(340)
    ex, ey = x + rr * math.cos(ta), y + rr * math.sin(ta)
    tx, ty = -math.sin(ta), math.cos(ta)
    nx, ny = math.cos(ta), math.sin(ta)
    tip = (ex + rr * 0.9 * tx, ey + rr * 0.9 * ty)
    b1 = (ex - rr * 0.1 * tx + rr * 0.55 * nx, ey - rr * 0.1 * ty + rr * 0.55 * ny)
    b2 = (ex - rr * 0.1 * tx - rr * 0.55 * nx, ey - rr * 0.1 * ty - rr * 0.55 * ny)
    tri3 = [tip, b1, b2]
    for i in range(3):
        x0, y0 = tri3[i]; x1, y1 = tri3[(i + 1) % 3]
        line(x0, y0, x1, y1, gray, 2)
    ys = [p[1] for p in tri3]
    for yy in range(int(min(ys)), int(max(ys)) + 1):
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
render(os.path.join(OUT, 'preview-fr255-paused.png'), 520, False, True)
render(os.path.join(OUT, 'preview-fr255s-ready.png'), 436, False)
