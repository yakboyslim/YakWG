table=readtable("table.xlsx","ReadRowNames",true,ReadVariableNames=true,VariableNamingRule="preserve")
[X Y]=meshgrid(str2double(table.Properties.VariableNames),str2double(table.Properties.RowNames))
data=table2array(table)

%% Fit: 'VVL0'.
[xData, yData, zData, weights] = prepareSurfaceData( X, Y, data, Y );

xmin=0
xmax=10000
ymin=0
ymax=10000
zmin=-1200
zmax=1399
excludedPoints = (xData > xmax) | (xData < xmin) | (yData < ymin) | (yData > ymax) | (zData < zmin) | (zData > zmax);

% Set up fittype and options.
ft = fittype( 'loess' );
opts = fitoptions( 'Method', 'LowessFit' );
opts.Weights = weights;
opts.Exclude = excludedPoints;

% Fit model to data.
[fitresult, gof] = fit( [xData, yData], zData, ft, opts );

% Create a figure for the plots.
figure( 'Name', 'Table' );

% Plot fit with data.
subplot( 2, 1, 1 );
h = plot( fitresult, [xData, yData], zData, 'Exclude', excludedPoints );
legend( h, 'Table', 'Plot', 'Excluded', 'Location', 'NorthEast', 'Interpreter', 'none' );
% Label axes
xlabel( 'X', 'Interpreter', 'none' );
ylabel( 'Y', 'Interpreter', 'none' );
zlabel( 'data', 'Interpreter', 'none' );
grid on
view( -17.7, 54.4 );
set(gca, 'YDir','reverse')

% Plot residuals.
subplot( 2, 1, 2 );
h = plot( fitresult, [xData, yData], zData, 'Style', 'Residual', 'Exclude', excludedPoints );
legend( h, 'VVL0 - residuals', 'Excluded VVL0data vs. VVL0X, VVL0Y', 'Location', 'NorthEast', 'Interpreter', 'none' );
% Label axes
xlabel( 'VVL0X', 'Interpreter', 'none' );
ylabel( 'VVL0Y', 'Interpreter', 'none' );
zlabel( 'VVL0data', 'Interpreter', 'none' );
grid on
view( -17.7, 54.4 );
set(gca, 'YDir','reverse')

% newrows=[300; 350; 400; 450]
newrows=[1600]
% newcolumns=[4000, 4500, 5000]


[desiredxX desiredyX]=meshgrid(str2double(table.Properties.VariableNames),newrows)
NewtableX=fitresult(desiredxX,desiredyX)

% [desiredxY desiredyY]=meshgrid(newcolumns,str2double(table.Properties.RowNames))
% NewtableY=fitresult(desiredxY,desiredyY)