%%Calculate the performance score of a given response

% grid command
score.reg_command = reshape(repmat(result.Bid_reg_rev', 1800, 1), [], 1) .* Signal_day;

% vpp response
% total power
score.P_total = sum(result.p_dis - result.p_ch)';% exchanged power (evergy 2 seconds)
% baseline output
score.P_baseline = reshape(repmat(result.Bid_p_rev', 1800, 1), [], 1);
score.reg_response = score.P_total - score.P_baseline;


%%
% a = score.reg_command - score.reg_response;
% plot(score.reg_command(1:3000)); hold on
% plot(score.reg_response(1:3000));
% legend("command", "response")

%% calc the hourly performance score

score.S_pre = zeros(24, 1);% precise
score.S_cor = zeros(24, 1);% corralation
score.S_delay = zeros(24, 1);% delay
score.Cap_mdf = zeros(24, 1);% modified response capacity

for hr_idx = 1 : 24
    command = score.reg_command((hr_idx - 1) * 1800 + 1 : hr_idx * 1800);
    response = score.reg_response((hr_idx - 1) * 1800 + 1 : hr_idx * 1800);

    if max(command) == 0% no regulation capacity
        score.S_pre(hr_idx) = 1;
        score.S_cor(hr_idx) = 1;
        score.S_delay(hr_idx) = 1;
        score.Cap_mdf(hr_idx) = 1;
        continue;
    end
    % precise score
    score.S_pre(hr_idx) = 1 - mean(abs(command - response)) / mean(abs(command));
    % modified response capacity
    score.Cap_mdf(hr_idx) = (max(response) - min(response)) / (max(command) - min(command));

    % corralation score
    cor_val = zeros(150, 1);
    for idx = 1 : 150 % within 5 minutes
        command_cor = command(idx : end);
        response_cor = response(1 : end + 1 - idx);
        temp = corrcoef(command_cor, response_cor);% corrcoef matrix
        cor_val(idx) = temp(1, 2);% corrcoef
    end

    score.S_cor(hr_idx) = max(cor_val);
    delta_delay = find(cor_val == max(cor_val));

    % delay score
    score.S_delay(hr_idx) = 1 - (delta_delay(1) - 1)/150;
end

%% total score
score.S = 1/3 * (score.S_pre + score.S_cor + score.S_delay);

% average
score.S_avg = score.S' * result.Bid_reg_rev / sum(result.Bid_reg_rev);

