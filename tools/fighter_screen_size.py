#!/usr/bin/env python3
# Fighter height on screen vs FightCamera/DuelCamera framing (T8 Hermes, docs/GDD/06-UI-UX.md § Розмір бійця на телефоні).
# Numbers mirror game/scripts/arena/FightCamera.gd, DuelCamera.gd, Arena.tscn (fov 48, keep_height) and Fighter.tscn (capsule 1.8 m).
import math
FOV=48.0; H=1.8; t=math.tan(math.radians(FOV/2))
def proj(cam, look, p):
    # camera looking at look; return NDC y (-1..1), vertical fov fixed (keep_height)
    f=[look[i]-cam[i] for i in range(3)]; n=math.sqrt(sum(x*x for x in f)); f=[x/n for x in f]
    up=(0,1,0)
    r=[f[1]*up[2]-f[2]*up[1], f[2]*up[0]-f[0]*up[2], f[0]*up[1]-f[1]*up[0]]; rn=math.sqrt(sum(x*x for x in r)); r=[x/rn for x in r]
    u=[r[1]*f[2]-r[2]*f[1], r[2]*f[0]-r[0]*f[2], r[0]*f[1]-r[1]*f[0]]
    d=[p[i]-cam[i] for i in range(3)]
    z=sum(d[i]*f[i] for i in range(3)); y=sum(d[i]*u[i] for i in range(3)); x=sum(d[i]*r[i] for i in range(3))
    return y/(z*t), x/(z*t)
def cam25(sep):
    dist=min(max(5.5+sep*0.78,7.0),15.5)
    return (0,1.6+dist*0.14,dist),(0,1.25,0),dist
def cam3d(sep,pull=0.0):
    dist=min(max(5.5+sep*0.78,7.0),15.5); lift=0.35+dist*0.14
    L=math.hypot(dist,lift)*(1+pull); a=math.atan2(lift,dist)
    focus=(0,1.25,0); cam=(0,1.25+L*math.sin(a),L*math.cos(a))
    return cam,focus,dist
PH=390.0  # phone height pt (06-UI-UX: 844x390)
print("mode   sep   dist | fighter h, % of screen | pt @390 | feet, % from bottom | centre x: 16:9 / 19.5:9")
for mode in ("2.5D","3D","3D+30%"):
    for sep in (1.5,3,6,9,12.82,20,25):
        if mode=="2.5D": cam,look,dist=cam25(sep)
        elif mode=="3D": cam,look,dist=cam3d(sep)
        else: cam,look,dist=cam3d(sep,0.3)
        x=sep/2
        yh,_=proj(cam,look,(x,H,0)); yf,xe=proj(cam,look,(x,0,0))
        frac=(yh-yf)/2
        print(f"{mode:6} {sep:5} {dist:5.2f} | {frac*100:5.1f}% | {frac*PH:5.1f} | {(yf+1)/2*100:5.1f}% | {(xe*0.5625+1)/2*100:5.1f}% / {(xe*9/19.5+1)/2*100:5.1f}%")
print("--- band & outer edge (body radius 0.35 m)")
for mode,fn in (("2.5D",lambda s:cam25(s)),("3D+30%",lambda s:cam3d(s,0.3))):
  for sep in (1.5,25):
    cam,look,d=fn(sep); x=sep/2
    yf,_=proj(cam,look,(x,0,0)); yh,_=proj(cam,look,(x,H,0))
    _,xo=proj(cam,look,(x+0.35,0.9,0))
    print(mode,sep,"feet pt",round((yf+1)/2*390),"head pt",round((yh+1)/2*390),
      "outer edge 16:9 %",round((xo*0.5625+1)/2*100,1),"19.5:9 %",round((xo*9/19.5+1)/2*100,1),"pt from right @844:",round(844-(xo*9/19.5+1)/2*844))
# dist needed for target fraction in 2.5D (sep=0 placement)
for target in (0.15,0.20):
  for D in [x/100 for x in range(700,1551)]:
    cam=(0,1.6+D*0.14,D); yh,_=proj(cam,(0,1.25,0),(0,H,0)); yf,_=proj(cam,(0,1.25,0),(0,0,0))
    if (yh-yf)/2 < target: print("target",target,"max dist",D-0.01); break
