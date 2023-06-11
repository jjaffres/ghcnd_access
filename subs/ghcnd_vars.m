function [mode_options,var_target,yr_options,yr1,yr2] = ...
    ghcnd_vars(dly_which,in_dir,var_options)
%% ghcnd_vars.m
% This function determines what data is wanted.
% This function also checks whether you have selected 'SN**', 'SX**', 'WT**' or 'WV**' (or a variation thereof).
%           If so, you will be asked whether you want:
%                   1) your specified (sub-)variable (e.g. SN31) or 
%                   2) data from the entire group.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     J. Jaffrés - 14 Apr 2018

if strcmp(dly_which,'*.dly') == 1
    disp('You are looking at all .dly files in your input directory')
else
    disp('You are only looking at a subset of available .dly files in your input directory')
end

%% Define wanted data
disp('Select the variable type to extract - if not listed, adjust var_options on line #38 before re-running script')
var_target = var_options(input(['      Choose from ',var_options{1},'(1), ',var_options{2},'(2), ',var_options{3},'(3) or ',var_options{4},'(4): ']));
if strcmp(var_target,'')
    error('You have not specified a valid variable (cf. var_options on line 38)')
end; clear var_options

chk = char(var_target); chk = chk(1:2);
var_grp = ''; % This variable is only relevant for 'SN**', 'SX**', 'WT**' and 'WV**'

if strcmp(chk,'SN') && not(strcmp(char(var_target),'SNOW')) && not(strcmp(char(var_target),'SNWD')) || ...
        strcmp(chk,'SX') || strcmp(chk,'WT') || strcmp(chk,'WV')
    var_grp = [chk,'**'];
    if strcmp([chk,'**'],var_target)
        disp(['You have selected ',char(var_target),'. Thus, it is assumed you want all subcategories in this group.'])
        subs_which = 2; % All (sub-)variables in this group will be extracted.
    else
        disp(['Do you want all ',chk,'** data or your specified subset (',char(var_target),')? -->'])
        subs_which = input('      Choose the specified sub-variable (1) or the entire group (2) for extraction: ');
        if subs_which == 2
            var_target = var_grp;
        end
    end
else % You have chosen a variable without sub-groups
    subs_which = 1; % Your specified variable will be extracted.
end

disp(['Do you want all available ',char(var_target),' data, a reduced period, or just one year? -->'])
yr_options = input('      Choose all years(1), reduced range(2), one year(3): ');

%% Select whether to convert the daily data into monthly values
disp('Select whether to keep daily values or obtain monthly values (total or averages). -->')
if strcmp(var_target,'PRCP') || strcmp(var_target,'SNOW') || strcmp(var_target,'DAEV')...
        || strcmp(var_target,'DAPR') || strcmp(var_target,'DASF') || strcmp(var_target,'DATN')...
        || strcmp(var_target,'DATX') || strcmp(var_target,'DAWM') || strcmp(var_target,'DWPR')...
        || strcmp(var_target,'EVAP') || strcmp(var_target,'MDEV') || strcmp(var_target,'MDPR')...
        || strcmp(var_target,'MDSF') || strcmp(var_target,'MDWM') || strcmp(var_target,'WESF')
    mode_options = input('      Choose daily(1), monthly total(2): ');
elseif strcmp(var_target,'SNWD') || strcmp(var_target,'TMAX') || strcmp(var_target,'TMIN')... 
        || strcmp(var_target,'ACMC') || strcmp(var_target,'ACMH') || strcmp(var_target,'ACSC')...
        || strcmp(var_target,'ACSH') || strcmp(var_target,'AWND') || strcmp(var_target,'FRGB')...
        || strcmp(var_target,'FRGT') || strcmp(var_target,'FRTH') || strcmp(var_target,'GAHT')...
        || strcmp(var_target,'MDTN') || strcmp(var_target,'MDTX') || strcmp(var_target,'MNPN')...
        || strcmp(var_target,'MXPN') || strcmp(var_target,'PSUN') || strcmp(var_grp,'SN**')...
        || strcmp(var_grp,'SX**') || strcmp(var_target,'TAVG') || strcmp(var_target,'THIC')...
        || strcmp(var_target,'TOBS') || strcmp(var_target,'WESD') || strcmp(var_target,'WSF1')...
        || strcmp(var_target,'WSF2') || strcmp(var_target,'WSF5') || strcmp(var_target,'WSFG')...
        || strcmp(var_target,'WSFI') || strcmp(var_target,'WSFM')
    mode_options = input('      Choose daily(1), monthly average(3): ');
elseif strcmp(var_target,'TSUN') || strcmp(var_target,'WDMV')
    mode_options = input('      Choose daily(1), monthly total(2), monthly average(3): ');
else % strcmp(var_target,'AWDR') || strcmp(var_target,'FMTM') || strcmp(var_target,'PGTM') || strcmp(var_target,'WDF1')...
%         || strcmp(var_target,'WDF2') || strcmp(var_target,'WDF5') || strcmp(var_target,'WDFG')...
%         || strcmp(var_target,'WDFI') || strcmp(var_target,'WDFM') || strcmp(var_grp,'WT**')...  
%         || strcmp(var_grp,'WV**')
    mode_options = 1; disp('      Daily data will be extracted')
end

%% Reduce data based on data type and range selection
if yr_options == 1
    disp(['You have selected to use all available ',char(var_target),' data.']);

    % Open ghcnd-inventory.txt to retrieve data types and activity period
    fid = fopen([in_dir,'ghcnd-inventory.txt'],'rt');
    try
        txt_loc = fread(fid, Inf, 'char=>char')';
    catch
        error('There is no ghcnd-inventory.txt file in your data folder!')
    end    
    fclose (fid); clear fid
    row_le = 45; % The fread method adds a space after each row. Hence, (45+1)
    txt_rows = repmat(char(0),length(txt_loc)/(row_le+1),row_le);
    pos1 = 1; pos2 = row_le;
    for x = 1:length(txt_loc)/(row_le+1)
        txt_rows(x,:) = txt_loc(pos1:pos2);
        pos1 = pos1 + (row_le+1); pos2 = pos2 + (row_le+1);
    end; clear pos1 pos2 row_le txt_loc x
    pos_rel_alldats = [1 11; 13 20; 22 30; 32 35; 37 40; 42 45];
    datatype = cellstr(txt_rows(:,pos_rel_alldats(4,1):pos_rel_alldats(4,2)));
    
    % Reduce list by only keeping rows with selected data type (e.g. PRCP):
    if subs_which == 1 % Only one variable is wanted
        idx = strcmp(cellstr(datatype),var_target); 
        yr_range = [str2num(txt_rows(idx,pos_rel_alldats(5,1):pos_rel_alldats(5,2)))... %#ok<ST2NM>
                    str2num(txt_rows(idx,pos_rel_alldats(6,1):pos_rel_alldats(6,2)))]; %#ok<ST2NM>
        try
            yr1 = min(yr_range(:,1)); yr2 = max(yr_range(:,2));
        catch
            error(['There are no ',char(var_target),' data for your specified period!'])
        end
    else % Extract the maximum temporal range for the wanted group of variables
        p34 = ghcnd_list(chk); % Obtain individual names from the ghcnd_list.m subroutine
        
        yr1 = 9999; yr2 = 0;
        for x = 1:length(p34) % Find the positions with relevant (sub)data and respective range in years
            var_target_tmp = [chk p34(x,:)];
            idx = strcmp(cellstr(datatype),var_target_tmp);
            yr_range = [str2num(txt_rows(idx,pos_rel_alldats(5,1):pos_rel_alldats(5,2)))... %#ok<ST2NM>
                        str2num(txt_rows(idx,pos_rel_alldats(6,1):pos_rel_alldats(6,2)))]; %#ok<ST2NM>
            try
                if min(yr_range(:,1)) < yr1
                    yr1 = min(yr_range(:,1));
                end
                if max(yr_range(:,2)) > yr2
                    yr2 = max(yr_range(:,2));
                end
            catch
        %         disp(['There are no ',char(var_target),' data for your specified period.'])
            end
        end
        
        if yr1 == 9999
            error(['There are no ',var_grp,' data for your specified period!'])
        end
        
    end
    clear datatype idx pos_rel_alldats txt_rows yr_range
elseif yr_options == 2
    yr1 = input('Choose starting year to extract: ');
    yr2 = input('Choose final year to extract: ');
    disp(['You have selected to extract ',char(var_target),' data from ',num2str(yr1),' to ',num2str(yr2)])
elseif yr_options == 3
    yr1 = input('Choose year to extract: '); yr2 = yr1;
    disp(['You have selected to extract ',char(var_target),' data for ',num2str(yr1)])
else
    error('You have selected an incorrect data period.')
end
