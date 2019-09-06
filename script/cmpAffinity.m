function affin = cmpAffinity(path_ref, path_new, option)
% this function computes affinity between the reference
% path and the given new path, the more similar the
% two paths are the small value it will output.
% by yucheng.l@outlook.com 2018-02-27

%% compute affinity
% average paths if neccessary
if strcmp(option, 'noaugment')
    path_mean = squeeze(nanmean(nanmean(path_new, 4), 1));
    smt_new = smooth(path_mean);
end

% compute affinity
affin = zeros([size(path_new, 1), 4, size(path_new, 4)]);

for rept = 1:size(path_ref, 4)
    tmp_ref = squeeze(path_ref(:, :, :, rept));
    smt_ref = smooth(tmp_ref);
    
    for ind = 1:size(path_new, 1)
        tmp_new = squeeze(path_new(ind, :, :, rept));
        
        if strcmp(option, 'augment')
            smt_new = smooth(tmp_new);
        end
        
        [met_scal, met_trans, met_proj] = calMetric(tmp_ref, tmp_new, smt_ref, smt_new);
        affin(ind, :, rept) = [met_scal, met_trans, met_proj];
    end
end


%% compute metrics
function [met_scal, met_trans, met_proj] = calMetric(path_ref, path_new, smt_ref, smt_new)
% scaling
wei_s = sum((path_ref(:, 1)-1).*(1-path_new(:, 1)) > 0)/size(path_ref, 1);
met_scal = wei_s*corr(path_ref(:, 1), path_new(:, 1), 'Type', 'Spearman');

% translation (without smooth)
dist_y = norm(path_ref(:, 2)-path_new(:, 2));
dist_x = norm(path_ref(:, 3)-path_new(:, 3));
wei_y1 = min(abs(1-norm(path_ref(:, 2))/dist_y), abs(1-dist_y/norm(path_ref(:, 2))));
wei_x1 = min(abs(1-norm(path_ref(:, 3))/dist_x), abs(1-dist_x/norm(path_ref(:, 3))));
met_trans(1) = wei_y1*corr(path_ref(:, 2), path_new(:, 2), 'Type', 'Spearman');
met_trans(2) = wei_x1*corr(path_ref(:, 3), path_new(:, 3), 'Type', 'Spearman');

% translation (with smooth and dominant projection)
jtr_ref = path_ref-smt_ref;
jtr_new = path_new-smt_new;
theta = mean(atan2(smt_ref(:, 2), smt_ref(:, 3)));
base_z = [-sin(theta), cos(theta)]';
vol_ref = [jtr_ref(:, 3), jtr_ref(:, 2)];
ver_ref = vol_ref*base_z;
vol_new = [jtr_new(:, 3), jtr_new(:, 2)];
ver_new = vol_new*base_z;
dist_y = norm(ver_ref-ver_new);
wei_y1 = min(abs(1-norm(ver_ref)/dist_y), abs(1-dist_y/norm(ver_ref)));
met_proj = wei_y1*corr(ver_ref, ver_new, 'Type', 'Spearman');

%% smooth path (code from William X.Liu)
function path_smooth = smooth(path_raw)
r = 1:size(path_raw, 1);
lambda = 5;
thr = 1e-3;
int = 50000;

path_old = squeeze(path_raw(:, :));
path_temp = squeeze(path_raw(:, :));

for ind = 1:int
    for t = 1:size(path_raw, 1)
        wtr = exp(-abs(r-t).^2./100)';
        wtr = wtr./sum(wtr);
        gamma = 1+2*lambda*sum(wtr);
        path_r = 2*lambda*repmat(wtr, 1, 4).*path_temp;
        path_t = (path_raw(t, :)+sum(path_r, 1))/gamma;
        
        if ~isnan(path_t)
            path_temp(t, :) = path_t;
        end
    end
    
    if abs(norm(path_temp)-norm(path_old)) < thr
        break;
    else
        path_old = path_temp;
    end
end

path_smooth = path_temp;