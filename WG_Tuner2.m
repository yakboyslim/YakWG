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

%% Create Trimmed datasets

minpedal=50
minboost=0
maxdelta=10

ACT=log;
ACT(ACT.DV>50,:) = [];
ACT(ACT.BOL>0,:) = [];
ACT(ACT.TOL>0,:) = [];
ACT(ACT.I_INH>0,:) = [];
ACT(ACT.BOOST<minboost,:) = [];
ACT(abs(ACT.deltaPUT)>maxdelta,:) = [];
ACTO=ACT;
ACTO(ACTO.WG_Final>98,:) = [];
ACT_VVL1=ACTO;
ACT_VVL1(ACT_VVL1.VVL~=1,:) = [];
ACT_VVL0=ACTO;
ACT_VVL0(ACT_VVL0.VVL~=0,:) = [];

WOT=log;
WOT(WOT.Pedal<minpedal,:) = [];
WOT(WOT.DV>50,:) = [];
WOT(WOT.BOOST<minboost,:) = [];
WOT(abs(WOT.deltaPUT)>maxdelta,:) = [];
WOTO=WOT;
WOTO(WOTO.WG_Final>98,:) = [];
WOT_VVL1=WOTO;
WOT_VVL1(WOT_VVL1.VVL~=1,:) = [];
WOT_VVL0=WOTO;
WOT_VVL0(WOT_VVL0.VVL~=0,:) = [];



%% Choose Best dataset
USE=ACT
USEO=ACTO
USE_VVL1=ACT_VVL1
USE_VVL0=ACT_VVL0


%% Read Axis Values
exhaxis=csvread(fullfile(getcurrentdir,"exh_axis.csv"))
intaxis=csvread(fullfile(getcurrentdir,"int_axis.csv"))
exhlabels=string(exhaxis)
intlabels=string(intaxis)

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
SUM0=SUM1
COUNT0=SUM1

%% Discretize VVL1

X1=discretize(USE_VVL1.EFF,xedges);
Y1=discretize(USE_VVL1.IFF,yedges);
for i=1:height(USE_VVL1)
   weight=USE_VVL1.deltaPUT(i)*(0.5-abs(USE_VVL1.EFF(i)-X1(i)))*(0.5-abs(USE_VVL1.IFF(i)-Y1(i)))
%    weight=abs(USE_VVL1.deltaPUT(i))+0.1
   SUM1(Y1(i),X1(i))=SUM1(Y1(i),X1(i))+weight*USE_VVL1.WGNEED(i);
   COUNT1(Y1(i),X1(i))=COUNT1(Y1(i),X1(i))+weight;
end
AVG1=round(SUM1./COUNT1)/100
Res_1=array2table(AVG1,'VariableNames',exhlabels,'RowNames',intlabels)

%% Discretize VVL0

X0=discretize(USE_VVL0.EFF,xedges);
Y0=discretize(USE_VVL0.IFF,yedges);
for i=1:height(USE_VVL0)
   weight=USE_VVL0.deltaPUT(i)*(0.5-abs(USE_VVL0.EFF(i)-X0(i)))*(0.5-abs(USE_VVL0.IFF(i)-Y0(i)))
%    weight=abs(USE_VVL0.deltaPUT(i))+0.1
   SUM0(Y0(i),X0(i))=SUM0(Y0(i),X0(i))+(weight)*USE_VVL0.WGNEED(i);
   COUNT0(Y0(i),X0(i))=COUNT0(Y0(i),X0(i))+weight;
end
AVG0=round(SUM0./COUNT0)/100
Res_0=array2table(AVG0,'VariableNames',exhlabels,'RowNames',intlabels)

%% Save Tables

writetable(Res_1,fullfile(pathopen,"VVL1 Results.csv"),'WriteRowNames',true);
writetable(Res_0,fullfile(pathopen,"VVL0 Results.csv"),'WriteRowNames',true);

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
  
% lgd = [o1 o0];
% leglabels = legend(lgd,'WG open - VVL1','WG open - VVL0');

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
  
% lgd = [o1p o0p];
% leglabels = legend(lgd, 'WG open - VVL1','WG open - VVL0');

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

f3=figure
scatter3 (log.flow,log.PressRatio__,log.RPM,log.BOOST+25,log.RPM)
hold on
plot([0 0.01 0.01 0.02 0.02 0.03 0.03 0.04 0.05 0.1],[1.06 1.09 1.12 1.22 1.31 1.55 1.71 2.1 3.29 4])
plot([0 0.01 0.01 0.02 0.02 0.03 0.03 0.04 0.05 0.1],[1.02 1.03 1.04 1.10 1.18 1.38 1.54 1.70 1.89 2.96])

view(2)

for i=2:height(log)-1
    slope(i)=(log.flow(i)-log.flow(i-1))/(log.PressRatio__(i)-log.PressRatio__(i-1));
end
f4=figure;
plot(slope,log.RPM(1:height(log)-1));

% 
% %% Plot Gplot
% 
% Xnames=["RPM" "Int Flow Factor" "Exh Flow Factor" "WG I" "WG PD" "WG Final" "PUT delta"];
% comparison=[USEO.RPM USEO.IFF USEO.EFF USEO.WG_I USEO.WG_PD USEO.WG_Final USEO.deltaPUT];
% f2=figure;
% gplotmatrix(comparison,[],USEO.VVL,[],[],[],'on','stairs',Xnames);