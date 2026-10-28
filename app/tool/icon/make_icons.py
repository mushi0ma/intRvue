#!/usr/bin/env python3
"""Android иконкалары мен splash белгісін жасайды (Inter Bold, бренд түсі).

app/ бумасынан: python3 tool/icon/make_icons.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

APP = Path(__file__).resolve().parents[2]
RES = APP / 'android/app/src/main/res'
FONT = APP / 'assets/fonts/Inter-Bold.ttf'
GREEN = (0x00, 0x6C, 0x4C)
MINT = (0x89, 0xF8, 0xC6)
WHITE = (255, 255, 255)


def glyph(size: int, scale: float, fg, bg=None, round_=False) -> Image.Image:
    """«iR» белгісі: сөзбелгінің (intRvue) бас әріптері."""
    im = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if bg:
        if round_:
            d.ellipse([0, 0, size - 1, size - 1], fill=bg)
        else:
            r = int(size * 0.22)
            d.rounded_rectangle([0, 0, size - 1, size - 1], r, fill=bg)
    font = ImageFont.truetype(str(FONT), int(size * scale))
    text = 'iR'
    box = d.textbbox((0, 0), text, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    x = (size - w) / 2 - box[0]
    y = (size - h) / 2 - box[1]
    d.text((x, y), text, font=font, fill=fg)
    # Төменгі сызық — splash-тағы прогресс жолағын қайталайды.
    bar_w, bar_h = w * 0.9, max(2, size * 0.035)
    by = y + box[3] + size * 0.06
    d.rounded_rectangle(
        [(size - bar_w) / 2, by, (size + bar_w) / 2, by + bar_h],
        bar_h / 2,
        fill=MINT if bg else fg,
    )
    return im


densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
for name, k in densities.items():
    folder = RES / f'mipmap-{name}'
    folder.mkdir(exist_ok=True)
    legacy = round(48 * k)
    glyph(legacy, 0.42, WHITE, GREEN).save(folder / 'ic_launcher.png')
    glyph(legacy, 0.42, WHITE, GREEN, round_=True).save(folder / 'ic_launcher_round.png')
    # Adaptive icon: 108dp қабат, қауіпсіз аймақ — ортадағы 66dp.
    glyph(round(108 * k), 0.26, WHITE).save(folder / 'ic_launcher_foreground.png')
    # Android 12+ splash: 288dp белгі, көрінетін бөлігі ортадағы 192dp шеңбер.
    drawable = RES / f'drawable-{name}'
    drawable.mkdir(exist_ok=True)
    glyph(round(288 * k), 0.24, GREEN).save(drawable / 'splash_mark.png')
    # Қараңғы тақырып: primary (dark) — #6CDBAB.
    night = RES / f'drawable-night-{name}'
    night.mkdir(exist_ok=True)
    glyph(round(288 * k), 0.24, (0x6C, 0xDB, 0xAB)).save(night / 'splash_mark.png')
print('ok')
