"""Generate four original short restart cues; no external audio assets."""
import math, pathlib, struct, wave
root = pathlib.Path(__file__).resolve().parent.parent / "LastSeenApp" / "Resources"
root.mkdir(parents=True,exist_ok=True)
rate=44100
for name,notes in {"RespringDown":[(660,0.00),(440,0.10),(220,0.21)],"RespringUp":[(330,0.00),(495,0.10),(660,0.20)],"UserspaceDown":[(294,0.00),(196,0.12),(131,0.26)],"UserspaceUp":[(196,0.00),(294,0.12),(392,0.26)]}.items():
    length=0.78
    frames=[]
    for i in range(int(rate*length)):
        t=i/rate
        sample=0
        for freq,offset in notes:
            d=t-offset
            if 0<=d<0.36:
                envelope=min(1,d/0.015)*math.exp(-d*13)*min(1,(0.36-d)/0.05)
                sample+=0.28*envelope*(math.sin(2*math.pi*freq*d)+0.16*math.sin(4*math.pi*freq*d))
        frames.append(struct.pack("<h",int(max(-1,min(1,sample))*32767)))
    with wave.open(str(root/(name+".wav")),"wb") as w:
        w.setparams((1,2,rate,0,"NONE","not compressed"))
        w.writeframes(b"".join(frames))
