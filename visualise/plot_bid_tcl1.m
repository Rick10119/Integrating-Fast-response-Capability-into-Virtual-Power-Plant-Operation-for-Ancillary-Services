%% Hourly bids of Case3/4
close; clc;
% cost_wrt_method;

linewidth = 1.3;

% Resource name
temp = ["pv", "es", "ev", "tcl", ""];
resource_name = temp(4);

load("../results_basic/result_noRR_ctrl_sep_" + resource_name + ".mat"); % Case 4
% Adjusted regulation capacity
stairs([result.Bid_reg_rev; result.Bid_reg_rev(end)], "--g", 'linewidth', linewidth); hold on;
stairs([result.Bid_res_rev; result.Bid_res_rev(end)], "--b", 'linewidth', linewidth);
stairs([result.Bid_p_rev; result.Bid_p_rev(end)], "--r", 'linewidth', linewidth);
% Actual energy

load("../results_basic/result_optimal_bid_ctrl_sep_" + resource_name + ".mat"); % Case 4
% Adjusted regulation capacity
stairs([result.Bid_reg_rev; result.Bid_reg_rev(end)], "-g", 'linewidth', 2 * linewidth); hold on;
stairs([result.Bid_res_rev; result.Bid_res_rev(end)], "-b", 'linewidth', linewidth);
stairs([result.Bid_p_rev; result.Bid_p_rev(end)], "-r", 'linewidth', linewidth);
% Actual energy

legend('Case1-TCL-Regulation', ...
    'Case1-TCL-Reserve', ...
    'Case1-TCL-Energy', ...
    'Case2-TCL-Regulation', ...
    'Case2-TCL-Reserve', ...
    'Case2-TCL-Energy', ...
    'fontsize', 13.5, ...
    'Location', 'NorthOutside', ...
    'Orientation', 'vertical', ...
    'NumColumns', 2, ...
    'FontName', 'Times New Roman');
set(gca, "YGrid", "on");

% Set figure parameters
x1 = xlabel('Hour', 'FontSize', 13.5, 'FontName', 'Times New Roman', 'FontWeight', 'bold'); % Axis title
y1 = ylabel('Capacity (MW)', 'FontSize', 13.5, 'FontName', 'Times New Roman', 'FontWeight', 'bold');

%% Figure size
figureUnits = 'centimeters';
figureWidth = 14;
figureHeight = 10;
set(gcf, 'Units', figureUnits, 'Position', [10 10 figureWidth figureHeight]);

%% Axis properties
ax = gca;
ax.XLim = [0, 25];
% ax.YLim = [-3, 3];
% ax.YLim = [30, 50];
% Font and size

ax.FontSize = 13.5;

% Set ticks
ax.XTick = [1:24];
% ax.YTick = [-3:3];

% Adjust labels
% ax.XTickLabel =  {'18','19','20','21','22','23','24','1','2','3','4','5','6','7','8','9'};
ax.FontName = 'Times New Roman';
% ax.FontName = 'Times New Roman';
set(gcf, 'PaperSize', [13.5, 10]);

saveas(gcf, 'bids_tcl.pdf');
