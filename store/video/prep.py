"""Buat versi 'bersih' screenshot: area yang akan dianimasikan dihapus."""
from PIL import Image
import numpy as np, os
A = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'assets')

def load(n): return np.array(Image.open(f'{A}/{n}').convert('RGB'))

# ---- beranda
im = load('home.png')
H, W, _ = im.shape
bg = im[:, 5].copy()                      # latar gradien vertikal (seragam horizontal)
def erase_bg(x0, x1, y0, y1):
    im[y0:y1, x0:x1] = bg[y0:y1, None, :]
yy, xx = np.mgrid[0:H, 0:W]
r = np.hypot(xx - 539.5, yy - 944.5)
ring = (r > 312) & (r < 368)
im[ring] = bg[yy[ring]]
erase_bg(250, 830, 905, 1000)             # angka total angsuran
erase_bg(225, 930, 1440, 1500)            # nilai legenda
erase_bg(140, 940, 245, 390)              # segmented switch
im[1798:1868, 70:880] = 255               # nilai jumlah pinjaman
im[1972:2045, 70:400] = 255               # tenor
im[1972:2045, 580:900] = 255              # bunga
Image.fromarray(im).save(f'{A}/home_clean.png')

# ---- daya bayar
im = load('daya_bayar.png')
im[1225:1275, 120:700] = 255
Image.fromarray(im).save(f'{A}/daya_clean.png')
print('ok', load('daya_bayar.png')[1700, 540], load('home.png')[1830, 100:330].min(0))
