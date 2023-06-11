function [ghcnd_data,ghcnd_date_indiv,ghcnd_gauge_info,date_vec,ghcnd_Qflag,...
    index_Qflag,header_gauge_info,data_unit,year_range] = ...
    ghcnd_daily(unit_which,dly_which,in_dir,mode_options,out_dir,qc_apply,var_target,yr_options,yr1,yr2)
%% ghcnd_daily.m
% This function extracts all the requested data from your GHCN-Daily .dly files. 
% Data are kept in their original daily format.
% The extracted data (that passed QC) are collated in one cell matrix and exported in a .mat file
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     J. Jaffrés - 22 Apr 2018

if mode_options ~= 1
    error(['You have chosen an incorrect data mode (mode_options == ',num2str(mode_options),').'])
end
tic

%% GNU Octave requires loading of several packages
if exist('OCTAVE_VERSION', 'builtin') ~= 0
    profile on % track the computation time
    page_output_immediately (1); % Enable the immediate display of text in Octave.
    disp('Loading financial package for GNU Octave users.'); %fflush(stdout())
    pkg load financial
end

%% Check available *.dly files and define wanted data
fileList = [];
for x = 1:length(dly_which)
    fileList = [fileList; dir([in_dir,char(dly_which(x))])];
end
statList = char({fileList.name}'); statList = statList(:,1:11);

%% Determine data unit
[data_unit,div] = ghcnd_units(unit_which,var_target);

%% Open ghcnd-stations.txt to retrieve weather station lat/lon
fid = fopen([in_dir,'ghcnd-stations.txt'],'rt');
try
    txt_loc = fread(fid, Inf, 'char=>char')';
catch
    error('Ensure that the ghcnd-stations.txt file is in your data folder!')
end
fclose (fid);
row_le = 85; % The fread method adds a space after each row. Hence, (85+1).
try
    txt_rows = repmat(char(0),length(txt_loc)/(row_le+1),row_le);
catch
    warning('Your ghcnd-stations.txt file is inconsistent. Please fix the data columns.')
    disp('For instance, issues were found with some FRE* stations in March 2018. These had an extra 5 columns.')
    disp('Suggested Freeware for column deletion: Notepad++ (https://notepad-plus-plus.org/) by Don Ho');
    disp('Notepad++ steps: 1) Alt + Click column 86 in row 1;');
    disp('                 2) Press Alt + Shift and select column ~100 in the last row;') 
    disp('                 3) Wait for area to be highlighted, then right-click + select Delete;');
    disp('                 4) Save file. [ghcnd_access.m should now run successfully when restarted.]')
    error('Fix the inconsistency in the ghcnd-stations.txt file (excess columns)!')
end
pos1 = 1; pos2 = row_le;
for x = 1:length(txt_loc)/(row_le+1)
    txt_rows(x,:) = txt_loc(pos1:pos2);
    pos1 = pos1 + (row_le+1); pos2 = pos2 + (row_le+1);
end

pos_rel_allstns = [1 11; 13 20; 22 30; 32 37];
gaugeID_allstns = cellstr(txt_rows(:,pos_rel_allstns(1,1):pos_rel_allstns(1,2)));
latlonelev_allstns = str2num(txt_rows(:,pos_rel_allstns(2,1):pos_rel_allstns(4,2))); %#ok<ST2NM>
latlonelev_allstns((latlonelev_allstns(:,3) == -999.9),3) = NaN; % Remove any NaN values for elevation

%% Open ghcnd-inventory.txt to retrieve data types and activity period
fid = fopen([in_dir,'ghcnd-inventory.txt'],'rt');
txt_loc = fread(fid, Inf, 'char=>char')'; fclose (fid);
row_le = 45; % The fread method adds a space after each row. Hence, (45+1)
txt_rows = repmat(char(0),length(txt_loc)/(row_le+1),row_le);
pos1 = 1; pos2 = row_le;
for x = 1:length(txt_loc)/(row_le+1)
    txt_rows(x,:) = txt_loc(pos1:pos2);
    pos1 = pos1 + (row_le+1); pos2 = pos2 + (row_le+1);
end
pos_rel_alldats = [1 11; 13 20; 22 30; 32 35; 37 40; 42 45];
datatype = cellstr(txt_rows(:,pos_rel_alldats(4,1):pos_rel_alldats(4,2)));

% Reduce list by only keeping rows with selected data type (e.g. PRCP):
idxI = strcmp(cellstr(datatype),var_target); 
chk = char(var_target); % idxI specification loop for 'SN**', 'SX**', 'WT**' and 'WV**':
if strcmp(chk(3:4),'**') % The individual variables of this group need to have their indices collated
    p12 = chk(1:2);
    p34 = ghcnd_list(p12); % Obtain individual names from the ghcnd_list.m subroutine
    for x = 1:length(p34) % Find the positions with relevant (sub)data
        var_target_tmp = [p12 p34(x,:)];
        if sum(strcmp(cellstr(datatype),var_target_tmp)) > 0
            idxI(strcmp(cellstr(datatype),var_target_tmp) == 1) = 1; % List all rows with relevant sub-variables
        end
    end
end

if sum(idxI) == 0
    disp(['None of the examined GHCN-Daily files have any ',char(var_target),' data for the specified period.'])
    error(['Is "',char(var_target),'" a valid variable? See line 38 in ghcnd_access.m'])
end
gaugeID_red = cellstr(txt_rows(idxI,pos_rel_alldats(1,1):pos_rel_alldats(1,2)));
yr_range = [str2num(txt_rows(idxI,pos_rel_alldats(5,1):pos_rel_alldats(5,2)))... %#ok<ST2NM>
            str2num(txt_rows(idxI,pos_rel_alldats(6,1):pos_rel_alldats(6,2)))]; %#ok<ST2NM>

% Reduce list further by removing any weather stations not in the fileList:
idxI2 = ismember(gaugeID_red,cellstr(statList));
gaugeID_red = gaugeID_red(idxI2,1); yr_range = yr_range(idxI2,:);

if exist('p34','var') % The individual variables of this group need to have their indices collated
    var_subs = cellstr(txt_rows(idxI,pos_rel_alldats(4,1):pos_rel_alldats(4,2))); % This vector will be used to label sub-variables
    var_subs = var_subs(idxI2,1); % Reduce list if no file is available (cf. fileList)
    % The variable's sub-category name also needs to be recorded:
    header_gauge_info = {'Station ID' 'Latitude' 'Longitude' 'Elevation' 'Date Start' 'Date End' 'Variable Name'};
else
    header_gauge_info = {'Station ID' 'Latitude' 'Longitude' 'Elevation' 'Date Start' 'Date End'};
end

%% Reduce data based on data type and range selection
if yr_options == 2
    gaugeID_red = gaugeID_red(yr_range(:,1) <= yr2 & yr_range(:,2) >= yr1);
    if exist('p34','var')
        var_subs = var_subs(yr_range(:,1) <= yr2 & yr_range(:,2) >= yr1);
    end
elseif yr_options == 3
    gaugeID_red = gaugeID_red(yr_range(:,1) <= yr1 & yr_range(:,2) >= yr1);
    if exist('p34','var')
        var_subs = var_subs(yr_range(:,1) <= yr1 & yr_range(:,2) >= yr1);
    end
end

date_range = datenum(yr1,1,1):datenum(yr2,12,31); % Full potential date period (in day format)

%% Obtain the relevant positions of wanted data:
% vars = {'ID' 'Year' 'Month' 'Element' 'Value' 'Measurement Flag' 'Quality Flag' 'Source Flag'};
% Empty Qflag field means that data is likely of good quality
pos = ([11, 4, 2, 4, repmat([5, 1, 1, 1],1,31)]);
pos_rel = NaN(length(pos),2); pos1 = 1;
for x = 1:length(pos)
    pos_rel(x,:) = [pos1 (pos1 + pos(x) - 1)];
    pos1 = pos_rel(x,2) + 1;
end

%% Aggregate all GHCN-Daily data in one cell matrix
ghcnd_data = cell(length(gaugeID_red),1);
ghcnd_date_indiv = cell(length(ghcnd_data),1); % gauge-specific date vectors
ghcnd_gauge_info = cell(length(ghcnd_data),length(header_gauge_info));
ghcnd_Qflag = cell(length(ghcnd_data),1); % Array for quality-flagged data
index_Qflag = cell(length(ghcnd_data),1); % Index array for quality-flagged data
count = 0; row_le = 269;
gaugeID = cell(length(ghcnd_data),1);

disp(['The script is now accessing ',num2str(length(unique(gaugeID_red))),' .dly files in a loop'])
if strcmp(chk(3:4),'**') 
    disp(['      Up to ',num2str(length(gaugeID_red)),' time series will be provided, as some files contain several ',char(var_target),' variables'])
end

var_target2 = var_target; % only needed to abbreviate code
for xg = 1:length(gaugeID_red)
    % Read file as one long char string. fread is faster than many fgetl-s
    fid = fopen([in_dir,char(gaugeID_red(xg)),'.dly'],'rt');
    txt_all = fread(fid, Inf, 'char=>char')';
    fclose(fid);

    % The fread method adds a space after each row. Hence, (269+1)
    txt_rows = repmat(char(0),length(txt_all)/(row_le+1),row_le); % This matrix should have length(txt_all)/269 rows and 269 columns
    pos1 = 1; pos2 = row_le;
    for x = 1:length(txt_all)/(row_le+1)
        txt_rows(x,:) = txt_all(pos1:pos2);
        pos1 = pos1 + (row_le+1); pos2 = pos2 + (row_le+1);
    end
    txt_rows_type = txt_rows(:,pos_rel(4,1):pos_rel(4,2));
    
    idx = strcmp(cellstr(txt_rows_type),var_target); % Only keep target variable data (e.g. PRCP)
    % idx specification for 'SN**', 'SX**', 'WT**' and 'WV**':
    chk = char(var_target);
    if strcmp(chk(3:4),'**') % List all rows with the relevant sub-category:
        idx(strcmp(cellstr(txt_rows_type),var_subs(xg)) == 1) = 1;
    end
    
    if exist('p34','var') % The individual variables of this group need to have their indices collated
        var_target2 = var_subs(xg);
    end
    
    if sum(idx) > 0 % Aggregate data if there is at least one value
        yr_m = str2num(txt_rows(idx,pos_rel(2,1):pos_rel(2,2))); %#ok<ST2NM>
        mth_m = str2num(txt_rows(idx,pos_rel(3,1):pos_rel(3,2))); %#ok<ST2NM>
        var_m = NaN(sum(idx),31); flagM_m = cell(sum(idx),31);
        flagQ_m = cell(sum(idx),31); flagS_m = cell(sum(idx),31);
        for xd = 1:31 % extract all daily values
            var_m(:,xd) = str2num(txt_rows(idx,pos_rel(xd*4 + 1,1):pos_rel(xd*4 + 1,2))); %#ok<ST2NM>
            flagM_m(:,xd) = cellstr(txt_rows(idx,pos_rel(xd*4 + 2,1):pos_rel(xd*4 + 2,2)));
            flagQ_m(:,xd) = cellstr(txt_rows(idx,pos_rel(xd*4 + 3,1):pos_rel(xd*4 + 3,2)));
            flagS_m(:,xd) = cellstr(txt_rows(idx,pos_rel(xd*4 + 4,1):pos_rel(xd*4 + 4,2)));
        end
        var_m(var_m == -9999) = NaN; % Assign NaN values for days without observations
        idx_flagQ = ~strcmp(flagQ_m,''); % Find all instances with failed quality check
        if qc_apply == 1 % Remove all data that failed quality checks
            var_m(idx_flagQ) = NaN;
        end
        
        % Require date vector:
        date_d = datenum([reshape(repmat(yr_m,1,31)',size(var_m,1)*31,1)...
            reshape(repmat(mth_m,1,31)',size(var_m,1)*31,1)...
            repmat((1:31)',size(var_m,1),1)]);
        % Rearrange data field into vector format:
        data_all = reshape(var_m',size(var_m,1)*31,1);
        flagQ = reshape(flagQ_m',size(flagQ_m,1)*31,1);
        % Remove data gaps from all vectors:
        date_d(isnan(data_all),:) = []; flagQ(isnan(data_all),:) = []; 
        data_all(isnan(data_all)) = [];
        [idx_1,idx_2] = ismember(date_d,date_range); idx_2(idx_2 == 0) = [];
        
        if isempty(idx_2) == 0 % Aggregate data if there is at least one value
            count = count + 1;
            if count/1000 == round(count/1000)
                disp(['We are aggregating the ',num2str(count),'th weather station file with relevant data (out of '...
                    ,num2str(length(gaugeID_red)),')'])
            end

            gaugeID(count,1) = cellstr(txt_rows(1,pos_rel(1,1):pos_rel(1,2)));
            % Obtain lat/lon/elevation based on the ghcnd-stations.txt file
            latlonelev = latlonelev_allstns(strcmp(gaugeID_allstns,gaugeID(count,1)),:);
            
            % To limit initial matrix size, data is aggregated based on data availability (within selected range).
            % Days without observations are ignored [] to save space.
            ghcnd_data(count,1) = num2cell(data_all(idx_1,:)/div,[1 2]);
            ghcnd_date_indiv(count,1) = num2cell(date_d(idx_1,:),[1 2]);
            
            if qc_apply ~= 1 % Compile concise matrix of quality flags.
                idxQ = find(~strcmp(flagQ,''));
                index_Qflag(count,1) = num2cell(idxQ,[1 2]);
                ghcnd_Qflag(count,1) = {flagQ(idxQ)};
            end
            
            if exist('p34','var') % The sub-category name also needs to be recorded:
                ghcnd_gauge_info(count,:) = [gaugeID(count,1) num2cell([latlonelev date_range(idx_2([1 end]))]) var_subs(xg)];
            else
                ghcnd_gauge_info(count,:) = [gaugeID(count,1) num2cell([latlonelev date_range(idx_2([1 end]))])];
            end            
            
        else % Display which (sub)variable is absent (if it is on the inventory list)
            if yr1 == yr2
                disp([char(gaugeID_red(xg)),'.dly file does not contain any ',char(var_target2),' data during the year ',num2str(yr1)])
            else
                disp([char(gaugeID_red(xg)),'.dly file does not contain any ',char(var_target2),' data during the years ',num2str(yr1),'-',num2str(yr2)])
            end
        end
    else
        if yr1 == yr2
            disp([char(gaugeID_red(xg)),'.dly file does not contain any ',char(var_target2),' data during the year ',num2str(yr1)])
        else
            disp([char(gaugeID_red(xg)),'.dly file does not contain any ',char(var_target2),' data during the years ',num2str(yr1),'-',num2str(yr2)])
        end
    end
end

%% Save the collated data
ghcnd_data = ghcnd_data(1:count,:);
ghcnd_date_indiv = ghcnd_date_indiv(1:count,:);
ghcnd_gauge_info = ghcnd_gauge_info(1:count,:);
date_vec = date_range';
if yr1 == yr2
    year_range = char(num2str(yr1));
else
    year_range = [num2str(yr1),'-',num2str(yr2)];
end
if qc_apply == 1 % As all quality-flagged data were removed, simplify the Q-arrays:
    index_Qflag = [];
    ghcnd_Qflag = 'All quality-flagged data were removed';
else % Keep all quality flag information:
    index_Qflag = index_Qflag(1:count,:);
    ghcnd_Qflag = ghcnd_Qflag(1:count,:);
end

% MATLAB and GNU Octave can accumulate daily data for the full GHCN-Daily dataset.
% However, GNU Octave cannot save matrices exceeding 2^31 bytes.
% MATLAB is able to save matrices exceeding 2^31 bytes with the '-v7.3' switch.
% However, the '-v7.3' switch results in much larger (>4x) .mat files that are also slower to load.
% Hence, if ghcnd_data exceeds the 2^31 bytes threshold, all weather station matrices are split into multiple matrices.
try
    disp('Extracted data are now saved in a .mat file.')
    ghcnd_daily_save(ghcnd_data,ghcnd_date_indiv,ghcnd_gauge_info,date_vec,ghcnd_Qflag,...
        index_Qflag,header_gauge_info,data_unit,out_dir,var_target,year_range)
catch
    disp('An error occurred with the .mat saving. Run function ghcnd_daily_save.m manually -->')
    disp('function ghcnd_daily_save(ghcnd_data,ghcnd_date_indiv,ghcnd_gauge_info,date_vec,ghcnd_Qflag,index_Qflag,header_gauge_info,data_unit,out_dir,var_target,year_range)')
end
    
if exist('OCTAVE_VERSION', 'builtin') ~= 0
    more off
    profile off
end
