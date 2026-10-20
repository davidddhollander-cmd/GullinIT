"""Build the HUD's native 6 px bitmap face; menu typography stays unchanged."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/fonts"
# Five ink rows plus one pixel of line spacing. Small glyphs are drawn at their
# native size, avoiding dropped strokes from shrinking the 8 px menu font.
GLYPHS = {
    "A":"010/101/111/101/101", "B":"110/101/110/101/110",
    "C":"111/100/100/100/111", "D":"110/101/101/101/110",
    "E":"111/100/110/100/111", "F":"111/100/110/100/100",
    "G":"111/100/101/101/111", "H":"101/101/111/101/101",
    "I":"111/010/010/010/111", "J":"001/001/001/101/111",
    "K":"101/101/110/101/101", "L":"100/100/100/100/111",
    "M":"10001/11011/10101/10001/10001", "N":"1001/1101/1011/1001/1001",
    "O":"111/101/101/101/111", "P":"110/101/110/100/100",
    "Q":"111/101/101/111/001", "R":"110/101/110/101/101",
    "S":"111/100/111/001/111", "T":"111/010/010/010/010",
    "U":"101/101/101/101/111", "V":"101/101/101/101/010",
    "W":"10001/10001/10101/10101/01010", "X":"101/101/010/101/101",
    "Y":"101/101/010/010/010", "Z":"111/001/010/100/111",
    "0":"111/101/101/101/111", "1":"010/110/010/010/111",
    "2":"111/001/111/100/111", "3":"111/001/111/001/111",
    "4":"101/101/111/001/001", "5":"111/100/111/001/111",
    "6":"111/100/111/101/111", "7":"111/001/010/010/010",
    "8":"111/101/111/101/111", "9":"111/101/111/001/111",
    "%":"11001/11010/00100/01011/10011", ">":"100/010/001/010/100",
    "<":"001/010/100/010/001", "/":"001/001/010/100/100",
    "-":"000/000/111/000/000", "+":"000/010/111/010/000",
    ".":"0/0/0/0/1", ":":"0/1/0/1/0", "!":"1/1/1/0/1",
    "?":"111/001/010/000/010", " ":"0/0/0/0/0",
}
GLYPHS.update({letter.lower():glyph for letter,glyph in list(GLYPHS.items()) if letter.isalpha()})
image = Image.new("RGBA",(128,((len(GLYPHS)+15)//16)*8),(0,0,0,0))
lines = [
    'info face="GullHud" size=6 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1',
    f'common lineHeight=6 base=5 scaleW={image.width} scaleH={image.height} pages=1 packed=0',
    'page id=0 file="gull_hud.png"', f'chars count={len(GLYPHS)}',
]
for index,(character,glyph) in enumerate(GLYPHS.items()):
    rows = glyph.split("/")
    x,y = index%16*8,index//16*8
    width = len(rows[0])
    for dy,row in enumerate(rows):
        for dx,bit in enumerate(row):
            if bit=="1":
                image.putpixel((x+dx,y+dy),(255,255,255,255))
    advance = 3 if character==" " else width+1
    lines.append(f'char id={ord(character)} x={x} y={y} width={width} height=5 xoffset=0 yoffset=0 xadvance={advance} page=0 chnl=15')
image.save(OUT / "gull_hud.png")
(OUT / "gull_hud.fnt").write_text("\n".join(lines)+"\n",encoding="utf-8")
print("Saved native 6 px HUD font and atlas.")
