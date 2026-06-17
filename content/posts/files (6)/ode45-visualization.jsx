import { useState, useMemo } from "react";

// ---- Dormand-Prince coefficients ----
const C = [0, 1/5, 3/10, 4/5, 8/9, 1, 1];
const A = [
  [],
  [1/5],
  [3/40, 9/40],
  [44/45, -56/15, 32/9],
  [19372/6561, -25360/2187, 64448/6561, -212/729],
  [9017/3168, -355/33, 46732/5247, 49/176, -5103/18656],
  [35/384, 0, 500/1113, 125/192, -2187/6784, 11/84],
];
const B  = [35/384, 0, 500/1113, 125/192, -2187/6784, 11/84, 0];
const BH = [5179/57600, 0, 7571/16695, 393/640, -92097/339200, 187/2100, 1/40];
const E  = B.map((b, i) => b - BH[i]);

function dot(a, b) { let s = 0; for (let i = 0; i < a.length; i++) s += a[i] * b[i]; return s; }
function vadd(a, b) { return a.map((v, i) => v + b[i]); }
function vscale(a, s) { return a.map(v => v * s); }
function vnorm(a) { return Math.sqrt(a.reduce((s, v) => s + v * v, 0)); }

function ode45(f, tspan, y0, rtol = 1e-6, atol = 1e-9) {
  const [t0, tf] = tspan;
  const dim = y0.length;
  let t = t0, y = [...y0];
  const hMax = (tf - t0) / 5;

  // initial step
  const f0 = f(t0, y0);
  const sc0 = y0.map(v => atol + rtol * Math.abs(v));
  const d0 = vnorm(y0.map((v, i) => v / sc0[i])) / Math.sqrt(dim);
  const d1 = vnorm(f0.map((v, i) => v / sc0[i])) / Math.sqrt(dim);
  let h = (d0 < 1e-5 || d1 < 1e-5) ? 1e-6 : Math.min(0.01 * d0 / d1, hMax);

  const tArr = [t0], yArr = [y0.slice()], hArr = [], rejArr = [];
  let k1 = f0.slice();
  let rejected = 0;

  for (let step = 0; step < 50000 && t < tf - 1e-14; step++) {
    h = Math.min(h, tf - t, hMax);
    h = Math.max(h, 1e-14);

    const K = [k1];
    for (let i = 1; i < 7; i++) {
      const ti = t + C[i] * h;
      let yi = [...y];
      for (let j = 0; j < i; j++) {
        const aij = A[i][j];
        for (let d = 0; d < dim; d++) yi[d] += h * aij * K[j][d];
      }
      K.push(f(ti, yi));
    }

    const yNew = y.map((v, d) => v + h * B.reduce((s, b, i) => s + b * K[i][d], 0));
    const errVec = y.map((_, d) => h * E.reduce((s, e, i) => s + e * K[i][d], 0));
    const sc = y.map((v, d) => atol + rtol * Math.max(Math.abs(v), Math.abs(yNew[d])));
    const errNorm = vnorm(errVec.map((e, i) => e / sc[i])) / Math.sqrt(dim);

    const factor = errNorm === 0 ? 5 : Math.min(5, Math.max(0.2, 0.9 * Math.pow(errNorm, -0.2)));

    if (errNorm <= 1) {
      t += h;
      y = yNew;
      k1 = K[6].slice();
      tArr.push(t);
      yArr.push(y.slice());
      hArr.push(h);
      rejArr.push(false);
      h = Math.min(h * factor, hMax);
    } else {
      h = h * factor;
      rejected++;
    }
  }
  return { t: tArr, y: yArr, h: hArr, rejected };
}

// ---- Example ODEs ----
const EQUATIONS = [
  {
    label: "dy/dt = −y",
    f: (t, y) => [-y[0]],
    exact: (t) => [Math.exp(-t)],
    y0: [1], tMax: 10, dim: 1, yIdx: 0,
  },
  {
    label: "dy/dt = −y + 5sin(3t)",
    f: (t, y) => [-y[0] + 5 * Math.sin(3 * t)],
    // y' = -y + 5sin(3t), y(0)=1
    // particular: yp = A sin3t + B cos3t
    // yp' + yp = (A-3B)sin + (3A+B)cos = 5sin
    // A - 3B = 5, 3A + B = 0 => B = -3A => A + 9A = 5 => A = 1/2, B = -3/2
    // yh = Ce^{-t}, y(0) = C + B = C - 3/2 = 1 => C = 5/2
    exact: (t) => [2.5 * Math.exp(-t) + 0.5 * Math.sin(3*t) - 1.5 * Math.cos(3*t)],
    y0: [1], tMax: 10, dim: 1, yIdx: 0,
  },
  {
    label: "Van der Pol (μ=3)",
    f: (t, y) => [y[1], 3 * (1 - y[0]*y[0]) * y[1] - y[0]],
    exact: null,
    y0: [2, 0], tMax: 30, dim: 2, yIdx: 0,
  },
];

const PAD = { top: 24, right: 20, bottom: 36, left: 52 };

function MiniChart({ width, height, data, domain, color, label, dashed }) {
  const [xMin, xMax] = domain.x;
  const [yMin, yMax] = domain.y;
  const sx = (v) => PAD.left + ((v - xMin) / (xMax - xMin)) * (width - PAD.left - PAD.right);
  const sy = (v) => PAD.top + ((yMax - v) / (yMax - yMin)) * (height - PAD.top - PAD.bottom);

  const path = data.map((p, i) => `${i===0?"M":"L"}${sx(p[0]).toFixed(1)},${sy(p[1]).toFixed(1)}`).join(" ");
  return <path d={path} fill="none" stroke={color} strokeWidth={dashed ? 1.5 : 2}
    strokeDasharray={dashed ? "5 3" : "none"} opacity={dashed ? 0.5 : 1} />;
}

function Chart({ width, height, eq, sol, rtolIdx }) {
  const exactPts = useMemo(() => {
    if (!eq.exact) return null;
    const pts = [];
    for (let i = 0; i <= 400; i++) {
      const t = (i / 400) * eq.tMax;
      pts.push([t, eq.exact(t)[0]]);
    }
    return pts;
  }, [eq]);

  const solPts = sol.t.map((t, i) => [t, sol.y[i][eq.yIdx]]);
  const allY = solPts.map(p => p[1]);
  if (exactPts) exactPts.forEach(p => allY.push(p[1]));
  const yMin = Math.min(...allY), yMax = Math.max(...allY);
  const yPad = (yMax - yMin) * 0.1 || 1;
  const domainX = [0, eq.tMax];
  const domainY = [yMin - yPad, yMax + yPad];

  const sx = (v) => PAD.left + ((v - domainX[0]) / (domainX[1] - domainX[0])) * (width - PAD.left - PAD.right);
  const sy = (v) => PAD.top + ((domainY[1] - v) / (domainY[1] - domainY[0])) * (height - PAD.top - PAD.bottom);

  // ticks
  const xStep = eq.tMax <= 12 ? 1 : eq.tMax <= 20 ? 2 : 5;
  const xTicks = []; for (let v = 0; v <= eq.tMax; v += xStep) xTicks.push(v);
  const yRange = domainY[1] - domainY[0];
  const yStep = yRange > 10 ? 2 : yRange > 4 ? 1 : yRange > 1 ? 0.5 : 0.2;
  const yTicks = [];
  for (let v = Math.ceil(domainY[0]/yStep)*yStep; v <= domainY[1]; v += yStep) yTicks.push(+v.toFixed(4));

  return (
    <svg viewBox={`0 0 ${width} ${height}`} style={{ width:"100%", display:"block" }}>
      {xTicks.map(v => <g key={`x${v}`}>
        <line x1={sx(v)} x2={sx(v)} y1={PAD.top} y2={height-PAD.bottom} stroke="var(--border,#e0e0e0)" strokeWidth={0.5}/>
        <text x={sx(v)} y={height-PAD.bottom+14} textAnchor="middle" fill="var(--text-secondary,#999)" fontSize={9} fontFamily="monospace">{v}</text>
      </g>)}
      {yTicks.map(v => <g key={`y${v}`}>
        <line x1={PAD.left} x2={width-PAD.right} y1={sy(v)} y2={sy(v)} stroke="var(--border,#e0e0e0)" strokeWidth={0.5}/>
        <text x={PAD.left-6} y={sy(v)+3} textAnchor="end" fill="var(--text-secondary,#999)" fontSize={9} fontFamily="monospace">{v%1===0?v:v.toFixed(1)}</text>
      </g>)}

      {exactPts && <MiniChart width={width} height={height} data={exactPts} domain={{x:domainX,y:domainY}} color="#6c5ce7" dashed />}
      <MiniChart width={width} height={height} data={solPts} domain={{x:domainX,y:domainY}} color="#00b894" />

      {solPts.map((p,i) => <circle key={i} cx={sx(p[0])} cy={sy(p[1])} r={2.5} fill="#00b894" opacity={0.7} />)}
    </svg>
  );
}

function StepChart({ width, height, sol, tMax }) {
  if (!sol.h.length) return null;
  const hMin = Math.min(...sol.h), hMax = Math.max(...sol.h);
  const logMin = Math.floor(Math.log10(hMin) - 0.3);
  const logMax = Math.ceil(Math.log10(hMax) + 0.3);

  const sx = (t) => PAD.left + (t / tMax) * (width - PAD.left - PAD.right);
  const sy = (h) => PAD.top + ((logMax - Math.log10(h)) / (logMax - logMin)) * (height - PAD.top - PAD.bottom);

  const pts = sol.t.slice(1).map((t, i) => [t, sol.h[i]]);
  const path = pts.map((p,i) => `${i===0?"M":"L"}${sx(p[0]).toFixed(1)},${sy(p[1]).toFixed(1)}`).join(" ");

  const yTicks = [];
  for (let e = logMin; e <= logMax; e++) yTicks.push(e);

  return (
    <svg viewBox={`0 0 ${width} ${height}`} style={{ width:"100%", display:"block" }}>
      {yTicks.map(e => <g key={e}>
        <line x1={PAD.left} x2={width-PAD.right} y1={sy(Math.pow(10,e))} y2={sy(Math.pow(10,e))} stroke="var(--border,#e0e0e0)" strokeWidth={0.5}/>
        <text x={PAD.left-6} y={sy(Math.pow(10,e))+3} textAnchor="end" fill="var(--text-secondary,#999)" fontSize={9} fontFamily="monospace">1e{e}</text>
      </g>)}
      <path d={path} fill="none" stroke="#e17055" strokeWidth={1.8} />
      {pts.map((p,i) => <circle key={i} cx={sx(p[0])} cy={sy(p[1])} r={2} fill="#e17055" opacity={0.6} />)}
      <text x={width/2} y={height-4} textAnchor="middle" fill="var(--text-secondary,#888)" fontSize={10} fontFamily="monospace">t</text>
      <text x={8} y={height/2} textAnchor="middle" fill="var(--text-secondary,#888)" fontSize={10} fontFamily="monospace" transform={`rotate(-90,8,${height/2})`}>h</text>
    </svg>
  );
}

const RTOLS = [1e-3, 1e-5, 1e-7, 1e-9];

export default function ODE45Viz() {
  const [eqIdx, setEqIdx] = useState(0);
  const [rtolIdx, setRtolIdx] = useState(1);

  const eq = EQUATIONS[eqIdx];
  const rtol = RTOLS[rtolIdx];

  const sol = useMemo(() => ode45(eq.f, [0, eq.tMax], eq.y0, rtol, rtol * 1e-3), [eqIdx, rtolIdx]);

  const maxErr = useMemo(() => {
    if (!eq.exact) return null;
    let mx = 0;
    for (let i = 0; i < sol.t.length; i++) {
      const ex = eq.exact(sol.t[i])[0];
      mx = Math.max(mx, Math.abs(sol.y[i][eq.yIdx] - ex));
    }
    return mx;
  }, [sol, eq]);

  return (
    <div style={{ fontFamily:"'IBM Plex Mono','SF Mono',monospace", maxWidth:740, margin:"0 auto", padding:"16px 12px", color:"var(--text-primary,#1a1a2e)" }}>
      <h2 style={{ fontSize:19, fontWeight:700, margin:"0 0 4px", letterSpacing:"-0.02em" }}>
        ODE45 自适应步长可视化
      </h2>
      <p style={{ fontSize:11.5, color:"var(--text-secondary,#777)", margin:"0 0 16px", lineHeight:1.5 }}>
        Dormand-Prince RK5(4) · 观察步长如何随解的行为自动变化
      </p>

      {/* Equation selector */}
      <div style={{ display:"flex", flexWrap:"wrap", gap:8, marginBottom:12 }}>
        {EQUATIONS.map((e, i) => (
          <button key={i} onClick={() => setEqIdx(i)} style={{
            padding:"5px 12px", fontSize:12, borderRadius:6, fontFamily:"inherit", cursor:"pointer",
            border: i===eqIdx ? "2px solid #00b894" : "1.5px solid var(--border,#ddd)",
            background: i===eqIdx ? "#00b89412" : "transparent",
            color: i===eqIdx ? "#00b894" : "var(--text-primary,#555)",
            fontWeight: i===eqIdx ? 700 : 400,
          }}>{e.label}</button>
        ))}
      </div>

      {/* Tolerance selector */}
      <div style={{ display:"flex", alignItems:"center", gap:10, marginBottom:14, flexWrap:"wrap" }}>
        <span style={{ fontSize:11.5, color:"var(--text-secondary,#888)" }}>容差 rtol =</span>
        {RTOLS.map((r, i) => (
          <button key={i} onClick={() => setRtolIdx(i)} style={{
            padding:"3px 10px", fontSize:11, borderRadius:5, fontFamily:"inherit", cursor:"pointer",
            border: i===rtolIdx ? "2px solid #e17055" : "1px solid var(--border,#ddd)",
            background: i===rtolIdx ? "#e1705512" : "transparent",
            color: i===rtolIdx ? "#e17055" : "var(--text-secondary,#888)",
            fontWeight: i===rtolIdx ? 700 : 400,
          }}>{r.toExponential(0)}</button>
        ))}
      </div>

      {/* Solution chart */}
      <div style={{ background:"var(--bg-secondary,#fafafa)", borderRadius:10, padding:8, border:"1px solid var(--border,#eee)", marginBottom:6 }}>
        <Chart width={700} height={280} eq={eq} sol={sol} rtolIdx={rtolIdx} />
      </div>

      {/* Legend */}
      <div style={{ display:"flex", justifyContent:"space-between", flexWrap:"wrap", gap:6, marginBottom:14, fontSize:11.5 }}>
        <div style={{ display:"flex", gap:14 }}>
          {eq.exact && <span style={{ color:"#6c5ce7" }}>- - 精确解</span>}
          <span style={{ color:"#00b894" }}>── ODE45</span>
        </div>
        <div style={{ display:"flex", gap:12 }}>
          <span style={{ color:"var(--text-secondary,#888)" }}>步数: <b>{sol.t.length - 1}</b></span>
          <span style={{ color:"var(--text-secondary,#888)" }}>拒步: <b style={{color: sol.rejected > 0 ? "#e17055" : "inherit"}}>{sol.rejected}</b></span>
          {maxErr !== null && (
            <span style={{
              padding:"1px 8px", borderRadius:4, fontWeight:600,
              background: maxErr < 1e-8 ? "#00b89415" : maxErr < 1e-4 ? "#f39c1215" : "#e74c3c15",
              color: maxErr < 1e-8 ? "#00b894" : maxErr < 1e-4 ? "#f39c12" : "#e74c3c",
            }}>误差 {maxErr.toExponential(2)}</span>
          )}
        </div>
      </div>

      {/* Step size chart */}
      <div style={{ fontSize:12, fontWeight:600, marginBottom:4, color:"var(--text-secondary,#666)" }}>
        步长变化 h(t)
      </div>
      <div style={{ background:"var(--bg-secondary,#fafafa)", borderRadius:10, padding:8, border:"1px solid var(--border,#eee)" }}>
        <StepChart width={700} height={180} sol={sol} tMax={eq.tMax} />
      </div>

      {/* Explanation */}
      <div style={{ marginTop:14, fontSize:11.5, color:"var(--text-secondary,#777)", lineHeight:1.7 }}>
        {eq.exact
          ? "上图：绿线为 ODE45 数值解，紫色虚线为精确解。下图：橙线显示每一步实际使用的步长——解变化平缓时步长自动增大，变化剧烈时自动缩小。调低容差可观察步数增多、误差减小。"
          : "上图：绿线为 ODE45 数值解（Van der Pol 无解析解）。下图：步长变化清晰反映了解的结构——在极限环的陡峭跳变段步长急剧缩小，在缓慢变化段步长回升。"
        }
      </div>
    </div>
  );
}
