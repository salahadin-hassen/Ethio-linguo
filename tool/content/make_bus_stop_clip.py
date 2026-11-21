# Generates an ORIGINAL demo clip: script by the team, voices synthesized with
# Piper (LibriTTS-R voice, dataset CC BY 4.0), visuals drawn procedurally here.
import json, wave, math, subprocess, os, numpy as np
from piper import PiperVoice
from piper.config import SynthesisConfig
from PIL import Image, ImageDraw

LINES = [
 ("liya",  "Hey, Dawit! Long time no see!"),
 ("dawit", "Liya! How have you been?"),
 ("liya",  "I've been busy with my new job. What about you?"),
 ("dawit", "Not bad. I'm studying English every day."),
 ("liya",  "That's great! Let's catch up this weekend."),
 ("dawit", "Sounds good. See you soon!"),
]
SPK = {"liya": 20, "dawit": 3}
v = PiperVoice.load("voice.onnx")
sr = v.config.sample_rate
lead, gap, tail = 0.6, 0.45, 0.8
audio = [np.zeros(int(lead*sr), np.int16)]
t = lead; segs = []
for i,(who,text) in enumerate(LINES):
    p = f"line{i}.wav"
    with wave.open(p,"wb") as w:
        v.synthesize_wav(text, w, syn_config=SynthesisConfig(speaker_id=SPK[who], length_scale=1.12))
    w = wave.open(p); x = np.frombuffer(w.readframes(w.getnframes()), np.int16)
    # trim silence
    nz = np.where(np.abs(x) > 300)[0]; x = x[max(nz[0]-400,0): nz[-1]+800]
    d = len(x)/sr
    segs.append({"id": f"s{i+1}", "speaker": who, "en": text, "startMs": round(t*1000), "endMs": round((t+d)*1000)})
    audio.append(x); audio.append(np.zeros(int(gap*sr), np.int16)); t += d + gap
audio.append(np.zeros(int(tail*sr), np.int16))
pcm = np.concatenate(audio); total = len(pcm)/sr
with wave.open("audio.wav","wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(pcm.tobytes())
# subtitles end just before the next starts (exclusive end, no overlap)
for a,b in zip(segs, segs[1:]): a["endMs"] = min(b["startMs"], a["endMs"] + 300)
segs[-1]["endMs"] = min(round(total*1000), segs[-1]["endMs"] + 300)
json.dump({"durationMs": round(total*1000), "segments": segs}, open("timings.json","w"), indent=1)

# ---- visuals (640x360, 15 fps) ----
W,H,FPS = 640,360,15
IND,IVO,COR,TEA,GOL,PER = (36,36,67),(255,248,239),(255,112,91),(32,184,166),(244,189,80),(113,131,245)
SKIN1,SKIN2 = (122,78,52),(94,60,40)
os.makedirs("frames", exist_ok=True)
def band(d, y, h):
    for x in range(0, W, 24):
        d.polygon([(x,y),(x+12,y+h),(x+24,y)], fill=GOL)
        d.polygon([(x+12,y+h),(x+24,y),(x+36,y+h)], fill=COR)
def person(d, cx, base, skin, top, hair, talking, ph, flip):
    bob = math.sin(ph*2*math.pi*2)*3 if talking else 0
    y = base + bob
    d.rounded_rectangle([cx-34, y-120, cx+34, y], 26, fill=top)            # body
    d.rectangle([cx-34, y-30, cx+34, y-22], fill=IND)                       # belt band
    d.ellipse([cx-30, y-185, cx+30, y-125], fill=skin)                      # head
    if not flip:  # Liya: rounded afro puff hair
        d.ellipse([cx-42, y-205, cx+42, y-140], fill=hair)
        d.ellipse([cx-30, y-178, cx+30, y-125], fill=skin)
        d.rectangle([cx-30, y-170, cx+30, y-166], fill=GOL)                 # headband
    else:
        d.pieslice([cx-33, y-192, cx+33, y-140], 180, 360, fill=hair)       # short hair
    ex = 9 if not flip else -9
    for dx in (-11, 11):
        d.ellipse([cx+dx+ex*0.4-4, y-162, cx+dx+ex*0.4+4, y-154], fill=IND)
    mo = (6 + 5*abs(math.sin(ph*2*math.pi*4))) if talking else 3
    d.rounded_rectangle([cx+ex*0.4-8, y-143, cx+ex*0.4+8, y-143+mo], 3, fill=IND)
n = math.ceil(total*FPS)
for f in range(n):
    ms = f*1000/FPS
    act = next((s["speaker"] for s in segs if s["startMs"] <= ms < s["endMs"]), None)
    im = Image.new("RGB",(W,H),IVO); d = ImageDraw.Draw(im)
    d.rectangle([0,0,W,200], fill=(255,236,214))
    d.ellipse([470,30,540,100], fill=GOL)                                    # sun
    for i,(bx,bh) in enumerate([(30,90),(110,130),(200,70),(560,110)]):     # city blocks
        d.rectangle([bx,200-bh,bx+70,200], fill=(232,214,196))
        for wy in range(200-bh+12, 196, 22):
            d.rectangle([bx+12,wy,bx+24,wy+10], fill=IVO); d.rectangle([bx+44,wy,bx+56,wy+10], fill=IVO)
    d.rectangle([0,200,W,H], fill=(234,223,207))
    d.rectangle([0,300,W,H], fill=(80,80,110))
    band(d, 290, 10)
    # bus-stop sign
    d.rectangle([318,110,324,292], fill=IND); d.rounded_rectangle([296,90,346,130], 10, fill=TEA)
    d.rounded_rectangle([308,102,334,118], 4, fill=IVO)
    person(d, 220, 292, SKIN1, COR, IND, act=="liya", ms/1000, False)
    person(d, 430, 292, SKIN2, PER, (30,30,40), act=="dawit", ms/1000, True)
    if act:
        cx = 220 if act=="liya" else 430
        d.ellipse([cx-10, 70, cx+10, 90], fill=IND)
        for k in range(3):
            if (f//4 + k) % 3 == 0: d.ellipse([cx-24+k*16-3, 77, cx-24+k*16+3, 83], fill=IVO)
    im.save(f"frames/{f:04d}.png")
    if f == int(1.2*FPS): im.save("poster.jpg", quality=80)
subprocess.run(["ffmpeg","-y","-loglevel","error","-framerate",str(FPS),"-i","frames/%04d.png","-i","audio.wav",
  "-c:v","libx264","-pix_fmt","yuv420p","-profile:v","baseline","-crf","28","-c:a","aac","-b:a","64k","-shortest","-movflags","+faststart","clip.mp4"], check=True)
print(json.dumps(segs, indent=1), total)
