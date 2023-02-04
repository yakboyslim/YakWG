[fileopen,pathopen]=uigetfile('*.csv','Select Log CSV File','MultiSelect','on');

if iscell(fileopen)
    log=readtable(fullfile(pathopen,string(fileopen(1))));
else
    log=readtable(fullfile(pathopen,fileopen));
end
if iscell(fileopen)
    for i=2:length(fileopen)
        log=vertcat(log,readtable(fullfile(pathopen,string(fileopen(i)))));
    end
end
logsave=log

%% intake cam

variable=['IntakeCamPosition_Degrees_']
xaxis=[500.00	750.00	1000.00	1250.00	1500.00	1750.00	2000.00	2500.00	3000.00	3500.00	4000.00	4500.00	5000.00	5500.00	6000.00	6500.00
]
yaxis=[79.99	100.00	150.02	199.99	299.99	399.99	499.98	599.98	750.00	900.02	1100.01	1500.00
]



log=logsave

log=renamevars(log,variable,'var')

log_VVL1=log;
log_VVL1(log_VVL1.ValveLiftState___~=1,:) = [];
log_VVL0=log;
log_VVL0(log_VVL0.ValveLiftState___~=0,:) = [];






xlabels=string(xaxis)
ylabels=string(yaxis)

%% Create Bins

xedges(1)=xaxis(1)-5000;
xedges(length(xaxis)+1)=xaxis(length(xaxis))+5000;
for i=1:length(xaxis)-1;
    xedges(i+1)=(xaxis(i)+xaxis(i+1))/2;
end

yedges(1)=yaxis(1)-5000;
yedges(length(yaxis)+1)=yaxis(length(yaxis))+5000;
for i=1:length(yaxis)-1;
    yedges(i+1)=(yaxis(i)+yaxis(i+1))/2;
end

%% Initialize matrixes

SUM1=zeros(length(yaxis),length(xaxis));
COUNT1=SUM1;
SUM0=SUM1
COUNT0=SUM1

%% Discretize VVL1

X1=discretize(log_VVL1.EngineSpeed_RPM_,xedges);
Y1=discretize(log_VVL1.AirMassIMPerStroke_mg_stk_,yedges);
for i=1:height(log_VVL1)
   SUM1(Y1(i),X1(i))=SUM1(Y1(i),X1(i))+log_VVL1.var(i);
   COUNT1(Y1(i),X1(i))=COUNT1(Y1(i),X1(i))+1;
end
AVG1=(SUM1./COUNT1)
Res_1=array2table(AVG1,'VariableNames',xlabels,'RowNames',ylabels)

%% Discretize VVL0

X0=discretize(log_VVL0.EngineSpeed_RPM_,xedges);
Y0=discretize(log_VVL0.AirMassIMPerStroke_mg_stk_,yedges);
for i=1:height(log_VVL0)
   SUM0(Y0(i),X0(i))=SUM0(Y0(i),X0(i))+log_VVL0.var(i);
   COUNT0(Y0(i),X0(i))=COUNT0(Y0(i),X0(i))+1;
end
AVG0=(SUM0./COUNT0)
Res_0=array2table(AVG0,'VariableNames',xlabels,'RowNames',ylabels)

%% Save Tables

writetable(Res_1,fullfile(pathopen,strcat(variable,"_VVL1.csv")),'WriteRowNames',true);
writetable(Res_0,fullfile(pathopen,strcat(variable,"_VVL0.csv")),'WriteRowNames',true);

%% exhaust cam

variable=['ExhaustCamPosition_Degrees_']
xaxis=[500.00	750.00	1000.00	1250.00	1500.00	1750.00	2000.00	2500.00	3000.00	3500.00	4000.00	4500.00	5000.00	5500.00	6000.00	6500.00
]
yaxis=[79.99	100.00	150.02	199.99	299.99	399.99	499.98	599.98	750.00	900.02	1100.01	1500.00
]



log=logsave

log=renamevars(log,variable,'var')


log_VVL1=log;
log_VVL1(log_VVL1.ValveLiftState___~=1,:) = [];
log_VVL0=log;
log_VVL0(log_VVL0.ValveLiftState___~=0,:) = [];






xlabels=string(xaxis)
ylabels=string(yaxis)

%% Create Bins

xedges(1)=xaxis(1)-5000;
xedges(length(xaxis)+1)=xaxis(length(xaxis))+5000;
for i=1:length(xaxis)-1;
    xedges(i+1)=(xaxis(i)+xaxis(i+1))/2;
end

yedges(1)=yaxis(1)-5000;
yedges(length(yaxis)+1)=yaxis(length(yaxis))+5000;
for i=1:length(yaxis)-1;
    yedges(i+1)=(yaxis(i)+yaxis(i+1))/2;
end

%% Initialize matrixes

SUM1=zeros(length(yaxis),length(xaxis));
COUNT1=SUM1;
SUM0=SUM1
COUNT0=SUM1

%% Discretize VVL1

X1=discretize(log_VVL1.EngineSpeed_RPM_,xedges);
Y1=discretize(log_VVL1.AirMassIMPerStroke_mg_stk_,yedges);
for i=1:height(log_VVL1)
   SUM1(Y1(i),X1(i))=SUM1(Y1(i),X1(i))+log_VVL1.var(i);
   COUNT1(Y1(i),X1(i))=COUNT1(Y1(i),X1(i))+1;
end
AVG1=(SUM1./COUNT1)
Res_1=array2table(AVG1,'VariableNames',xlabels,'RowNames',ylabels)

%% Discretize VVL0

X0=discretize(log_VVL0.EngineSpeed_RPM_,xedges);
Y0=discretize(log_VVL0.AirMassIMPerStroke_mg_stk_,yedges);
for i=1:height(log_VVL0)
   SUM0(Y0(i),X0(i))=SUM0(Y0(i),X0(i))+log_VVL0.var(i);
   COUNT0(Y0(i),X0(i))=COUNT0(Y0(i),X0(i))+1;
end
AVG0=(SUM0./COUNT0)
Res_0=array2table(AVG0,'VariableNames',xlabels,'RowNames',ylabels)

%% Save Tables

writetable(Res_1,fullfile(pathopen,strcat(variable,"_VVL1.csv")),'WriteRowNames',true);
writetable(Res_0,fullfile(pathopen,strcat(variable,"_VVL0.csv")),'WriteRowNames',true);

%% ignition

variable='IgnitionTableOutput_Degrees_'
xaxis=[400.00	700.00	1000.00	1250.00	1500.00	1750.00	2000.00	2500.00	3000.00	3500.00	4000.00	4500.00	5000.00	5500.00	6000.00	6500.00
]
yaxis=[79.99	100.00	150.02	199.99	250.01	299.99	350.01	399.99	499.98	599.98	699.98	800.02	900.02	1049.99	1200.01	1400.00
]



log=logsave

log=renamevars(log,variable,'var')


log_VVL1=log;
log_VVL1(log_VVL1.ValveLiftState___~=1,:) = [];
log_VVL0=log;
log_VVL0(log_VVL0.ValveLiftState___~=0,:) = [];






xlabels=string(xaxis)
ylabels=string(yaxis)

%% Create Bins

xedges(1)=xaxis(1)-5000;
xedges(length(xaxis)+1)=xaxis(length(xaxis))+5000;
for i=1:length(xaxis)-1;
    xedges(i+1)=(xaxis(i)+xaxis(i+1))/2;
end

yedges(1)=yaxis(1)-5000;
yedges(length(yaxis)+1)=yaxis(length(yaxis))+5000;
for i=1:length(yaxis)-1;
    yedges(i+1)=(yaxis(i)+yaxis(i+1))/2;
end

%% Initialize matrixes

SUM1=zeros(length(yaxis),length(xaxis));
COUNT1=SUM1;
SUM0=SUM1
COUNT0=SUM1

%% Discretize VVL1

X1=discretize(log_VVL1.EngineSpeed_RPM_,xedges);
Y1=discretize(log_VVL1.AirMassIMPerStroke_mg_stk_,yedges);
for i=1:height(log_VVL1)
   SUM1(Y1(i),X1(i))=SUM1(Y1(i),X1(i))+log_VVL1.var(i);
   COUNT1(Y1(i),X1(i))=COUNT1(Y1(i),X1(i))+1;
end
AVG1=(SUM1./COUNT1)
Res_1=array2table(AVG1,'VariableNames',xlabels,'RowNames',ylabels)

%% Discretize VVL0

X0=discretize(log_VVL0.EngineSpeed_RPM_,xedges);
Y0=discretize(log_VVL0.AirMassIMPerStroke_mg_stk_,yedges);
for i=1:height(log_VVL0)
   SUM0(Y0(i),X0(i))=SUM0(Y0(i),X0(i))+log_VVL0.var(i);
   COUNT0(Y0(i),X0(i))=COUNT0(Y0(i),X0(i))+1;
end
AVG0=(SUM0./COUNT0)
Res_0=array2table(AVG0,'VariableNames',xlabels,'RowNames',ylabels)

%% Save Tables

writetable(Res_1,fullfile(pathopen,strcat(variable,"_VVL1.csv")),'WriteRowNames',true);
writetable(Res_0,fullfile(pathopen,strcat(variable,"_VVL0.csv")),'WriteRowNames',true);

