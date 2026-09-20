function [sys,x0,str,ts] = DFIG_sfun(t, x, u, flag)
% DFIG S-Function：转子电流动态方程（σLr 形式）
%
% 状态：x = [ird; irq]
% 输入：u = [Vrd; Vrq]
% 输出：y = [ird; irq; Ps; Qs]

% 参数（直接写死，或用 mask 传入）
Rs = 0.048; Rr = 0.018;
Ls = 0.03459; Lr = 0.03459; Lm = 0.03348;
Np = 2; ws = 2*pi*60;
Vs = 460/sqrt(3);       %相电压，460V 是线电压（line-to-line）RMS
sigma = 1 - Lm^2/(Ls*Lr);
sLr = sigma * Lr;
psi_s = Vs / ws;
wm = 226.6;                    % 恒速（可改为输入端口），假设转子转速恒定（不随负载变化）
w_slip = ws - Np * wm;

switch flag
    case 0   % 初始化
        sizes = simsizes;
        sizes.NumContStates  = 2;    % ird, irq
        sizes.NumDiscStates  = 0;
        sizes.NumOutputs     = 4;    % ird, irq, Ps, Qs
        sizes.NumInputs      = 2;    % Vrd, Vrq
        sizes.DirFeedthrough = 0;
        sizes.NumSampleTimes = 1;
        sys = simsizes(sizes);
        % 初始电流设为第一段功率参考的稳态值（Ps=-60kW, PF=0.85）
        % irq_ref = -Ps_ref*Ls/(1.5*Lm*Vs), ird_ref = psi_s/Lm - Qs_ref*Ls/(1.5*Lm*Vs)
        Ps0 = -60e3; PF0 = 0.85;
        Qs0 = Ps0*sqrt(1-PF0^2)/PF0;
        irq0 = -Ps0*Ls/(1.5*Lm*Vs);
        ird0 = psi_s/Lm - Qs0*Ls/(1.5*Lm*Vs);
        x0  = [ird0; irq0];
        str = [];
        ts  = [0 0];                % 连续时间

    case 1   % 导数（连续状态）
        ird = x(1); irq = x(2);
        Vrd = u(1); Vrq = u(2);

        dird = (1/sLr) * (Vrd - Rr*ird + w_slip*sLr*irq);
        dirq = (1/sLr) * (Vrq - Rr*irq - w_slip*(sLr*ird + Lm/Ls*psi_s));

        sys = [dird; dirq];

    case 3   % 输出
        ird = x(1); irq = x(2);
        Ps = -1.5 * Lm * Vs / Ls * irq;
        Qs =  1.5 * Vs / Ls * (psi_s - Lm * ird);
        sys = [ird; irq; Ps; Qs];

    case {2, 4, 9}
        sys = [];

    otherwise
        error(['Unhandled flag = ', num2str(flag)]);
end
end