load("../results_basic/result_optimal_bid_ctrl_sep_tcl.mat"); % Case 4
% load("../results_basic/result_noRR_ctrl_sep_tcl.mat"); % Case 3
hour = 7;
range = 600;
load("../data_prepare/param_day_15.mat")
allocate = {};

% Statistical data for existing mechanisms
% Find a case where signal = 0
% Output situation: New energy, EV, ES
signal_hour = Signal_day((hour-1) * 1800 + 1 : hour * 1800);
allocate.P_ver = result.P_alloc(1, (hour-1) * 1800 + 1 : hour * 1800) - result.P_bl_rev(1, hour);
allocate.P_es = result.P_alloc(2, (hour-1) * 1800 + 1 : hour * 1800) - result.P_bl_rev(2, hour);

% allocate.P_ev = result.P_alloc(3 : NOFDER - 1, (hour-1) * 1800 + 1 : hour * 1800);
% allocate.P_ev = sum(allocate.P_ev - result.P_bl_rev(3 : 122, hour));

allocate.P_tcl = result.P_alloc(NOFDER : NOFDER, (hour-1) * 1800 + 1 : hour * 1800);
allocate.P_tcl = allocate.P_tcl - result.P_bl_rev(NOFDER : NOFDER, hour);

allocate.ttp = sum([allocate.P_ver; allocate.P_es; allocate.P_tcl]);

allocate.command = signal_hour(1:range)' * result.Bid_reg_rev(hour);

linewidth = 1.5;

allocate.P_val = [allocate.P_tcl(1:range); allocate.P_es(1:range)];

area(allocate.command - allocate.ttp(1:range), 'LineStyle', 'none', 'FaceColor', 'yellow');
hold on
plot(allocate.command, '--black', 'linewidth', linewidth);
plot(allocate.P_tcl(1:range), 'b', 'linewidth', linewidth);

x1 = xlabel('Time', 'FontSize', 13.5, 'FontName', 'Arial'); % Axis title
y1 = ylabel('Adjusted Output (MW)', 'FontSize', 13.5, 'FontName', 'Arial');
ax = gca;
ax.XTick = [0 : 150 : 900];
ax.YColor = 'black';

legend('Power mismatch', 'Control signal', 'TCL response', ...
    'FontSize', 13.5, ...
    'FontName', 'Arial', ...
    'Location', 'NorthOutside', ...
    'Orientation', 'vertical', ...
    'NumColumns', 3);

set(gca, "YGrid", "on");
set(gca, "ylim", [-0.3, 0.3]);

m = linspace(datenum(hour - 1 + ":00", 'HH:MM'), datenum(hour - 1 + ":30", 'HH:MM'), 7);
for n = 1:length(m)
    tm{n} = datestr(m(n), 'HH:MM');
end
set(gca, 'xticklabel', tm);

% Figure size
figureUnits = 'centimeters';
figureWidth = 15;
figureHeight = figureWidth * 2 / 4;
set(gcf, 'Units', figureUnits, 'Position', [10 10 figureWidth figureHeight]);

ax.FontName = 'Arial';
set(gcf, 'PaperSize', [15, 7.5]);

saveas(gcf, 'typical_hour_RR_tcl.pdf');
