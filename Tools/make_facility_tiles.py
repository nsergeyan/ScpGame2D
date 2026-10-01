"""Repaint Kenney's platformer tilesheet into a Containment Breach style facility.

Reads  Assets/Spritesheet/platformPack_tilesheet.png  (Kenney, CC0, left untouched)
Writes Assets/Spritesheet/facility_tilesheet.png      (what the game loads)

Only the tiles the level uses as architecture are repainted: concrete walls,
steel floors, crates, catwalks, the ladder, the acid and the platforms. Items
that have to stay readable (keys, buttons, hearts, the checkpoint terminals,
the exit gate) are copied over unchanged.

Every tile is painted at 16x16 and scaled up 4x with nearest neighbour, so one
art pixel is 4 screen pixels. That matches the character sprites, which are
drawn at the same scale, so the world and the people in it read as one style.

Run from the project root:  python3 Tools/make_facility_tiles.py   (needs Pillow)
The output is deterministic: a fixed seed means a rerun gives the same image.
"""
import colorsys
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "Assets/Spritesheet/platformPack_tilesheet.png"
OUT = ROOT / "Assets/Spritesheet/facility_tilesheet.png"

ART = 16      # art pixels per tile side
SCALE = 4     # 16 * 4 = the 64px tile size the TileSet uses
CLEAR = (0, 0, 0, 0)

rng = random.Random(173)


def shade(rgb, d):
    return tuple(max(0, min(255, c + d)) for c in rgb[:3]) + (255,)


def grime_field(amp):
    """Smooth low-frequency noise that wraps, so tiled copies meet seamlessly."""
    g = [[rng.uniform(-amp, amp) for _ in range(4)] for _ in range(4)]
    field = []
    for y in range(ART):
        row = []
        for x in range(ART):
            fx, fy = x / 4.0, y / 4.0
            x0, y0 = int(fx) % 4, int(fy) % 4
            x1, y1 = (x0 + 1) % 4, (y0 + 1) % 4
            tx, ty = fx - int(fx), fy - int(fy)
            top = g[y0][x0] * (1 - tx) + g[y0][x1] * tx
            bot = g[y1][x0] * (1 - tx) + g[y1][x1] * tx
            row.append(top * (1 - ty) + bot * ty)
        field.append(row)
    return field


def surface(base, noise, grime):
    """A 16x16 grid of a base colour broken up by speckle and soft grime."""
    field = grime_field(grime)
    return [[shade(base, int(field[y][x] + rng.randint(-noise, noise))) for x in range(ART)] for y in range(ART)]


def hazard(px, x, y, period=8):
    """Diagonal yellow and black warning stripes. The period has to divide 16
    or the stripes break where two tiles meet."""
    on = ((x + y) // (period // 2)) % 2 == 0
    px[y][x] = (214, 168, 38, 255) if on else (34, 32, 30, 255)


# ---------------------------------------------------------------- tiles

def concrete_wall():
    """Ceilings and walls: pale cast concrete in 64px panels."""
    px = surface((146, 148, 142), 4, 9)
    for i in range(ART):
        px[ART - 1][i] = (96, 98, 94, 255)        # panel seam, bottom
        px[i][ART - 1] = (96, 98, 94, 255)        # panel seam, right
        px[0][i] = shade(px[0][i], 10)            # lit lip under the seam above
        px[i][0] = shade(px[i][0], 6)
    for _ in range(3):                            # air pockets in the pour
        x, y = rng.randint(2, 13), rng.randint(2, 13)
        px[y][x] = shade(px[y][x], -24)
    return px


def steel_floor():
    """The walkable top row: a dark steel slab with a worn bright lip and bolts."""
    px = surface((86, 88, 92), 3, 4)
    for x in range(ART):
        px[0][x] = (156, 158, 156, 255)
        px[1][x] = (116, 118, 118, 255)
        px[ART - 1][x] = (62, 64, 66, 255)
    for y in range(2, ART):
        px[y][ART - 1] = (66, 68, 70, 255)
    for bx in (3, 12):
        px[5][bx] = (134, 136, 138, 255)
        px[6][bx] = (54, 56, 58, 255)
    return px


def foundation():
    """Everything below the floor: dark, low-contrast concrete."""
    px = surface((64, 65, 66), 3, 5)
    for i in range(ART):
        px[ART - 1][i] = (50, 51, 52, 255)
        px[i][ART - 1] = (50, 51, 52, 255)
    return px


def back_wall():
    """The background wall behind the play space, with rust streaks running down."""
    px = surface((134, 135, 129), 3, 7)
    for i in range(ART):                          # faint seams, or the wall reads as graph paper
        px[ART - 1][i] = shade(px[ART - 1][i], -10)
        px[i][ART - 1] = shade(px[i][ART - 1], -10)
    for x in (rng.randint(2, 6), rng.randint(9, 13)):
        for y in range(rng.randint(5, 14)):
            px[y][x] = (px[y][x][0] - 8, px[y][x][1] - 10, px[y][x][2] - 14, 255)
    return px


def steel_crate():
    """Cover crates: a riveted steel box with a small hazard label."""
    px = surface((96, 99, 102), 2, 3)
    for i in range(ART):
        for e in (0, ART - 1):
            px[e][i] = (56, 58, 60, 255)
            px[i][e] = (56, 58, 60, 255)
        if 1 <= i <= ART - 2:
            px[1][i] = shade(px[1][i], 16)
            px[i][1] = shade(px[i][1], 12)
    for i in range(3, 13):                        # X brace
        px[i][i] = (80, 83, 86, 255)
        px[i][ART - 1 - i] = (80, 83, 86, 255)
    for y in range(11, 14):
        for x in range(10, 14):
            hazard(px, x, y, period=4)
    return px


def catwalk():
    """One-way platforms: a perforated steel grate, empty below."""
    px = [[CLEAR] * ART for _ in range(ART)]
    for x in range(ART):
        px[0][x] = (148, 150, 152, 255)
        px[1][x] = (100, 102, 106, 255)
        px[2][x] = (40, 41, 43, 255) if x % 2 else (100, 102, 106, 255)
        px[3][x] = (100, 102, 106, 255)
        px[4][x] = (60, 62, 64, 255)
    return px


def steel_ladder():
    """Two rails and two rungs per tile, so stacked tiles form one ladder."""
    px = [[CLEAR] * ART for _ in range(ART)]
    for y in range(ART):
        for x, c in ((2, (150, 152, 155)), (3, (100, 102, 106)), (12, (150, 152, 155)), (13, (100, 102, 106))):
            px[y][x] = c + (255,)
    for r in (2, 10):
        for x in range(4, 12):
            px[r][x] = (130, 132, 136, 255)
            px[r + 1][x] = (70, 72, 76, 255)
    return px


def unstable_ledge():
    """Crumbling platforms: hazard-striped, because they are a hazard."""
    px = [[CLEAR] * ART for _ in range(ART)]
    for y in range(ART):
        for x in range(ART):
            hazard(px, x, y)
    for x in range(ART):
        px[0][x] = (60, 58, 52, 255)
        px[7][x] = (40, 38, 34, 255)
    return px


def lift_plate():
    """Moving platforms: a riveted steel plate."""
    px = surface((92, 95, 100), 2, 3)
    for x in range(ART):
        px[0][x] = (150, 152, 156, 255)
        px[7][x] = (50, 52, 55, 255)
    for bx in (2, 13):
        px[3][bx] = (140, 142, 146, 255)
        px[4][bx] = (50, 52, 55, 255)
    return px


def door_body(striped=False):
    """Sliding blast door: two steel leaves meeting at a centre seam. The
    bottom tile carries the hazard band."""
    px = surface((88, 92, 96), 2, 3)
    for y in range(ART):
        px[y][0] = (52, 54, 58, 255)
        px[y][1] = (120, 124, 128, 255)
        px[y][ART - 1] = (52, 54, 58, 255)
        px[y][7] = (118, 122, 126, 255)
        px[y][8] = (52, 54, 58, 255)
    for x in range(ART):
        px[ART - 1][x] = (60, 62, 66, 255)
    if striped:
        for y in range(10, ART):
            for x in range(ART):
                hazard(px, x, y, period=4)
        for x in range(ART):
            px[9][x] = (34, 32, 30, 255)
    return px


# ---------------------------------------------------------------- assembly

def place(sheet, col, row, px):
    art = Image.new("RGBA", (ART, ART))
    art.putdata([c for line in px for c in line])
    sheet.paste(art.resize((ART * SCALE, ART * SCALE), Image.NEAREST), (col * 64, row * 64))


def hue_shift(sheet, col, row, hue, sat=0.75, val=0.8):
    """Recolour a tile in place, keeping its shading: orange lava to toxic green.
    Saturation and value are pulled down too, or Kenney's orange turns neon."""
    box = (col * 64, row * 64, col * 64 + 64, row * 64 + 64)
    tile = sheet.crop(box)
    out = []
    for r, g, b, a in tile.get_flattened_data():
        _, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        nr, ng, nb = colorsys.hsv_to_rgb(hue, s * sat, v * val)
        out.append((int(nr * 255), int(ng * 255), int(nb * 255), a))
    tile.putdata(out)
    sheet.paste(tile, box)


def main():
    sheet = Image.open(SRC).convert("RGBA")
    # (col, row) are atlas coordinates, matching facility_tileset.tres
    place(sheet, 3, 4, concrete_wall())
    place(sheet, 4, 4, steel_floor())
    place(sheet, 3, 1, foundation())
    place(sheet, 13, 0, back_wall())      # an empty slot in Kenney's sheet
    place(sheet, 3, 3, steel_crate())
    place(sheet, 4, 3, catwalk())
    place(sheet, 1, 4, steel_ladder())
    place(sheet, 3, 2, unstable_ledge())
    place(sheet, 6, 0, lift_plate())
    place(sheet, 13, 1, door_body())      # empty slot
    place(sheet, 12, 2, door_body(True))  # empty slot
    hue_shift(sheet, 5, 0, 0.27, 0.6, 0.62)
    hue_shift(sheet, 5, 1, 0.27, 0.6, 0.62)
    sheet.save(OUT)
    print("wrote", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
