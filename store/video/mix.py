"""Mixing SFX ElevenLabs + musik sesuai out/events_<o>.json → out/audio_<o>.wav"""
import json, subprocess, sys, numpy as np, os
SR = 48000
HERE = os.path.dirname(os.path.abspath(__file__))
def load(name):
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', f'{HERE}/sfx/{name}', '-f', 'f32le', '-ac', '2', '-ar', str(SR), '-'],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2).copy()
def norm(x, peak=.9):
    m = np.abs(x).max(); return x * (peak / m) if m > 0 else x
def trim(x, thr=.02):
    e = np.abs(x).max(1); idx = np.where(e > thr * e.max())[0]
    return x[max(0, idx[0] - 48):idx[-1] + 480] if len(idx) else x
def hits(x, min_gap=.07, length=.11):
    """Pecah rekaman ketik jadi ketukan tunggal (onset energi)."""
    x = norm(x); env = np.convolve(np.abs(x).max(1), np.ones(96) / 96, 'same')
    thr = env.max() * .18; out = []; last = -1e9
    for i in range(1, len(env)):
        if env[i] > thr >= env[i - 1] and i - last > min_gap * SR:
            s = max(0, i - 96); seg = x[s:s + int(length * SR)].copy()
            fade = np.linspace(1, 0, int(.03 * SR)); seg[-len(fade):] *= fade[:, None]
            out.append(norm(seg, .9)); last = i
    return out

S = {
    'tap': [norm(trim(load('tap4.mp3')))],
    'key': hits(load('keys_phone.mp3')),
    'type': hits(load('keys_mech.mp3')),
    'whoosh': [norm(trim(load('whoosh.mp3')))],
    'pop': [norm(trim(load('pop.mp3')))],
    'ding': [norm(trim(load(f'ding{i}.mp3'))) for i in (1, 2, 3)],
}
S['swoosh'] = S['whoosh']
print({k: len(v) for k, v in S.items()})
VOL = {'tap': .6, 'key': .42, 'type': .36, 'whoosh': .45, 'swoosh': .3, 'pop': .5, 'ding': .42}

def mix(ori):
    data = json.load(open(f'{HERE}/out/events_{ori}.json'))
    dur = data['duration']; n = int(dur * SR) + SR
    out = np.zeros((n, 2), np.float32); rng = np.random.default_rng(7)
    def put(sample, t, g):
        i = int(t * SR); seg = sample[: max(0, n - i)]; out[i:i + len(seg)] += seg * g
    for e in data['events']:
        ty = e['type']
        if ty == 'count':   # tik-tik saat angka menghitung naik
            for k in range(18):
                tt = e['t'] + .075 * k * (1 + k * .045)
                put(S['key'][k % len(S['key'])], tt, .18 * (1 - k / 22))
            continue
        bank = S[ty]; smp = bank[rng.integers(len(bank))]
        put(smp, e['t'] + rng.uniform(-.004, .004), VOL[ty] * e['gain'] * rng.uniform(.85, 1.05))
    # musik: loop 30 dtk dengan crossfade, fade in/out
    m = norm(load('music.mp3'), .9)[: int(24.0 * SR)]; xf = int(.25 * SR)  # ekor fade-out musik dibuang
    bed = m.copy()
    while len(bed) < n:
        a = bed[-xf:] * np.linspace(1, 0, xf)[:, None] + m[:xf] * np.linspace(0, 1, xf)[:, None]
        bed = np.concatenate([bed[:-xf], a, m[xf:]])
    bed = bed[:n] * .17
    fi = int(.8 * SR); bed[:fi] *= np.linspace(0, 1, fi)[:, None]
    end = int(dur * SR); fo = int(2.5 * SR); bed[end - fo:end] *= np.linspace(1, 0, fo)[:, None]; bed[end:] = 0
    # voice-over per potongan + ducking musik
    vo_env = np.zeros(n, np.float32)
    if data.get('vo') and os.path.exists(f'{HERE}/vo/voiceover_siti.mp3'):
        v = norm(load('../vo/voiceover_siti.mp3'), .95)
        for seg in data['vo']:
            a, b = int(seg['src'][0] * SR), int(seg['src'][1] * SR)
            piece = v[a:b].copy(); f = int(.02 * SR)
            piece[:f] *= np.linspace(0, 1, f)[:, None]; piece[-f:] *= np.linspace(1, 0, f)[:, None]
            i = int(seg['t'] * SR); piece = piece[: max(0, n - i)]
            out[i:i + len(piece)] += piece * .9
            vo_env[i:i + len(piece)] = 1
        k = int(.25 * SR); vo_env = np.convolve(vo_env, np.ones(k) / k, 'same')
    duck = 1 - .6 * np.clip(vo_env, 0, 1)
    out += bed * duck[:, None]
    out = out[: end]
    pk = np.abs(out).max(); out = out / pk * .89 if pk > .89 else out
    path = f'{HERE}/out/audio_{ori}.wav'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '2', '-i', '-', '-c:a', 'pcm_s16le', path],
                   input=out.astype(np.float32).tobytes(), check=True)
    print(path, round(dur, 2))
for o in sys.argv[1:] or ['v', 'h']: mix(o)
