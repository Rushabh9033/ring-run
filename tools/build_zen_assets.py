#!/usr/bin/env python3
"""Build the Ring Run Zen Bamboo UI asset pack.

Every asset is drawn here as a 1024x1024 (or matching) RGBA canvas with the
exact filenames the design calls for, so the Godot side can reference them
directly and the whole pack can be regenerated at any size.

Palette: jade green, gold, warm ivory, and the purple / orange / blue rings.
"""

import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# --------------------------------------------------------------------------
# paths
# --------------------------------------------------------------------------
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PACK = os.path.join(ROOT, "assets", "ui", "ring_run_zen")

FOLDERS = ["backgrounds", "branding", "rings", "ui", "icons", "effects"]

# --------------------------------------------------------------------------
# palette
# --------------------------------------------------------------------------
JADE = (34, 120, 72)
JADE_DARK = (18, 78, 52)
JADE_LIGHT = (108, 186, 126)
GOLD = (222, 170, 60)
GOLD_DARK = (162, 116, 24)
GOLD_LIGHT = (245, 214, 130)
IVORY = (255, 253, 244)
CREAM = (255, 246, 222)
BROWN_DARK = (92, 58, 22)
BROWN = (140, 92, 38)
LEAF_GREEN = (92, 176, 78)
LEAF_DARK = (46, 120, 56)
LEAF_LIGHT = (150, 208, 110)

RING_PURPLE = (150, 72, 230)
RING_PURPLE_DARK = (86, 34, 150)
RING_ORANGE = (244, 132, 40)
RING_ORANGE_DARK = (170, 66, 16)
RING_BLUE = (64, 176, 240)
RING_BLUE_DARK = (22, 104, 168)

RING_STONE = (238, 228, 206)
RING_STONE_DARK = (196, 180, 150)
RING_STONE_LIGHT = (252, 247, 236)


def font(size):
    for path in (
        os.path.join(ROOT, "assets/fonts/lilita_one.ttf"),
        os.path.join(ROOT, "assets/fonts/LilitaOne-Regular.ttf"),
    ):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def out(folder, name):
    return os.path.join(PACK, folder, name)


def save(img, folder, name):
    path = out(folder, name)
    img.save(path)
    print("  %s/%s" % (folder, name))


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------
def rrect(draw, box, radius, fill, outline=None, width=0):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def outline_text(draw, xy, text, fnt, fill, stroke, stroke_w=6, anchor="mm", shadow=None):
    x, y = xy
    if shadow:
        draw.text((x + shadow[0], y + shadow[1]), text, font=fnt, fill=shadow[2],
                  anchor=anchor, stroke_width=stroke_w, stroke_fill=shadow[2])
    draw.text((x, y), text, font=fnt, fill=fill, anchor=anchor,
              stroke_width=stroke_w, stroke_fill=stroke)


def leaf_shape(draw, cx, cy, angle, length, width, col):
    """A closed almond leaf: one side out, the other side back.

    Both sides have to be walked in the same direction or the outline
    self-intersects and PIL fills it with a hatch.
    """
    a = math.radians(angle)
    ux, uy = math.cos(a), math.sin(a)
    nx, ny = -uy, ux
    steps = 28
    side_a = []
    side_b = []
    for i in range(steps + 1):
        t = i / steps
        r = length * t
        s = max(0.0, math.sin(math.pi * t)) ** 0.75
        w = width * s
        px, py = cx + ux * r, cy + uy * r
        side_a.append((px + nx * w, py + ny * w))
        side_b.append((px - nx * w, py - ny * w))
    draw.polygon(side_a + side_b[::-1], fill=col)


def glossy_pill(img, box, radius, fill_top, fill_bottom, edge, gloss=True):
    """A pill with a vertical gradient, a dark rim and a top gloss."""
    w = int(box[2] - box[0])
    h = int(box[3] - box[1])
    if w <= 0 or h <= 0:
        return
    grad = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for y in range(h):
        t = y / max(1, h - 1)
        gd.line([(0, y), (w, y)], fill=(
            int(fill_top[0] + (fill_bottom[0] - fill_top[0]) * t),
            int(fill_top[1] + (fill_bottom[1] - fill_top[1]) * t),
            int(fill_top[2] + (fill_bottom[2] - fill_top[2]) * t),
            255))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], radius=radius, fill=255)
    img.paste(grad, (int(box[0]), int(box[1])), mask)

    d = ImageDraw.Draw(img)
    d.rounded_rectangle(box, radius=radius, outline=edge, width=max(3, int(h * 0.10)))
    if gloss:
        d.rounded_rectangle([box[0] + h * 0.16, box[1] + h * 0.10,
                             box[2] - h * 0.16, box[1] + h * 0.46],
                            radius=int(h * 0.22), fill=(255, 255, 255, 70))


def soft_shadow(img, shape_fn, offset=(0, 10), blur=18, alpha=90):
    """Render shape_fn on a transparent layer, blur it, and lay it under."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shape_fn(ImageDraw.Draw(layer))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow.paste((20, 40, 20, alpha), (0, 0), layer.split()[3])
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur * 0.4))
    img.alpha_composite(shadow, offset)
    return layer


# --------------------------------------------------------------------------
# backgrounds
# --------------------------------------------------------------------------
def build_backgrounds():
    print("backgrounds")
    src = os.path.join(ROOT, "assets/ui/bamboo_zen/background/zen_garden_clean.png")
    if os.path.exists(src):
        img = Image.open(src).convert("RGBA")
        # The menu background is the shaded version of the same garden.
        shade = Image.new("RGBA", img.size, (26, 58, 30, 40))
        img.alpha_composite(shade)
        save(img, "backgrounds", "bamboo_garden_menu.png")
        save(Image.open(src).convert("RGBA"), "backgrounds", "bamboo_garden_clean.png")


# --------------------------------------------------------------------------
# branding
# --------------------------------------------------------------------------
def build_branding():
    print("branding")
    W, H = 1024, 560
    for name, with_text in (("logo_plaque_blank.png", False), ("ring_run_logo.png", True)):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        cx, cy = W // 2, H // 2
        rw, rh = 400, 215

        # Leaves behind the plaque, in two depths so the edge reads clean.
        for args in (
            (cx - 336, cy - 142, 210, 132, 44, LEAF_DARK),
            (cx - 382, cy - 62, 172, 104, 36, LEAF_GREEN),
            (cx + 336, cy - 140, -30, 128, 42, LEAF_DARK),
            (cx + 380, cy - 58, 10, 102, 35, LEAF_GREEN),
            (cx - 300, cy + 158, 22, 102, 34, LEAF_DARK),
            (cx + 304, cy + 154, 158, 100, 34, LEAF_DARK),
        ):
            leaf_shape(d, *args)

        # The plaque: a gold bevel with a lit top edge and a shadowed base.
        d.ellipse([cx - rw - 20, cy - rh - 22, cx + rw + 20, cy + rh + 26], fill=(14, 40, 22, 120))
        d.ellipse([cx - rw - 16, cy - rh - 16, cx + rw + 16, cy + rh + 20], fill=GOLD_DARK)
        d.ellipse([cx - rw - 8, cy - rh - 8, cx + rw + 8, cy + rh + 12], fill=GOLD)
        d.ellipse([cx - rw - 8, cy - rh - 8, cx + rw + 8, cy + rh + 12], outline=GOLD_LIGHT, width=5)
        # the jade face
        d.ellipse([cx - rw, cy - rh, cx + rw, cy + rh], fill=JADE)
        d.ellipse([cx - rw + 14, cy - rh + 14, cx + rw - 14, cy + rh - 14], outline=JADE_DARK, width=7)
        # a soft light across the top of the jade, feathered so it does not
        # read as a band
        glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.ellipse([cx - rw + 10, cy - rh + 10, cx + rw - 10, cy - rh * 0.10],
                    fill=(80, 175, 120, 130))
        glow = glow.filter(ImageFilter.GaussianBlur(26))
        img.alpha_composite(glow)

        if with_text:
            # Big, chunky, bevelled lettering. Each word gets a gold plate
            # behind it so it reads as carved into the plaque.
            for text, cyy, fill, stroke in (
                ("RING", cy - 74, IVORY, JADE_DARK),
                ("RUN", cy + 82, GOLD, JADE_DARK),
            ):
                f = font(196)
                bbox = d.textbbox((0, 0), text, font=f, stroke_width=10)
                tw = bbox[2] - bbox[0]
                x = cx - tw / 2.0 - bbox[0]
                y = cyy - (bbox[1] + bbox[3]) / 2.0
                # a hard drop shadow for depth
                d.text((x + 7, y + 10), text, font=f, fill=(8, 34, 22, 190),
                       stroke_width=10, stroke_fill=(8, 34, 22, 190))
                # the bevelled body
                d.text((x, y), text, font=f, fill=fill, stroke_width=10, stroke_fill=stroke)
                # a bright top edge, so the letters look raised
                d.text((x - 2, y - 3), text, font=f, fill=fill, stroke_width=3,
                       stroke_fill=(255, 255, 255, 120))
        save(img, "branding", name)


# --------------------------------------------------------------------------
# rings
# --------------------------------------------------------------------------
def tube_polygon(cx, cy, r, a0, a1, half_width):
    """A stadium shape: an arc of the given half-width with round caps.

    The outline is traced in ONE consistent direction - outer edge forward,
    cap, inner edge back, cap - so the polygon never folds over itself.
    Filling one polygon gives perfectly smooth ends that continue the tube's
    own shading; drawing a line and bolting circles on the ends reads as a
    bead stuck to the arc.
    """
    steps = max(24, int(abs(a1 - a0) * r / 3))
    outer = []
    inner = []
    for i in range(steps + 1):
        a = a0 + (a1 - a0) * (i / steps)
        outer.append((cx + math.cos(a) * (r + half_width), cy + math.sin(a) * (r + half_width)))
        inner.append((cx + math.cos(a) * (r - half_width), cy + math.sin(a) * (r - half_width)))

    pts = []
    # outer edge, a0 -> a1
    pts.extend(outer)
    # the cap at a1: a half turn around the tube's end, continuing forwards
    ex, ey = outer[-1]
    ix, iy = inner[-1]
    for i in range(1, steps):
        a = math.pi * (i / steps)
        # rotate the outward direction by a half turn
        bx = (ex + ix) / 2.0
        by = (ey + iy) / 2.0
        vx, vy = ex - bx, ey - by
        ca, sa = math.cos(a), math.sin(a)
        pts.append((bx + vx * ca - vy * sa, by + vx * sa + vy * ca))
    # inner edge, a1 -> a0
    pts.extend(reversed(inner))
    # the cap at a0: the other half turn
    ex, ey = inner[0]
    ix, iy = outer[0]
    for i in range(1, steps):
        a = math.pi * (i / steps)
        bx = (ex + ix) / 2.0
        by = (ey + iy) / 2.0
        vx, vy = ex - bx, ey - by
        ca, sa = math.cos(a), math.sin(a)
        pts.append((bx + vx * ca - vy * sa, by + vx * sa + vy * ca))
    return pts


def _arc_points(cx, cy, r, a0, a1, steps):
    pts = []
    for i in range(steps + 1):
        a = a0 + (a1 - a0) * (i / steps)
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def build_ring(name, base, dark, light, start_deg, sweep_deg, width, radius_frac=0.36):
    """A glossy C-arc of the given radius on a 1024x1024 canvas.

    The tube is built the way a real one looks: a dark outer rim, the body,
    a broad sheen up and to the left, and a tight specular highlight. The
    light comes from the top-left everywhere.

    The ends are rounded caps that continue the tube's own shading - a dark
    ring with a bright dot in the middle reads as a bead, not a cut tube.
    """
    S = 1024
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = S / 2.0
    r = S * radius_frac
    a0 = math.radians(start_deg)
    a1 = a0 + math.radians(sweep_deg)
    hw = width / 2.0

    # A soft drop shadow, offset down and right like the light on the board.
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon(tube_polygon(cx + 7, cy + 11, r, a0, a1, hw + 4), fill=(28, 58, 30, 120))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(11)))

    # The tube, from the outside in. Each layer is one filled stadium, so the
    # ends stay smooth and the shading is continuous all the way round.
    d.polygon(tube_polygon(cx, cy, r, a0, a1, hw + 5.5), fill=dark)
    d.polygon(tube_polygon(cx, cy, r, a0, a1, hw), fill=base)

    # The sheen is a narrower stadium pushed up and to the left, so it reads
    # as a highlight running along the top of the tube.
    d.polygon(tube_polygon(cx - hw * 0.26, cy - hw * 0.34, r, a0, a1, hw * 0.42), fill=light)
    # A tight specular on top of the sheen.
    d.polygon(tube_polygon(cx - hw * 0.34, cy - hw * 0.44, r, a0, a1, hw * 0.15),
              fill=(255, 255, 255, 165))
    # A darker underside, so the tube reads as round.
    d.polygon(tube_polygon(cx + hw * 0.28, cy + hw * 0.36, r, a0, a1, hw * 0.30),
              fill=dark)
    save(img, "rings", name)


def build_rings():
    print("rings")
    # the stone board the rings sit on
    S = 1024
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S / 2.0
    r = S * 0.46
    d.ellipse([c - r + 12, c - r + 16, c + r + 12, c + r + 16], fill=(60, 48, 30, 90))
    d.ellipse([c - r, c - r, c + r, c + r], fill=RING_STONE)
    # A smooth sanded stone. The old board drew 26 grooves and read as a
    # target; the surface has to stay quiet so the rings carry the detail.
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([c - r * 0.92, c - r * 0.92, c + r * 0.92, c + r * 0.30],
               fill=(255, 253, 246, 150))
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    # the rim: a warm edge with a bright inner lip
    d.ellipse([c - r, c - r, c + r, c + r], outline=RING_STONE_DARK, width=8)
    d.ellipse([c - r * 0.94, c - r * 0.94, c + r * 0.94, c + r * 0.94],
              outline=RING_STONE_LIGHT, width=5)
    # A soft shade around the whole rim, so the stone has depth without a
    # hard edge cutting across it.
    shade = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    sd.ellipse([c - r * 0.80, c - r * 0.80, c + r * 0.80, c + r * 0.80],
                fill=(0, 0, 0, 0))
    sd.ellipse([c - r * 0.99, c - r * 0.99, c + r * 0.99, c + r * 0.99],
               outline=(186, 170, 140, 150), width=26)
    shade = shade.filter(ImageFilter.GaussianBlur(26))
    img.alpha_composite(shade)
    save(img, "rings", "zen_stone_board.png")

    # the three ring arcs. Same canvas, same centre, so they line up exactly.
    # Same canvas and same centre for all three, so they nest and turn as one
    # assembly. The radii differ so each ring sits outside the next.
    build_ring("ring_outer_purple.png", RING_PURPLE, RING_PURPLE_DARK, (198, 150, 255), -100, 250, 66, 0.415)
    build_ring("ring_middle_orange.png", RING_ORANGE, RING_ORANGE_DARK, (255, 186, 120), -70, 235, 64, 0.325)
    build_ring("ring_inner_blue.png", RING_BLUE, RING_BLUE_DARK, (150, 214, 255), -55, 205, 60, 0.235)

    # the hub at the very centre
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = 128
    d.ellipse([c - 46, c - 46, c + 46, c + 46], fill=(210, 196, 160, 255))
    d.ellipse([c - 38, c - 38, c + 38, c + 38], fill=(240, 232, 208, 255))
    d.ellipse([c - 22, c - 22, c + 22, c + 22], fill=JADE_LIGHT)
    d.ellipse([c - 12, c - 12, c + 12, c + 12], fill=JADE_DARK)
    save(img, "rings", "center_hub.png")


# --------------------------------------------------------------------------
# ui skins
# --------------------------------------------------------------------------
def build_ui():
    print("ui")
    # The stat card: a solid ivory card with a controlled gold border and a
    # soft shadow. The old one was a translucent pill, which read as a gold
    # outline around nothing.
    W, H = 256, 128
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = 30
    d.rounded_rectangle([4, 4, W - 4, H - 4], radius=r + 2, fill=GOLD_DARK)
    d.rounded_rectangle([9, 9, W - 9, H - 9], radius=r - 2, fill=GOLD)
    d.rounded_rectangle([13, 13, W - 13, H - 13], radius=r - 4, fill=IVORY)
    # The highlight only in the corner patches (40px), so it does not smear.
    for x0, x1 in ((14, 40), (W - 40, W - 14)):
        d.rounded_rectangle([x0, 18, x1, 40], radius=10, fill=(255, 255, 255, 130))
    save(img, "ui", "panel_stat.png")

    # The currency pill: the same treatment, squarer for the top corner.
    W, H = 256, 96
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = 40
    d.rounded_rectangle([4, 4, W - 4, H - 4], radius=r + 2, fill=GOLD_DARK)
    d.rounded_rectangle([9, 9, W - 9, H - 9], radius=r - 2, fill=GOLD)
    d.rounded_rectangle([13, 13, W - 13, H - 13], radius=r - 4, fill=IVORY)
    for x0, x1 in ((14, 44), (W - 44, W - 14)):
        d.rounded_rectangle([x0, 18, x1, 38], radius=9, fill=(255, 255, 255, 140))
    save(img, "ui", "pill_currency.png")

    # A tall card built for 9-patching: fixed gold corners, a cream middle.
    # Godot's NinePatchRect then stretches only the middle, so the panel can be
    # any size without the rim distorting.
    W, H = 256, 256
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = 56
    # gold rim
    d.rounded_rectangle([6, 6, W - 6, H - 6], radius=r, fill=GOLD_DARK)
    d.rounded_rectangle([12, 12, W - 12, H - 12], radius=r - 4, fill=GOLD)
    # cream face
    d.rounded_rectangle([18, 18, W - 18, H - 18], radius=r - 8, fill=IVORY)
    d.rounded_rectangle([18, 18, W - 18, 74], radius=r - 8, fill=(255, 250, 232, 255))
    # a highlight along the top inner edge
    d.arc([22, 22, W - 22, 120], 200, 340, fill=(255, 255, 255, 190), width=5)
    save(img, "ui", "panel_card.png")

    # The button skins are built as 9-patchable rounded rectangles: the
    # corners are fixed, the middle stretches, so a button can be any size
    # without the rim or the radius distorting.
    # Nine-patch layout: the corners are 44px, so the middle 168px stretches.
    # Anything drawn across the middle gets smeared horizontally, so the
    # surface detail has to live in the corner patches or be a flat band.
    # The nine-patch margin must sit just past the corner radius, or the
    # round end stretches into an oval. A 38px radius wants a 44px margin.
    def button_skin(name, top, bottom, edge, gloss=True):
        W, H = 256, 112
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        r = 38
        d.rounded_rectangle([4, 4, W - 4, H - 4], radius=r + 2, fill=edge)
        d.rounded_rectangle([9, 9, W - 9, H - 9], radius=r - 2, fill=top)
        # a soft vertical shade down the face (a flat band, so it stretches
        # without smearing)
        for y in range(9, H - 9):
            t = (y - 9) / max(1, (H - 18))
            col = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
            d.line([(9, y), (W - 9, y)], fill=col)
        if gloss:
            # The highlight lives entirely inside the top-left and top-right
            # corner patches (44px), so it stays two short caps instead of
            # smearing into a stripe across the whole button.
            for x0, x1 in ((10, 44), (W - 44, W - 10)):
                d.rounded_rectangle([x0, 14, x1, 34], radius=9, fill=(255, 255, 255, 115))
        save(img, "ui", name)

    button_skin("button_nav.png", (255, 250, 226), (238, 214, 158), GOLD)
    button_skin("button_nav_pressed.png", (222, 186, 120), (176, 138, 78), GOLD_DARK, gloss=False)
    button_skin("button_daily.png", (255, 250, 226), (238, 214, 158), GOLD)
    button_skin("button_start_normal.png", (126, 226, 84), (52, 158, 44), (30, 96, 28))
    button_skin("button_start_pressed.png", (86, 186, 58), (36, 120, 32), (22, 74, 20), gloss=False)
    button_skin("button_start_disabled.png", (176, 178, 178), (128, 130, 132), (92, 94, 96), gloss=False)

    # a small round button face
    W = 256
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([10, 10, W - 10, W - 10], fill=GOLD_DARK)
    d.ellipse([18, 18, W - 18, W - 18], fill=GOLD)
    d.ellipse([40, 40, W - 40, W - 40], fill=GOLD_LIGHT)
    save(img, "ui", "button_square.png")


# --------------------------------------------------------------------------
# icons
# --------------------------------------------------------------------------
def icon_base():
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def build_icons():
    print("icons")

    # coin: gold disc with a leaf
    img, d = icon_base()
    d.ellipse([16, 16, 240, 240], fill=BROWN_DARK)
    d.ellipse([26, 26, 230, 230], fill=GOLD)
    d.ellipse([46, 46, 210, 210], fill=GOLD_LIGHT)
    leaf_shape(d, 128, 128, -90, 80, 30, LEAF_GREEN)
    d.line([(128, 72), (128, 178)], fill=LEAF_DARK, width=7)
    save(img, "icons", "icon_coin.png")

    # collection: a purple card with a star
    img, d = icon_base()
    d.rounded_rectangle([46, 30, 210, 226], radius=22, fill=BROWN_DARK)
    d.rounded_rectangle([54, 38, 202, 218], radius=18, fill=RING_PURPLE)
    pts = []
    for i in range(10):
        a = math.radians(-90 + i * 36)
        rr = 62 if i % 2 == 0 else 28
        pts.append((128 + math.cos(a) * rr, 126 + math.sin(a) * rr))
    d.polygon(pts, fill=GOLD)
    d.polygon(pts, outline=GOLD_DARK)
    save(img, "icons", "icon_collection.png")

    # daily: a calendar with a check
    img, d = icon_base()
    d.rounded_rectangle([38, 46, 218, 222], radius=20, fill=BROWN_DARK)
    d.rounded_rectangle([46, 54, 210, 214], radius=16, fill=IVORY)
    d.rounded_rectangle([46, 54, 210, 104], radius=16, fill=(226, 106, 46))
    d.rectangle([46, 86, 210, 104], fill=(226, 106, 46))
    for x in (80, 176):
        d.rounded_rectangle([x - 10, 24, x + 10, 66], radius=8, fill=BROWN)
    d.line([(84, 140), (112, 168), (176, 104)], fill=(64, 168, 92), width=16, joint="curve")
    save(img, "icons", "icon_daily.png")

    # flame
    img, d = icon_base()
    d.polygon([(128, 18), (186, 92), (170, 118), (196, 150), (176, 218),
                (86, 224), (52, 176), (72, 116), (96, 128)], fill=(232, 96, 28))
    d.polygon([(128, 96), (162, 142), (150, 200), (104, 204), (94, 158)], fill=(255, 226, 120))
    save(img, "icons", "icon_flame.png")

    # home: an up arrow over a house
    img, d = icon_base()
    d.polygon([(128, 16), (216, 96), (178, 96), (178, 226), (78, 226), (78, 96), (40, 96)],
              fill=(212, 160, 60))
    d.polygon([(128, 46), (186, 100), (160, 100), (160, 200), (96, 200), (96, 100), (70, 100)],
              fill=(250, 220, 140))
    save(img, "icons", "icon_home.png")

    # leaf
    img, d = icon_base()
    leaf_shape(d, 128, 128, -48, 108, 46, LEAF_GREEN)
    d.line([(74, 182), (182, 74)], fill=LEAF_DARK, width=10)
    d.line([(104, 152), (104, 108)], fill=LEAF_DARK, width=6)
    d.line([(134, 122), (168, 122)], fill=LEAF_DARK, width=6)
    save(img, "icons", "icon_leaf.png")

    # pause
    img, d = icon_base()
    d.rounded_rectangle([72, 46, 112, 210], radius=14, fill=GOLD)
    d.rounded_rectangle([144, 46, 184, 210], radius=14, fill=GOLD)
    d.rounded_rectangle([78, 52, 106, 204], radius=10, fill=GOLD_LIGHT)
    d.rounded_rectangle([150, 52, 178, 204], radius=10, fill=GOLD_LIGHT)
    save(img, "icons", "icon_pause.png")

    # play
    img, d = icon_base()
    d.polygon([(74, 26), (226, 128), (74, 230)], fill=GOLD)
    d.polygon([(88, 56), (196, 128), (88, 200)], fill=GOLD_LIGHT)
    save(img, "icons", "icon_play.png")

    # plus
    img, d = icon_base()
    d.rounded_rectangle([96, 34, 160, 222], radius=22, fill=LEAF_GREEN)
    d.rounded_rectangle([34, 96, 222, 160], radius=22, fill=LEAF_GREEN)
    d.rounded_rectangle([104, 44, 130, 210], radius=12, fill=(140, 220, 100))
    save(img, "icons", "icon_plus.png")

    # settings: a gear
    img, d = icon_base()
    for i in range(8):
        a = math.radians(i * 45)
        d.ellipse([128 + math.cos(a) * 78 - 26, 128 + math.sin(a) * 78 - 26,
                   128 + math.cos(a) * 78 + 26, 128 + math.sin(a) * 78 + 26], fill=GOLD)
    d.ellipse([36, 36, 220, 220], fill=GOLD)
    d.ellipse([52, 52, 204, 204], fill=GOLD_LIGHT)
    d.ellipse([96, 96, 160, 160], fill=IVORY)
    d.ellipse([108, 108, 148, 148], fill=LEAF_GREEN)
    save(img, "icons", "icon_settings.png")

    # shop
    img, d = icon_base()
    d.rounded_rectangle([40, 92, 216, 226], radius=14, fill=BROWN)
    d.rounded_rectangle([48, 100, 208, 216], radius=10, fill=(206, 150, 62))
    d.polygon([(30, 92), (226, 92), (214, 40), (42, 40)], fill=IVORY)
    for x in (44, 92, 140, 188):
        d.polygon([(x, 92), (x + 40, 92), (x + 33, 44), (x + 7, 44)], fill=(226, 214, 190))
    d.rounded_rectangle([112, 148, 144, 226], radius=8, fill=LEAF_GREEN)
    save(img, "icons", "icon_shop.png")

    # trophy
    img, d = icon_base()
    d.rounded_rectangle([70, 30, 186, 138], radius=16, fill=GOLD)
    d.rounded_rectangle([84, 44, 172, 122], radius=12, fill=GOLD_LIGHT)
    d.rectangle([118, 136, 138, 176], fill=GOLD)
    d.rounded_rectangle([84, 172, 172, 206], radius=10, fill=GOLD)
    d.arc([22, 40, 92, 120], 90, 270, fill=GOLD, width=16)
    d.arc([164, 40, 234, 120], -90, 90, fill=GOLD, width=16)
    save(img, "icons", "icon_trophy.png")


# --------------------------------------------------------------------------
# effects
# --------------------------------------------------------------------------
def build_effects():
    print("effects")

    # a four-point gold sparkle
    img, d = icon_base()
    cx = cy = 128
    pts = []
    for i in range(8):
        a = math.radians(i * 45 - 90)
        r = 118 if i % 2 == 0 else 30
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    d.polygon(pts, fill=(255, 236, 150))
    d.polygon(pts, outline=(250, 210, 90))
    d.ellipse([112, 112, 144, 144], fill=(255, 255, 240))
    save(img, "effects", "sparkle_gold.png")

    # a soft touch ripple
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, r in enumerate((96, 70, 44)):
        d.ellipse([128 - r, 128 - r, 128 + r, 128 + r],
                  outline=(255, 214, 110, 200 - i * 55), width=10)
    img = img.filter(ImageFilter.GaussianBlur(3))
    save(img, "effects", "touch_ripple.png")

    # a curved rotation hint arrow
    img = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = _arc_points(256, 256, 170, math.radians(200), math.radians(340), 90)
    d.line(pts, fill=GOLD_LIGHT, width=26, joint="curve")
    tip = pts[-1]
    d.polygon([(tip[0] + 26, tip[1] - 34), (tip[0] + 62, tip[1] - 6), (tip[0] + 4, tip[1] + 22)], fill=GOLD)
    save(img, "effects", "rotation_hint_arrow.png")


# --------------------------------------------------------------------------
def main():
    for folder in FOLDERS:
        os.makedirs(os.path.join(PACK, folder), exist_ok=True)
    build_backgrounds()
    build_branding()
    build_rings()
    build_ui()
    build_icons()
    build_effects()
    print("done -> %s" % PACK)


if __name__ == "__main__":
    main()
