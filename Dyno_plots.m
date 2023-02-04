[fileopen,pathopen]=uigetfile('*.csv','Select Log CSV File','MultiSelect','on');

f1=figure
tiledlayout(3,3)


colors=['r','b','g','c','m','k','w'];
list="empty"

if iscell(fileopen)
    for i=1:length(fileopen)
        log=readtable(fullfile(pathopen,string(fileopen(i))));
        log(log.PedalPos___<90,:)=[];
%         log(log.DVPosition___>50,:) = [];
        log(log.Gear__<1,:)=[];
        log.smoothHP=smooth(log.EngineSpeed_rpm_,log.CalcHP_hp_,7,'rlowess','LineStyle','-', 'Marker', 'none')
        log.smoothTQ=smooth(log.EngineSpeed_rpm_,log.CalcTQ_lbft_,7,'rlowess','LineStyle','--', 'Marker', 'none')
        
        nexttile(1,[2 3])
        hold on
        plot(log,"EngineSpeed_rpm_","smoothHP","Color",colors(i))
        plot(log,"EngineSpeed_rpm_","smoothTQ","Color",colors(i))
        
        nexttile(7,[1 3])
        hold on
        yyaxis left
%         plot(log,"EngineSpeed_rpm_","Lambda__","Color",colors(i),'LineStyle','-', 'Marker', 'none')
        yyaxis right
        plot(log,"EngineSpeed_rpm_","Boost_psi_","Color",colors(i),'LineStyle','--', 'Marker', 'none')
        ylim([15 inf])

        list(i)=string(fileopen(i))
    end

end
lg = legend(list,'Orientation','Horizontal','NumColumns',3)
lg.Layout.Tile = 'South';