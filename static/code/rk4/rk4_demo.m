%% ================================================================
%  四阶 Runge-Kutta (RK4) 方法 —— MATLAB 实现
%  ================================================================
%  包含：
%    1. 通用 RK4 求解器（标量 & 向量 ODE）
%    2. 三个示例：指数增长、阻尼振荡、Lotka-Volterra 捕食系统
%    3. 与精确解 / ode45 对比 + 可视化
%    4. 收敛阶验证
%
%  运行方式：直接执行此脚本，或调用其中的函数
%  ================================================================

clear; clc; close all;

%% 主程序
convergence_test();
plot_all();

%% ================================================================
%  1. 通用 RK4 求解器
%  ================================================================

function [t_arr, y_arr] = rk4_solve(f, tspan, y0, h)
% RK4_SOLVE  用等步长四阶 Runge-Kutta 求解 ODE 初值问题
%
%   输入
%   ----
%   f     : 函数句柄 @(t,y)，返回列向量
%   tspan : [t0, tf] 积分区间
%   y0    : 初值（列向量或标量）
%   h     : 步长
%
%   输出
%   ----
%   t_arr : (N x 1) 时间节点
%   y_arr : (N x dim) 每行为一个时间步的状态

    t0 = tspan(1);  tf = tspan(2);
    y0 = y0(:);                     % 确保列向量
    dim = length(y0);

    N = ceil((tf - t0) / h);
    t_arr = zeros(N + 1, 1);
    y_arr = zeros(N + 1, dim);

    t_arr(1) = t0;
    y_arr(1, :) = y0';
    t = t0;
    y = y0;

    for i = 1:N
        hi = min(h, tf - t);       % 最后一步可能不足 h

        k1 = f(t,          y);
        k2 = f(t + hi/2,   y + hi/2 * k1);
        k3 = f(t + hi/2,   y + hi/2 * k2);
        k4 = f(t + hi,     y + hi   * k3);

        y = y + (hi / 6) * (k1 + 2*k2 + 2*k3 + k4);
        t = t + hi;

        t_arr(i + 1) = t;
        y_arr(i + 1, :) = y';
    end
end

%% ================================================================
%  2. 示例 ODE 定义
%  ================================================================

% 示例 1：dy/dt = y，精确解 y = e^t
function dydt = f_exp(~, y)
    dydt = y;
end

% 示例 2：dy/dt = -y + sin(t)
function dydt = f_osc(t, y)
    dydt = -y + sin(t);
end

function y = exact_osc(t)
    % y(0)=1 的精确解: y = (3/2)e^{-t} + (1/2)sin(t) - (1/2)cos(t)
    y = 1.5 * exp(-t) + 0.5 * sin(t) - 0.5 * cos(t);
end

% 示例 3：Lotka-Volterra
function dYdt = f_lotka(~, Y)
    alpha = 1.1;  beta = 0.4;
    delta = 0.1;  gamma = 0.4;
    x = Y(1);  y = Y(2);
    dYdt = [alpha*x - beta*x*y;
            delta*x*y - gamma*y];
end

%% ================================================================
%  3. 收敛阶验证
%  ================================================================

function convergence_test()
    fprintf('\n%s\n', repmat('=', 1, 56));
    fprintf('  收敛阶验证：dy/dt = y,  y(0) = 1,  t ∈ [0, 2]\n');
    fprintf('%s\n', repmat('=', 1, 56));
    fprintf('  %10s  %14s  %8s  %6s\n', 'h', '最大误差', '误差比', '阶');
    fprintf('%s\n', repmat('-', 1, 56));

    hs = [0.5, 0.25, 0.125, 0.0625, 0.03125];
    errors = zeros(size(hs));

    for k = 1:length(hs)
        [t, y] = rk4_solve(@f_exp, [0, 2], 1, hs(k));
        errors(k) = max(abs(y - exp(t)));
    end

    for k = 1:length(hs)
        if k == 1
            fprintf('  %10.5f  %14.6e  %8s  %6s\n', hs(k), errors(k), '—', '—');
        else
            ratio = errors(k-1) / errors(k);
            order = log2(ratio);
            fprintf('  %10.5f  %14.6e  %8.2f  %6.2f\n', hs(k), errors(k), ratio, order);
        end
    end

    fprintf('%s\n', repmat('-', 1, 56));
    fprintf('  步长减半时误差约缩小 16 倍 → 四阶精度\n\n');
end

%% ================================================================
%  4. 可视化
%  ================================================================

function plot_all()
    figure('Position', [100, 100, 1000, 750]);

    % ---- (a) 指数增长 ----
    subplot(2, 2, 1); hold on; grid on;
    t_fine = linspace(0, 3, 300);
    for info = {0.5, 'o--'; 0.25, 's-'; 0.1, '.-'}'
        hh = info{1};  style = info{2};
        [t, y] = rk4_solve(@f_exp, [0, 3], 1, hh);
        plot(t, y, style, 'MarkerSize', 4, ...
             'DisplayName', sprintf('RK4 h=%.2g', hh));
    end
    plot(t_fine, exp(t_fine), 'k-', 'LineWidth', 1.5, ...
         'Color', [0 0 0 0.35], 'DisplayName', '精确解 e^t');
    title('(a) dy/dt = y');
    xlabel('t'); ylabel('y');
    legend('Location', 'northwest', 'FontSize', 8);

    % ---- (b) 阻尼振荡 ----
    subplot(2, 2, 2); hold on; grid on;
    t_fine2 = linspace(0, 8, 400);
    [t, y] = rk4_solve(@f_osc, [0, 8], 1, 0.2);
    plot(t, y, 'o-', 'MarkerSize', 3, 'DisplayName', 'RK4 h=0.2');
    plot(t_fine2, exact_osc(t_fine2), 'k-', 'LineWidth', 1.5, ...
         'Color', [0 0 0 0.35], 'DisplayName', '精确解');
    title('(b) dy/dt = −y + sin(t)');
    xlabel('t'); ylabel('y');
    legend('Location', 'northeast', 'FontSize', 8);

    % ---- (c) Lotka-Volterra ----
    subplot(2, 2, 3); hold on; grid on;
    [t, Y] = rk4_solve(@f_lotka, [0, 50], [10; 5], 0.05);
    % ode45 参考
    opts = odeset('RelTol', 1e-10, 'AbsTol', 1e-12);
    [t_ref, Y_ref] = ode45(@f_lotka, [0, 50], [10; 5], opts);
    plot(t, Y(:,1), '-', 'LineWidth', 1.2, 'DisplayName', '猎物 x (RK4)');
    plot(t, Y(:,2), '-', 'LineWidth', 1.2, 'DisplayName', '捕食者 y (RK4)');
    plot(t_ref, Y_ref(:,1), 'k--', 'LineWidth', 0.8, ...
         'Color', [0 0 0 0.35], 'DisplayName', 'ode45 参考');
    plot(t_ref, Y_ref(:,2), 'k--', 'LineWidth', 0.8, ...
         'Color', [0 0 0 0.35], 'HandleVisibility', 'off');
    title('(c) Lotka-Volterra 捕食模型');
    xlabel('t'); ylabel('种群数量');
    legend('FontSize', 8);

    % ---- (d) 收敛阶 log-log ----
    subplot(2, 2, 4); hold on; grid on;
    hs = [0.5, 0.25, 0.125, 0.0625, 0.03125, 0.015625];
    errs = zeros(size(hs));
    for k = 1:length(hs)
        [t, y] = rk4_solve(@f_exp, [0, 2], 1, hs(k));
        errs(k) = max(abs(y - exp(t)));
    end
    loglog(hs, errs, 'o-', 'LineWidth', 2, 'DisplayName', 'RK4 误差');
    loglog(hs, errs(1) * (hs / hs(1)).^4, 'k--', ...
           'Color', [0 0 0 0.4], 'DisplayName', 'O(h^4) 参考线');
    title('(d) 全局误差 vs 步长');
    xlabel('步长 h'); ylabel('最大绝对误差');
    legend('FontSize', 8);

    sgtitle('四阶 Runge-Kutta 方法演示', 'FontSize', 14, 'FontWeight', 'bold');

    % 保存
    saveas(gcf, 'rk4_results.png');
    fprintf('图片已保存为 rk4_results.png\n');
end
