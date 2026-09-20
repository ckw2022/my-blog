function [sys,x0,str,ts] = PMSM_dq_sfun(t, x, u, flag)
% PMSM S-Function：SPMSM dq 坐标系模型
% 状态：x = [id; iq; ωm; θe]
% 输入：u = [ud; uq; TL]
% 输出：y = [id; iq; ωm; θe; Te]

Rs = 1.74;  Ls = 0.004;  psi_f = 0.1167;
Np = 4;  J = 1.74e-4;  B = 7.403e-5;

switch flag
    case 0
        sizes = simsizes;
        sizes.NumContStates  = 4;
        sizes.NumDiscStates  = 0;
        sizes.NumOutputs     = 5;
        sizes.NumInputs      = 3;
        sizes.DirFeedthrough = 0;
        sizes.NumSampleTimes = 1;
        sys = simsizes(sizes);
        x0  = [0; 0; 0; 0];
        str = [];
        ts  = [0 0];

    case 1
        id = x(1); iq = x(2); wm = x(3); theta_e = x(4);
        ud = u(1); uq = u(2); TL = u(3);
        we = Np * wm;

        did = (1/Ls) * (ud - Rs*id + we*Ls*iq);
        diq = (1/Ls) * (uq - Rs*iq - we*Ls*id - we*psi_f);
        Te  = 1.5 * Np * psi_f * iq;
        dwm = (Te - B*wm - TL) / J;
        dtheta = we;

        sys = [did; diq; dwm; dtheta];

    case 3
        id = x(1); iq = x(2); wm = x(3);
        Te = 1.5 * Np * psi_f * iq;
        sys = [id; iq; wm; x(4); Te];

    case {2, 4, 9}
        sys = [];
    otherwise
        error(['Unhandled flag = ', num2str(flag)]);
end
end