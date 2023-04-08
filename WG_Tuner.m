%% Read Log
clear all
close all

%% Get Variable list

varconv=readtable(fullfile(getcurrentdir,"variables.csv"),Delimiter=',',TextType='string',ReadVariableNames=false);
varconv=table2array(varconv);
varconv(:,1)=[];

%% Open Files

[fileopen,pathopen]=uigetfile('*.csv','Select Log CSV File','MultiSelect','on');

if iscell(fileopen)
    log=readtable(fullfile(pathopen,string(fileopen(1))));
    log=log(:,1:width(log)-1);
else
    log=readtable(fullfile(pathopen,fileopen));
    log=log(:,1:width(log)-1);
end
if iscell(fileopen)
    for i=2:length(fileopen)
        openlog=readtable(fullfile(pathopen,string(fileopen(i))));
        openlog=openlog(:,1:width(openlog)-1);
        log=vertcat(log,openlog);
    end
end

%% Convert Variables
logvars = log.Properties.VariableNames;
for i=1:width(varconv)
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
    USE_VVL1=USEO;
    USE_VVL1(USE_VVL1.VVL~=1,:) = [];
    USE_VVL0=USEO;
    USE_VVL0(USE_VVL0.VVL~=0,:) = [];


%% Read Axis Values
exhaxis=csvread(fullfile(getcurrentdir,"x_axis.csv"));
intaxis=csvread(fullfile(getcurrentdir,"y_axis.csv"));
exhlabels=string(exhaxis);
intlabels=string(intaxis);

%% Create Bins

xedges(1)=exhaxis(1);
xedges(length(exhaxis)+1)=exhaxis(length(exhaxis))+2;
for i=1:length(exhaxis)-1;
    xedges(i+1)=(exhaxis(i)+exhaxis(i+1))/2;
end

yedges(1)=intaxis(1);
yedges(length(intaxis)+1)=intaxis(length(intaxis))+2;
for i=1:length(intaxis)-1;
    yedges(i+1)=(intaxis(i)+intaxis(i+1))/2;
end

%% Initialize matrixes

SUM1=zeros(length(intaxis),length(exhaxis));
COUNT1=SUM1;
SUM0=SUM1;
COUNT0=SUM1;

%% Discretize VVL1

X1=discretize(USE_VVL1.EFF,xedges);
Y1=discretize(USE_VVL1.IFF,yedges);
for i=1:height(USE_VVL1)
   weight=abs(USE_VVL1.deltaPUT(i))*(0.5-abs(USE_VVL1.EFF(i)-X1(i)))*(0.5-abs(USE_VVL1.IFF(i)-Y1(i)));
   SUM1(Y1(i),X1(i))=SUM1(Y1(i),X1(i))+weight*USE_VVL1.WGNEED(i);
   COUNT1(Y1(i),X1(i))=COUNT1(Y1(i),X1(i))+weight;
end
AVG1=round(SUM1./COUNT1)/100;
Res_1=array2table(AVG1,'VariableNames',exhlabels,'RowNames',intlabels);

%% Discretize VVL0

X0=discretize(USE_VVL0.EFF,xedges);
Y0=discretize(USE_VVL0.IFF,yedges);
for i=1:height(USE_VVL0)
   weight=abs(USE_VVL0.deltaPUT(i))*(0.5-abs(USE_VVL0.EFF(i)-X0(i)))*(0.5-abs(USE_VVL0.IFF(i)-Y0(i)));
   SUM0(Y0(i),X0(i))=SUM0(Y0(i),X0(i))+(weight)*USE_VVL0.WGNEED(i);
   COUNT0(Y0(i),X0(i))=COUNT0(Y0(i),X0(i))+weight;
end
AVG0=round(SUM0./COUNT0)/100;
Res_0=array2table(AVG0,'VariableNames',exhlabels,'RowNames',intlabels);

% %% Save Tables

% writetable(Res_1,fullfile(pathopen,"VVL1 WG Results.csv"),'WriteRowNames',true);
% writetable(Res_0,fullfile(pathopen,"VVL0 WG Results.csv"),'WriteRowNames',true);

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
xticks(exhaxis);
yticks(intaxis);
rows=[find(USE.RPM>2000,1) find(USE.RPM>3000,1) find(USE.RPM>4000,1) find(USE.RPM>5000,1)];
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
xticks(exhaxis);
yticks(intaxis);
rows=[find(USE.RPM>2000,1) find(USE.RPM>3000,1) find(USE.RPM>4000,1) find(USE.RPM>5000,1)];
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
