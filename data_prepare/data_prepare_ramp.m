%% Read and Handle the Ramp Rate Parameters

% Signals: already read by the data_prepare_regd.m file

% Time interval
delta_hat_t = 30;

% Uncertainty credit - quantile
c_up = 0.95;
c_dn = 0.05;

% Signal difference value
Signals_diff = Signals(1 + delta_hat_t : end, :) - Signals(1 : end - delta_hat_t, :);

% One distribution per hour
quantile_up = [];
quantile_dn = [];

for hour_idx = 1 : 24
    
    % Past 14 days data
    signals = Signals_diff((hour_idx - 1) * (1800 - delta_hat_t) + 1 : (hour_idx) * (1800 - delta_hat_t), day_reg - nofHisDays : day_reg - 1); % Extract columns
    signals = reshape(signals, 1, []);
    
    quantile_up = [quantile_up; quantile(signals, c_up) / delta_hat_t * 30]; % Calculate quantile up, /min
    quantile_dn = [quantile_dn; quantile(signals, c_dn) / delta_hat_t * 30]; % Calculate quantile down, /min
end

% Record
param.epsilon_dn = quantile_dn;
param.epsilon_up = quantile_up;
param.epsilon_res = 0.1; % Response in 10 min

param.h_R = 2 / min(max(abs(param.epsilon_dn), param.epsilon_up)); % Ramping time

clear Mileage mileage signals Distributions Distribution hourly_Distribution hourly_Mileage nofHisDays
clear col s_idx Signals c_up c_dn quantile_up quantile_dn diff
clear filename hour_idx sheet t_cap Signals_diff delta_hat_t
