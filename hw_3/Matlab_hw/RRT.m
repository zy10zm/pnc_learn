%***************************************
%Author: Chaoqun Wang
%Date: 2019-10-15
%***************************************

%% 流程初始化
clc
clear all; close all;
x_I=1; y_I=1;           % 设置初始点
x_G=700; y_G=700;       % 设置目标点
Thr=50;                 % 设置目标点阈值
Delta= 30;              % 设置扩展步长

%% 建树初始化
T.v(1).x = x_I;         % T是我们要做的树，v是节点，这里先把起始点加入到T里面来
T.v(1).y = y_I; 
T.v(1).xPrev = x_I;     % 起始节点的父节点仍然是其本身
T.v(1).yPrev = y_I;
T.v(1).dist=0;          % 从父节点到该节点的距离，这里可取欧氏距离
T.v(1).indPrev = 0;     %

%% 开始构建树——作业部分
figure(1);
ImpRgb=imread('newmap.png');
Imp=rgb2gray(ImpRgb);
imshow(Imp)
xL=size(Imp,1);%地图x轴长度
yL=size(Imp,2);%地图y轴长度
hold on
plot(x_I, y_I, 'ro', 'MarkerSize',10, 'MarkerFaceColor','r');
plot(x_G, y_G, 'go', 'MarkerSize',10, 'MarkerFaceColor','g');% 绘制起点和目标点
count=1;
total_iter = 60;

%Snapshot cost:  Met node around goal with iter: 283

for iter = 1:total_iter
    x_rand=[];
    %Step 1: 在地图中随机采样一个点x_rand
    %提示：用（x_rand(1),x_rand(2)）表示环境中采样点的坐标
    x_rand = rand(1,2);
    x_rand(1) = ceil(x_rand(1) * size(Imp, 1));
    x_rand(2) = ceil(x_rand(2) * size(Imp, 2));
    % nearest_node = 
    
    % x_near=[];
    %Step 2: 遍历树，从树中找到最近邻近点x_near 
    %提示：x_near已经在树T里
    
    [x_near, x_near_idx] = findNearest(T, count, x_rand(1), x_rand(2));
    %x_near = node_dis(1)
    %dis = node_dis(2)
    disp("nearest node is: x:" +x_near(1) + "; y:"+ x_near(2))

    x_new=[];
    %Step 3: 扩展得到x_new节点
    %提示：注意使用扩展步长Delta
    x_new = try_rand_node([x_near(1), x_near(2)], x_rand, Delta);


    %if dis < Delta
    %    x_new(1) = x_near
    %else
    %    
    %end

    %检查节点是否是collision-free
    if ~collisionChecking(x_near,x_new,Imp) 
        disp("collision failed ignore x_new.")
        continue;
    end
    count=count+1;

    %scatter(x_new(1), x_new(2),  'g');
    
    %Step 4: 将x_new插入树T 
    %提示：新节点x_new的父节点是x_near
    T.v(count).x = x_new(1);         % T是我们要做的树，v是节点，这里先把起始点加入到T里面来
    T.v(count).y = x_new(2); 
    T.v(count).xPrev = x_near(1);     % 起始节点的父节点仍然是其本身
    T.v(count).yPrev = x_near(2);
    T.v(count).dist=computeNodeDist(x_near, x_new);          % 从父节点到该节点的距离，这里可取欧氏距离
    T.v(count).indPrev = x_near_idx;     % index of parent?
    
    %Step 5:检查是否到达目标点附近 
    %提示：注意使用目标点阈值Thr，若当前节点和终点的欧式距离小于Thr，则跳出当前for循环
    if computeDistance(x_new(1),x_new(2), x_G, y_G ) <= Thr
        disp("Met node around goal with iter: " + iter)
        line([x_near(1),x_new(1)], [x_near(2),   x_new(2)],'Color','b',  'Linewidth', 1);
        hold on
        break;
    end
    
   %Step 6:将x_near和x_new之间的路径画出来
   %提示 1：使用plot绘制，因为要多次在同一张图上绘制线段，所以每次使用plot后需要接上hold on命令
   %提示 2：在判断终点条件弹出for循环前，记得把x_near和x_new之间的路径画出来
   line([x_near(1),x_new(1)] , [x_near(2), x_new(2)], 'Color',  'b', 'Linewidth', 1);
   hold on
   
   pause(0.2); %暂停0.1s，使得RRT扩展过程容易观察
end
%% 路径已经找到，反向查询
if iter < total_iter

    % count is the last node added to T.
    path.pos(1).x = x_G; path.pos(1).y = y_G;
    path.pos(2).x = T.v(count).x;
    path.pos(2).y = T.v(count).y;
    pathIndex = T.v(count).indPrev; % 终点加入路径
    j=0;
    while 1
        path.pos(j+3).x = T.v(pathIndex).x;
        path.pos(j+3).y = T.v(pathIndex).y;
        pathIndex = T.v(pathIndex).indPrev;
        if pathIndex == 1
            break
        end
        j=j+1;
    end  % 沿终点回溯到起点

    path.pos(end+1).x = x_I; path.pos(end).y = y_I; % 起点加入路径
    for j = 2:length(path.pos)
        line([path.pos(j).x; path.pos(j-1).x;], [path.pos(j).y; path.pos(j-1).y], 'Color','r', 'Linewidth', 3);
    end
else
    disp('Error, no path found!');
end


function [nearest_nodexxx, nearest_node_idx] =findNearest(T, t_size,x, y)
    ret_n_node = T.v(1);
    node_index = 1;
    min_distance = inf;
    for i = 1:t_size
        % iterate all nodes in the T and compute distance
        tmp_node = T.v(i);
        
        dis = computeDistance(x, y, tmp_node.x, tmp_node.y);
        if dis < min_distance
            min_distance = dis;
            node_index = i;
            ret_n_node = tmp_node;
        end
    end
    
    nearest_nodexxx = [ret_n_node.x ret_n_node.y];

    nearest_node_idx = node_index;
    %return [n_node min_dis]

end


function new_node = try_rand_node(near_node, rand_node, threshold)
    dis = computeDistance(near_node(1),near_node(2), rand_node(1), rand_node(2));
    ret = [ 0.0 0.0];
    if dis >= threshold
        % for both dx and dy , proportional to threshold/dis
        ret(1) = near_node(1) +  (rand_node(1) - near_node(1)) * threshold / dis;
        ret(2) = near_node(2) + (rand_node(2) - near_node(2)) * threshold / dis;
    else
        ret(1) = rand_node(1);
        ret(2) = rand_node(2);
    end

    new_node = ret;

end

function distance = computeNodeDist(p1, p2)
    distance = sqrt((p1(1)-p2(1))^2 + (p1(2)-p2(2))^2);
end

function distance = computeDistance(x1,y1, x2, y2)
    distance =  sqrt((x1-x2)^2 + (y1-y2)^2);
end
