function theta = arctanTwoPoints(arg1, arg2, arg3, arg4)
% ARCTANTWOPOINTS Computes 4-quadrant angle between two points or vectors.
%
% Usage:
%   theta = arctanTwoPoints(dx, dy)
%       Computes atan2(dy, dx) in radians.
%
%   theta = arctanTwoPoints(x1, y1, x2, y2)
%       Computes atan2(y2 - y1, x2 - x1) in radians.
%
% Note: In Maine.m, the user writes:
%   angle = rad2deg(arctanTwoPoints([Bx-Fx], [By-Fy]))
% Therefore, this function accepts (dx, dy) and returns radians, so that
% rad2deg(...) correctly produces degrees.
%
% Inputs:
%   arg1 : dx (or x1)
%   arg2 : dy (or y1)
%   arg3 : [optional] x2
%   arg4 : [optional] y2
%
% Output:
%   theta : angle in radians in range [-pi, pi]

    if nargin == 2
        dx = double(arg1);
        dy = double(arg2);
    elseif nargin == 4
        x1 = double(arg1);
        y1 = double(arg2);
        x2 = double(arg3);
        y2 = double(arg4);
        dx = x2 - x1;
        dy = y2 - y1;
    else
        error('arctanTwoPoints requires either 2 arguments (dx, dy) or 4 arguments (x1, y1, x2, y2).');
    end

    % Standard MATLAB atan2 takes (Y, X)
    theta = atan2(dy, dx);
end
