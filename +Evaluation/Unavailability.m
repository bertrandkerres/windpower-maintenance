%% PlotUA
ua_edges = 0:0.0001:0.02;
ua_xlabel = ua_edges*100;
ua_XTick = 0:0.5:2;
ua_YTick = 0:0.01:0.06;

%results_folder = fullfile ('C:', 'Users/bertrand/Desktop/Results_100000');
results_folder = 'Results_100000';
res_files_baseline = dir (fullfile(results_folder, 'Results_Baseline_wt*.mat'));
res_files_cms = dir (fullfile(results_folder, 'Results_CMS_wt*.mat'));

mean_ua_bs = zeros (1, length(res_files_baseline));
mean_ua_cms = zeros (1, length(res_files_cms));
mean_rev_bs = zeros (1, length(res_files_baseline));
mean_rev_cms = zeros (1, length(res_files_cms));
mean_tot_bs = zeros (1, length(res_files_baseline));
mean_tot_cms = zeros (1, length(res_files_cms));

wait_time_bs = 20 * (1:1:length(mean_ua_bs));
wait_time_cms = 20 * (1:1:length(mean_ua_cms));

for k=1:length(res_files_baseline)
    res = load (fullfile (results_folder, res_files_baseline(k).name), 'availability', 'npv_om', 'npv_rev');
    ua = 1-res.availability;
    mean_ua_bs(k) = mean(ua);
    mean_rev_bs(k) = mean (res.npv_rev(3,:));
    mean_tot_bs(k) = mean (res.npv_om(3,:) + res.npv_rev(3,:));
end

for k=1:length(res_files_cms)
    res = load (fullfile (results_folder, res_files_cms(k).name), 'availability', 'npv_om', 'npv_rev');
    ua = 1-res.availability;
    mean_ua_cms(k) = mean(ua);
    mean_rev_cms(k) = mean (res.npv_rev(3,:));
    mean_tot_cms(k) = mean (res.npv_om(3,:) + res.npv_rev(3,:));

end  

hf1 = figure;
scatter (wait_time_bs, mean_ua_bs*100, 'ok')
hold on
scatter (wait_time_cms, mean_ua_cms*100, 'vk');
set (gca, 'XGrid', 'on','YGrid', 'on');
xlim ([0 450]);
ylim ([0 2]);
legend ('Baseline', 'CMS');
xlabel ('Wait time [h]');
ylabel ('Mean (1-A) [%]');

hf2 = figure;
scatter (wait_time_bs, mean_rev_bs/1000, 'ok')
hold on
scatter (wait_time_cms, mean_rev_cms/1000, 'vk');
set (gca, 'XGrid', 'on','YGrid', 'on');
xlim ([0 450]);
%ylim ([0 2]);
legend ('Baseline', 'CMS');
xlabel ('Wait time [h]');
ylabel ('Mean NPV of lost production [kSEK]');

hf3 = figure;
scatter (wait_time_bs, mean_tot_bs/1000, 'ok')
hold on
scatter (wait_time_cms, mean_tot_cms/1000, 'vk');
set (gca, 'XGrid', 'on','YGrid', 'on');
xlim ([0 450]);
%ylim ([0 2]);
legend ('Baseline', 'CMS');
xlabel ('Wait time [h]');
ylabel ('Mean total cost NPV [kSEK]');
