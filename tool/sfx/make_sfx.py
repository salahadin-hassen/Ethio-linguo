# Original UI sound effects, synthesized from scratch (no samples, no
# third-party audio). Run: python tool/sfx/make_sfx.py  -> assets/sfx/*.wav
import wave, numpy as np, os
SR = 22050
def tone(freq, dur, vol=0.35, attack=0.005, decay=None, harm=(1, .35, .12)):
    t = np.arange(int(SR * dur)) / SR
    w = sum(a * np.sin(2 * np.pi * freq * (i + 1) * t) for i, a in enumerate(harm))
    env = np.minimum(1, t / attack) * np.exp(-t / (decay or dur / 3))
    return vol * w * env
def seq(notes, gap=0.0):
    out = []
    for f, d, *v in notes:
        out.append(tone(f, d, *(v or [])) if f else np.zeros(int(SR * d)))
        if gap: out.append(np.zeros(int(SR * gap)))
    return np.concatenate(out)
def mix(*parts):
    n = max(len(p) for p in parts); o = np.zeros(n)
    for p in parts: o[:len(p)] += p
    return o
def save(name, x):
    x = x / max(1e-9, np.abs(x).max()) * 0.6           # quiet by design
    fade = int(SR * 0.01); x[-fade:] *= np.linspace(1, 0, fade)
    with wave.open(os.path.join('assets/sfx', name + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
C5, E5, G5, A5, C6, D5, F5, B4, G4, E6 = 523.25, 659.25, 783.99, 880, 1046.5, 587.33, 698.46, 493.88, 392, 1318.5
save('correct', seq([(E5, .09), (A5, .22)]))                       # bright rising 4th
save('incorrect', seq([(D5, .11, .25), (B4, .22, .25)]))            # soft, falling, not harsh
save('xp', seq([(C6, .05, .2), (E6, .05, .2), (G5 * 2, .12, .2)]))  # sparkle
save('save', mix(tone(G5, .12, .3, .002, .04), tone(C6, .16, .2, .02)))  # pop + shine
save('complete', seq([(C5, .1), (E5, .1), (G5, .1), (C6, .38)], gap=.015))
save('achievement', mix(seq([(G4, .12), (C5, .12), (E5, .12), (G5, .5)]), np.concatenate([np.zeros(int(SR*.36)), tone(C6, .5, .18)])))
save('tap', tone(F5, .04, .15, .001, .015, (1,)))
print(sorted(os.listdir('assets/sfx')))
