%% Calculate the revenue of each resource providing frequency regulation (Without considering fast response capability limitations, as a baseline)

%% Parameter Reading
% Update step size
NOFTCAP_bid = 1800;
NOFTCAP_ctrl = 1;

for resource_idx = 2 : 4
    
    yalmip("clear");
    result = {};
    day_price = 15;
    load("../data_prepare/param_day_" + day_price + ".mat");
    
    % Cancel the ramp limit
    % Record
    param.epsilon_dn = 0 * param.epsilon_dn;
    param.epsilon_up = 0 * param.epsilon_up;
    param.epsilon_res = 0 * 0.1; % Response in 10 minutes

    %% Modify Matrices

    % Resource Name
    resource_name = param.resource_names(resource_idx);

    % Resource Range
    resource_range = param.resource_range;

    % Set parameters to zero for resources not considered
    for idx = 1 : NOFDER
        if idx < resource_range(resource_idx, 1) || idx > resource_range(resource_idx, 2)
            param_std.energy_init(idx) = 0;
            param_std.energy_upper_limit(idx, :) = zeros(1, NOFSLOTS);
            param_std.energy_end(idx) = 0;
            param_std.energy_lower_limit(idx, :) = zeros(1, NOFSLOTS);
            param_std.power_dis_upper_limit(idx, :) = zeros(1, NOFSLOTS);
            param_std.power_dis_lower_limit(idx, :) = zeros(1, NOFSLOTS);
            param_std.power_ch_upper_limit(idx, :) = zeros(1, NOFSLOTS);
            param_std.power_ch_lower_limit(idx, :) = zeros(1, NOFSLOTS);
            param_std.wOmiga(idx, :) = zeros(1, NOFSLOTS);
        end
    end

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

    save("../results_basic/result_noRR_ctrl_sep_" + resource_name +".mat", "result", "distribution_der");

end
