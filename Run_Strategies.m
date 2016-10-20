clear
no_of_years = 20;
no_of_runs = 10000;
no_of_turbines = 1;

results_folder = 'Results';

%% Economic factors
% For sensitivity analysis
interest_rate = [0.05 0.07 0.09 0.11 0.13];
power_prices_factor = [0.8 0.9 1.0 1.1 1.2 1.3];

offline_hours = zeros (1, no_of_runs);
npv_om = zeros (length(interest_rate), no_of_runs);
npv_rev = zeros (length(interest_rate), no_of_runs);
discount_factors = zeros (no_of_years, length(interest_rate));

for k = 1 : length (interest_rate)
    discount_factors(:,k) = (cumprod ((1+interest_rate(k))* ones(no_of_years, 1))).^(-1);
end

electricity_spot_price = 0.420 * ones (no_of_years, 1);
if no_of_years > 15
    elcertifikat_price = [0.25* ones(15,1); zeros(no_of_years-15,1)];
else
    elcertifikat_price = 0.25* ones (no_of_years, 1);
end

power_prices = electricity_spot_price + elcertifikat_price;


%% Wind
wind = wblrnd (7.4156, 1.6901, no_of_years*8760, 1);
pc = [4.5, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20; ...
     0, 30.4, 77.3, 135, 206, 287, 371, 450, 514, 558, 582, 594, 598, 600, 600, 600, 600];

 
%% Run different strategies
my_local_pool = parpool ('local');
% Wait time sensitivity analysis
for k=1:8
    mean_wait_time = 50*k;
    k_suffix = ['wt', int2str(mean_wait_time)];
    base_filename = ['Results_Baseline_', k_suffix, '.mat'];
    CMS_filename = ['Results_CMS_', k_suffix, '.mat'];
    
    RunStrat_Baseline;
    save (fullfile (results_folder, base_filename), 'availability', 'npv_om', 'npv_rev', 'offline_hours');
    
    RunStrat_CMS;
    save (fullfile (results_folder, CMS_filename), 'availability', 'npv_om', 'npv_rev', 'offline_hours');    
end
my_local_pool.delete ();