function [ird_ref, irq_ref] = power_to_current(Ps_ref, Qs_ref)
% 功率参考 → 转子电流参考

Ls = 0.03459; Lm = 0.03348;
Vs = 460/sqrt(3); ws = 2*pi*60;
psi_s = Vs / ws;

irq_ref = -Ps_ref * Ls / (1.5 * Lm * Vs);
ird_ref = psi_s / Lm - Qs_ref * Ls / (1.5 * Lm * Vs);
end