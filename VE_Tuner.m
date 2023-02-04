%% Read Log
clear all
close all

%% Get Variable list

varconv=readtable(fullfile(getcurrentdir,"variables.csv"),Delimiter=',',TextType='string',ReadVariableNames=false)
varconv=table2array(varconv)
varconv(:,1)=[]

%% Open Files

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



% export = questdlg('Do you want to open another .csv?','Open CSV','Yes','No','Yes');
% while strcmpi(export,'Yes')
%         [fileopen,pathopen]=uigetfile('*.csv','Select Log CSV File');
%         log=vertcat(log,readtable(fullfile(pathopen,fileopen)));
%         export = questdlg('Do you want to open another .csv?','Open CSV','Yes','No','Yes');
% end


%% Convert Variables

log=renamevars(log,varconv(1,:),varconv(2,:));

fudge=0.71;
%% Create Derived Values
log.deltaPUT=log.PUT-log.PUTSP;
log.WGCL=log.WG_PD+log.WG_I
log.WGNEED=log.WGPosBase___+log.WGCL-log.deltaPUT.*fudge
log.flow=log.RPM.*log.Airmass_mg_stk_./(60*1222000)
log.MAP=log.MAP.*10
log.LAM_PCT=100*(log.LAMBDA-log.LAMBDA_SP)./log.LAMBDA_SP

%% Create Trimmed datasets

% minpedal=50
% minboost=0
% maxdelta=10
% 
% ACT=log;
% ACT(ACT.DV>50,:) = [];
% ACT(ACT.BOL>0,:) = [];
% ACT(ACT.TOL>0,:) = [];
% ACT(ACT.I_INH>0,:) = [];
% ACT(ACT.BOOST<minboost,:) = [];
% ACT(abs(ACT.deltaPUT)>maxdelta,:) = [];
% ACTO=ACT;
% ACTO(ACTO.WG_Final>98,:) = [];
% ACT_VVL1=ACTO;
% ACT_VVL1(ACT_VVL1.VVL~=1,:) = [];
% ACT_VVL0=ACTO;
% ACT_VVL0(ACT_VVL0.VVL~=0,:) = [];
% 
% WOT=log;
% WOT(WOT.Pedal<minpedal,:) = [];
% WOT(WOT.DV>50,:) = [];
% WOT(WOT.BOOST<minboost,:) = [];
% WOT(abs(WOT.deltaPUT)>maxdelta,:) = [];
% WOTO=WOT;
% WOTO(WOTO.WG_Final>98,:) = [];
% WOT_VVL1=WOTO;
% WOT_VVL1(WOT_VVL1.VVL~=1,:) = [];
% WOT_VVL0=WOTO;
% WOT_VVL0(WOT_VVL0.VVL~=0,:) = [];



%% Choose Best dataset
% USE=ACT
% USEO=ACTO
% log=ACT_VVL1
% USE_VVL0=ACT_VVL0


%% Read Axis Values
xaxis=csvread(fullfile(getcurrentdir,"N_axis.csv"))
yaxis=csvread(fullfile(getcurrentdir,"MAP_axis.csv"))
xlabels=string(xaxis)
ylabels=string(yaxis)

%% Create Bins

xedges(1)=0;
xedges(length(xaxis)+1)=inf;
for i=1:length(xaxis)-1;
    xedges(i+1)=(xaxis(i)+xaxis(i+1))/2;
end

yedges(1)=0;
yedges(length(yaxis)+1)=inf;
for i=1:length(yaxis)-1;
    yedges(i+1)=(yaxis(i)+yaxis(i+1))/2;
end

%% Initialize matrixes

SUM=zeros(length(yaxis),length(xaxis));
COUNT=SUM;


%% Discretize VVL1

X=discretize(log.RPM,xedges);
Y=discretize(log.MAP,yedges);
for i=1:height(log)
   weight=1
   fudge=0.5
   SUM(Y(i),X(i))=SUM(Y(i),X(i))+weight*(log.STFT(i)+fudge*log.LAM_PCT(i));
   COUNT(Y(i),X(i))=COUNT(Y(i),X(i))+weight;
end
AVG=round(SUM./COUNT,2)
Res=array2table(AVG,'VariableNames',xlabels,'RowNames',ylabels)

%% Save Tables

writetable(Res,fullfile(pathopen,"VE Results.csv"),'WriteRowNames',true);
