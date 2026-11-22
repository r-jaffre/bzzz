#!/usr/bin/env python3
"""Rasterize a TrueType font's digits into BMFont text-format .fnt + PNG pages
for the Connect IQ resource compiler (which ingests BMFont assets, not raw
TTFs). Used by app/resources/fonts/fonts.xml.

Usage: python3 tools/genfont.py [size ...]
       (default sizes: 215 180 125)
"""
import os
import sys

import freetype
from PIL import Image

TTF = os.path.join(os.path.dirname(__file__), "..", "app", "resources", "fonts", "Roboto-Black.ttf")
OUT = os.path.join(os.path.dirname(__file__), "..", "app", "resources", "fonts")
DIGITS = "0123456789"
SPACING = 1  # px between glyphs on the page (line spacing too)


def rasterize(size: int) -> None:
    face = freetype.Face(TTF)
    face.set_pixel_sizes(0, size)
    asc, desc = face.size.ascender >> 6, -face.size.descender >> 6
    line_h = asc + desc
    glyphs = []
    for ch in DIGITS:
        face.load_char(ch, freetype.FT_LOAD_RENDER | freetype.FT_LOAD_TARGET_NORMAL)
        bmp = face.glyph.bitmap
        w, h = bmp.width, bmp.rows
        glyph = {
            "ch": ch,
            "w": w,
            "h": h,
            "pitch": bmp.pitch,
            "left": face.glyph.bitmap_left,
            "top": face.glyph.bitmap_top,
            "adv": face.glyph.advance.x >> 6,
            "buf": bytes(bmp.buffer) if w and h else b"",
        }
        glyphs.append(glyph)

    # Simple pack: one row per 5 glyphs, sized to the tallest glyph.
    rows = [glyphs[i:i + 5] for i in range(0, len(glyphs), 5)]
    page_w = max(sum(g["w"] for g in row) for row in rows) + SPACING * (5 + 1)
    page_h = sum(max(g["h"] for g in row) for row in rows) + SPACING * (len(rows) + 1)

    img = Image.new("RGBA", (page_w, page_h), (0, 0, 0, 0))
    px = img.load()
    cy = SPACING
    for row in rows:
        cx = SPACING
        for g in row:
            g["x"], g["y"] = cx, cy
            for yy in range(g["h"]):
                for xx in range(g["w"]):
                    a = g["buf"][yy * g["pitch"] + xx]
                    if a:
                        px[cx + xx, cy + yy] = (255, 255, 255, a)
            cx += g["w"] + SPACING
        cy += max(g["h"] for g in row) + SPACING

    stem = f"RobotoBlack_{size}"
    img.save(os.path.join(OUT, stem + "_0.png"))
    with open(os.path.join(OUT, stem + ".fnt"), "w") as f:
        f.write(
            f'info face="Roboto Black" size={size} bold=0 italic=0 charset="" '
            f'unicode=1 stretchH=100 smooth=1 aa=2 padding=0,0,0,0 spacing=1,1 outline=0\n'
        )
        f.write(
            f"common lineHeight={line_h} base={asc} scaleW={page_w} scaleH={page_h} "
            f"pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4\n"
        )
        f.write(f'page id=0 file="{stem}_0.png"\n')
        f.write(f"chars count={len(glyphs)}\n")
        for g in glyphs:
            yoff = asc - g["top"]
            f.write(
                f"char id={ord(g['ch'])} x={g['x']} y={g['y']} width={g['w']} "
                f"height={g['h']} xoffset={g['left']} yoffset={yoff} "
                f"xadvance={g['adv']} page=0 chnl=15\n"
            )
        f.write("kernings count=0\n")
    print(f"{stem}: glyphs max {max(g['h'] for g in glyphs)}px tall, page {page_w}x{page_h}")


if __name__ == "__main__":
    for s in (sys.argv[1:] or ["290", "185", "125"]):
        rasterize(int(s))
