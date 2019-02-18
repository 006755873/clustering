function dpeak_auto(dataPath,percent,kernel,k)
% Aimed at clustering the data with Density Peak Algorithm (DPeak) automatically
% -------------------------------------------------------------------------
% Input:
% dataPath - the file path of data
% percent - average percentage of neighbours
% kernel - gaussian or cutoff kernel
% k - number of clusters

tic;

disp('Description of distance.mat: [i, j, dist(i,j)]')

%����distances����
datafile = [dataPath,'/distances.mat'];
load(datafile);

xx = distances;

%ND��NL��Ϊxx��������������
ND = max(xx(:,2));
NL = max(xx(:,1));
if (NL > ND)
    ND = NL;
end

%����xx������������Ϊn*(n-1)/2
N = size(xx,1);

%��ɾ�������ʼ��
if (exist([dataPath,'distMat.mat'],'file'))
    load([dataPath,'distMat.mat']);
    dist = distMat;
else
    for i = 1 : ND              %��ʼ��dist ��������Ԫ��ȫΪ0
        for j = 1 : ND
            dist(i,j) = 0;
        end
    end
    for i = 1 : N                   %����xx�������λ���dist����
        ii = xx(i,1);
        jj = xx(i,2);
        dist(ii,jj) = xx(i,3);
        dist(jj,ii) = xx(i,3);
    end
    save distance_matrix dist;
end

%����ؾ�dc
fprintf('average percentage of neighbours (hard coded): %5.6f\n', percent);

%����ǰN*percent/100�ĸ���
position = round(N*percent/100);

%��xx��3�У�����������д�С��������
sda = sort(xx(:,3));%get distance of all points

%����positionλ�õ�Ԫ����ֵ������cutoff distance
dc = sda(position); %dc is a  distance from the  paires of some point which index in dataset is equal to value of variable position

fprintf('Computing Rho with gaussian kernel of radius: %5.6f\n', dc);

%����ֲ��ܶ�
for i = 1 : ND
    rho(i) = 0.;
end

switch(kernel)
    case 'gaussian'
        for i = 1 : ND-1
            for j = i+1 : ND
                % i��j������dc���Խ��,exp(-(dist(i,j)/dc)*(dist(i,j)/dc)ֵԽС��
                % �����ۻ��õ�rho(i)ԽС��ʾ��������i����Ͻ��ĵ��٣������ʾ������i�ܱ��кܶ����Ͻ��ĵ�
                rho(i) = rho(i) + exp(-(dist(i,j)/dc) * (dist(i,j)/dc));
                rho(j) = rho(j) + exp(-(dist(i,j)/dc) * (dist(i,j)/dc));
            end
        end
    case 'cutoff'   % �����﹫ʽ1�Ŀ�������
        neibors = zeros(ND,1);
        for i = 1 : ND-1
            count = 0;
            for j = 1 : ND
                if (i ~= j)
                    if (dist(i,j)<dc)
                        count = count + 1;
                        rho(i) = rho(i) + 1.;
                        neibors(i,count) = j;
                    end
                end
            end
        end
    otherwise
        disp('please input the correct kernel')
end

%ȡ��dist������ֵ���Ԫ��
maxd = max(max(dist));

%rho_sorted�ǵ���������������ordrho��rho_sorted��Ԫ����ԭ����rho�е�λ��,���±�����,
%��ordrho(1)���ܶ������������λ�ã�rho_sorted(1)���ܶ�ֵ��ordrho(i)���ܶ�ֵ�ŵ�iλ��������
[rho_sorted, ordrho]=sort(rho, 'descend');

%�������
for ii = 2 : ND
    delta(ordrho(ii)) = maxd;
    for jj = 1 : ii-1
        if(dist(ordrho(ii),ordrho(jj)) < delta(ordrho(ii)))
            delta(ordrho(ii)) = dist(ordrho(ii), ordrho(jj));     %ȡ�������Сֵ
            nneigh(ordrho(ii)) = ordrho(jj);
        end
    end
end
delta(ordrho(1)) = max(delta(:));  %�ܶ�ֵ���ĵ��Ӧ�ľ���ֵ


%����һ�����ƾ���ͼ����-�ģ�
disp('Description of decision_graph: [density, delta]')

fid = fopen('decision_graph', 'w');
for i = 1 : ND
    fprintf(fid, '%6.2f %6.2f\n', rho(i), delta(i));
end

%�����������ƾ���ͼ��n-�ã�
for i=1:ND
  ind(i)=i;
  gamma(i)=rho(i)*delta(i);
end

figure(1)
plot(rho(:),delta(:),'o','MarkerSize',3,'MarkerFaceColor','k','MarkerEdgeColor','k');
title('Decision Graph','FontSize',15.0)
xlabel('\rho')
ylabel('\delta')

%ͳ�ƾ������ĸ���
NCLUST = k;
for i = 1:ND
  cl(i) = -1;   %clΪ�����־���飬cl(i)=j��ʾ��i�����ݵ���鵽��j��cluster
end

[B, Index] = sort(gamma, 'descend');
disp(Index)

figure(2)
plot(ind(:),B(:),'o','MarkerSize',3,'MarkerFaceColor','k','MarkerEdgeColor','k');
title('Decision Graph','FontSize',15.0)
xlabel('n')
ylabel('\gamma')

% cl��ÿ�����ݵ����������
% icl�����о������ĵ����
icl = Index(1:k);
cl(Index(1:k)) = 1:k;

%����
disp('Performing assignation')
for i = 1 : ND
    if (cl(ordrho(i)) == -1)
        cl(ordrho(i)) = cl(nneigh(ordrho(i)));   %�ܶ�ֵ��С��i���Ҿ���i�����
    end
end

%halo
for i = 1 : ND
    halo(i) = cl(i);
end

if (NCLUST > 1)
    for i = 1 : NCLUST
        bord_rho(i) = 0.;     %�߽��ܶ���ֵ
    end
    for i = 1 : ND-1
        for j = i+1 : ND
            if ((cl(i)~=cl(j)) && (dist(i,j)<=dc))  %�����㹻С��������ͬһ��cluster��i��j
                rho_aver = (rho(i)+rho(j))/2.;
                if (rho_aver > bord_rho(cl(i)))
                    bord_rho(cl(i)) = rho_aver;
                end
                if (rho_aver > bord_rho(cl(j)))
                    bord_rho(cl(j)) = rho_aver;
                end
            end
        end
    end
    for i = 1 : ND
        if (rho(i) < bord_rho(cl(i)))       %halo����
            halo(i) = 0;
        end
    end
end

%ͳ�ƺ��ĵ�͹��ε����
for i = 1 : NCLUST
    nc = 0;
    nh = 0;
    for j = 1 : ND
        if (cl(j) == i)
            nc = nc + 1;
        end
        if (halo(j) == i)
            nh = nh + 1;
        end
    end
    fprintf('CLUSTER: %i CENTER: %i ELEMENTS: %i CORE: %i HALO: %i \n', i, icl(i), nc, nh, nc-nh);
end

%���ӻ�
cmap = colormap;
for i = 1 : NCLUST
    ic = int8((i*64.) / (NCLUST*1.));
    figure(3)
    hold on
    plot(rho(icl(i)),delta(icl(i)),'o','MarkerSize',10,'MarkerFaceColor',cmap(ic,:),'MarkerEdgeColor',cmap(ic,:));
    xlabel ('\rho');
    ylabel ('\delta');
end

if (exist([dataPath,'/points.mat'],'file'))
    load([dataPath,'/points.mat']);
else
    points = mdscale(dist, 2, 'criterion','metricstress');
    save 'points.mat' points;
end

for i = 1 : ND
    A(i,1) = 0.;
    A(i,2) = 0.;
end

for i = 1 : NCLUST
    nn = 0;
    ic = int8((i*64.)/(NCLUST*1.));
    for j = 1 : ND
        if (cl(j) == i)
            nn = nn + 1;
            A(nn,1) = points(j,1);
            A(nn,2) = points(j,2);
        end
    end
    hold on
    figure(4)
    title ('DPEAK')
    plot(A(1:nn,1),A(1:nn,2),'o','MarkerSize',5,'MarkerFaceColor',cmap(ic,:),'MarkerEdgeColor',cmap(ic,:));
end


for i = 1 : ND
    if (halo(i) > 0)
        ic = int8((halo(i)*64.)/(NCLUST*1.));
        hold on
        plot(points(i,1),points(i,2),'o','MarkerSize',5,'MarkerFaceColor',cmap(ic,:),'MarkerEdgeColor',cmap(ic,:));
    end
end

fr = fopen('cluster_assignation', 'w');
disp('Description of cluster_assignation: [id, cluster assignation without halo control, cluster assignation with halo control]');
for i = 1 : ND
    fprintf(fr, '%i %i %i\n',i,cl(i),halo(i));
end

result = cl';
save label result

%��peak������
for i = 1 : NCLUST
    ic = int8((i*64.)/(NCLUST*1.));
    figure(4)
    plot(points(icl(i),1),points(icl(i),2),'o','MarkerSize',8,'MarkerFaceColor','k','MarkerEdgeColor','k');
    hold on
end
toc;