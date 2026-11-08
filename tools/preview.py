import zlib, struct, math, os

# Renders a mock of the Bzzz main screen at a given size/state.
# The icon geometry mirrors drawButtonIcons() in source/StopwatchView.mc:
# keep the two in sync when changing layout.
#
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

    # System button hints (personality system_icon_dark__hint_button_*):
    # small gray rounded rects placed close to the screen edge at each
    # used button position: right-top START, right-bottom BACK,
    # left-middle UP, left-bottom DOWN.
    d = int(r * 0.90)
    gs = int(W * 0.045)
    for ang in (-45, 45, 180, 135):
        rad = math.radians(ang)
        x = int(cx + d * math.cos(rad))
        y = int(cy + d * math.sin(rad))
        rect(x - gs // 2, y - gs // 2, gs, gs, gray)

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
render(os.path.join(OUT, 'preview-fr255-ready.png'), 260, False)
render(os.path.join(OUT, 'preview-fr255-running.png'), 260, True)
render(os.path.join(OUT, 'preview-fr255s-ready.png'), 218, False)
