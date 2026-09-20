function [sys,x0,str,ts] = DFIG_ab_sfun(t, x, u, flag)
% DFIG S-Function：αβ 静止坐标系，磁链为状态变量
% 状态：x = [ψsα; ψsβ; ψrα; ψrβ]
% 输入：u = [usα; usβ; urα; urβ]（定子电压 + 转子电压，均为 αβ 坐标系）
% 输出：y = [isα; isβ; irα; irβ; Ps; Qnov; Qs]

Rs = 2.3; Rr = 1.83;
Ls = 0.2413; Lr = 0.2413; Lm = 0.2258;
Np = 2;
D = Ls*Lr - Lm^2;      % LsLr - Lm²
wm = 188.5;             % 转子机械角速度 [rad/s]
wr = Np * wm;           % 转子电角速度

switch flag
    case 0   % 初始化
        sizes = simsizes;
        sizes.NumContStates  = 4;    % ψsα, ψsβ, ψrα, ψrβ
        sizes.NumDiscStates  = 0;
        sizes.NumOutputs     = 7;    % isα, isβ, irα, irβ, Ps, Qnov, Qs
        sizes.NumInputs      = 4;    % usα, usβ, urα, urβ
        sizes.DirFeedthrough = 0;
        sizes.NumSampleTimes = 1;
        sys = simsizes(sizes);

        % 空载稳态初始磁链
        Vs = 380*sqrt(2)/sqrt(3);%380V 是线电压有效值。转换为相电压峰值，线电压 → 除以√3得相电压有效值(220V) → 乘以√2得峰值。
        ws = 2*pi*50;
        x0 = [0; -Vs/ws; 0; -Lm*Vs/(ws*Ls)];
        str = [];
        ts  = [0 0];

    case 1   % 导数
        psi = x;
        us_alpha = u(1); us_beta = u(2);
        ur_alpha = u(3); ur_beta = u(4);

        % 电流
        is_alpha = (Lr*psi(1) - Lm*psi(3)) / D;
        is_beta = (Lr*psi(2) - Lm*psi(4)) / D;
        ir_alpha = (Ls*psi(3) - Lm*psi(1)) / D;
        ir_beta = (Ls*psi(4) - Lm*psi(2)) / D;

        % 磁链导数，对应公式（1）和（2）
        dpsi_sa = us_alpha - Rs*is_alpha;
        dpsi_sb = us_beta - Rs*is_beta;
        dpsi_ra = ur_alpha - Rr*ir_alpha - wr*psi(4);
        dpsi_rb = ur_beta - Rr*ir_beta + wr*psi(3);

        sys = [dpsi_sa; dpsi_sb; dpsi_ra; dpsi_rb];

    case 3   % 输出
        psi = x;
        is_alpha = (Lr*psi(1) - Lm*psi(3)) / D;
        is_beta = (Lr*psi(2) - Lm*psi(4)) / D;
        ir_alpha = (Ls*psi(3) - Lm*psi(1)) / D;
        ir_beta = (Ls*psi(4) - Lm*psi(2)) / D;

        % 注意：功率计算需要电压信息，但 DirFeedthrough=0
        % 这里用磁链估算电压（近似）：us ≈ dψs/dt + Rs*is ≈ ws*ψs_perp + Rs*is
        % 简化：直接输出电流，功率由外部计算
        % 或者输出 0 占位，用 Scope 中单独计算
        Ps = 0;    % 占位：功率在外部用电压和电流计算
        Qnov = 0;
        Qs = 0;

        sys = [is_alpha; is_beta; ir_alpha; ir_beta; Ps; Qnov; Qs];

    case {2, 4, 9}
        sys = [];
    otherwise
        error(['Unhandled flag = ', num2str(flag)]);
end
end