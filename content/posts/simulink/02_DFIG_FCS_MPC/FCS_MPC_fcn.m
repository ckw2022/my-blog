function [Vrd, Vrq] = FCS_MPC_fcn(ird, irq, ird_ref, irq_ref, theta_slip)
% FCS-MPC 控制器：穷举 8 个矢量，选代价最小的

% 参数
Rr = 0.018; Ls = 0.03459; Lr = 0.03459; Lm = 0.03348;
Np = 2; ws = 2*pi*60; Vs = 460/sqrt(3);
sigma = 1 - Lm^2/(Ls*Lr);
sLr = sigma * Lr;
psi_s = Vs / ws;
wm = 226.6;
w_slip = ws - Np * wm;
Vdc = 800;
Ts = 100e-6;

% 8 个开关状态
Sa = [0 1 1 0 0 0 1 1];
Sb = [0 0 1 1 1 0 0 1];
Sc = [0 0 0 0 1 1 1 1];

% Park 变换
ct = cos(theta_slip); st = sin(theta_slip);
ct2 = cos(theta_slip - 2*pi/3); st2 = sin(theta_slip - 2*pi/3);
ct3 = cos(theta_slip + 2*pi/3); st3 = sin(theta_slip + 2*pi/3);

J_min = 1e20;
Vrd_opt = 0;
Vrq_opt = 0;

for j = 1:8
    % abc 相电压
    Sj = [Sa(j); Sb(j); Sc(j)];
    Va = Vdc/3 * (2*Sj(1) - Sj(2) - Sj(3));
    Vb = Vdc/3 * (-Sj(1) + 2*Sj(2) - Sj(3));
    Vc = Vdc/3 * (-Sj(1) - Sj(2) + 2*Sj(3));

    % Park 变换 abc → dq 等幅值变换
    Vrd_j = 2/3 * (Va*ct + Vb*ct2 + Vc*ct3);
    Vrq_j = 2/3 * (-Va*st - Vb*st2 - Vc*st3);

    % 预测
    ird_p = ird + (Ts/sLr) * (Vrd_j - Rr*ird + w_slip*sLr*irq);
    irq_p = irq + (Ts/sLr) * (Vrq_j - Rr*irq - w_slip*(sLr*ird + Lm/Ls*psi_s));

    % 代价函数
    J = (ird_ref - ird_p)^2 + (irq_ref - irq_p)^2;

    if J < J_min
        J_min = J;
        Vrd_opt = Vrd_j;
        Vrq_opt = Vrq_j;
    end
end

Vrd = Vrd_opt;
Vrq = Vrq_opt;
end