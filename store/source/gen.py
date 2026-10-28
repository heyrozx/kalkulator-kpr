"""Generate HTML pages for Play Store listing assets."""
import os

HERE = os.path.dirname(os.path.abspath(__file__))

BASE_CSS = """
@font-face { font-family: 'R'; src: url('fonts/Roboto-Regular.ttf'); font-weight: 400; }
@font-face { font-family: 'R'; src: url('fonts/Roboto-Medium.ttf'); font-weight: 500; }
@font-face { font-family: 'R'; src: url('fonts/Roboto-Bold.ttf'); font-weight: 700; }
@font-face { font-family: 'R'; src: url('fonts/Roboto-Black.ttf'); font-weight: 900; }
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { width: __W__px; height: __H__px; overflow: hidden; }
body { font-family: 'R', sans-serif; color: #fff; position: relative;
  background: linear-gradient(160deg, #D154E8 0%, #7B1FA2 100%); }

/* ---------- dekorasi ---------- */
.blob { position: absolute; border-radius: 50%; filter: blur(70px); }
.ring { position: absolute; border-radius: 50%; border: 2px solid rgba(255,255,255,.14); }
.ring.thick { border-width: 26px; border-color: rgba(255,255,255,.06); }
.dots { position: absolute; opacity: .5;
  background-image: radial-gradient(rgba(255,255,255,.55) 2.2px, transparent 2.6px);
  background-size: 26px 26px; }
.deco { position: absolute; opacity: .16; }
.spark { position: absolute; color: #fff; opacity: .7; }

/* ---------- teks ---------- */
h1 { font-weight: 900; line-height: 1.05; letter-spacing: -1px; }
.sub { font-weight: 400; color: rgba(255,255,255,.88); line-height: 1.35; }
.hl { color: #fff; font-weight: 900; }

/* ---------- kartu melayang ---------- */
.float { position: absolute; z-index: 6; display: flex; align-items: center; gap: 16px;
  padding: 16px 26px 16px 16px; border-radius: 28px; background: #fff; color: #2b123a;
  box-shadow: 0 26px 60px rgba(40,0,70,.35), 0 6px 14px rgba(40,0,70,.15); }
.float .ic { width: 56px; height: 56px; border-radius: 20px; flex: none;
  display: flex; align-items: center; justify-content: center;
  background: linear-gradient(160deg, #D154E8, #7B1FA2); }
.float .ic svg { width: 30px; height: 30px; fill: #fff; }
.float .t1 { font-size: 20px; color: #7d6b88; font-weight: 500; }
.float .t2 { font-size: 29px; font-weight: 900; color: #2b123a; margin-top: 2px; }

/* ---------- mockup HP ---------- */
.phone { --w: 600px; position: absolute; width: var(--w);
  padding: calc(var(--w) * .026);
  border-radius: calc(var(--w) * .145);
  background: linear-gradient(150deg, #4a4a52 0%, #1b1b1f 22%, #0d0d10 55%, #2c2c33 100%);
  box-shadow:
    0 calc(var(--w) * .09) calc(var(--w) * .18) rgba(25, 0, 45, .55),
    0 calc(var(--w) * .02) calc(var(--w) * .05) rgba(0, 0, 0, .35),
    inset 0 0 0 2px rgba(255,255,255,.18),
    inset 0 0 0 5px #070708; }
.phone::before { /* kilap tepi frame */ content: ''; position: absolute; inset: 3px;
  border-radius: calc(var(--w) * .14); pointer-events: none;
  background: linear-gradient(135deg, rgba(255,255,255,.22), transparent 18%, transparent 82%, rgba(255,255,255,.10)); }
.btn { position: absolute; width: calc(var(--w) * .011); border-radius: 4px;
  background: linear-gradient(90deg, #2a2a30, #5b5b63 50%, #1d1d22); }
.btn.power { right: calc(var(--w) * -.009); top: 27%; height: 9%; }
.btn.vol { right: calc(var(--w) * -.009); top: 15%; height: 9.5%; }
.screen { position: relative; width: 100%; aspect-ratio: 1080 / 2340; overflow: hidden;
  border-radius: calc(var(--w) * .118); background: #fff; }
.screen img.app { width: 100%; height: 100%; display: block; }
.screen::after { /* pantulan kaca */ content: ''; position: absolute; inset: 0; pointer-events: none;
  background: linear-gradient(115deg, rgba(255,255,255,.16) 0%, rgba(255,255,255,0) 32%); }
.cam { position: absolute; top: 1.35%; left: 50%; transform: translateX(-50%);
  width: calc(var(--w) * .042); height: calc(var(--w) * .042); border-radius: 50%;
  background: radial-gradient(circle at 35% 35%, #3a3f5c 0 18%, #0b0b10 30%, #000 70%);
  box-shadow: 0 0 0 2px #111; z-index: 3; }
.status { position: absolute; top: 0; left: 0; right: 0; height: 3.85%; z-index: 2;
  display: flex; align-items: center; justify-content: space-between;
  padding: 0 7.5%; color: #1d1b20; font-weight: 700; font-size: calc(var(--w) * .036); }
.status .icons { display: flex; align-items: center; gap: calc(var(--w) * .014); }
.status svg { height: calc(var(--w) * .036); width: auto; fill: #1d1b20; }
.gesture { position: absolute; bottom: .75%; left: 50%; transform: translateX(-50%);
  width: 30%; height: calc(var(--w) * .009); border-radius: 10px; background: rgba(0,0,0,.55); z-index: 2; }
"""

STATUS_ICONS = """
<svg viewBox="0 0 20 16"><rect x="0" y="11" width="3.4" height="5" rx="1"/><rect x="5.4" y="7.5" width="3.4" height="8.5" rx="1"/><rect x="10.8" y="4" width="3.4" height="12" rx="1"/><rect x="16.2" y="0" width="3.4" height="16" rx="1"/></svg>
<svg viewBox="0 0 22 16"><path d="M11 15.5 L0.6 4.6 A15.5 15.5 0 0 1 21.4 4.6 Z"/></svg>
<svg viewBox="0 0 30 16"><rect x="0.8" y="0.8" width="25" height="14.4" rx="3.5" fill="none" stroke="#1d1b20" stroke-width="1.6"/><rect x="3" y="3" width="17.5" height="10" rx="1.8"/><rect x="27" y="5" width="2.6" height="6" rx="1.2"/></svg>
"""

HOUSE = """<svg class="deco" style="{style}" viewBox="0 0 64 64" fill="none" stroke="#fff" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"><path d="M8 30 L32 10 L56 30"/><path d="M14 26 V54 H50 V26"/><rect x="27" y="38" width="10" height="16"/><rect x="18" y="32" width="7" height="7"/><rect x="39" y="32" width="7" height="7"/></svg>"""
PERCENT = """<svg class="deco" style="{style}" viewBox="0 0 64 64" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round"><circle cx="18" cy="18" r="9"/><circle cx="46" cy="46" r="9"/><path d="M50 12 L14 52"/></svg>"""
COIN = """<svg class="deco" style="{style}" viewBox="0 0 64 64" fill="none" stroke="#fff" stroke-width="3.5"><circle cx="32" cy="32" r="26"/><circle cx="32" cy="32" r="19"/><text x="32" y="40" text-anchor="middle" font-family="R" font-weight="900" font-size="20" fill="#fff" stroke="none">Rp</text></svg>"""
SPARK = """<svg class="spark" style="{style}" viewBox="0 0 24 24"><path fill="currentColor" d="M12 0 C13 7 17 11 24 12 C17 13 13 17 12 24 C11 17 7 13 0 12 C7 11 11 7 12 0Z"/></svg>"""


ICONS = {
    'home': '<path d="M3 11 L12 3 L21 11 V21 H14.5 V15 H9.5 V21 H3Z"/>',
    'layers': '<path d="M12 2 L22 7.5 L12 13 L2 7.5Z"/><path d="M4 11.3 L12 15.7 L20 11.3 L22 12.4 L12 18 L2 12.4Z"/><path d="M4 15.6 L12 20 L20 15.6 L22 16.7 L12 22.3 L2 16.7Z"/>',
    'chart': '<rect x="3" y="12" width="4" height="9" rx="1"/><rect x="10" y="7" width="4" height="14" rx="1"/><rect x="17" y="3" width="4" height="18" rx="1"/>',
    'pie': '<path d="M11 2.05 V13 H21.95 A10 10 0 1 1 11 2.05Z"/><path d="M13 2.05 A10 10 0 0 1 21.95 11 H13Z"/>',
    'list': '<rect x="3" y="4" width="18" height="3" rx="1.5"/><rect x="3" y="10.5" width="18" height="3" rx="1.5"/><rect x="3" y="17" width="12" height="3" rx="1.5"/>',
    'check': '<path d="M12 2 A10 10 0 1 1 11.99 2Z M10.2 15.6 L17.4 8.4 L15.9 7 L10.2 12.7 L7.6 10.1 L6.2 11.5Z" fill-rule="evenodd"/>',
    'percent': '<circle cx="7" cy="7" r="3.2"/><circle cx="17" cy="17" r="3.2"/><path d="M18.6 3.9 L20.1 5.4 L5.4 20.1 L3.9 18.6Z"/>',
    'wallet': '<path d="M3 6 A2 2 0 0 1 5 4 H18 V7 H5 V7.2 H20 A1 1 0 0 1 21 8.2 V19 A1 1 0 0 1 20 20 H5 A2 2 0 0 1 3 18Z M16 12.5 A1.6 1.6 0 1 0 16.01 12.5Z" fill-rule="evenodd"/>',
    'pdf': '<path d="M6 2 H14 L20 8 V21 A1 1 0 0 1 19 22 H6 A1 1 0 0 1 5 21 V3 A1 1 0 0 1 6 2Z M13 3.5 V9 H18.5" fill-rule="evenodd"/>',
    'save': '<path d="M6 3 H18 A1 1 0 0 1 19 4 V21 L12 17 L5 21 V4 A1 1 0 0 1 6 3Z"/>',
}


def floating(icon, label, value, style):
    return f"""<div class="float" style="{style}"><div class="ic"><svg viewBox="0 0 24 24">{ICONS[icon]}</svg></div>
<div><div class="t1">{label}</div><div class="t2">{value}</div></div></div>"""


def phone(shot, width, style, rotate=0):
    return f"""
<div class="phone" style="--w:{width}px; {style}; transform: rotate({rotate}deg);">
  <span class="btn vol"></span><span class="btn power"></span>
  <div class="screen">
    <div class="status"><span>9:41</span><span class="icons">{STATUS_ICONS}</span></div>
    <div class="cam"></div>
    <img class="app" src="shots/{shot}.png">
    <div class="gesture"></div>
  </div>
</div>"""


def decorations(variant=0):
    """Dekorasi latar; variant menggeser posisi supaya tiap slide tidak identik."""
    flip = variant % 2 == 1
    l, r = ('right', 'left') if flip else ('left', 'right')
    return f"""
<div class="blob" style="width:620px;height:620px;{r}:-240px;top:-200px;background:rgba(255,255,255,.16)"></div>
<div class="blob" style="width:700px;height:700px;{l}:-300px;bottom:-320px;background:rgba(40,0,80,.25)"></div>
<div class="ring" style="width:540px;height:540px;{r}:-240px;top:280px"></div>
<div class="ring thick" style="width:420px;height:420px;{l}:-210px;top:-120px"></div>
<div class="ring" style="width:300px;height:300px;{l}:-120px;bottom:120px"></div>
<div class="dots" style="width:240px;height:190px;{r}:46px;top:{70 if not flip else 96}px"></div>
<div class="dots" style="width:210px;height:240px;{l}:30px;bottom:{260 + variant * 24}px"></div>
{HOUSE.format(style=f'width:120px;{l}:60px;top:{560 + variant * 30}px;transform:rotate(-8deg)')}
{PERCENT.format(style=f'width:74px;{r}:70px;top:{720 + variant * 20}px;transform:rotate(10deg)')}
{COIN.format(style=f'width:96px;{l}:110px;bottom:{110 + variant * 18}px;transform:rotate(-12deg)')}
{HOUSE.format(style=f'width:80px;{r}:120px;bottom:{90 + variant * 10}px;transform:rotate(9deg);opacity:.12')}
{SPARK.format(style=f'width:34px;{r}:200px;top:{250 + variant * 12}px')}
{SPARK.format(style=f'width:22px;{l}:150px;top:{470 + variant * 14}px;color:#fff;opacity:.8')}
{SPARK.format(style=f'width:28px;{l}:70px;bottom:{520 - variant * 10}px')}
"""


def page(w, h, body):
    css = BASE_CSS.replace('__W__', str(w)).replace('__H__', str(h))
    return f"<!doctype html><html><head><meta charset='utf-8'><style>{css}</style></head><body>{body}</body></html>"


def write(name, html):
    with open(os.path.join(HERE, name), 'w') as f:
        f.write(html)


# ---------------------------------------------------------------- slide intro
intro = f"""
{decorations(0)}
<div style="position:absolute;left:0;right:0;top:96px;text-align:center;z-index:5">
  <div style="display:inline-flex;align-items:center;gap:18px">
    <img src="logo.png" style="width:84px;height:84px;border-radius:22px;background:#fff;box-shadow:0 14px 32px rgba(30,0,50,.3)">
    <h1 style="font-size:60px">Kalkulator KPR</h1>
  </div>
  <p class="sub" style="font-size:44px;margin-top:24px">Simulasi cicilan rumah<br><b class="hl">cepat, lengkap & akurat</b></p>
</div>
{phone('grafik', 580, 'left:430px;top:470px;z-index:2', 7)}
{phone('home', 620, 'left:80px;top:420px;z-index:3', -5)}
{floating('home', 'Angsuran per bulan', 'Rp 4.635.062', 'left:36px;top:1745px')}
{floating('layers', 'Metode bunga', 'Anuitas · Efektif · Flat', 'right:36px;top:400px')}
"""
write('slide_01.html', page(1080, 1920, intro))

# ------------------------------------------------------------- slide fitur
FEATURES = [
    ('home', 'Tiga Metode Bunga', 'Anuitas, efektif, dan flat<br>cukup <b class="hl">satu ketukan</b>', [
        ('layers', 'Pilih metode', 'Anuitas · Efektif · Flat', 'right:30px;top:600px'),
        ('home', 'Angsuran per bulan', 'Rp 4.635.062', 'left:24px;top:1010px'),
    ]),
    ('grafik', 'Grafik Angsuran', 'Total bayar, sisa pinjaman, dan<br><b class="hl">pokok vs bunga</b> tiap tahun', [
        ('pie', 'Porsi bunga', '40% dari total', 'right:24px;top:1345px'),
    ]),
    ('tabel', 'Tabel Angsuran', 'Rincian pokok, bunga, dan sisa<br>pinjaman <b class="hl">sampai lunas</b>', [
        ('list', 'Rincian lengkap', '180 bulan', 'right:16px;top:1700px'),
    ]),
    ('daya_bayar', 'Cek Daya Bayar', 'Pastikan cicilan masih <b class="hl">aman</b><br>untuk penghasilan Anda', [
        ('check', 'Rasio cicilan', '28,5% · Aman', 'right:24px;top:1450px'),
    ]),
    ('advanced', 'Fix & Floating', 'Simulasi bunga fix, floating,<br>dan <b class="hl">bunga berjenjang</b>', [
        ('percent', 'Bunga fix 3 tahun', '6,5%', 'right:24px;top:1205px'),
    ]),
    ('syariah', 'KPR Syariah', 'Akad <b class="hl">murabahah</b> &<br>musyarakah mutanaqisah', [
        ('home', 'Angsuran tetap', 'Rp 6.050.000', 'right:24px;top:1210px'),
    ]),
    ('riwayat', 'Simpan Riwayat', 'Simpan simulasi, bandingkan,<br>lalu <b class="hl">ekspor ke PDF</b>', [
        ('save', 'Tersimpan', '3 simulasi', 'right:24px;top:600px'),
        ('pdf', 'Bagikan', 'Ekspor ke PDF', 'left:30px;top:1660px'),
    ]),
]
for i, (shot, title, sub, floats) in enumerate(FEATURES, start=2):
    cards = '\n'.join(floating(*f) for f in floats)
    body = f"""
{decorations(i)}
<div style="position:absolute;left:0;right:0;top:80px;text-align:center;z-index:5">
  <h1 style="font-size:76px">{title}</h1>
  <p class="sub" style="font-size:44px;margin-top:16px">{sub}</p>
</div>
{phone(shot, 700, 'left:190px;top:372px;z-index:3')}
{cards}
"""
    write(f'slide_{i:02d}.html', page(1080, 1920, body))

# ---------------------------------------------------------- feature graphic
fg = f"""
<div class="blob" style="width:420px;height:420px;right:-60px;top:-180px;background:rgba(255,255,255,.16)"></div>
<div class="blob" style="width:420px;height:420px;left:-160px;bottom:-240px;background:rgba(40,0,80,.25)"></div>
<div class="ring" style="width:380px;height:380px;right:-120px;top:120px"></div>
<div class="ring thick" style="width:300px;height:300px;left:-150px;top:-150px;border-width:20px"></div>
<div class="dots" style="width:170px;height:120px;left:560px;top:30px;background-size:22px 22px"></div>
{HOUSE.format(style='width:76px;left:520px;bottom:40px;transform:rotate(-8deg)')}
{COIN.format(style='width:58px;left:440px;top:46px;transform:rotate(12deg)')}
{PERCENT.format(style='width:46px;right:32px;bottom:60px;transform:rotate(10deg)')}
{SPARK.format(style='width:26px;left:610px;top:200px')}
{SPARK.format(style='width:16px;left:380px;bottom:60px;color:#fff;opacity:.8')}
<div style="position:absolute;left:64px;top:0;bottom:0;display:flex;flex-direction:column;justify-content:center;z-index:5">
  <div style="display:flex;align-items:center;gap:18px">
    <img src="logo.png" style="width:84px;height:84px;border-radius:22px;background:#fff;box-shadow:0 14px 30px rgba(30,0,50,.35)">
    <h1 style="font-size:58px">Kalkulator KPR</h1>
  </div>
  <p class="sub" style="font-size:28px;margin-top:20px">Simulasi cicilan rumah<br><b class="hl" style="font-weight:900">cepat, lengkap & akurat</b></p>
</div>
{phone('grafik', 300, 'left:780px;top:60px;z-index:2', 9)}
{phone('home', 320, 'left:580px;top:36px;z-index:3', -5)}
"""
write('feature_graphic.html', page(1024, 500, fg))
print('ok')
