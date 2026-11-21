#!/usr/bin/env python3
"""Night Garden approved-art RGBA preparation: Batches 02-08, 36 source assets.
Preserves original full-resolution RGB pixels; creates NON-APPROVED QA candidates only.
Source: the 40 original SHA-verified PNGs staged from GitHub Release V1.
Dry-run by default. Pass --apply to write into isolated ArtSource/RGBA_Candidates.
"""
import argparse
import csv
import hashlib
import io
import json
import sys
from collections import Counter
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "ArtSource" / "NightGarden" / "Approved_40_Icon_Batches"
DEST = ROOT / "ArtSource" / "NightGarden" / "RGBA_Candidates"
MANIFEST = SOURCE / "_Provenance" / "ARTWORK_MANIFEST.json"
EXPECTED = {2:4,3:4,4:4,5:6,6:6,7:6,8:6}
PAINTED = {
 "Night_Gameplay", "Night_Test_Strawberries", "Night_Save_Inspector",
 "Night_Combo_Preview", "Night_Economy_Inspector"
}
GENERATOR_VERSION = "2026-11-20-b02-b08-v1"
def digest(blob):
    return hashlib.sha256(blob).hexdigest()

def checkwrite(path,content,apply):
    if path.exists() and path.read_bytes()!=content:
        raise ValueError(f"Refusing to replace a different file: {path}")
    if apply and not path.exists():
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_bytes(content)

def pbytes(im,fmt="PNG"):
    buf=io.BytesIO()
    if fmt=="PNG":
        im.save(buf,format="PNG",compress_level=2)
    else:
        im.save(buf,format="JPEG",quality=92)
    return buf.getvalue()

def classifier(im,name):
    if im.mode=="RGBA" and np.asarray(im.getchannel("A")).min()<255:
        return "already_rgba"
    if name in PAINTED:
        return "painted_roundcard"
    a=np.asarray(im.convert("RGB"))
    corners=np.array([a[0,0],a[-1,0],a[0,-1],a[-1,-1]],dtype=np.int16)
    if (corners.max(axis=1)<=40).all():
        return "dark_matte"
    if ((corners.min(axis=1)>=180).all() and
        ((corners.max(axis=1)-corners.min(axis=1))<=25).all()):
        return "pale_checker"
    return "painted_roundcard"

def outer_matte(rgb,style):
    if style=="dark_matte":
        candidate=(rgb.max(axis=2)<=10).astype(np.uint8)
    else:
        a=rgb.astype(np.int16)
        candidate=((a.min(axis=2)>=203) &
                   ((a.max(axis=2)-a.min(axis=2))<=14)).astype(np.uint8)
    _, labels=cv2.connectedComponents(candidate,connectivity=8)
    at_edge=np.unique(np.hstack((labels[0,:],labels[-1,:],
                                 labels[:,0],labels[:,-1])))
    at_edge=at_edge[at_edge!=0]
    outside=np.isin(labels,at_edge).astype(np.uint8)
    alpha=cv2.GaussianBlur((1-outside).astype(np.float32),
                            (0,0),sigmaX=.85)
    return np.uint8(np.clip(np.rint(alpha*255),0,255))

def round_card_alpha(w,h,r=126):
    # Only clear the outer corners of a complete painted night scene.
    y,x=np.mgrid[:h,:w].astype(np.float32)
    qx=np.abs(x-(w-1)/2)-(w/2-r)
    qy=np.abs(y-(h-1)/2)-(h/2-r)
    sd=(np.sqrt(np.maximum(qx,0)**2+np.maximum(qy,0)**2)
        +np.minimum(np.maximum(qx,qy),0)-r)
    return np.uint8(np.rint(np.clip(.5-sd/(2*1.3),0,1)*255))

def convert(im,name):
    rgb=np.asarray(im.convert("RGB"))
    style=classifier(im,name)
    if style=="already_rgba":
        output=im.copy()
    else:
        a=(outer_matte(rgb,style) if style in
            ("dark_matte","pale_checker") else
            round_card_alpha(im.width,im.height))
        output=Image.fromarray(np.dstack((rgb,a)),"RGBA")
        if not np.array_equal(np.asarray(output)[:,:,:3],rgb):
            raise ValueError(f"Original RGB pixels changed: {name}")
    alpha=np.asarray(output.getchannel("A"))
    if alpha.min()!=0 or alpha.max()!=255 or alpha[0,0]!=0:
        raise ValueError(f"Invalid true-alpha result: {name}")
    transparent=float(np.count_nonzero(alpha==0))/alpha.size
    accepted={
       "dark_matte":(.008,.65),
       "pale_checker":(.05,.65),
       "painted_roundcard":(.003,.06),
       "already_rgba":(.01,.7)
    }
    lo,hi=accepted[style]
    if not lo<=transparent<=hi:
        raise ValueError(f"Suspicious alpha coverage {name}: {transparent}")
    return output,style,round(transparent,6)

def composite(image,bg,size=218):
    tile=image.resize((size,size),Image.Resampling.LANCZOS)
    if bg=="checker":
        canvas=Image.new("RGB",(size,size),"#f8f8f8")
        draw=ImageDraw.Draw(canvas)
        for y in range(0,size,16):
            for x in range(0,size,16):
                if (x//16+y//16)%2:
                    draw.rectangle((x,y,x+15,y+15),fill="#bdbdbd")
    else:
        canvas=Image.new("RGB",(size,size),bg)
    canvas.paste(tile,(0,0),tile)
    return canvas

def preview(items,results,batch):
    size=218
    canvas=Image.new("RGB",(size*4,len(items)*246),"#ffffff")
    draw=ImageDraw.Draw(canvas)
    for index,item in enumerate(items):
        name=item["asset_name"]
        orig,rgba,style=results[name]
        y=index*246
        draw.text((5,y+5),f"{name} ({style})",fill="#202020")
        for j,tile in enumerate((
            orig.resize((size,size),Image.Resampling.LANCZOS),
            composite(rgba,"checker"),composite(rgba,"#fff2ec"),
            composite(rgba,"#171026"))):
            canvas.paste(tile,(j*size,y+25))
    return pbytes(canvas,"JPEG")

def main(apply):
    manifest=json.loads(MANIFEST.read_text())
    items=[x for x in manifest["items"] if x["batch"] in EXPECTED]
    if len(items)!=36:
        raise ValueError("Expected exactly 36 Batch 2-8 approved icons")
    counts=Counter(x["batch"] for x in items)
    if dict(counts)!=EXPECTED:
        raise ValueError(f"Unexpected batch totals: {counts}")
    results={}
    audit=[]
    staged=[]
    for item in items:
        name=item["asset_name"]
        if item["owner_visual_approval"]!="APPROVED":
            raise ValueError(f"Not owner-approved: {name}")
        suffix=item["original_file"].removeprefix("01_Original_Approved_PNG/")
        original_path=SOURCE / suffix
        original_bytes=original_path.read_bytes()
        if digest(original_bytes)!=item["sha256"]:
            raise ValueError(f"Original PNG SHA mismatch: {name}")
        with Image.open(io.BytesIO(original_bytes)) as src:
            src.load()
            if src.size!=(1254,1254):
                raise ValueError(f"Wrong image dimensions for {name}")
            original=src.copy()
        rgba,style,transparent=convert(original,name)
        outpath=DEST / f"Batch_{item['batch']:02d}" / f"{name}_RGBA_CANDIDATE.png"
        data=pbytes(rgba)
        with Image.open(io.BytesIO(data)) as verification:
            verification.load()
            if verification.mode!="RGBA" or verification.size!=(1254,1254):
                raise ValueError(f"Wrong RGBA output format: {name}")
        checkwrite(outpath,data,apply)
        staged.append(outpath)
        results[name]=(original,rgba,style)
        audit.append(dict(batch=item["batch"],asset_name=name,method=style,
            transparent_fraction=transparent,original_sha256=item["sha256"],
            candidate_sha256=digest(data),original_approved="YES",
            candidate_visual_approval="PENDING",xcode_integrated="NO"))
    for batch in sorted(EXPECTED):
        batch_items=[x for x in items if x["batch"]==batch]
        proof=preview(batch_items,results,batch)
        p=DEST / f"Batch_{batch:02d}" / "_QA" / f"Batch_{batch:02d}_Original_Checker_Light_Dark.jpg"
        checkwrite(p,proof,apply)
        staged.append(p)
    fields=list(audit[0])
    text_stream=io.StringIO()
    writer=csv.DictWriter(text_stream,fieldnames=fields)
    writer.writeheader();writer.writerows(audit)
    p=DEST / "_Batch_02_to_08_Alpha_Audit.csv"
    checkwrite(p,text_stream.getvalue().encode(),apply)
    staged.append(p)
    summary=dict(generator_version=GENERATOR_VERSION,candidate_count=len(audit),
        methods=dict(Counter(x["method"] for x in audit)),items=audit,
        approved_originals_unchanged=True,artwork_visual_approval="PENDING",
        live_xcode_assets_modified=False)
    p=DEST / "_Batch_02_to_08_Manifest.json"
    checkwrite(p,json.dumps(summary,indent=2).encode(),apply)
    staged.append(p)
    notes=(
        "# Night Garden RGBA candidates: Batches 2-8 (36 images)\\n\\n"
        "Each 1254x1254 PNG is a separate QA candidate derived from an "
        "unchanged owner-approved Release V1 source, checksum checked.\\n"
        "Dark matte: transparent only edge-connected near-black pixels.\\n"
        "Pale/checker: transparent only edge-connected pale neutral pixels.\\n"
        "Painted scene: preserve full original night scene INSIDE a rounded "
        "square; only the corner arcs are transparent. This is NOT a cut-out "
        "of the foreground object.\\n"
        "Already RGBA: unchanged true-alpha image from source.\\n\\n"
        "No originals overwritten, no Xcode image sets changed. "
        "Visual review, edge/fringe inspection, and iPhone 16e QA required.\\n"
    )
    p=DEST / "_Batch_02_to_08_README.md"
    checkwrite(p,notes.encode(),apply)
    staged.append(p)
    print(json.dumps(dict(result="PASS",apply=apply,images=36,
        artifacts=len(staged),methods=summary["methods"]),indent=2))

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply",action="store_true")
    args=parser.parse_args()
    try:
        main(args.apply)
    except (OSError,ValueError,KeyError,AssertionError) as exc:
        print(f"NIGHT RGBA ERROR: {exc}",file=sys.stderr)
        sys.exit(1)
