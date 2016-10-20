 %% Initialize Windfarm
wf = WindFarm;
wf.traveltime = 2;
wf.mean_wait_time = mean_wait_time;

InitTurbine (wf, no_of_turbines, no_of_years, pc);

s = RunEnvironment (no_of_years);
s.SetWindFarm (wf);

%% Initialize service team
tech = Technician (no_of_years);
tech.cost_per_workhour = 900;
tech.cost_per_drivinghour = 600;
s.SetServiceTeam (tech);

%% Monte-Carlo simulation
display ('Starting Baseline maintenance scenario run...');
tic
parfor m = 1:no_of_runs
    s.Init();
    s.Run();
    offline_hours(m) = sum(wf.offline_hrs(:));
    lost_production = sum (wf.LostProduction (wind), 2);
    npv_om(:,m) = discount_factors' * tech.total_bill;
    npv_rev(:,m) = discount_factors' * (lost_production .* power_prices);
end
display ('Baseline maintenance scenario run was succesful');
toc
%% Calculate availability, clean up
availability = 1 - (offline_hours / (8760 * no_of_years * no_of_turbines));

clear tech
clear wf
clear s
