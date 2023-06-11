%% ghcnd_access_dailypostproc.m
% This script is ancillary code that forms part of the ghcnd_access.m package.
% It converts the extracted daily output from .mat into .xlsx.
%
% Note: 1) To be used AFTER ghcnd_access.m was applied to extract the individual GHCN-Daily
%               .dly files into .mat format.
%       2) Exporting into Excel is not recommended if you have extracted a very large
%               proportion of station data from GHCN-Daily.
%
% This script can be used in either MATLAB or GNU Octave (v4.2.0).
%
% NOTE (for GNU Octave users): 
%      Script only appears to work properly if the (empty) Excel file already exists if 
%             the output directory is different from the current directory. 
%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You can redistribute this script and/or modify it under the terms of the
% GNU General Public License as published by the Free Software Foundation,
% either version 3 of the License, or (at your option) any later version.
%
% This script is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     J. Jaffrés - 27 Jun 2018

var_sel = 'MNPN';
out_dir = '..\output\';
load([out_dir,'GHCND_day_',var_sel,'.mat'])

data_all = NaN(length(date_vec),length(ghcnd_date_indiv));
for x = 1:length(ghcnd_data)
    data_x = cell2mat(ghcnd_data(x,1));
    [~,xpos,~] = intersect(date_vec,cell2mat(ghcnd_date_indiv(x,1)));
    data_all(xpos,x) = data_x;
end

% Reduce date vector to relevant period:
if exist('OCTAVE_VERSION', 'builtin') ~= 0
    disp('Loading nan, io and windows packages for GNU Octave users.')
    pkg load nan; pkg load io; pkg load windows
    % Script does not work if output directory differs from current directory and file has not been created yet:   
    out_dir = ''; warning('The output directory was changed to the Current Directory to ensure that the script runs successfully')
end

% Find the first and last day with data
tmp = nansum(10+data_all,2);
xpos1 = find(tmp > 0,1,'first'); xpos2 = find(tmp > 0,1,'last');

% Crop excess dates
data_all = [date_vec(xpos1:xpos2,1) data_all(xpos1:xpos2,:)]; 
clear tmp xpos1 xpos2

date_det = datevec(data_all(:,1)); date_det = date_det(:,1:3); % Extract the year/month/day info

% Save as Excel file:
xlswrite([out_dir,'GHCND_',var_sel,'_collated.xlsx'],header_gauge_info',1,'D1')
xlswrite([out_dir,'GHCND_',var_sel,'_collated.xlsx'],ghcnd_gauge_info',1,'E1')
xlswrite([out_dir,'GHCND_',var_sel,'_collated.xlsx'],['Year' 'Month' 'Day' 'Date' repmat({var_sel},1,length(ghcnd_data))],1,'A7')
xlswrite([out_dir,'GHCND_',var_sel,'_collated.xlsx'],[date_det data_all],1,'A8')
