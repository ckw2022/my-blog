function y = fal(e, alpha, delta)
% FAL 非线性函数，用于 ADRC 的 ESO 和 NLSEF
%
% 输入：
%   e     - 误差信号
%   alpha - 幂次（0 < alpha < 1，越小越温和）
%   delta - 线性段宽度（通常取采样周期 h）
%
% 输出：
%   y - fal 函数值
%
% 公式：
%   |e| <= delta: y = e / delta^(1-alpha)   （线性段，避免抖振）
%   |e| >  delta: y = |e|^alpha * sign(e)   （非线性段，有限时间收敛）

if abs(e) <= delta
    y = e / (delta^(1 - alpha));
else
    y = (abs(e)^alpha) * sign(e);
end
end
