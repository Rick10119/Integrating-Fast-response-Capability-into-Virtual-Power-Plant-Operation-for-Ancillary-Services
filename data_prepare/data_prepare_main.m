%% Main Program: Prepare Parameter Settings
clc;
clear;

day_price = 15;
param = {};

M = 1e6; % Large number

%% Read RegD Signal Data

% Number of time slots, 24 hours
NOFSLOTS = 24;

% Select the date as July 17th-18th
% day_price = 21; % Price date
day_reg = day_price + 1; % Frequency regulation signal: RegD signal distribution for July 16th, 2020 used for simulation
hour_init = 0; % Starting from 00:00-01:00 (the original first time slot)

% Read and process RegD signal data from xlsx
diff = 0.1; % Fine granularity of frequency regulation signal

load("param_day_" + day_price + ".mat");
data_prepare_regd;

% Read and handle the ramp rate parameters
data_prepare_ramp;

%% Parameters for Each Resource
data_prepare_parameters;

%% Standardize Parameters
data_prepare_std;

% Resource names
param.resource_names = ["pv", "es", "ev", "tcl"];

% Resource numbers
param.resource_range = [[1, 1]; [2, 2]; [3, NOFEV + 2]; ...
    [NOFEV + 3, size(param_std.energy_init, 1)]];

%% Market Prices and Other Parameters
% Time slot length, 1 hour
delta_t = 1;
delta_t_req = 1 / 6;

% Read day-ahead ancillary service market price data
filename = "20240413damasp.csv";

% Read the excel file
temp = readtable(filename);
% N.Y.C. zone
temp = temp(9 : 11 : end, :);

% Convert to values
price_cap = table2array(temp(:, 8)); % Datetime type
param.price_res = table2array(temp(:, 5)); % Double type

% Read real-time ancillary service market price data
filename = "20240413rtasp.csv";
% Read the excel file
temp = readtable(filename);
% N.Y.C. zone
temp = temp(9 : 11 : end, :);
% Convert to values, mileage price
price_mil = table2array(temp([1 : 157, 160 : end], 9)); % Datetime type, excluding abnormal values
% Convert to hourly
price_mil = mean(reshape(price_mil, 12, []))';
param.price_mil = price_mil;

% Equivalent regulation capacity price
param.price_reg = price_cap + param.hourly_Mileage .* price_mil;

% Number of scenarios
NOFSCEN = length(param.hourly_Distribution(1, :));
% Frequency regulation performance
param.s_perf = 0.984;

% Read day-ahead energy market price data
filename = "20240413damlbmp_zone.csv";

% Read the excel file
temp = readtable(filename);
% N.Y.C. zone
temp = temp(10 : 15 : end, :);

% Convert to values
param.price_e = table2array(temp(:, 4)) + table2array(temp(:, 5)); % Datetime type

clear filename temp sheet t_cap xlRange day_idx price_cap price_mil

save("param_day_" + day_price + ".mat");
