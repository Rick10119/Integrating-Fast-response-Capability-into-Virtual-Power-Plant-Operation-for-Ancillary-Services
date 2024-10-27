%% Read and Handle the Signal Data from Excel
filename = '07 2020.xlsx';
sheet = 'Dynamic'; % Sheet name
xlRange = 'B2:AF43202'; % Range

% Read all signal data for July, 2s per point * 31 days
Signals = xlsread(filename, sheet, xlRange);

% Data cleaning, exclude data outside of [-1, 1]
Signals(Signals < -1) = -1;
Signals(Signals > 1) = 1;

%% Process the Original Signal Data
% Organize by 0.1 resolution: 1) signal distribution for this month, 2) signal distribution for July 15th

nofHisDays = 14; % Past 14 days of historical data for prediction
signal_length = 43202 - 2; % (excluding the first and last points, total 24*1800)

% Data for simulation on the 15th
Signal_day = Signals(1 : end - 1, day_reg);

% One distribution per hour
hourly_Distribution = [];
hourly_Mileage = [];

for hour = 1 : 24
    
    Distributions = [];
    
    for day_idx = day_reg - nofHisDays : day_reg - 1 % Past 14 days data
        signals = Signals(1 : end - 1, day_idx); % Extract columns
        
        Distribution = zeros(2 / diff + 2, 1); % Initialize, discretize df, consider -1 and 1 separately
        % Numbered from 1 to 22: -1 to 1
        
        % Scan to get pdf
        for t_cap = 1 + (hour - 1) * 1800 : hour * 1800
            if signals(t_cap) >= 0 % Ramp up
                s_idx = ceil(signals(t_cap) / diff) + 1 / diff + 1; % Scenario index
                if signals(t_cap) > 0.9999 % Consider as 1
                    s_idx = length(Distribution);
                end
            else
                s_idx = floor(signals(t_cap) / diff) + 1 / diff + 2; % Scenario index
                if signals(t_cap) < -0.9999 % Consider as -1
                    s_idx = 1;
                end
            end
            Distribution(s_idx) = Distribution(s_idx) + 1;
        end
        
        % Calculate frequency
        Distribution = Distribution / sum(Distribution);
        
        Distributions = [Distributions, Distribution];
    end
    
    Distribution = Distributions * 1/nofHisDays * ones(nofHisDays, 1);
    hourly_Distribution = [hourly_Distribution, Distribution];
    
end

%% Calculate Historical Mileage
for hour = 1 : 24

    Mileage = [];
    for day_idx = day_reg - nofHisDays : day_reg - 1 % Past two weeks of data
        
        % Extract column (one day)
        signals = Signals(1 + (hour - 1) * 1800 : hour * 1800, day_idx);
        
        % Calculate mileage for this hour
        mileage = sum(abs(signals(2 : end) - signals(1 : end - 1)));
        
        Mileage = [Mileage, mileage];
    end
    
    Mileage = Mileage * 1/nofHisDays * ones(nofHisDays, 1);
    
    hourly_Mileage = [hourly_Mileage, Mileage];
    
end

%% Rows: Different intervals; Columns (different times)
param.hourly_Mileage = hourly_Mileage';
param.hourly_Distribution = hourly_Distribution';
param.d_s = [-1; (-1 + 0.5 * diff : diff : 1 - 0.5 * diff)'; 1]; % Average signal values for each scenario, in capacity unit 1

%% Introduce the value of backup signals {0, 1}
% Probability of being called
param.prob_call_res = 1/720; % One hour a month
param.hourly_Distribution = [param.hourly_Distribution * (1 - param.prob_call_res), ...
    param.hourly_Distribution * (param.prob_call_res)];
param.d_s = [param.d_s, zeros(length(param.d_s), 1); param.d_s, ones(length(param.d_s), 1)];

% Baseline scenario
NOFSCEN = size(param.hourly_Distribution, 2);
param.hourly_Distribution = [param.hourly_Distribution(:, 1 : NOFSCEN/2), zeros(24, 1), ...
    param.hourly_Distribution(:, NOFSCEN/2 + 1 : end)];

param.d_s = [param.d_s(1 : NOFSCEN/2, :); zeros(1, 2); param.d_s(NOFSCEN/2 + 1 : end, :)];

clear Mileage mileage signals Distributions Distribution hourly_Distribution hourly_Mileage
clear col s_idx
clear filename hour sheet xlRange day_idx
% clear diff
