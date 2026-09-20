function [sys,x0,str,ts] = PMSM_sfun(t, x, u, flag)
% PMSM S-Function：SPMSM αβ 坐标系电流动态方程 + 机械方程
% 状态：x = [isα; isβ; θe; ωm]
% 输入：u = [usα; usβ; TL]
% 输出：y = [isα; isβ; θe; ωm; id; iq; Te]

% --- 电机参数（论文 Table I）---
Rs   = 2.34;          % 定子电阻 [Ω]
Ls   = 19.36e-3;      % 定子电感 [H]（Ld = Lq = Ls）
psi_f = 0.402;        % 永磁体磁链 [Wb]
Np   = 4;             % 极对数
J    = 0.003;         % 转动惯量 [kg·m²]
B    = 0.001;         % 粘滞摩擦 [N·m·s/rad]

switch flag
    case 0   % 初始化
        sizes = simsizes;
        sizes.NumContStates  = 4;    % isα, isβ, θe, ωm
        sizes.NumDiscStates  = 0;
        sizes.NumOutputs     = 7;    % isα, isβ, θe, ωm, id, iq, Te
        sizes.NumInputs      = 3;    % usα, usβ, TL
        sizes.DirFeedthrough = 0;
        sizes.NumSampleTimes = 1;
        sys = simsizes(sizes);
        x0  = [0; 0; 0; 0];    % 从静止开始
        str = [];
        ts  = [0 0];

    case 1   % 导数
        isa = x(1); isb = x(2); theta_e = x(3); wm = x(4);
        usa = u(1); usb = u(2); TL = u(3);
        we = Np * wm;

        % 电流微分方程（论文式3，αβ 坐标系）
        % dis/dt = (1/Ls)*(us - Rs*is - jω*ψr)
        % -jω*ψr 展开：α分量 = +ω*ψf*sinθ，β分量 = -ω*ψf*cosθ
        disa = (1/Ls) * (usa - Rs*isa + we*psi_f*sin(theta_e));
        disb = (1/Ls) * (usb - Rs*isb - we*psi_f*cos(theta_e));

        % 电磁转矩
        Te = 1.5 * Np * psi_f * (isb*cos(theta_e) - isa*sin(theta_e));

        % 机械方程
        dwm = (Te - TL - B*wm) / J;

        % 电角度
        dtheta = we;

        sys = [disa; disb; dtheta; dwm];

    case 3   % 输出
        isa = x(1); isb = x(2); theta_e = x(3); wm = x(4);
        % αβ → dq
        id =  isa * cos(theta_e) + isb * sin(theta_e);
        iq = -isa * sin(theta_e) + isb * cos(theta_e);
        Te = 1.5 * Np * psi_f * iq;
        sys = [isa; isb; theta_e; wm; id; iq; Te];

    case {2, 4, 9}
        sys = [];
    otherwise
        error(['Unhandled flag = ', num2str(flag)]);
end
end