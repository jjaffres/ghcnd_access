%% ghcnd_access.m
%
% Copyright (C) 2018 by Jasmine B. D. Jaffrés
% James Cook University, Australia and C&R Consulting, Australia (http://candrconsulting.com.au/)
%
% Citation: Jaffrés, J.B.D. (2019) GHCN-Daily: a treasure trove of climate data awaiting
%           discovery. Computers & Geosciences 122, 35-44.
%
% This script imports all the GHCN-Daily .dly files in your folder of choice.
% All chosen data (that passed QC) are then saved in a matrix that is saved as a .mat file.
% This script can be used in either MATLAB or GNU Octave (v4.2.0).
%
% This script can easily be modified to suit your needs, e.g. 
%       - save data in individual .txt files
%       - calculate monthly average/maxima
%
% NOTE: The GHCN-Daily unit for temperature is tenths °C!
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You can redistribute this script and/or modify it under the terms of the
% GNU General Public License as published by the Free Software Foundation,
% either version 3 of the License, or (at your option) any later version.
%
% This script is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     J. Jaffrés - 21 Oct 2018
clear

%% Pre-run modifications
in_dir = '.\data\'; % Your input directory
out_dir = '.\output\'; % Your output directory
addpath('.\subs\'); % Location of subroutines

unit_which = 'SI'; % By default, all units are converted to SI units (°C, mm, m/s).
                   % For original units, change 'SI' to any other text (e.g. '')
% Specify whether you want to access all .dly files (*.dly) in your in_dir directory or only a subset (examples shown below):
dly_which = {'*.dly'}; % all files:                  {'*.dly'};
                    % files beginning with US:       {'US*.dly'};
                    % files starting with AGE or LY: {'AGE*.dly'; 'LY*.dly'};
% If you want to extract another variable, substitute the last cell by your choice:
var_options = {'PRCP' 'TMAX' 'TMIN' ''};
                    % Default:     {'PRCP' 'TMAX' 'TMIN' ''}
                    % EVAP wanted: {'PRCP' 'TMAX' 'TMIN' 'EVAP'}
                    % Note: If you have selected 'SN**', 'SX**', 'WT**' or 'WV**' (or a variation thereof),
                    %       you will be asked whether you want all data or your specified subset.
% Specify whether you want to apply the quality flags (remove all flagged data):
qc_apply = 1; % By default, all flagged data are removed (qc_apply = 1).
              % To keep all data (and store the corresponding QC flags), change to any other value.

%% Define wanted data
[mode_options,var_target,yr_options,yr1,yr2] = ...
    ghcnd_vars(dly_which,in_dir,var_options); % Also relevant if you have selected 'SN**', 'SX**', 'WT**' or 'WV**' (or a variation thereof)

%% Access all individual selected GHCN-Daily .dly files
disp(['User input is now complete and your selected GHCN-Daily data - ',char(var_target),' - will now be collated.'])
if mode_options == 1
    disp(['Daily ',char(var_target),' output will be created.'])
    [ghcnd_data,ghcnd_date_indiv,ghcnd_gauge_info,date_vec,ghcnd_Qflag,index_Qflag,...
        header_gauge_info,data_unit,year_range] = ...
        ghcnd_daily(unit_which,dly_which,in_dir,mode_options,out_dir,qc_apply,var_target,yr_options,yr1,yr2);
else
    disp(['Monthly ',char(var_target),' output will be created.'])
    [ghcnd_data,ghcnd_gauge_info,date_vec,header_gauge_info,count_mth_obs,data_unit,year_range] = ...
        ghcnd_mthly(unit_which,dly_which,in_dir,mode_options,out_dir,var_target,yr_options,yr1,yr2);
end

toc
% %% If the .mat did not save properly for daily output, run function ghcnd_daily_save
% if mode_options == 1
%     ghcnd_daily_save(ghcnd_data,ghcnd_date_indiv,ghcnd_gauge_info,date_vec,ghcnd_Qflag,index_Qflag,header_gauge_info,data_unit,out_dir,var_target,year_range)
% end
