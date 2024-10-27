%% Main Program
clc;
clear;
% Store results
yalmip("clear");
result = {};

%% Parameter Reading

% Default data for the 15th day
day_price = 15;
load("../data_prepare/param_day_" + day_price + ".mat");

% Modify the AS price to 0.01 times the original value, equivalent to not participating in the ancillary service market
param.price_reg = -1e2 * param.price_reg;
param.price_res = -1e2 * param.price_res;

% Update step size
NOFTCAP_bid = 900;
NOFTCAP_ctrl = 1;
result.P_alloc = []; % Used to record results
result.actualMil = zeros(NOFSLOTS, 1);
result.actualEnergy = zeros(NOFSLOTS, 1);
result.actualCost = zeros(NOFSLOTS, 1);

%% Initial Time Interval
warning('off');
maxProfit_1;

%% Profit 
% VPP Income / Cost
delta_hat_t = 1/1800;

result.P_bl_rev = value(temp_dis - temp_ch); % Record power
result.P_alloc = reshape(repmat(result.P_bl_rev, 1800, 1), NOFDER, []);

% Revenue of the DERs
% Energy income
distribution_der.income_e_orignal = result.P_alloc * reshape(repmat(param.price_e', 1800, 1), [], 1) / 1800;

% Costs
distribution_der.actualCost_orignal = sum(repmat(param_std.pr_dis, 1, 43200) .* result.p_dis * delta_hat_t ...
    + repmat(param_std.pr_ch, 1, 43200) .* result.p_ch * delta_hat_t, 2);

save("../results_basic/result_optimal_bid_ctrl_energy.mat", "result", "distribution_der");
