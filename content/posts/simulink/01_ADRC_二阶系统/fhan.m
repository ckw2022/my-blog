function fh = fhan(x1, x2, r, h)
% FHAN 最速控制综合函数（对应论文式(11)，变量名与论文一致）
%
% 输入：
%   x1 - 状态1（误差或跟踪误差）
%   x2 - 状态2（误差导数）
%   r  - 加速度限幅参数
%   h  - 步长（TD 中用 h，NLSEF 中用 h1）
%
% 输出：
%   fh - 时间最优控制量（bang-bang + 平滑边界层）
%
% 论文式(11)原始公式（sign形式）：
%   d  = h^2 * r
%   a0 = h * x2
%   y  = x1 + a0
%   a1 = sqrt(d*(d + 8|y|))
%   a2 = a0 + sign(y)*(a1 - d)/2
%   sy = (sign(y+d) - sign(y-d))/2     |y|<d → 1, 否则 0
%   a  = (a0 + y - a2)*sy + a2
%   sa = (sign(a+d) - sign(a-d))/2     |a|<d → 1, 否则 0
%   fhan = -r*(a/d - sign(a))*sa - r*sign(a)
%
% 下面用等价的 if/else 写法，更直观：

d  = r * h^2;                          % 论文中 d = h^2 * r
a0 = h * x2;                           % 速度预测量
y  = x1 + a0;                          % 一步预测位置

a1 = sqrt(d^2 + 8 * d * abs(y));       % sqrt(d*(d + 8|y|))
a2 = a0 + sign(y) * (a1 - d) / 2;     % 远离原点时的切换变量

% sy 分支：选择切换变量 a
if abs(y) <= d
    a = a0 + y;                         % 接近原点：线性段
else
    a = a2;                             % 远离原点：抛物线切换
end

% sa 分支：输出控制量
if abs(a) <= d
    fh = -r * a / d;                    % 边界层内：线性
else
    fh = -r * sign(a);                  % 边界层外：bang-bang
end
end
