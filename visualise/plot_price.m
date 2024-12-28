%% Hourly prices
close;
diff = 0.1;
load("../data_prepare/param_day_15.mat");

linewidth = 2;

% Actual energy
plot(param.price_e, "-r", 'linewidth', linewidth); hold on;

y1 = ylabel('Market prices ($/MWh)', 'FontSize', 13.5, 'FontName', 'Arial');
% ax.YLim = [0, 90];
% Draw battery charge (right axis)
% yyaxis right

% ax.YLim = [0, 90];
plot(param.price_reg, "-b", 'linewidth', linewidth);
plot(param.price_res, "-g", 'linewidth', linewidth);

yyaxis right
linewidth = 1;
plot(param.epsilon_up, "-<b", 'linewidth', linewidth);
plot(param.epsilon_dn, "->b", 'linewidth', linewidth);
ax = gca;
ax.YColor = 'black';

legend('Energy', 'Regulation', '10 Min Spinning Reserve', ...
    '\epsilon^{up}', '\epsilon^{dn}', ...
    'FontSize', 13.5, ...
    'FontName', 'Arial', ...
    'Location', 'NorthOutside', ...
    'Orientation', 'horizontal', ...
    'NumColumns', 3);
set(gca, "YGrid", "on");

% Set figure parameters
x1 = xlabel('Hour', 'FontSize', 13.5, 'FontName', 'Arial'); % Axis title
y1 = ylabel('Ramp rate demand for regulation', 'FontSize', 13.5, 'FontName', 'Arial');

%% Figure size
figureUnits = 'centimeters';
figureWidth = 15;
figureHeight = 10;
set(gcf, 'Units', figureUnits, 'Position', [10 10 figureWidth figureHeight]);

%% Axis properties
ax = gca;
ax.XLim = [0, 25];

% Font and size
ax.FontSize = 13.5;

% Set ticks
ax.XTick = [1:24];

% Adjust labels
% ax.XTickLabel =  {'18','19','20','21','22','23','24','1','2','3','4','5','6','7','8','9'};
ax.FontName = 'Arial';
set(gcf, 'PaperSize', [15, 10]);

saveas(gcf, 'price_RR_demand.pdf');
