% MIT License
% 
% Copyright (c) 2020 liuzhenboo
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
% format long 
% I. ��ʼ��
%
disp('EKF-2D-SLAM sample program start!!')
% �˶�����
q = [0.01;0.02];
Q = diag(q.^2);
% ��������
m = [.15; 1*pi/180];
M = diag(m.^2);

% R: �����˳�ʼλ��
% u: ������
R = [0;-2.2;0];
u = [0.1;0.05];

% �������·��㻷��
% ���ΰڷŵ�landmarks
% W: ��������·���λ��
jiaodu_perLandMark =6;  %ȡ1,3,6,15,30,60...(360�ı�������)
r1=2;
r2=3;
r3=3.5;
W = landmarks(r1,r2,r3,jiaodu_perLandMark);

% ������̽��뾶
sensor_r = 2.5;

% Id���������б�ǰ̽�⵽��·��������Ƿ񱻹۲������û�й۲������ô��ʱ��Ҫ�������Id������
% ����ʹ��W��ÿ�����������Ϊ·����id��Id��ʼ��Ϊһ���㹻��������鼴�ɡ�
% Id(����)==1����ʾ�����۲����Id(����)==0����ʾ����û�й۲����
% �����c++ʵ�֣�����ʹ��map�ṹ��
Id = zeros(1,size(W,2));

% y_news��ʾ��ǰ��̽�⵽��·��㣬y_news(:,i)��¼�۲�����·�������
% ͬ��y_olds
y_olds = zeros(3,size(W,2));
y_news = zeros(3,size(W,2));

%   ״̬����Э�����ʼ��
x = zeros(numel(R)+numel(W), 1);
P = zeros(numel(x),numel(x));

% id_to_x_map��id------>>>id��Ӧ��״̬������x�е�λ��
id_to_x_map = zeros(1,size(W,2));

% x��P��ʼ��
r = [1 2 3];
x(r) = R;
%x(r) = [8;-2.5;0];
P(r,r) = 0;

% ÿ��״̬������x�е�λ��
s = [4 5];

%��ѭ������
% 125/ÿȦ
 loop =250;
 
% ���λ�˷�����
poses_ = zeros(3,loop);

% ���λ����ʷ������
poses = zeros(3,loop);

 %  ��ͼ
mapFig = figure(1);
cla;
axis([-5 5 -5 5])
axis square
%axis equal
% ����·���
WG = line('parent',gca,...
    'linestyle','none',...
    'marker','.',...
    'color','m',...
    'xdata',W(1,:),...
    'ydata',W(2,:));
% �����»�����λ��
RG = line('parent',gca,...
    'marker','+',...
    'color','r',...
    'xdata',R(1),...
    'ydata',R(2));
% ���ƵĻ�����λ��
rG = line('parent',gca,...
    'linestyle','none',...
    'marker','+',...
    'color','b',...
    'xdata',x(r(1)),...
    'ydata',x(r(2)));
% ���Ƶ�·���λ��
lG = line('parent',gca,...
    'linestyle','none',...
    'marker','+',...
    'color','k',...
    'xdata',[],...
    'ydata',[]);

% ���Ƶ�·���Э����
eG1 = zeros(1,size(W,2));
for i = 1:numel(eG1)
    eG1(i) = line(...
        'parent', gca,...
        'color','k',...
        'xdata',[],...
        'ydata',[]);
end

% ���ƵĻ�����λ��
reG = line(...
    'parent', gca,...
    'color','r',...
    'xdata',[],...
    'ydata',[]);

% ������̽�ⷶΧ������ʵλ��ΪԲ�ģ�
sensor1 = line(...
    'parent', gca,...
    'color','m',...
    'xdata',[],...
    'ydata',[],...
    'LineStyle','--');
sensor2 = line(...
    'parent', gca,...
    'color','m',...
    'xdata',[],...
    'ydata',[],...
    'LineStyle','--');

%������̽�ⷶΧ���Թ���λ��ΪԲ�ģ�
Sensor1 = line(...
    'parent', gca,...
    'color','m',...
    'xdata',[],...
    'ydata',[],...
     'LineStyle','--');
 Sensor2 = line(...
    'parent', gca,...
    'color','m',...
    'xdata',[],...
    'ydata',[],...
     'LineStyle','--');

 true_pose = line(...
    'parent', gca,...
    'color','r',...
    'xdata',[],...
    'ydata',[],...
    'LineWidth',0.8);
     %'LineStyle','--');
 
 estimate_pose = line(...
    'parent', gca,...
    'color','b',...
    'xdata',[],...
    'ydata',[],...
    'LineWidth',0.8);
    % 'LineStyle','--');
 
 % II. ��ѭ����
 % ������ÿǰ��һ����ѭ��һ��
for t = 1:loop
%     if t == 125
%         u(1) = 0.2;
%         sensor_r = 4;
%     end
%     if t == 375
%         u(1) = 0.2;
%         sensor_r = 5;
%     end
    %��ͬ̽��뾶
%      if t == 200
%           sensor_r = 1;         
%      end
%      if t == 400
%          sensor_r =1.5; 
%      end 
%      if t == 600
%         sensor_r =2; 
%      end 
%      if t == 800
%         sensor_r =2.5; 
%      end 
%      if t == 1000
%          sensor_r = 3;         
%      end

    % 1. �۲����
    n = q.*randn(2,1);
    % ��һʱ�̻�������ʵλ�ã�
    R = move(R, u, n);
    
    % ��������ȡ����Ϣ��i��ʾ·����ΨһID��ʶ�ţ�yi��ʾ�۲⵽���������ڵ�ǰ����ϵ�����꣬����Ϊ�㣬��ʾ����·���û�й۲⵽��
    % �۲⵽��·�����������Դ��
    % 1:�����۲⵽����EKFʱ��ֻ��Ҫ��������۲ⷽ��project�Ե�ǰ״̬�����������Ϳ����ˡ�
    % 2:֮ǰδ���۲⵽������ʱ����Ҫ��״̬�������㣬������۲ⷽ��backProject��ʼ������״̬��
    % y_olds ��ʾ�����۲⵽����·��㼯�ϡ�
    % y_news ��ʾ�·��ֵĵ�·��㼯�ϡ�
    i_olds=1;
    i_news=1;
    %��������һ��̽�⵽��·��temp=1
    %temp =1;
    for i = 1:size(W,2)
        v = m.*randn(2,1);
         yi= project(R, W(:,i)) + v;
        if yi(1) < sensor_r && Id(i) == 1
               y_olds(:,i_olds) = [yi(1);yi(2);i];
               i_olds = i_olds + 1;
        elseif  yi(1) < sensor_r &&  Id(i) == 0 %&& temp ==1
                y_news(:,i_news) = [yi(1);yi(2);i];
                i_news = i_news + 1;
                Id(i) = 1;
                %temp = temp +1;
        end
    end
    
    for i = i_olds:size(W,2)
        y_olds(:,i) = [100;0;0];
    end
    for i = i_news:size(W,2)
        y_news(:,i) = [101;0;0];
    end
  
    % 2. EKF�˲�
    %   a. Ԥ��
    % x(r)��һ��Ԥ��λ�ã�R_r��R_n��x(r)��R��n�ڵ�ǰ״̬���ſɱȾ���
    [x(r), R_r, R_n] = move(x(r), u, [0 0]);
    P_rr = P(r,r);
    P(r,:) = R_r*P(r,:);
    P(:,r) = P(r,:)';
    P(r,r) = R_r*P_rr*R_r' + R_n*Q*R_n';
    
 %     b. ����
 % �Զ���۲����Ĵ���ʽ���Թ۲����������ÿ�θ��ݶ�һ��·���Ĺ۲�����״̬���и���
    end_old = find(y_olds(1,:)==100,1);  
    if isempty(end_old)
        end_old=size(y_olds,2)+1;
    end
    
    for j = 1:(end_old-1)
        % expectation
        if isempty(j)
            break
        end
        id = find(id_to_x_map==y_olds(3,j),1);
        v = [id*2+2 id*2+3];
        [e, E_r, E_l] = project(x(r), x(v));
        E_rl = [E_r E_l];
        rl   = [r v];
        E    = E_rl * P(rl,rl) * E_rl';
        
        % measurement
        yi_1 = y_olds(:,j);
        yi1 = yi_1(1:2,1);
        
        % innovation
        z = yi1 - e;
        if z(2) > pi
            z(2) = z(2) - 2*pi;
        end
        if z(2) < -pi
            z(2) = z(2) + 2*pi;
        end
        Z = M + E;
        
        % Kalman gain
        K = P(:, rl) * E_rl' * Z^-1;
        
        % update
        x = x + K * z;
        P = P - K * Z * K';
    end
    
     % 3. ״̬����
    % ÿ����ѭ�����״̬�������㣬����һ���µ�·���״̬��������ȵ�·���ȫ���Ѿ���ʼ������ô��ʼ�����־Ͳ�����ִ�С�   
    end_new = find(y_news(1,:)==101,1);
    if isempty(end_new)
        end_new=size(y_news,2)+1;
    end
    for m1 = 1:(end_new-1)
        if isempty(m1)
            break
        end
        id = find(id_to_x_map==0,1);
        id_to_x_map(id) = y_news(3,m1);
        
        % measurement
        yi_2 = y_news(:,m1);
        yi2 = yi_2(1:2,1);
        [x(s), L_r, L_y] = backProject(x(r ), yi2);
        P(s,:) = L_r * P(r,:);
        P(:,s) = P(s,:)';
        P(s,s) = L_r * P(r,r) * L_r' + L_y * M * L_y';
        s = s + [2 2];
    end
    
     % 4. ��ȡ��Ҫ����Ϣ
    % ��ȡposes��Ϣ
    poses(1,t) = x(1);
    poses(2,t) = x(2);
    poses(3,t) = x(3);   
    poses_(1,t) = R(1);
    poses_(2,t) = R(2);
    poses_(3,t) = R(3);
    % ...
    
     % 5. ��ͼչʾ

     % �����˷���λ���봫����̽�ⷶΧ 
    set(RG, 'xdata', R(1), 'ydata', R(2));
    circle_x = linspace((R(1)-0.9999*sensor_r),(R(1)+0.9999*sensor_r));
    circle_y1 = sqrt(sensor_r^2 - (circle_x - R(1)).^2) + R(2);
    circle_y2 = R(2) - sqrt(sensor_r^2 - (circle_x - R(1)).^2);
    set(sensor1,'xdata',circle_x,'ydata',circle_y1);
    set(sensor2,'xdata',circle_x,'ydata',circle_y2);
    
    % ̽�ⷶΧ������λ��ΪԲ�ģ�
    set(rG, 'xdata', x(r(1)), 'ydata', x(r(2)));
    Circle_x = linspace((x(r(1))-0.9999*sensor_r),(x(r(1))+0.9999*sensor_r));
    Circle_y1 = sqrt(sensor_r^2 - (Circle_x - x(r(1))).^2) + x(r(2));
    Circle_y2 = x(r(2)) - sqrt(sensor_r^2 - (Circle_x - x(r(1))).^2);
    %set(Sensor1,'xdata',Circle_x,'ydata',Circle_y1);
    %set(Sensor2,'xdata',Circle_x,'ydata',Circle_y2);    
    
    % λ�ö�λ�켣
    set(estimate_pose,'xdata',poses(1,1:t),'ydata',poses(2,1:t));
    set(true_pose,'xdata',poses_(1,1:t),'ydata',poses_(2,1:t));
    
    legend([estimate_pose true_pose lG WG],{'Estimate','Truth' 'Estimate landmark' 'True landmark'})
  % �����һ��û��״̬���㣬���̷��ؽ�����һ��ѭ��
  if s(1)==4
        continue
  end
  
  % ���Ƶ�·���λ��
  w = 2:((s(1)-2)/2);
  w = 2*w;
  lx = x(w);
  ly = x(w+1);
  set(lG, 'xdata', lx, 'ydata', ly);
  
  % ��������·���Э������Բ
  % ���Ƶ�·����Ϊ���֣�
  % 1���ո�̽�����ֵ�
  % 2��֮ǰ����������������������
  % 3��֮ǰ����������ǰû������
  
% �Ƚ�����·����Э������Բ����ֵ��ɫ
%   for i = 1:numel(eG1)
%      set(eG1(i),'color','k');   
%   end
  
%%%%%��һ�֣��ո�̽�����ֵģ���ɫ��
  for g1 = 1:(end_new-1)
      if isempty(g1)
            break
      end
      o1 = y_news(3,g1);
      h1 = find(id_to_x_map==o1,1);
      temp1 = [2*h1+2;2*h1+3];
      le = x(temp1);
      LE = P(temp1,temp1);
      [X,Y] = cov2elli(le,LE,3,16);   
      set(eG1(o1),'xdata',X,'ydata',Y,'color','b');
  end
  %%%%�ڶ��֣�֮�����������������������ģ���ɫ��
  for g2 = 1:(end_old-1)
      if isempty(g2)
            break
      end
      o2 = y_olds(3,g2);
      h2 = find(id_to_x_map==o2,1);
      temp2 = [2*h2+2;2*h2+3];
      le = x(temp2);
      LE = P(temp2,temp2);
      [X,Y] = cov2elli(le,LE,3,16);  
      set(eG1(o2),'xdata',X,'ydata',Y,'color','r');
  end
  %%%%�����֣�֮ǰ������������û����������ɫ��
  v = find(id_to_x_map==0,1);
  if isempty(v)
      v = size(id_to_x_map,2)+1;
  end
  for g3 = 1:v-1
      if isempty(g3)
            break
      end
      a = find(y_olds(3,:)==id_to_x_map(g3),1);
      b = find(y_news(3,:)==id_to_x_map(g3),1);   
      if (isempty (a)) && (isempty(b)) 
         temp3 =  [2*g3+2;2*g3+3];
            le = x(temp3);
      LE = P(temp3,temp3);
      [X,Y] = cov2elli(le,LE,3,16);
      set(eG1(id_to_x_map(g3)),'xdata',X,'ydata',Y,'color','k');
      end
  end

% ���ƵĻ�����λ��Э������Բ����ɫ��
     if t > 1
         re = x(r(1:2));
         RE = P(r(1:2),r(1:2));
         [X,Y] = cov2elli(re,RE,3,16);
         set(reG,'xdata',X,'ydata',Y);
     end
   
   drawnow;
   
   pause(0.1);
    
end


