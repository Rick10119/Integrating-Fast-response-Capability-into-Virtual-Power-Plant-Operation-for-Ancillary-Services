%% Main Program
clc;
clear;
main_energy; % Only participating in the energy market, used for comparing participation in ancillary service revenue
yalmip("clear");
result = {}; % Store results

%% Parameter Reading

% Default data for the 15th day
day_price = 15;
load("../data_prepare/param_day_" + day_price + ".mat");

% Update step size
NOFTCAP_bid = 900;
NOFTCAP_ctrl = 1;

%% Initial Time Interval
warning('off');
maxProfit_1;

%% Intermediate Time Intervals
for t_cap = 1 : (NOFSLOTS - 1) * 1800
    if mod(t_cap, NOFTCAP_bid) == 1 % At the beginning or middle of the interval, update bids and multipliers, but do not update the bid for the current interval
        delta_t_rest = delta_t - mod(t_cap - 1, 1800) / 1800; % Remaining time in the current interval
        yalmip("clear");
        maxProfit_t;
    end
        delta_t_rest = delta_t - mod(t_cap - 1, 1800) / 1800; % Remaining time in the current interval
        fastControl_prepare; % Update L multipliers and construct parameter matrices
        fastControl_implement; % Power allocation
end

% Last time interval, no need to bid again
for t_cap = (NOFSLOTS - 1) * 1800 + 1 : NOFSLOTS * 1800
        result.lambda_rev.e = zeros(NOFDER, 1); % Avoid numerical issues
        fastControl_prepare; % Update L multipliers and construct parameter matrices
        fastControl_implement; % Power allocation
end

%% Profit Distribution
profitDistribution;

save("../results_basic/result_optimal_bid_ctrl_sep_.mat", "result", "distribution_der");
