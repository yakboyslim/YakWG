%% Read Log
clear all
close all

%% Get Variable list

varconv=readtable(fullfile(getcurrentdir,"variables.csv"),Delimiter=',',TextType='string',ReadVariableNames=false);

xaxis=csvread(fullfile(getcurrentdir,"x_axis.csv"));
yaxis=csvread(fullfile(getcurrentdir,"y_axis.csv"));

edit = questdlg('Edit variable conversion and axis tables?','Edit?','Yes','No','Yes');
if strcmp(edit,'Yes')
    figedit = uifigure('Name','DO NOT CLOSE THIS TABLE USING THE X, USE CONTINUE BUTTON',"Position",[500 500 760 500]);
    lbl1 = uilabel(figedit,"Text",'Variables','Position',[20 450 720 30]);
    uit1 = uitable(figedit, "Data",varconv, "Position",[20 350 720 100], 'ColumnEditable',true);
    lbl2 = uilabel(figedit,"Text",'X Axis','Position',[20 290 720 30]);
    uit2 = uitable(figedit, "Data",xaxis, "Position",[20 210 720 80], 'ColumnEditable',true);
    lbl3 = uilabel(figedit,"Text",'Y Axis','Position',[20 150 720 30]);
    uit3 = uitable(figedit, "Data",yaxis, "Position",[20 70 720 80], 'ColumnEditable',true);
    c = uicontrol(figedit,'String','CONTINUE','Callback','uiresume(figedit)')
    uiwait(figedit)    
    varconv = uit1.Data;
    xaxis = uit2.Data;
    yaxis = uit3.Data;
    writetable(varconv,fullfile(getcurrentdir,"variables.csv"),'WriteVariableNames',false)
    writematrix(xaxis,fullfile(getcurrentdir,"x_axis.csv"))
    writematrix(yaxis,fullfile(getcurrentdir,"y_axis.csv"))
    close(figedit)
end

varconv=table2array(varconv);
exhlabels=string(xaxis);
intlabels=string(yaxis);

%% Open Files

[fileopen,pathopen]=uigetfile('*.csv','Select Log CSV File','MultiSelect','on');

if iscell(fileopen)
    log=readtable(fullfile(pathopen,string(fileopen(1))),"VariableNamingRule","preserve");
    log=log(:,1:width(log)-1);
else
    log=readtable(fullfile(pathopen,fileopen),"VariableNamingRule","preserve");
    log=log(:,1:width(log)-1);
end
if iscell(fileopen)
    for i=2:length(fileopen)
        openlog=readtable(fullfile(pathopen,string(fileopen(i))),"VariableNamingRule","preserve");
        openlog=openlog(:,1:width(openlog)-1);
        log=outerjoin(log,openlog,'MergeKeys', true);
    end
end

%% Convert Variables
logvars = log.Properties.VariableNames;
for i=2:width(varconv)
    if any(contains(logvars,varconv(1,i)))
        log=renamevars(log,varconv(1,i),varconv(2,i));
    end
end

logvars = log.Properties.VariableNames;

%% Determine SWG/FF

WGlogic = questdlg('Are you using FeedForward or SWG?','WG Logic','FF','SWG','FF');

if strcmp(WGlogic,'SWG')
    log.EFF=log.RPM
    log.IFF=log.PUTSP
    yaxis=yaxis/10
end

%% Get other inputs

prompt = {'PUT fudge factor:','Minimum pedal:','Maximum PUT delta:','Minimum boost:'};
dlgtitle = 'Inputs';
dims = [1 50];
definput = {'0.71','50','10','0'};
answer = inputdlg(prompt,dlgtitle,dims,definput)
fudge=str2num(answer{1});
minpedal=str2num(answer{2});
maxdelta=str2num(answer{3});
minboost=str2num(answer{4});

%% Create Derived Values
log.deltaPUT=log.PUT-log.PUTSP;
log.WGNEED=log.WG_Final-log.deltaPUT.*fudge;
log.WGCL=log.WG_Final-log.WG_Base;


%% Create Bins

xedges(1)=xaxis(1);
xedges(length(xaxis)+1)=xaxis(length(xaxis))+2;
for i=1:length(xaxis)-1;
    xedges(i+1)=(xaxis(i)+xaxis(i+1))/2;
end

yedges(1)=yaxis(1);
yedges(length(yaxis)+1)=yaxis(length(yaxis))+2;
for i=1:length(yaxis)-1;
    yedges(i+1)=(yaxis(i)+yaxis(i+1))/2;
end


%% Create Trimmed datasets

USE=log;
if any(contains(logvars,'I_INH'))
    USE(USE.I_INH>0,:) = [];
else
    USE(USE.Pedal<minpedal,:) = [];
end

USE(USE.DV>50,:) = [];
USE(USE.BOOST<minboost,:) = [];
USE(abs(USE.deltaPUT)>maxdelta,:) = [];
USEO=USE;
USEO(USEO.WG_Final>98,:) = [];

USEO.X=discretize(USEO.EFF,xedges);
USEO.Y=discretize(USEO.IFF,yedges);
USEO.XAMP=discretize(USEO.AMP*10,[-inf 750 930 990 inf]);
USEO.YAMP=discretize(USEO.WGF,[-inf 100 300 500 inf]);



USE_VVL1=USEO;
USE_VVL1(USE_VVL1.VVL~=1,:) = [];
USE_VVL0=USEO;
USE_VVL0(USE_VVL0.VVL~=0,:) = [];



%% Initialize matrixes

SUM1=zeros(length(yaxis),length(xaxis));
COUNT1=SUM1;
SUM0=SUM1;
COUNT0=SUM1;
COUNTFAC=zeros(4,4);
SUMFAC=zeros(4,4);
COUNTOFS=zeros(4,4);
SUMOFS=zeros(4,4);
columns1= zeros(10,16)
rows1=columns1
rows0=rows1
columns0=columns1


%% Discretize VVL1

for i=1:height(USE_VVL1)
   weight=abs(USE_VVL1.deltaPUT(i))*(0.5-abs(USE_VVL1.EFF(i)-USE_VVL1.X(i)))*(0.5-abs(USE_VVL1.IFF(i)-USE_VVL1.Y(i)));
   SUM1(USE_VVL1.Y(i),USE_VVL1.X(i))=SUM1(USE_VVL1.Y(i),USE_VVL1.X(i))+weight*USE_VVL1.WGNEED(i);
   COUNT1(USE_VVL1.Y(i),USE_VVL1.X(i))=COUNT1(USE_VVL1.Y(i),USE_VVL1.X(i))+1;
end

for i=1:length(xaxis)
        temp=USE_VVL1;
        temp(temp.X~=i,:)=[];
        if height(temp)>1
            columns1(:,i) = lsq_lut_piecewise( temp.IFF, temp.WGNEED, yaxis )
        end
end

for j=1:length(yaxis)
        temp=USE_VVL1;
        temp(temp.Y~=j,:)=[];
        if height(temp)>1
            rows1(j,:) = lsq_lut_piecewise( temp.EFF, temp.WGNEED, xaxis )
        end
end
data1=COUNT1>0
AVG1=round(((SUM1./COUNT1)+rows1.*data1+columns1.*data1)/3)/100;
Res_1=array2table(AVG1,'VariableNames',exhlabels,'RowNames',intlabels);

%% Discretize VVL0

for i=1:height(USE_VVL0)
   weight=abs(USE_VVL0.deltaPUT(i))*(0.5-abs(USE_VVL0.EFF(i)-USE_VVL0.X(i)))*(0.5-abs(USE_VVL0.IFF(i)-USE_VVL0.Y(i)));
   SUM0(USE_VVL0.Y(i),USE_VVL0.X(i))=SUM0(USE_VVL0.Y(i),USE_VVL0.X(i))+(weight)*USE_VVL0.WGNEED(i);
   COUNT0(USE_VVL0.Y(i),USE_VVL0.X(i))=COUNT0(USE_VVL0.Y(i),USE_VVL0.X(i))+weight;
end

for i=1:length(xaxis)
        temp=USE_VVL0;
        temp(temp.X~=i,:)=[];
        if height(temp)>1
            columns0(:,i) = lsq_lut_piecewise( temp.IFF, temp.WGNEED, yaxis)
        end
end

for j=1:length(yaxis)
        temp=USE_VVL0;
        temp(temp.Y~=j,:)=[];
        if height(temp)>1   
            rows0(j,:) = lsq_lut_piecewise( temp.EFF, temp.WGNEED, xaxis )  
        end
end
data0=COUNT0>0
AVG0=round(((SUM0./COUNT0)+rows0.*data0+columns0.*data0)/3)/100;
Res_0=array2table(AVG0,'VariableNames',exhlabels,'RowNames',intlabels);


%% Plot Scatters

f1=tiledlayout(2,1)
nexttile
hold on
for i=1:height(USE)
    if USE.VVL(i)==1
        if USE.WG_Final(i)>98
            c1=scatter(USE.EFF(i),USE.IFF(i),100,USE.deltaPUT(i),"^","filled");
        else
            o1=scatter(USE.EFF(i),USE.IFF(i),100,USE.deltaPUT(i),"^");
        end
    else
        if USE.WG_Final(i)>98
            c0=scatter(USE.EFF(i),USE.IFF(i),100,USE.deltaPUT(i),"o","filled");
        else
            o0=scatter(USE.EFF(i),USE.IFF(i),100,USE.deltaPUT(i),"o");
        end
    end
end

mycolormap = customcolormap([0 .25 .5 .75 1], {'#9d0142','#f66e45','#ffffff','#65c0ae','#5e4f9f'});
c = colorbar;
c.Label.String = 'PUT - PUT SP';
colormap(mycolormap);
clim([-15 15]);
set(gca, 'Ydir', 'reverse');
xlabel('Exh Flow Factor') ;
ylabel('Int Flow Factor') ;
% set(gca,'TickLength',[1 1])
grid on;
set(gca,"XAxisLocation","top");
xticks(xaxis);
yticks(yaxis);
rows=[1,1,1,1]
rowsfound=[find(USE.RPM>2000,1) find(USE.RPM>3000,1) find(USE.RPM>4000,1) find(USE.RPM>5000,1)];
rows(1,1:numel(rowsfound)) = rowsfound;
lscatter(USE.EFF(rows),USE.IFF(rows),[2000 3000 4000 5000]);
hold off

nexttile
hold on
for i=1:height(USE)
    if USE.VVL(i)==1
        if USE.WG_Final(i)>98
            c1p=scatter(USE.EFF(i),USE.IFF(i),100,USE.WGCL(i),"^","filled");
        else
            o1p=scatter(USE.EFF(i),USE.IFF(i),100,USE.WGCL(i),"^");
        end
    else
        if USE.WG_Final(i)>98
            c0p=scatter(USE.EFF(i),USE.IFF(i),100,USE.WGCL(i),"o","filled");
        else
            o0p=scatter(USE.EFF(i),USE.IFF(i),100,USE.WGCL(i),"o");
        end
    end
end

mycolormap = customcolormap([0 .25 .5 .75 1], {'#9d0142','#f66e45','#ffffff','#65c0ae','#5e4f9f'});
c = colorbar;
c.Label.String = 'WG CL';
colormap(mycolormap);
clim([-10 10]);
set(gca, 'Ydir', 'reverse');
xlabel('Exh Flow Factor') ;
ylabel('Int Flow Factor') ;
% set(gca,'TickLength',[1 1])
grid on;
set(gca,"XAxisLocation","top");
xticks(xaxis);
yticks(yaxis);
rows=[1,1,1,1]
rowsfound=[find(USE.RPM>2000,1) find(USE.RPM>3000,1) find(USE.RPM>4000,1) find(USE.RPM>5000,1)];
rows(1,1:numel(rowsfound)) = rowsfound;
lscatter(USE.EFF(rows),USE.IFF(rows),[2000 3000 4000 5000]);
hold off


fig0 = uifigure('Name','VVL0 WG Results',"Position",[500 500 760 360]);
uit = uitable(fig0, "Data",Res_0, "Position",[20 20 720 320]);

styleIndices = ~ismissing(Res_0);
[row,col] = find(styleIndices);
s = uistyle("BackgroundColor",'gr');
addStyle(uit,s,"cell",[row,col]);

fig1 = uifigure('Name','VVL1 WG Results',"Position",[500 500 760 360]);
uit = uitable(fig1, "Data",Res_1, "Position",[20 20 720 320]);

styleIndices = ~ismissing(Res_1);
[row,col] = find(styleIndices);
s = uistyle("BackgroundColor",'gr');
addStyle(uit,s,"cell",[row,col]);
