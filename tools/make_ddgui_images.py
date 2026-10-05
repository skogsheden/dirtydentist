"""Draws the images of DD-GUI's dark, flat look (dd-gui/images/*.png).

    python3 tools/make_ddgui_images.py .        (from the root of the repository)

The widgets are coloured by the scripts (gui.set_color tints the image), so the
images themselves are white and grey: white where the tint is to show at full
strength (frames, lines), grey where it is to be darker (the fill). That way
any tint gives a readable widget with white text on it - also a tint set from
outside, such as green or red for a right or wrong answer.

  button.png        flat white *                        buttons, the text block
  bg_blank.png      flat white                          the rows of a dropdown list
  field.png         grey, a white line at the bottom *  text boxes, the box of a combobox
  checkbox.png      white frame, grey fill *            the checkbox
  radio.png         white ring, grey fill               the radio button
  radio_center.png  white dot                           the dot of a selected radio button
  knob.png          white disc                          the handle of the slider
  bg.png            dark with a thin frame (not tinted) the background of a dropdown list
  arrow.png         white chevron                       the arrow of a combobox
check.png and line.png (the tick and the dash of a checkbox) are left as they were.
* drawn 1 px inside the image, so that widgets placed edge to edge get a thin gap between them.
"""
import os, sys
from PIL import Image, ImageDraw

FILL = 128           # grey of the fills: the tint at half strength
BOX_FILL = 110       # a little darker inside the checkbox and the radio button
LIST_FILL, LIST_FRAME = 36, 104     # the list background is drawn in its final colours

MARGIN = 1           # buttons, text boxes and checkboxes are drawn this much inside their node: a gap between neighbours

def inset(im, margin=MARGIN):
    """the image with a transparent margin around it (the margin keeps the image's color, for clean scaling)"""
    if not margin:
        return im
    w, h = im.size
    out = im.resize((w + 2 * margin, h + 2 * margin), Image.NEAREST)
    out.putalpha(0)
    out.paste(im, (margin, margin))
    return out

def flat(size):
    return Image.new("RGBA", (size, size), (255, 255, 255, 255))

def field(size=40, line=2):
    im = Image.new("RGBA", (size, size), (FILL, FILL, FILL, 255))
    ImageDraw.Draw(im).rectangle([0, size - line, size - 1, size - 1], fill=(255, 255, 255, 255))
    return im

def checkbox(size=40, frame=2):
    im = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    ImageDraw.Draw(im).rectangle([frame, frame, size - frame - 1, size - frame - 1], fill=(BOX_FILL, BOX_FILL, BOX_FILL, 255))
    return im

def list_bg(size=80, frame=1):
    im = Image.new("RGBA", (size, size), (LIST_FRAME, LIST_FRAME, LIST_FRAME, 255))
    ImageDraw.Draw(im).rectangle([frame, frame, size - frame - 1, size - frame - 1], fill=(LIST_FILL, LIST_FILL, LIST_FILL, 255))
    return im

def disc(size, radius, grey=255, ring=None, ring_grey=255, ss=4):
    """an antialiased disc in the middle of a transparent square; ring: width of a ring around it"""
    big = Image.new("RGBA", (size * ss, size * ss), (255, 255, 255, 0))
    d = ImageDraw.Draw(big)
    c = size * ss / 2
    def circle(r, g):
        d.ellipse([c - r * ss, c - r * ss, c + r * ss, c + r * ss], fill=(g, g, g, 255))
    if ring:
        circle(radius, ring_grey)
        circle(radius - ring, grey)
    else:
        circle(radius, grey)
    # the transparent pixels keep the colour of the edge, so that the edge is not darkened when the image is scaled
    out = big.resize((size, size), Image.LANCZOS)
    alpha = out.getchannel("A")
    edge = ring_grey if ring else grey
    rgb = Image.new("RGB", (size, size), (edge, edge, edge))
    rgb.paste(out.convert("RGB"), mask=alpha.point(lambda v: 255 if v == 255 else 0))
    rgb.putalpha(alpha)
    return rgb

def chevron(size=120, width=13, ss=4):
    """points up; the combobox mirrors it with a negative size when the list opens downwards"""
    big = Image.new("L", (size * ss, size * ss), 0)
    d = ImageDraw.Draw(big)
    pts = [(0.20, 0.66), (0.50, 0.36), (0.80, 0.66)]
    pts = [(x * size * ss, y * size * ss) for x, y in pts]
    d.line(pts, fill=255, width=width * ss, joint="curve")
    r = width * ss / 2
    for x, y in (pts[0], pts[-1]):
        d.ellipse([x - r, y - r, x + r, y + r], fill=255)
    alpha = big.resize((size, size), Image.LANCZOS)
    im = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    im.putalpha(alpha)
    return im

def main(repo):
    out = os.path.join(repo, "dd-gui", "images")
    images = {
        "button.png": inset(flat(38)),
        "bg_blank.png": flat(40),
        "field.png": inset(field(38)),
        "checkbox.png": inset(checkbox(38)),
        "bg.png": list_bg(),
        "radio.png": disc(120, 56, grey=BOX_FILL, ring=8),      # the node is 30 px: a ring of 2 px
        "radio_center.png": disc(120, 11),                         # a dot of 5.5 px, as before
        "knob.png": disc(100, 48),
        "arrow.png": chevron(),
    }
    for name, im in images.items():
        im.save(os.path.join(out, name), optimize=True)
        print("%-18s %s" % (name, im.size))

if __name__ == "__main__":
    main(sys.argv[1])
