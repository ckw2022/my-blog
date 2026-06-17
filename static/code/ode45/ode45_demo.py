"""
ODE45 (Dormand-Prince) 方法 —— Python 实现
============================================
包含：
  1. 完整的自适应步长 Dormand-Prince 求解器（含 FSAL、拒步机制）
  2. 三个示例：指数衰减、Van der Pol 振子、三体问题（受限）
  3. 与 scipy.solve_ivp 对比 + 可视化

依赖：numpy, matplotlib, scipy（仅用于对比）
安装：pip install numpy matplotlib scipy
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp


# ============================================================
# 1. Dormand-Prince 系数（Butcher 表）
# ============================================================

# 节点 c_i
C = np.array([0, 1/5, 3/10, 4/5, 8/9, 1, 1])

# 系数矩阵 a_ij
A = np.array([
    [0,            0,           0,           0,          0,            0],
    [1/5,          0,           0,           0,          0,            0],
    [3/40,         9/40,        0,           0,          0,            0],
    [44/45,       -56/15,       32/9,        0,          0,            0],
    [19372/6561,  -25360/2187,  64448/6561, -212/729,    0,            0],
    [9017/3168,   -355/33,      46732/5247,  49/176,    -5103/18656,   0],
    [35/384,       0,           500/1113,    125/192,   -2187/6784,    11/84],
])

# 5 阶权重 b_i（用于推进，等于 A 的第 7 行）
B = np.array([35/384, 0, 500/1113, 125/192, -2187/6784, 11/84, 0])

# 4 阶权重 b̂_i（用于误差估计）
B_HAT = np.array([5179/57600, 0, 7571/16695, 393/640, -92097/339200, 187/2100, 1/40])

# 误差系数 e_i = b_i - b̂_i
E = B - B_HAT


# ============================================================
# 2. 核心求解器
# ============================================================

def ode45(f, tspan, y0, rtol=1e-6, atol=1e-9, h_max=None, h_min=1e-14,
          max_steps=100000):
    """自适应步长 Dormand-Prince (ODE45) 求解器

    参数
    ----
    f       : callable  f(t, y) → ndarray, ODE 右端函数
    tspan   : (t0, tf)  积分区间
    y0      : array_like  初值
    rtol    : float  相对容差 (默认 1e-6)
    atol    : float  绝对容差 (默认 1e-9)
    h_max   : float  最大步长 (默认 (tf-t0)/10)
    h_min   : float  最小步长 (默认 1e-14)
    max_steps : int  最大步数

    返回
    ----
    sol : dict  包含:
        't'       : ndarray  时间节点
        'y'       : ndarray  shape (len(t), dim) 状态
        'h_hist'  : list     每步实际使用的步长
        'rejected': int      拒步总次数
        'nfev'    : int      函数求值总次数
    """
    t0, tf = tspan
    y0 = np.atleast_1d(np.asarray(y0, dtype=float))
    dim = len(y0)

    if h_max is None:
        h_max = (tf - t0) / 10

    # ---- 初始步长估计（Hairer-Nørsett-Wanner 算法）----
    f0 = f(t0, y0)
    d0 = np.linalg.norm(y0 / (atol + rtol * np.abs(y0))) / np.sqrt(dim)
    d1 = np.linalg.norm(f0 / (atol + rtol * np.abs(y0))) / np.sqrt(dim)

    if d0 < 1e-5 or d1 < 1e-5:
        h0 = 1e-6
    else:
        h0 = 0.01 * d0 / d1

    h0 = min(h0, h_max)
    y1_euler = y0 + h0 * f0
    f1 = f(t0 + h0, y1_euler)
    d2 = np.linalg.norm((f1 - f0) / (atol + rtol * np.abs(y0))) / (h0 * np.sqrt(dim))

    if max(d1, d2) <= 1e-15:
        h1 = max(1e-6, h0 * 1e-3)
    else:
        h1 = (0.01 / max(d1, d2)) ** (1/5)

    h = min(100 * h0, h1, h_max)
    nfev = 2  # f0 和 f1

    # ---- 主循环 ----
    t_list = [t0]
    y_list = [y0.copy()]
    h_hist = []
    rejected = 0

    t = t0
    y = y0.copy()
    k1 = f0.copy()

    K = np.zeros((7, dim))
    step = 0

    SAFETY = 0.9
    FMAX = 5.0
    FMIN = 0.2
    EXPONENT = -1.0 / 5.0  # -1/(q) where q=5

    while t < tf - 1e-14 * abs(tf):
        if step >= max_steps:
            print(f"警告：达到最大步数 {max_steps}")
            break

        h = min(h, tf - t)  # 不越过终点
        h = max(h, h_min)

        # --- 计算 7 个斜率 ---
        K[0] = k1  # FSAL: 继承上一步的 k7
        for i in range(1, 7):
            ti = t + C[i] * h
            yi = y + h * np.dot(A[i, :i], K[:i])
            K[i] = f(ti, yi)
        nfev += 6

        # --- 5 阶解 ---
        y_new = y + h * np.dot(B, K)

        # --- 误差估计 ---
        err_vec = h * np.dot(E, K)
        sc = atol + rtol * np.maximum(np.abs(y), np.abs(y_new))
        err_norm = np.linalg.norm(err_vec / sc) / np.sqrt(dim)

        # --- 步长调整 ---
        if err_norm == 0:
            factor = FMAX
        else:
            factor = min(FMAX, max(FMIN, SAFETY * err_norm ** EXPONENT))

        if err_norm <= 1.0:
            # 接受
            t = t + h
            y = y_new
            k1 = K[6].copy()  # FSAL

            t_list.append(t)
            y_list.append(y.copy())
            h_hist.append(h)

            h = h * factor
            h = min(h, h_max)
            step += 1
        else:
            # 拒绝
            h = h * factor
            rejected += 1
            # 不更新 t, y, k1

    return {
        't': np.array(t_list),
        'y': np.array(y_list),
        'h_hist': np.array(h_hist),
        'rejected': rejected,
        'nfev': nfev,
    }


# ============================================================
# 3. 示例 ODE
# ============================================================

# ---- 示例 1：dy/dt = -y，精确解 y = e^{-t} ----
def f_decay(t, y):
    return -y

def exact_decay(t):
    return np.exp(-t)


# ---- 示例 2：Van der Pol 振子（mu 较大时逐渐变刚性）----
#  x'' - mu*(1-x^2)*x' + x = 0
#  令 y1=x, y2=x'
def make_vanderpol(mu):
    def f(t, Y):
        y1, y2 = Y
        return np.array([y2, mu * (1 - y1**2) * y2 - y1])
    return f


# ---- 示例 3：受限三体问题（Arenstorf 轨道）----
MU_MOON = 0.012277471
MU_EARTH = 1 - MU_MOON

def f_arenstorf(t, Y):
    x, y, vx, vy = Y
    D1 = ((x + MU_MOON)**2 + y**2) ** 1.5
    D2 = ((x - MU_EARTH)**2 + y**2) ** 1.5
    ax = x + 2*vy - MU_EARTH*(x + MU_MOON)/D1 - MU_MOON*(x - MU_EARTH)/D2
    ay = y - 2*vx - MU_EARTH*y/D1 - MU_MOON*y/D2
    return np.array([vx, vy, ax, ay])

# 周期约 17.0652166...
ARENSTORF_Y0 = [0.994, 0, 0, -2.00158510637908]
ARENSTORF_T = 17.0652165601579


# ============================================================
# 4. 可视化
# ============================================================

def run_demos():
    fig = plt.figure(figsize=(14, 10))

    # ============ (a) 指数衰减 + 步长历史 ============
    ax1 = fig.add_subplot(2, 2, 1)
    sol = ode45(f_decay, (0, 10), [1.0], rtol=1e-6, atol=1e-9)
    t_fine = np.linspace(0, 10, 500)
    ax1.plot(t_fine, exact_decay(t_fine), 'k-', lw=1, alpha=0.4, label='Exact')
    ax1.plot(sol['t'], sol['y'][:, 0], 'o-', ms=3, lw=1, label='ODE45')
    ax1.set_title(f"(a) dy/dt = -y  |  {len(sol['t'])-1} steps, {sol['nfev']} f-evals")
    ax1.legend(fontsize=8)
    ax1.set_xlabel('t'); ax1.set_ylabel('y')
    ax1.grid(True, alpha=0.3)

    # 步长历史
    ax1b = fig.add_subplot(2, 2, 2)
    ax1b.semilogy(sol['t'][1:], sol['h_hist'], '.-', ms=3)
    ax1b.set_title('(b) Step size history (decay)')
    ax1b.set_xlabel('t'); ax1b.set_ylabel('h')
    ax1b.grid(True, alpha=0.3, which='both')

    # ============ (c) Van der Pol ============
    ax2 = fig.add_subplot(2, 2, 3)
    for mu, color in [(1.0, '#2ecc71'), (5.0, '#e74c3c'), (10.0, '#3498db')]:
        sol_vdp = ode45(make_vanderpol(mu), (0, 40), [2.0, 0.0],
                        rtol=1e-8, atol=1e-10)
        ax2.plot(sol_vdp['y'][:, 0], sol_vdp['y'][:, 1], '-', lw=0.8,
                 color=color,
                 label=f'mu={mu} ({len(sol_vdp["t"])-1} steps)')
    ax2.set_title('(c) Van der Pol oscillator (phase plane)')
    ax2.set_xlabel('x'); ax2.set_ylabel("x'")
    ax2.legend(fontsize=7)
    ax2.grid(True, alpha=0.3)

    # ============ (d) Arenstorf 轨道 ============
    ax3 = fig.add_subplot(2, 2, 4)
    sol_ar = ode45(f_arenstorf, (0, ARENSTORF_T), ARENSTORF_Y0,
                   rtol=1e-10, atol=1e-12)
    ax3.plot(sol_ar['y'][:, 0], sol_ar['y'][:, 1], '-', lw=0.7, color='#6c5ce7')
    ax3.plot(-MU_MOON, 0, 'o', ms=8, color='#f39c12', label='Earth')
    ax3.plot(MU_EARTH, 0, 'o', ms=4, color='#bbb', label='Moon')
    ax3.set_title(f'(d) Arenstorf orbit  |  {len(sol_ar["t"])-1} steps, '
                  f'{sol_ar["rejected"]} rejected')
    ax3.set_xlabel('x'); ax3.set_ylabel('y')
    ax3.legend(fontsize=8)
    ax3.set_aspect('equal')
    ax3.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig('ode45_results.png', dpi=150, bbox_inches='tight')
    plt.show()
    print('Figure saved to ode45_results.png')


def convergence_comparison():
    """对比固定步长 RK4 和自适应 ODE45 的效率"""
    print('=' * 64)
    print('  效率对比：dy/dt = -y,  y(0) = 1,  t in [0, 10]')
    print('=' * 64)
    print(f'  {"方法":<24s}  {"步数":>6s}  {"f 求值":>8s}  {"最大误差":>14s}')
    print('-' * 64)

    # 固定步长 RK4
    from rk4_demo import rk4_solve
    for h in [0.2, 0.1, 0.05]:
        t, y = rk4_solve(f_decay, (0, 10), 1.0, h)
        err = np.max(np.abs(y - exact_decay(t)))
        nsteps = len(t) - 1
        nfev = 4 * nsteps
        print(f'  RK4 (h={h:<5g})          {nsteps:>6d}  {nfev:>8d}  {err:>14.6e}')

    # 自适应 ODE45
    for rtol in [1e-4, 1e-6, 1e-8]:
        sol = ode45(f_decay, (0, 10), [1.0], rtol=rtol, atol=rtol*1e-3)
        err = np.max(np.abs(sol['y'][:, 0] - exact_decay(sol['t'])))
        nsteps = len(sol['t']) - 1
        print(f'  ODE45 (rtol={rtol:<8g})  {nsteps:>6d}  {sol["nfev"]:>8d}  {err:>14.6e}')

    print('-' * 64)
    print('  ODE45 自动在平缓区域用大步长，精度/计算量比固定步长更优\n')


# ============================================================
# 主入口
# ============================================================

if __name__ == '__main__':
    run_demos()
    try:
        convergence_comparison()
    except ImportError:
        print('（跳过效率对比：需要 rk4_demo.py 在同一目录）')
