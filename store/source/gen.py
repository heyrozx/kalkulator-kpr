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
  background: linear-gradient(165deg, #B13BCB 0%, #8E24AA 38%, #6A1B9A 70%, #3F0D63 100%); }

/* ---------- dekorasi ---------- */
.blob { position: absolute; border-radius: 50%; filter: blur(70px); }
.ring { position: absolute; border-radius: 50%; border: 2px solid rgba(255,255,255,.14); }
.ring.thick { border-width: 26px; border-color: rgba(255,255,255,.06); }
.dots { position: absolute; opacity: .5;
  background-image: radial-gradient(rgba(255,255,255,.55) 2.2px, transparent 2.6px);
  background-size: 26px 26px; }
.deco { position: absolute; opacity: .16; }
.spark { position: absolute; color: #FFD54F; }

/* ---------- teks ---------- */
.eyebrow { display: inline-flex; align-items: center; gap: 10px; padding: 10px 22px;
  border-radius: 40px; background: rgba(255,255,255,.16); border: 1.5px solid rgba(255,255,255,.28);
  font-weight: 700; font-size: 26px; letter-spacing: .5px; }
.eyebrow i { width: 12px; height: 12px; border-radius: 50%; background: #FFC940; display: block; }
h1 { font-weight: 900; line-height: 1.05; letter-spacing: -1px; }
.sub { font-weight: 400; color: rgba(255,255,255,.88); line-height: 1.35; }
.hl { color: #FFD166; }

/* ---------- kartu kecil melayang ---------- */
.chip { position: absolute; display: flex; align-items: center; gap: 16px; padding: 18px 24px;
  border-radius: 26px; background: rgba(255,255,255,.96); color: #2b123a;
  box-shadow: 0 24px 50px rgba(30,0,50,.35); }
.chip .ic { width: 58px; height: 58px; border-radius: 18px; display: flex; align-items: center;
  justify-content: center; }
.chip .t1 { font-size: 20px; color: #7a6a85; font-weight: 500; }
.chip .t2 { font-size: 28px; font-weight: 900; color: #2b123a; }

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
<div class="blob" style="width:620px;height:620px;{r}:-220px;top:-180px;background:rgba(255,128,214,.55)"></div>
<div class="blob" style="width:520px;height:520px;{l}:-200px;top:820px;background:rgba(255,201,64,.32)"></div>
<div class="blob" style="width:700px;height:700px;{r}:-260px;bottom:-300px;background:rgba(120,40,220,.55)"></div>
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
<div style="position:absolute;left:0;right:0;top:118px;text-align:center;z-index:5">
  <div style="display:inline-flex;align-items:center;gap:22px">
    <img src="logo.png" style="width:104px;height:104px;border-radius:28px;background:#fff;box-shadow:0 18px 40px rgba(30,0,50,.35)">
    <h1 style="font-size:84px;text-align:left">Kalkulator<br>KPR</h1>
  </div>
  <p class="sub" style="font-size:40px;margin-top:34px">Simulasi cicilan rumah<br><b class="hl" style="font-weight:900">cepat, lengkap & akurat</b></p>
</div>
{phone('grafik', 520, 'left:470px;top:700px;z-index:2', 8)}
{phone('home', 560, 'left:96px;top:640px;z-index:3', -6)}
<div class="chip" style="left:40px;top:1748px;z-index:6">
  <div class="ic" style="background:linear-gradient(135deg,#D154E8,#7B1FA2)">
    <svg width="34" viewBox="0 0 24 24" fill="#fff"><path d="M3 11 L12 3 L21 11 V21 H14 V15 H10 V21 H3Z"/></svg></div>
  <div><div class="t1">Angsuran per bulan</div><div class="t2">Rp 4.635.062</div></div>
</div>
<div class="chip" style="right:44px;top:560px;z-index:6;padding:16px 22px">
  <div class="ic" style="background:linear-gradient(135deg,#FFC940,#E08A00)">
    <svg width="32" viewBox="0 0 24 24" fill="#fff"><path d="M12 2 L14.6 8.6 L21.6 9.2 L16.3 13.8 L17.9 20.6 L12 17 L6.1 20.6 L7.7 13.8 L2.4 9.2 L9.4 8.6Z"/></svg></div>
  <div><div class="t1">Metode bunga</div><div class="t2" style="font-size:24px">Anuitas · Efektif · Flat</div></div>
</div>
"""
write('slide_01.html', page(1080, 1920, intro))

# ------------------------------------------------------------- slide fitur
FEATURES = [
    ('home', 'Tiga Metode Bunga', 'Anuitas, efektif, dan flat<br>cukup <b class="hl">satu ketukan</b>', '3 METODE'),
    ('grafik', 'Grafik Angsuran', 'Total bayar, sisa pinjaman, dan<br><b class="hl">pokok vs bunga</b> tiap tahun', 'VISUAL'),
    ('tabel', 'Tabel Angsuran', 'Rincian pokok, bunga, dan sisa<br>pinjaman <b class="hl">sampai lunas</b>', 'DETAIL'),
    ('daya_bayar', 'Cek Daya Bayar', 'Pastikan cicilan masih <b class="hl">aman</b><br>untuk penghasilan Anda', 'BARU'),
    ('advanced', 'Fix & Floating', 'Simulasi bunga fix, floating,<br>dan <b class="hl">bunga berjenjang</b>', 'LANJUTAN'),
    ('syariah', 'KPR Syariah', 'Akad <b class="hl">murabahah</b> &<br>musyarakah mutanaqisah', 'TANPA BUNGA'),
    ('riwayat', 'Simpan Riwayat', 'Simpan simulasi, bandingkan,<br>lalu <b class="hl">ekspor ke PDF</b>', 'PRAKTIS'),
]
for i, (shot, title, sub, eyebrow) in enumerate(FEATURES, start=2):
    body = f"""
{decorations(i)}
<div style="position:absolute;left:0;right:0;top:110px;text-align:center;z-index:5">
  <span class="eyebrow"><i></i>{eyebrow}</span>
  <h1 style="font-size:88px;margin-top:30px">{title}</h1>
  <p class="sub" style="font-size:40px;margin-top:22px">{sub}</p>
</div>
{phone(shot, 620, 'left:230px;top:560px;z-index:3')}
"""
    write(f'slide_{i:02d}.html', page(1080, 1920, body))

# ---------------------------------------------------------- feature graphic
fg = f"""
<div class="blob" style="width:420px;height:420px;right:-60px;top:-160px;background:rgba(255,128,214,.6)"></div>
<div class="blob" style="width:360px;height:360px;left:-140px;bottom:-200px;background:rgba(255,201,64,.35)"></div>
<div class="blob" style="width:420px;height:420px;right:120px;bottom:-260px;background:rgba(120,40,220,.6)"></div>
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
  <div style="display:flex;gap:10px;margin-top:26px;flex-wrap:wrap;max-width:440px">
    <span class="eyebrow" style="font-size:18px;padding:8px 16px"><i></i>Anuitas · Efektif · Flat</span>
    <span class="eyebrow" style="font-size:18px;padding:8px 16px"><i></i>KPR Syariah</span>
  </div>
</div>
{phone('grafik', 270, 'left:800px;top:70px;z-index:2', 9)}
{phone('home', 290, 'left:610px;top:44px;z-index:3', -5)}
"""
write('feature_graphic.html', page(1024, 500, fg))
print('ok')
