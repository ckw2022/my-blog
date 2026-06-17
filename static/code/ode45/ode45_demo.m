%% ================================================================
%  ODE45 (Dormand-Prince) 方法 —— MATLAB 实现
%  ================================================================
%  包含：
%    1. 完整的自适应步长 Dormand-Prince 求解器（含 FSAL、拒步机制）
%    2. 三个示例：指数衰减、Van der Pol 振子、Arenstorf 轨道
%    3. 与 MATLAB 内置 ode45 对比 + 可视化
%
%  运行方式：直接执行此脚本
%  ================================================================

clear; clc; close all;
run_demos();

%% ================================================================
%  1. 核心求解器
%  ================================================================

function sol = my_ode45(f, tspan, y0, options)
% MY_ODE45  自适应步长 Dormand-Prince (RK45) 求解器
%
%   输入
%   ----
%   f       : 函数句柄 @(t,y)，返回列向量
%   tspan   : [t0, tf] 积分区间
%   y0      : 初值（列向量）
%   options : 结构体（可选），字段：
%             .rtol   相对容差 (默认 1e-6)
%             .atol   绝对容差 (默认 1e-9)
%             .h_max  最大步长 (默认 (tf-t0)/10)
%
%   输出
%   ----
%   sol : 结构体
%         .t       (N x 1) 时间节点
%         .y       (N x dim) 状态
%         .h_hist  每步实际步长
%         .rejected  拒步总次数
%         .nfev    函数求值总次数

    if nargin < 4, options = struct(); end
    if ~isfield(options, 'rtol'), options.rtol = 1e-6; end
    if ~isfield(options, 'atol'), options.atol = 1e-9; end

    t0 = tspan(1);  tf = tspan(2);
    y0 = y0(:);
    dim = length(y0);

    rtol = options.rtol;
    atol = options.atol;
    if isfield(options, 'h_max')
        h_max = options.h_max;
    else
        h_max = (tf - t0) / 10;
    end

    % ---- Dormand-Prince 系数 ----
    c = [0; 1/5; 3/10; 4/5; 8/9; 1; 1];

    A = zeros(7, 6);
    A(2,1) = 1/5;
    A(3,1:2) = [3/40, 9/40];
    A(4,1:3) = [44/45, -56/15, 32/9];
    A(5,1:4) = [19372/6561, -25360/2187, 64448/6561, -212/729];
    A(6,1:5) = [9017/3168, -355/33, 46732/5247, 49/176, -5103/18656];
    A(7,1:6) = [35/384, 0, 500/1113, 125/192, -2187/6784, 11/84];

    b  = [35/384; 0; 500/1113; 125/192; -2187/6784; 11/84; 0];
    bh = [5179/57600; 0; 7571/16695; 393/640; -92097/339200; 187/2100; 1/40];
    e_coeff = b - bh;

    % ---- 初始步长估计 ----
    f0 = f(t0, y0);
    sc0 = atol + rtol * abs(y0);
    d0 = norm(y0 ./ sc0) / sqrt(dim);
    d1 = norm(f0 ./ sc0) / sqrt(dim);

    if d0 < 1e-5 || d1 < 1e-5
        h0 = 1e-6;
    else
        h0 = 0.01 * d0 / d1;
    end
    h0 = min(h0, h_max);

    y1e = y0 + h0 * f0;
    f1 = f(t0 + h0, y1e);
    d2 = norm((f1 - f0) ./ sc0) / (h0 * sqrt(dim));

    if max(d1, d2) <= 1e-15
        h1 = max(1e-6, h0 * 1e-3);
    else
        h1 = (0.01 / max(d1, d2))^(1/5);
    end
    h = min([100*h0, h1, h_max]);
    nfev = 2;

    % ---- 主循环 ----
    SAFETY = 0.9;
    FMAX = 5.0;
    FMIN = 0.2;
    MAX_STEPS = 100000;

    t_list = t0;
    y_list = y0';
    h_hist = [];
    rejected = 0;

    t = t0;
    y = y0;
    k1 = f0;
    K = zeros(dim, 7);

    for step = 1:MAX_STEPS
        if t >= tf - 1e-14 * abs(tf)
            break
        end
        h = min(h, tf - t);
        h = max(h, 1e-14);

        % --- 计算 7 个斜率 ---
        K(:,1) = k1;
        for i = 2:7
            ti = t + c(i) * h;
            yi = y + h * K(:,1:i-1) * A(i,1:i-1)';
            K(:,i) = f(ti, yi);
        end
        nfev = nfev + 6;

        % --- 5 阶解 ---
        y_new = y + h * K * b;

        % --- 误差估计 ---
        err_vec = h * K * e_coeff;
        sc = atol + rtol * max(abs(y), abs(y_new));
        err_norm = norm(err_vec ./ sc) / sqrt(dim);

        % --- 步长调整 ---
        if err_norm == 0
            factor = FMAX;
        else
            factor = min(FMAX, max(FMIN, SAFETY * err_norm^(-1/5)));
        end

        if err_norm <= 1.0
            % 接受
            t = t + h;
            y = y_new;
            k1 = K(:,7);  % FSAL

            t_list(end+1, 1) = t;      %#ok<AGROW>
            y_list(end+1, :) = y';     %#ok<AGROW>
            h_hist(end+1, 1) = h;      %#ok<AGROW>

            h = min(h * factor, h_max);
        else
            % 拒绝
            h = h * factor;
            rejected = rejected + 1;
        end
    end

    sol.t = t_list;
    sol.y = y_list;
    sol.h_hist = h_hist;
    sol.rejected = rejected;
    sol.nfev = nfev;
end

%% ================================================================
%  2. 示例 ODE
%  ================================================================

function dydt = f_decay(~, y)
    dydt = -y;
end

function dYdt = f_vanderpol(t, Y, mu) %#ok<INUSL>
    dYdt = [Y(2); mu * (1 - Y(1)^2) * Y(2) - Y(1)];
end

function dYdt = f_arenstorf(~, Y)
    mu  = 0.012277471;
    mu2 = 1 - mu;
    x = Y(1); y = Y(2); vx = Y(3); vy = Y(4);
    D1 = ((x + mu)^2 + y^2)^1.5;
    D2 = ((x - mu2)^2 + y^2)^1.5;
    ax = x + 2*vy - mu2*(x + mu)/D1 - mu*(x - mu2)/D2;
    ay = y - 2*vx - mu2*y/D1 - mu*y/D2;
    dYdt = [vx; vy; ax; ay];
end

%% ================================================================
%  3. 可视化
%  ================================================================

function run_demos()
    figure('Position', [50, 50, 1100, 800]);

    % ---- (a) 指数衰减 ----
    subplot(2, 2, 1); hold on; grid on;
    sol = my_ode45(@f_decay, [0, 10], 1);
    t_fine = linspace(0, 10, 500);
    plot(t_fine, exp(-t_fine), 'k-', 'LineWidth', 1, 'Color', [0 0 0 0.35]);
    plot(sol.t, sol.y(:,1), 'o-', 'MarkerSize', 3, 'LineWidth', 1);
    title(sprintf('(a) dy/dt = -y  |  %d steps, %d f-evals', ...
          length(sol.t)-1, sol.nfev));
    xlabel('t'); ylabel('y');
    legend('Exact', 'my\_ode45', 'FontSize', 8);

    % ---- (b) 步长历史 ----
    subplot(2, 2, 2); hold on; grid on;
    semilogy(sol.t(2:end), sol.h_hist, '.-', 'MarkerSize', 4);
    title('(b) Step size history (decay)');
    xlabel('t'); ylabel('h');

    % ---- (c) Van der Pol ----
    subplot(2, 2, 3); hold on; grid on;
    colors = {[0.18 0.8 0.44], [0.91 0.3 0.24], [0.2 0.6 0.86]};
    for idx = 1:3
        mus = [1, 5, 10];
        mu = mus(idx);
        opts.rtol = 1e-8;  opts.atol = 1e-10;
        sol_vdp = my_ode45(@(t,Y) f_vanderpol(t, Y, mu), [0, 40], [2; 0], opts);
        plot(sol_vdp.y(:,1), sol_vdp.y(:,2), '-', 'LineWidth', 0.8, ...
             'Color', colors{idx}, ...
             'DisplayName', sprintf('mu=%d (%d steps)', mu, length(sol_vdp.t)-1));
    end
    title('(c) Van der Pol (phase plane)');
    xlabel('x'); ylabel("x'");
    legend('FontSize', 7);

    % ---- (d) Arenstorf 轨道 ----
    subplot(2, 2, 4); hold on; grid on;
    T_period = 17.0652165601579;
    y0_ar = [0.994; 0; 0; -2.00158510637908];
    opts2.rtol = 1e-10;  opts2.atol = 1e-12;
    sol_ar = my_ode45(@f_arenstorf, [0, T_period], y0_ar, opts2);
    plot(sol_ar.y(:,1), sol_ar.y(:,2), '-', 'LineWidth', 0.7, 'Color', [0.42 0.36 0.9]);
    mu = 0.012277471;
    plot(-mu, 0, 'o', 'MarkerSize', 8, 'Color', [0.95 0.61 0.07], ...
         'MarkerFaceColor', [0.95 0.61 0.07], 'DisplayName', 'Earth');
    plot(1-mu, 0, 'o', 'MarkerSize', 4, 'Color', [0.7 0.7 0.7], ...
         'MarkerFaceColor', [0.7 0.7 0.7], 'DisplayName', 'Moon');
    title(sprintf('(d) Arenstorf orbit  |  %d steps, %d rejected', ...
          length(sol_ar.t)-1, sol_ar.rejected));
    xlabel('x'); ylabel('y');
    axis equal;
    legend('Location', 'southwest', 'FontSize', 8);

    sgtitle('ODE45 (Dormand-Prince) 自适应步长演示', ...
            'FontSize', 14, 'FontWeight', 'bold');

    saveas(gcf, 'ode45_results.png');
    fprintf('Figure saved to ode45_results.png\n');

    % ---- 效率对比 ----
    efficiency_comparison();
end

%% ================================================================
%  4. 效率对比
%  ================================================================

function efficiency_comparison()
    fprintf('\n%s\n', repmat('=', 1, 66));
    fprintf('  效率对比：dy/dt = -y,  y(0) = 1,  t in [0, 10]\n');
    fprintf('%s\n', repmat('=', 1, 66));
    fprintf('  %-28s  %6s  %8s  %14s\n', 'Method', 'Steps', 'f-evals', 'Max Error');
    fprintf('%s\n', repmat('-', 1, 66));

    % 自己的 ode45
    for rtol = [1e-4, 1e-6, 1e-8]
        opts.rtol = rtol;  opts.atol = rtol * 1e-3;
        sol = my_ode45(@f_decay, [0, 10], 1, opts);
        err = max(abs(sol.y(:,1) - exp(-sol.t)));
        fprintf('  my_ode45 (rtol=%.0e)      %6d  %8d  %14.6e\n', ...
                rtol, length(sol.t)-1, sol.nfev, err);
    end

    % MATLAB 内置 ode45
    for rtol = [1e-4, 1e-6, 1e-8]
        opts_ml = odeset('RelTol', rtol, 'AbsTol', rtol*1e-3, 'Stats', 'off');
        [t_ml, y_ml] = ode45(@f_decay, [0, 10], 1, opts_ml);
        err = max(abs(y_ml - exp(-t_ml)));
        fprintf('  MATLAB ode45 (rtol=%.0e)  %6d  %8s  %14.6e\n', ...
                rtol, length(t_ml)-1, '—', err);
    end

    fprintf('%s\n', repmat('-', 1, 66));
    fprintf('  两者精度接近，验证实现正确性\n\n');
end
