"""Toy Monte Carlo of the LED-ring cavity: how evenly does light reach the diffuser opening?

Lambertian white walls (reflectance RHO, an assumption), LED ring outside the baffle skirt facing the
outer wall, diffuser opening as a perfect sink. It ignores the strip body and any scatter inside the
diffuser, so read the numbers as a trend against the 88 mm design, not as a prediction.
Needs numpy:  python3 docs/cavity_sim.py   (prints centre/edge irradiance for a few sizes and depths)"""
import numpy as np, sys
rng = np.random.default_rng(1)
RHO = 0.75

def cyl_hits(p, d, a, L):
    """smallest positive t where ray hits cylinder r=a within z in [0,L]; inf if none"""
    A = d[:,0]**2 + d[:,1]**2
    B = p[:,0]*d[:,0] + p[:,1]*d[:,1]
    C = p[:,0]**2 + p[:,1]**2 - a*a
    disc = B*B - A*C
    ok = (disc > 0) & (A > 1e-12)
    sq = np.sqrt(np.where(ok, disc, 0)); Asafe = np.where(A > 1e-12, A, 1)
    best = np.full(len(p), np.inf)
    for s in (-1, 1):
        t = (-B + s*sq)/Asafe
        z = p[:,2] + t*d[:,2]
        v = ok & (t > 1e-6) & (z >= 0) & (z <= L)
        best = np.where(v & (t < best), t, best)
    return best

def run(dd, depth=20.0, skirt_len=10.0, n=400000, bounces=80):
    seat_r = dd/2 - 1; si = dd/2 + 1; so = si + 1.5; Rc = dd/2 + 6; r_led = so + 1.6
    # emit from LED ring, lambertian about outward radial normal
    ph = rng.uniform(0, 2*np.pi, n); z = rng.uniform(0, min(10, skirt_len), n)
    p = np.stack([r_led*np.cos(ph), r_led*np.sin(ph), z], 1)
    nrm = np.stack([np.cos(ph), np.sin(ph), np.zeros(n)], 1)
    tang = np.stack([-np.sin(ph), np.cos(ph), np.zeros(n)], 1); zax = np.array([0,0,1.0])
    def lamb(nrm, tang):
        u = rng.random(len(nrm)); v = rng.uniform(0, 2*np.pi, len(nrm))
        s = np.sqrt(u); c = np.sqrt(1-u)
        b = np.cross(nrm, tang)
        return s[:,None]*np.cos(v)[:,None]*tang + s[:,None]*np.sin(v)[:,None]*b + c[:,None]*nrm
    d = lamb(nrm, tang)
    rs = []
    alive = np.ones(n, bool)
    for _ in range(bounces):
        idx = np.where(alive)[0]
        if len(idx) == 0: break
        P, D = p[idx], d[idx]
        m = len(idx)
        T = np.full((m, 5), np.inf)
        # 0 back wall z=depth, 1 floor z=0, 2 outer wall, 3 skirt outer, 4 skirt inner ; skirt top handled below
        dz = D[:,2]; safe = np.where(np.abs(dz) > 1e-12, dz, 1)
        t0 = (depth - P[:,2])/safe; T[:,0] = np.where((dz > 0) & (t0 > 1e-6), t0, np.inf)
        t1 = (0 - P[:,2])/safe;     T[:,1] = np.where((dz < 0) & (t1 > 1e-6), t1, np.inf)
        # outer wall: inside ray, far root
        A = D[:,0]**2 + D[:,1]**2; B = P[:,0]*D[:,0] + P[:,1]*D[:,1]; C = P[:,0]**2 + P[:,1]**2 - Rc*Rc
        disc = np.maximum(B*B - A*C, 0); As = np.where(A > 1e-12, A, 1)
        t2 = (-B + np.sqrt(disc))/As; z2 = P[:,2] + t2*D[:,2]
        T[:,2] = np.where((A > 1e-12) & (t2 > 1e-6) & (z2 >= 0) & (z2 <= depth), t2, np.inf)
        T[:,3] = cyl_hits(P, D, so, skirt_len); T[:,4] = cyl_hits(P, D, si, skirt_len)
        t5 = (skirt_len - P[:,2])/safe; h5 = P + t5[:,None]*D; r5 = np.hypot(h5[:,0], h5[:,1])
        t5 = np.where((np.abs(dz) > 1e-12) & (t5 > 1e-6) & (r5 >= si) & (r5 <= so), t5, np.inf)
        allT = np.concatenate([T, t5[:,None]], 1)
        k = np.argmin(allT, 1); t = allT[np.arange(m), k]
        hit = np.isfinite(t)
        H = P + np.where(hit, t, 0)[:,None]*D
        # floor opening = sink
        rH = np.hypot(H[:,0], H[:,1])
        sink = hit & (k == 1) & (rH < seat_r)
        rs.append(rH[sink])
        absorb = ~hit | sink | (rng.random(m) > RHO)
        # normals
        n0 = np.zeros((m,3))
        for kk in (0,1,5): n0[k == kk, 2] = 1.0
        rad = np.stack([H[:,0], H[:,1], np.zeros(m)], 1)/np.maximum(rH, 1e-9)[:,None]
        for kk in (2,3,4): n0[k == kk] = rad[k == kk]
        s = np.sign(np.sum(n0*D, 1)); s[s == 0] = 1
        n0 = -s[:,None]*n0
        tg = np.cross(n0, np.where(np.abs(n0[:,2:3]) > 0.9, np.array([1.0,0,0]), zax))
        tg /= np.maximum(np.linalg.norm(tg, axis=1), 1e-9)[:,None]
        nd = lamb(n0, tg)
        p[idx] = H + n0*1e-4; d[idx] = nd
        alive[idx[absorb]] = False
    rs = np.concatenate(rs)
    edges = np.linspace(0, seat_r, 9); cnt, _ = np.histogram(rs, edges)
    area = np.pi*(edges[1:]**2 - edges[:-1]**2); irr = cnt/area
    return irr/irr.mean(), len(rs)/n

if __name__ == "__main__":
    cases = [(88,20,10),(118,20,10),(150,20,10),(200,20,10),(250,20,10),(305,20,10),
             (305,60,30),(305,100,50)]
    print(f"RHO={RHO}  profile = relative irradiance in 8 annuli, centre -> edge")
    for dd, dep, sl in cases:
        prof, eff = run(dd, dep, sl)
        print(f"diff {dd:3d} depth {dep:3d} skirt {sl:2d} | centre/edge {prof[:2].mean()/prof[-2:].mean():5.2f} | min/max {prof.min()/prof.max():4.2f} | eff {eff*100:4.1f}% |", " ".join(f"{x:4.2f}" for x in prof))
