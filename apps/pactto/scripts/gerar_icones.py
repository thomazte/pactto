"""Gera os ícones do app (Android e web) a partir do mesmo desenho da capa do portfólio.

Símbolo branco (folha com itens, assinatura e selo de R$) sobre o gradiente azul da marca.
Rode da pasta apps/pactto: python3 scripts/gerar_icones.py
"""

from __future__ import annotations

from math import cos, pi, sin
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

APP = Path(__file__).resolve().parents[1]
RES = APP / "android" / "app" / "src" / "main" / "res"
WEB = APP / "web"

# Fonte do "R$". A Ubuntu vem instalada no Ubuntu; em outro sistema, troque o caminho.
FONT = Path("/usr/share/fonts/truetype/ubuntu/Ubuntu[wdth,wght].ttf")

BASE = 480  # espaço de coordenadas do desenho original
SS = 4  # desenha em 4x e reduz, para suavizar as bordas
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)

# Gradiente radial da capa: centro em 50% x 36%, do azul claro ao escuro
GRADIENT = ((0.0, (0x3B, 0x82, 0xF6)), (0.45, (0x25, 0x63, 0xEB)), (1.0, (0x1D, 0x4E, 0xD8)))

# Densidades do Android: ícone legado tem 48dp e o adaptativo, 108dp
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def s(v: float) -> int:
    return round(v * SS)


def rounded_polygon(points: list[tuple[float, float]], radius: float) -> list[tuple[int, int]]:
    """Pontos (em escala) de um polígono com os cantos arredondados."""
    out = []
    n = len(points)
    for i in range(n):
        px, py = points[i - 1]
        cx, cy = points[i]
        nx, ny = points[(i + 1) % n]
        v1 = (px - cx, py - cy)
        v2 = (nx - cx, ny - cy)
        l1 = (v1[0] ** 2 + v1[1] ** 2) ** 0.5
        l2 = (v2[0] ** 2 + v2[1] ** 2) ** 0.5
        r = min(radius, l1 / 2, l2 / 2)
        a = (cx + v1[0] / l1 * r, cy + v1[1] / l1 * r)
        b = (cx + v2[0] / l2 * r, cy + v2[1] / l2 * r)
        for k in range(17):  # curva de Bézier quadrática com o vértice como controle
            t = k / 16
            x = (1 - t) ** 2 * a[0] + 2 * (1 - t) * t * cx + t ** 2 * b[0]
            y = (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * cy + t ** 2 * b[1]
            out.append((s(x), s(y)))
    return out


def simbolo() -> Image.Image:
    """Símbolo branco com fundo transparente, recortado rente ao desenho."""
    img = Image.new("RGBA", (BASE * SS, BASE * SS), CLEAR)
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = 128, 58, 318, 330
    fold = 70
    # Folha com o canto superior direito cortado: forma cheia menos o miolo
    d.polygon(rounded_polygon([(x0, y0), (x1 - fold, y0), (x1, y0 + fold), (x1, y1), (x0, y1)], 28),
              fill=WHITE)
    inset = 24
    d.polygon(rounded_polygon([(x0 + inset, y0 + inset), (x1 - fold - inset * 0.41, y0 + inset),
                               (x1 - inset, y0 + fold + inset * 0.41), (x1 - inset, y1 - inset),
                               (x0 + inset, y1 - inset)], 10), fill=CLEAR)
    # Orelha dobrada: contorno em L ligando as pontas do corte
    ear = [(x1 - fold + 2, y0 + 12), (x1 - fold + 2, y0 + fold - 2), (x1 - 12, y0 + fold - 2)]
    d.line([(s(x), s(y)) for x, y in ear], fill=WHITE, width=s(20), joint="curve")
    # Itens da proposta: descrição à esquerda, valor à direita
    for i, (desc, valor) in enumerate(((70, 34), (52, 46), (62, 30))):
        top = 140 + i * 36
        d.rounded_rectangle((s(x0 + 34), s(top), s(x0 + 34 + desc), s(top + 16)),
                            radius=s(8), fill=WHITE)
        d.rounded_rectangle((s(x1 - 34 - valor), s(top), s(x1 - 34), s(top + 16)),
                            radius=s(8), fill=WHITE)
    # Assinatura cursiva: laços para cima que diminuem, terminando num traço
    scribble = []
    for i in range(0, 241):
        t = i / 240 * 5 * pi
        fade = 1 - 0.35 * t / (5 * pi)
        x = x0 + 40 + 6 * t - 16 * fade * sin(t)
        y = 262 - 15 * fade * cos(t)
        scribble.append((x, y))
    d.line([(s(x), s(y)) for x, y in scribble], fill=WHITE, width=s(6), joint="curve")
    d.rounded_rectangle((s(x0 + 32), s(286), s(x0 + 150), s(296)), radius=s(5), fill=WHITE)
    # Selo de R$ sobrepondo o canto inferior direito
    cx, cy, r = 330, 292, 60
    d.ellipse((s(cx - r - 12), s(cy - r - 12), s(cx + r + 12), s(cy + r + 12)), fill=CLEAR)
    d.ellipse((s(cx - r), s(cy - r), s(cx + r), s(cy + r)), fill=WHITE)
    font = ImageFont.truetype(str(FONT), s(54))
    font.set_variation_by_name("Bold")
    left, top, right, bottom = d.textbbox((0, 0), "R$", font=font)
    d.text((s(cx) - (left + right) / 2, s(cy) - (top + bottom) / 2), "R$", font=font, fill=CLEAR)
    return img.crop(img.getbbox())


def gradiente(size: int) -> Image.Image:
    """Gradiente radial da marca, como o capaGradient do portfólio."""
    small = 128
    img = Image.new("RGB", (small, small))
    px = img.load()
    rx, ry = 1.6 * small / 2 * 1.1, 1.3 * small / 2 * 1.1
    for y in range(small):
        for x in range(small):
            t = min(1.0, (((x - small * 0.5) / rx) ** 2 + ((y - small * 0.36) / ry) ** 2) ** 0.5)
            for (t0, c0), (t1, c1) in zip(GRADIENT, GRADIENT[1:]):
                if t <= t1:
                    k = (t - t0) / (t1 - t0)
                    px[x, y] = tuple(round(a + (b - a) * k) for a, b in zip(c0, c1))
                    break
    return img.resize((size, size), Image.Resampling.BICUBIC).convert("RGBA")


def compor(size: int, altura: float, fundo: bool, raio: float = 0) -> Image.Image:
    """Símbolo centralizado ocupando `altura` (fração do lado), com ou sem fundo."""
    big = size * SS
    img = gradiente(big) if fundo else Image.new("RGBA", (big, big), CLEAR)
    sym = simbolo()
    h = round(big * altura)
    w = round(sym.width * h / sym.height)
    sym = sym.resize((w, h), Image.Resampling.LANCZOS)
    img.alpha_composite(sym, ((big - w) // 2, (big - h) // 2))
    if raio:
        mask = Image.new("L", img.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, big - 1, big - 1), radius=round(big * raio), fill=255)
        img.putalpha(mask)
    return img.resize((size, size), Image.Resampling.LANCZOS)


def salvar(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG", optimize=True)
    print(f"Ícone: {path.relative_to(APP)}")


def main() -> None:
    for nome, fator in DENSITIES.items():
        pasta = RES / f"mipmap-{nome}"
        # Legado (Android 7 e anteriores): quadrado de cantos arredondados
        salvar(compor(round(48 * fator), 0.6, True, raio=0.22), pasta / "ic_launcher.png")
        # Adaptativo: o símbolo cabe no círculo seguro de 66dp dos 108dp
        salvar(compor(round(108 * fator), 0.46, False), pasta / "ic_launcher_foreground.png")
        salvar(gradiente(round(108 * fator)), pasta / "ic_launcher_background.png")

    # Web: ícone comum com cantos arredondados; o maskable preenche tudo e respeita a zona segura
    salvar(compor(192, 0.6, True, raio=0.22), WEB / "icons" / "Icon-192.png")
    salvar(compor(512, 0.6, True, raio=0.22), WEB / "icons" / "Icon-512.png")
    salvar(compor(192, 0.5, True), WEB / "icons" / "Icon-maskable-192.png")
    salvar(compor(512, 0.5, True), WEB / "icons" / "Icon-maskable-512.png")
    salvar(compor(32, 0.7, True, raio=0.22), WEB / "favicon.png")


if __name__ == "__main__":
    main()
