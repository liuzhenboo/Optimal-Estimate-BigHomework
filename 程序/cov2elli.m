function [X,Y] = cov2elli(x,P,ns,NP)

% Ellipsoidal representation of multivariate Gaussian variables (2D). Different
% sigma-value ellipses can be defined for the same covariances matrix. The most useful
% ones are 2-sigma and 3-sigma
% ����Բ����ά��˹״̬�����ֲ�
% xΪ2ά״̬�ľ�ֵ��pΪЭ���nsΪsigma-value��NPΪ����Բʱ��ɢ��ĸ�����
%Ellipse points from mean and covariances matrix.
%   [X,Y] = COV2ELLI(X0,P,NS,NP) returns X and Y coordinates of the NP
%   points of the the NS-sigma bound ellipse of the Gaussian defined by
%   mean X0 and covariances matrix P.
%
%   The ellipse can be plotted in a 2D graphic by just creating a line
%   with line(X,Y).
%
persistent circle

if isempty(circle)
    alpha = 2*pi/NP*(0:NP);
    circle = [cos(alpha);sin(alpha)];
end

% ���ַ�����
% һ����SVD��P���зֽ�õ���Բ����d(1,1),d(2,2)����ת����R
% SVD method, R*d*d*R' = P
 [R,D]=svd(P);
 d = sqrt(D);
% % circle -> aligned ellipse -> rotated ellipse -> ns-ellipse
 ellip = ns*R*d*circle;

% ����Choleski������P�ֽ�ֱ�ӵõ�R*d
% Choleski method, C*C' = P
%C = chol(P)';
%ellip = ns*C*circle;

% output ready for plotting (X and Y line vectors)
X = x(1)+ellip(1,:);
Y = x(2)+ellip(2,:);
