import { useState, useMemo, useCallback } from "react";

const EQUATIONS = [
  {
    label: "dy/dt = y",
    f: (t, y) => y,
    exact: (t) => Math.exp(t),
    y0: 1,
    tMax: 3,
  },
  {
    label: "dy/dt = −y + sin(t)",
    f: (t, y) => -y + Math.sin(t),
    exact: (t) => 1.5 * Math.exp(-t) + 0.5 * Math.sin(t) - 0.5 * Math.cos(t),
    y0: 1,
    tMax: 6,
  },
  {
    label: "dy/dt = t − y",
    f: (t, y) => t - y,
    exact: (t) => t - 1 + 2 * Math.exp(-t),
    y0: 1,
    tMax: 5,
  },
];

function rk4Full(f, y0, tMax, h) {
  const steps = [];
  let t = 0, y = y0;
  steps.push({ t, y, k1: 0, k2: 0, k3: 0, k4: 0 });
  while (t + h / 2 < tMax) {
    const k1 = f(t, y);
    const k2 = f(t + h / 2, y + (h / 2) * k1);
    const k3 = f(t + h / 2, y + (h / 2) * k2);
    const k4 = f(t + h, y + h * k3);
    y = y + (h / 6) * (k1 + 2 * k2 + 2 * k3 + k4);
    t = t + h;
    steps.push({ t, y, k1, k2, k3, k4 });
  }
  return steps;
}

function exactCurve(fn, tMax, n = 300) {
  const pts = [];
  for (let i = 0; i <= n; i++) {
    const t = (i / n) * tMax;
    pts.push({ t, y: fn(t) });
  }
  return pts;
}

const PAD = { top: 32, right: 28, bottom: 44, left: 56 };

function Chart({ width, height, eq, steps, exactPts, activeStep }) {
  const allY = [...exactPts.map(p => p.y), ...steps.map(s => s.y)];
  const yMin = Math.min(...allY), yMax = Math.max(...allY);
  const yPad = (yMax - yMin) * 0.12 || 1;
  const domainY = [yMin - yPad, yMax + yPad];
  const domainX = [0, eq.tMax];

  const sx = (t) => PAD.left + ((t - domainX[0]) / (domainX[1] - domainX[0])) * (width - PAD.left - PAD.right);
  const sy = (y) => PAD.top + ((domainY[1] - y) / (domainY[1] - domainY[0])) * (height - PAD.top - PAD.bottom);

  const exactPath = exactPts.map((p, i) => `${i === 0 ? "M" : "L"}${sx(p.t).toFixed(2)},${sy(p.y).toFixed(2)}`).join(" ");
  const rk4Path = steps.map((s, i) => `${i === 0 ? "M" : "L"}${sx(s.t).toFixed(2)},${sy(s.y).toFixed(2)}`).join(" ");

  // grid
  const xTicks = [];
  const xStep = eq.tMax <= 4 ? 0.5 : 1;
  for (let v = 0; v <= eq.tMax; v += xStep) xTicks.push(v);

  const yRange = domainY[1] - domainY[0];
  const yStep = yRange > 8 ? 2 : yRange > 3 ? 1 : 0.5;
  const yTicks = [];
  for (let v = Math.ceil(domainY[0] / yStep) * yStep; v <= domainY[1]; v += yStep) yTicks.push(+v.toFixed(4));

  // active step detail: draw k-slopes
  const aStep = activeStep !== null && activeStep > 0 ? steps[activeStep] : null;
  const aPrev = activeStep !== null && activeStep > 0 ? steps[activeStep - 1] : null;
  const h = steps.length > 1 ? steps[1].t - steps[0].t : 0;

  const slopeLines = [];
  if (aStep && aPrev) {
    const t0 = aPrev.t, y0 = aPrev.y;
    const colors = ["#e74c3c", "#f39c12", "#2ecc71", "#3498db"];
    const labels = ["k₁", "k₂", "k₃", "k₄"];
    const ks = [aStep.k1, aStep.k2, aStep.k3, aStep.k4];
    const offsets = [0, h / 2, h / 2, h];
    const bases = [
      y0,
      y0 + (h / 2) * aStep.k1,
      y0 + (h / 2) * aStep.k2,
      y0 + h * aStep.k3,
    ];

    ks.forEach((k, i) => {
      const tStart = t0 + offsets[i];
      const yStart = bases[i];
      const segLen = i < 3 ? h * 0.4 : h * 0.35;
      const tEnd = tStart + segLen;
      const yEnd = yStart + k * segLen;
      slopeLines.push(
        <g key={i}>
          <line
            x1={sx(tStart)} y1={sy(yStart)}
            x2={sx(tEnd)} y2={sy(yEnd)}
            stroke={colors[i]} strokeWidth={2.5} strokeLinecap="round"
            opacity={0.85}
          />
          <circle cx={sx(tStart)} cy={sy(yStart)} r={3} fill={colors[i]} />
          <text x={sx(tEnd) + 5} y={sy(yEnd) - 6}
            fill={colors[i]} fontSize={11} fontWeight={700} fontFamily="'IBM Plex Mono', monospace">
            {labels[i]}={k.toFixed(3)}
          </text>
        </g>
      );
    });
  }

  return (
    <svg viewBox={`0 0 ${width} ${height}`} style={{ width: "100%", height: "auto", display: "block" }}>
      <defs>
        <linearGradient id="exactGrad" x1="0" x2="1" y1="0" y2="0">
          <stop offset="0%" stopColor="#6c5ce7" stopOpacity="0.7" />
          <stop offset="100%" stopColor="#a29bfe" stopOpacity="0.7" />
        </linearGradient>
      </defs>

      {/* grid */}
      {xTicks.map(v => (
        <g key={`x${v}`}>
          <line x1={sx(v)} x2={sx(v)} y1={PAD.top} y2={height - PAD.bottom}
            stroke="var(--border, #e0e0e0)" strokeWidth={0.5} />
          <text x={sx(v)} y={height - PAD.bottom + 16} textAnchor="middle"
            fill="var(--text-secondary, #999)" fontSize={10} fontFamily="'IBM Plex Mono', monospace">{v}</text>
        </g>
      ))}
      {yTicks.map(v => (
        <g key={`y${v}`}>
          <line x1={PAD.left} x2={width - PAD.right} y1={sy(v)} y2={sy(v)}
            stroke="var(--border, #e0e0e0)" strokeWidth={0.5} />
          <text x={PAD.left - 8} y={sy(v) + 3.5} textAnchor="end"
            fill="var(--text-secondary, #999)" fontSize={10} fontFamily="'IBM Plex Mono', monospace">
            {v % 1 === 0 ? v : v.toFixed(1)}
          </text>
        </g>
      ))}

      {/* axes labels */}
      <text x={width / 2} y={height - 4} textAnchor="middle"
        fill="var(--text-secondary, #888)" fontSize={12} fontFamily="'IBM Plex Mono', monospace">t</text>
      <text x={12} y={height / 2} textAnchor="middle"
        fill="var(--text-secondary, #888)" fontSize={12} fontFamily="'IBM Plex Mono', monospace"
        transform={`rotate(-90,12,${height / 2})`}>y</text>

      {/* exact */}
      <path d={exactPath} fill="none" stroke="url(#exactGrad)" strokeWidth={2} strokeDasharray="6 3" />

      {/* highlight active interval */}
      {aPrev && aStep && (
        <rect x={sx(aPrev.t)} y={PAD.top} width={sx(aStep.t) - sx(aPrev.t)}
          height={height - PAD.top - PAD.bottom}
          fill="var(--text-primary, #000)" opacity={0.04} rx={3} />
      )}

      {/* rk4 line */}
      <path d={rk4Path} fill="none" stroke="#00b894" strokeWidth={2.5} strokeLinejoin="round" />

      {/* rk4 dots */}
      {steps.map((s, i) => (
        <circle key={i} cx={sx(s.t)} cy={sy(s.y)} r={activeStep === i ? 5.5 : 3.5}
          fill={activeStep === i ? "#00b894" : "#00b894"}
          stroke={activeStep === i ? "#fff" : "none"} strokeWidth={2}
          style={{ cursor: "pointer", transition: "r 0.15s" }}
        />
      ))}

      {/* slope lines for active step */}
      {slopeLines}
    </svg>
  );
}

export default function RK4Viz() {
  const [eqIdx, setEqIdx] = useState(0);
  const [numSteps, setNumSteps] = useState(6);
  const [activeStep, setActiveStep] = useState(null);

  const eq = EQUATIONS[eqIdx];
  const h = eq.tMax / numSteps;

  const steps = useMemo(() => rk4Full(eq.f, eq.y0, eq.tMax, h), [eqIdx, h]);
  const exactPts = useMemo(() => exactCurve(eq.exact, eq.tMax), [eqIdx]);

  const globalErr = useMemo(() => {
    return Math.max(...steps.map(s => Math.abs(s.y - eq.exact(s.t))));
  }, [steps, eqIdx]);

  const aStep = activeStep !== null && activeStep > 0 ? steps[activeStep] : null;

  return (
    <div style={{
      fontFamily: "'IBM Plex Mono', 'SF Mono', monospace",
      maxWidth: 720,
      margin: "0 auto",
      color: "var(--text-primary, #1a1a2e)",
      padding: "20px 12px",
    }}>
      <h2 style={{
        fontSize: 20, fontWeight: 700, margin: "0 0 4px",
        letterSpacing: "-0.02em",
      }}>
        四阶 Runge-Kutta 可视化
      </h2>
      <p style={{
        fontSize: 12, margin: "0 0 20px",
        color: "var(--text-secondary, #777)", lineHeight: 1.5,
      }}>
        点击 RK4 步进点查看该步四条斜率线 · 拖动步数观察精度变化
      </p>

      {/* Controls */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, marginBottom: 16, alignItems: "center" }}>
        {EQUATIONS.map((e, i) => (
          <button key={i} onClick={() => { setEqIdx(i); setActiveStep(null); }}
            style={{
              padding: "6px 14px", fontSize: 13, borderRadius: 6,
              border: i === eqIdx ? "2px solid #00b894" : "1.5px solid var(--border, #ddd)",
              background: i === eqIdx ? "#00b89415" : "transparent",
              color: i === eqIdx ? "#00b894" : "var(--text-primary, #555)",
              fontFamily: "inherit", cursor: "pointer", fontWeight: i === eqIdx ? 700 : 400,
              transition: "all 0.15s",
            }}>
            {e.label}
          </button>
        ))}
      </div>

      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16, flexWrap: "wrap" }}>
        <label style={{ fontSize: 12, color: "var(--text-secondary, #888)" }}>
          步数 N = {numSteps}　(h = {h.toFixed(3)})
        </label>
        <input type="range" min={2} max={30} value={numSteps}
          onChange={e => { setNumSteps(+e.target.value); setActiveStep(null); }}
          style={{ flex: 1, minWidth: 120, accentColor: "#00b894" }} />
      </div>

      {/* Chart */}
      <div style={{
        background: "var(--bg-secondary, #fafafa)",
        borderRadius: 10, padding: 10,
        border: "1px solid var(--border, #eee)",
      }}
        onClick={(e) => {
          // detect click on dots — use simple approach via step buttons below
        }}
      >
        <Chart width={680} height={360} eq={eq} steps={steps} exactPts={exactPts} activeStep={activeStep} />
      </div>

      {/* Step selector */}
      <div style={{
        display: "flex", gap: 4, flexWrap: "wrap", marginTop: 10,
        justifyContent: "center",
      }}>
        {steps.map((s, i) => (
          <button key={i} onClick={() => setActiveStep(i === activeStep ? null : i)}
            style={{
              width: 28, height: 28, borderRadius: 6, fontSize: 10,
              border: activeStep === i ? "2px solid #00b894" : "1px solid var(--border, #ddd)",
              background: activeStep === i ? "#00b894" : "transparent",
              color: activeStep === i ? "#fff" : "var(--text-secondary, #999)",
              cursor: "pointer", fontFamily: "inherit", fontWeight: 600,
              transition: "all 0.12s",
            }}>
            {i}
          </button>
        ))}
      </div>

      {/* Legend + error */}
      <div style={{
        display: "flex", justifyContent: "space-between",
        alignItems: "center", marginTop: 14, flexWrap: "wrap", gap: 8,
      }}>
        <div style={{ display: "flex", gap: 16, fontSize: 12 }}>
          <span style={{ color: "#6c5ce7" }}>- - 精确解</span>
          <span style={{ color: "#00b894" }}>── RK4</span>
        </div>
        <span style={{
          fontSize: 12, padding: "3px 10px", borderRadius: 5,
          background: globalErr < 0.01 ? "#00b89418" : globalErr < 0.1 ? "#f39c1218" : "#e74c3c18",
          color: globalErr < 0.01 ? "#00b894" : globalErr < 0.1 ? "#f39c12" : "#e74c3c",
          fontWeight: 600,
        }}>
          最大误差 {globalErr.toExponential(2)}
        </span>
      </div>

      {/* Detail panel */}
      {aStep && activeStep > 0 && (
        <div style={{
          marginTop: 16, padding: 14, borderRadius: 10,
          background: "var(--bg-secondary, #f7f7f7)",
          border: "1px solid var(--border, #eee)",
          fontSize: 12, lineHeight: 1.8,
        }}>
          <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 6 }}>
            第 {activeStep} 步　t: {steps[activeStep - 1].t.toFixed(3)} → {aStep.t.toFixed(3)}
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))", gap: "4px 20px" }}>
            <span><span style={{ color: "#e74c3c", fontWeight: 700 }}>k₁</span> = {aStep.k1.toFixed(6)}</span>
            <span><span style={{ color: "#f39c12", fontWeight: 700 }}>k₂</span> = {aStep.k2.toFixed(6)}</span>
            <span><span style={{ color: "#2ecc71", fontWeight: 700 }}>k₃</span> = {aStep.k3.toFixed(6)}</span>
            <span><span style={{ color: "#3498db", fontWeight: 700 }}>k₄</span> = {aStep.k4.toFixed(6)}</span>
          </div>
          <div style={{ marginTop: 8, color: "var(--text-secondary, #888)" }}>
            y<sub>{activeStep}</sub> = {steps[activeStep - 1].y.toFixed(6)} + (h/6)·({aStep.k1.toFixed(3)} + 2×{aStep.k2.toFixed(3)} + 2×{aStep.k3.toFixed(3)} + {aStep.k4.toFixed(3)}) = <strong style={{ color: "#00b894" }}>{aStep.y.toFixed(6)}</strong>
            <span style={{ marginLeft: 10, color: "#6c5ce7" }}>精确值 {eq.exact(aStep.t).toFixed(6)}</span>
          </div>
        </div>
      )}
    </div>
  );
}
