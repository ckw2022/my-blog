"""
四阶 Runge-Kutta (RK4) 方法 —— Python 实现
=============================================
包含：
  1. 通用 RK4 求解器（标量 & 向量 ODE）
  2. 三个示例：指数增长、阻尼振荡、Lotka-Volterra 捕食系统
  3. 与精确解/scipy 对比 + matplotlib 可视化

依赖：numpy, matplotlib, scipy（仅用于对比）
安装：pip install numpy matplotlib scipy
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp


# ============================================================
# 1. 通用 RK4 求解器
# ============================================================

def rk4_step(f, t, y, h):
    """单步四阶 Runge-Kutta
    
    参数
    ----
    f : callable  —— f(t, y), 返回与 y 同形的导数
    t : float     —— 当前时间
    y : ndarray   —— 当前状态
    h : float     —— 步长
    
    返回
    ----
    y_next : ndarray  —— 下一步的状态
    ks     : tuple    —— (k1, k2, k3, k4) 用于调试 / 可视化
    """
    k1 = f(t, y)
    k2 = f(t + h / 2, y + h / 2 * k1)
    k3 = f(t + h / 2, y + h / 2 * k2)
    k4 = f(t + h, y + h * k3)
    y_next = y + (h / 6) * (k1 + 2 * k2 + 2 * k3 + k4)
    return y_next, (k1, k2, k3, k4)


def rk4_solve(f, tspan, y0, h):
    """用等步长 RK4 求解 ODE 初值问题
    
    参数
    ----
    f     : callable       —— f(t, y)
    tspan : (t0, tf)       —— 积分区间
    y0    : float 或 array —— 初值
    h     : float          —— 步长
    
    返回
    ----
    t_arr : ndarray  (N,)
    y_arr : ndarray  (N,) 或 (N, dim)
    """
    t0, tf = tspan
    scalar = np.isscalar(y0)
    y = np.atleast_1d(np.array(y0, dtype=float))

    t_list = [t0]
    y_list = [y.copy()]

    t = t0
    while t < tf - 1e-12:
        hi = min(h, tf - t)          # 最后一步可能不足 h
        y, _ = rk4_step(f, t, y, hi)
        t += hi
        t_list.append(t)
        y_list.append(y.copy())

    t_arr = np.array(t_list)
    y_arr = np.array(y_list)
    if scalar:
        y_arr = y_arr.ravel()
    return t_arr, y_arr


# ============================================================
# 2. 示例 ODE
# ============================================================

# ---- 示例 1：dy/dt = y，精确解 y = e^t ----
def f_exp(t, y):
    return y

def exact_exp(t):
    return np.exp(t)


# ---- 示例 2：dy/dt = -y + sin(t) ----
def f_osc(t, y):
    return -y + np.sin(t)

def exact_osc(t):
    # y(0)=1 的精确解: y = (3/2)e^{-t} + (1/2)sin(t) - (1/2)cos(t)
    return 1.5 * np.exp(-t) + 0.5 * np.sin(t) - 0.5 * np.cos(t)


# ---- 示例 3：Lotka-Volterra 捕食方程（向量 ODE）----
#   dx/dt = alpha*x - beta*x*y
#   dy/dt = delta*x*y - gamma*y
ALPHA, BETA, DELTA, GAMMA = 1.1, 0.4, 0.1, 0.4

def f_lotka(t, Y):
    x, y = Y
    dxdt = ALPHA * x - BETA * x * y
    dydt = DELTA * x * y - GAMMA * y
    return np.array([dxdt, dydt])


# ============================================================
# 3. 收敛阶验证
# ============================================================

def convergence_test():
    """通过逐步减半 h，验证 RK4 全局误差为 O(h^4)"""
    tspan = (0, 2)
    y0 = 1.0
    hs = [0.5, 0.25, 0.125, 0.0625, 0.03125]
    errors = []

    print("=" * 52)
    print("  收敛阶验证：dy/dt = y,  y(0) = 1,  t ∈ [0, 2]")
    print("=" * 52)
    print(f"  {'h':>10s}  {'最大误差':>14s}  {'误差比':>8s}  {'阶':>6s}")
    print("-" * 52)

    for h in hs:
        t_arr, y_arr = rk4_solve(f_exp, tspan, y0, h)
        err = np.max(np.abs(y_arr - exact_exp(t_arr)))
        errors.append(err)

    for i, (h, err) in enumerate(zip(hs, errors)):
        if i == 0:
            print(f"  {h:10.5f}  {err:14.6e}  {'—':>8s}  {'—':>6s}")
        else:
            ratio = errors[i - 1] / err
            order = np.log2(ratio)
            print(f"  {h:10.5f}  {err:14.6e}  {ratio:8.2f}  {order:6.2f}")

    print("-" * 52)
    print("  步长减半时误差约缩小 16 倍 → 四阶精度 ✓\n")


# ============================================================
# 4. 可视化
# ============================================================

def plot_all():
    fig, axes = plt.subplots(2, 2, figsize=(12, 9))
    fig.suptitle("四阶 Runge-Kutta 方法演示", fontsize=15, fontweight="bold")

    # ---- (a) 指数增长 ----
    ax = axes[0, 0]
    t_fine = np.linspace(0, 3, 300)
    for h, ls in [(0.5, "o--"), (0.25, "s-"), (0.1, ".-")]:
        t, y = rk4_solve(f_exp, (0, 3), 1.0, h)
        ax.plot(t, y, ls, markersize=4, label=f"RK4 h={h}")
    ax.plot(t_fine, exact_exp(t_fine), "k-", lw=1.5, alpha=0.4, label="精确解 $e^t$")
    ax.set_title("(a) dy/dt = y")
    ax.legend(fontsize=8)
    ax.set_xlabel("t")
    ax.set_ylabel("y")
    ax.grid(True, alpha=0.3)

    # ---- (b) 阻尼振荡 ----
    ax = axes[0, 1]
    t_fine2 = np.linspace(0, 8, 400)
    t, y = rk4_solve(f_osc, (0, 8), 1.0, 0.2)
    ax.plot(t, y, "o-", markersize=3, label="RK4 h=0.2")
    ax.plot(t_fine2, exact_osc(t_fine2), "k-", lw=1.5, alpha=0.4, label="精确解")
    ax.set_title("(b) dy/dt = −y + sin(t)")
    ax.legend(fontsize=8)
    ax.set_xlabel("t")
    ax.set_ylabel("y")
    ax.grid(True, alpha=0.3)

    # ---- (c) Lotka-Volterra ----
    ax = axes[1, 0]
    t, Y = rk4_solve(f_lotka, (0, 50), [10.0, 5.0], 0.05)
    # scipy 参考
    sol = solve_ivp(f_lotka, [0, 50], [10.0, 5.0], max_step=0.01,
                    rtol=1e-10, atol=1e-12)
    ax.plot(t, Y[:, 0], "-", lw=1.2, label="猎物 x (RK4)")
    ax.plot(t, Y[:, 1], "-", lw=1.2, label="捕食者 y (RK4)")
    ax.plot(sol.t, sol.y[0], "k--", lw=0.8, alpha=0.4, label="scipy 参考")
    ax.plot(sol.t, sol.y[1], "k--", lw=0.8, alpha=0.4)
    ax.set_title("(c) Lotka-Volterra 捕食模型")
    ax.legend(fontsize=8)
    ax.set_xlabel("t")
    ax.set_ylabel("种群数量")
    ax.grid(True, alpha=0.3)

    # ---- (d) 收敛阶 log-log ----
    ax = axes[1, 1]
    hs = np.array([0.5, 0.25, 0.125, 0.0625, 0.03125, 0.015625])
    errs = []
    for h in hs:
        t_arr, y_arr = rk4_solve(f_exp, (0, 2), 1.0, h)
        errs.append(np.max(np.abs(y_arr - exact_exp(t_arr))))
    errs = np.array(errs)
    ax.loglog(hs, errs, "o-", lw=2, label="RK4 误差")
    ax.loglog(hs, errs[0] * (hs / hs[0]) ** 4, "k--", alpha=0.5, label="$O(h^4)$ 参考线")
    ax.set_title("(d) 全局误差 vs 步长")
    ax.set_xlabel("步长 h")
    ax.set_ylabel("最大绝对误差")
    ax.legend(fontsize=8)
    ax.grid(True, alpha=0.3, which="both")

    plt.tight_layout()
    plt.savefig("rk4_results.png", dpi=150, bbox_inches="tight")
    plt.show()
    print("图片已保存为 rk4_results.png")


# ============================================================
# 主入口
# ============================================================

if __name__ == "__main__":
    convergence_test()
    plot_all()
