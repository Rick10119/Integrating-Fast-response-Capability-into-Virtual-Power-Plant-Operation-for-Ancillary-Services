%% Output Power of Each Resource and Change State
% Input: Power output of each resource (NOFDER * 1)
% Output: Change in state of each resource, cumulative cost accumulation

% Extract Signal
delta = Signal_day(t_cap);

% Required response amount
P_req = Bid_p_cur + Bid_reg_cur * delta;

param_std.seg_p_allocated = param_std.seg_parameter;

%% Quickly Determine Power Output of Each DER After Receiving Frequency Regulation Signal
% Input: Total power required by frequency regulation signal P_req
% Output: Power output of each resource (NOFDER * 1)

%% Power Allocation
% Initialize to minimum values
p_allocated = param_std.seg_parameter(:, 4);
% Initial power deviation
delta_p = P_req - sum(p_allocated);
% Matrix (index, flag_ch, c_k, p_lower, p_upper)
kdx = 1;

while delta_p > 0
    if param_std.seg_parameter(kdx, 5) - p_allocated(kdx) < delta_p
        % Power deviation is greater than the length of the power segment
        p_allocated(kdx) = param_std.seg_parameter(kdx, 5); % Fill the power segment
        delta_p = delta_p - param_std.seg_parameter(kdx, 5) + param_std.seg_parameter(kdx, 4);
        kdx = kdx + 1;
    else
        p_allocated(kdx) = param_std.seg_parameter(kdx, 4) + delta_p; % Fill the power segment
        delta_p = 0;
        kdx = kdx + 1;
        break;
    end
    
    % Handle potential numerical issues
    if kdx > 2 * NOFDER
        break;
    end
end

% Record marginal response cost
marginal_idx = max(find(p_allocated > 0));
if kdx > 1
    result.actualMarginalCost(t_cap) = param_std.seg_parameter(kdx - 1, 3);
else
    result.actualMarginalCost(t_cap) = param_std.seg_parameter(kdx, 3);
end

% disp("Time Slot " + (t_cap))

%% Restore Power
% Restore from kth number of p_allocated to ith number, and store in param_std.seg_p_allocated

param_std.seg_p_allocated(:, 6) = p_allocated;
% Add the second column to the first column to restore by number.
param_std.seg_p_allocated(:, 1) = param_std.seg_p_allocated(:, 1) ...
    + 0.5 * param_std.seg_p_allocated(:, 2);
% Restore by number
param_std.seg_p_allocated = sortrows(param_std.seg_p_allocated, 1);

% Variable substitution
param_std.seg_p_allocated = reshape(param_std.seg_p_allocated(:, end), 2, NOFDER)';

% Record charging/discharging power
result.p_dis_cur = param_std.seg_p_allocated(:, 1);
result.p_ch_cur = -param_std.seg_p_allocated(:, 2);

% Record allocation results
result.p_dis(:, t_cap) = result.p_dis_cur;
result.p_ch(:, t_cap) = result.p_ch_cur;

%% Update Data
% Update energy levels
result.E_cur = (ones(NOFDER, 1) - delta_hat_t * (ones(NOFDER, 1) - param_std.theta)) .* result.E_cur ...
    + param_std.eta_ch * result.p_ch_cur * delta_hat_t ...
    - param_std.eta_dis * result.p_dis_cur  * delta_hat_t ...
    + param_std.wOmiga(:, CUR_SLOT) * delta_hat_t;
result.E_rev(:, t_cap + 1) = result.E_cur;
