function ghcnd_daily_save(ghcnd_data,ghcnd_date_indiv,ghcnd_gauge_info,date_vec,ghcnd_Qflag,...
    index_Qflag,header_gauge_info,data_unit,out_dir,var_target,year_range)
% MATLAB and GNU Octave can accumulate daily data for the full GHCN-Daily dataset.
% However, GNU Octave cannot save matrices exceeding 2^31 bytes.
% MATLAB is able to save matrices exceeding 2^31 bytes with the '-v7.3' switch.
% However, the '-v7.3' switch results in much larger (>4x) .mat files that are also slower to load.
% Hence, if ghcnd_data exceeds the 2^31 bytes threshold, all weather station matrices are split into multiple matrices.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     J. Jaffrés - 22 Apr 2018

chk = char(var_target); 
if strcmp(chk(3:4),'**') % File names cannot contain the '*' character
    var_target = [chk(1:2) '..'];
end

S = whos('ghcnd_data');
if S.bytes < 2^31 % If the maximum matrix size threshold is exceeded
    save([out_dir,'GHCND_day_',char(var_target),'.mat'],'ghcnd_data','ghcnd_date_indiv',...
        'ghcnd_gauge_info','date_vec','header_gauge_info','data_unit','year_range',...
        'ghcnd_Qflag','index_Qflag','-mat')
else
    xdiv = ceil(S.bytes/2^31); % Number of groups to create (if submatrices had equal bytes size)
    xdiv = ceil(S.bytes/2^31 + 0.2*xdiv); % Leave a size buffer to ensure that all submatrices stay within the 2^31 bytes limit
    xt1 = 1; xt = ceil(size(ghcnd_data,1)/xdiv); xt2 = xt; % Rows/columns to be attributed to submatrices.
    disp(['ghcnd_data exceeds the maximum size allowed for a regular .mat file - hence split into ',num2str(xdiv),' matrices'])
    
    ghcnd_data1 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data1');
    if Sn.bytes > 2^31 % Submatrix is still too large
        % Remove 1000 weather station .dly files to reduce the submatrix byte size to below 2^31
        while Sn.bytes > 2^31
            xt2 = xt2 - 1000;
            ghcnd_data1 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data1');
        end
    elseif Sn.bytes < 2^31/2 % Submatrix is too small (and subsequent submatrices may thus be too large)
        % Add 5000 weather station .dly files to increase the submatrix byte size
        while Sn.bytes < 2^31/2
            xt2 = xt2 + 5000;
            ghcnd_data1 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data1');
        end
    end
    ghcnd_date_indiv1 = ghcnd_date_indiv(xt1:xt2,1);
    ghcnd_gauge_info1 = ghcnd_gauge_info(xt1:xt2,:);
    if xdiv == 2
        xt1 = xt2 + 1;
        ghcnd_data2 = ghcnd_data(xt1:end,1);
        ghcnd_date_indiv2 = ghcnd_date_indiv(xt1:end,1);
        ghcnd_gauge_info2 = ghcnd_gauge_info(xt1:end,:);

        S = [whos('ghcnd_data1') whos('ghcnd_data2')];
        if  max([S.bytes]) < 2^31
            save([out_dir,'GHCND_day_',char(var_target),'.mat'],...
                'ghcnd_data1','ghcnd_data2','ghcnd_date_indiv1','ghcnd_date_indiv2','ghcnd_gauge_info1',...
                'ghcnd_gauge_info2','date_vec','header_gauge_info','data_unit','year_range',...
                'ghcnd_Qflag','index_Qflag','-mat')
        else
            disp(['The data have not been saved because ',num2str(max([S.bytes])),' < 2^31. Ensure you create sufficiently small submatrices.'])
        end
    else
        xt1 = xt2 + 1; xt2 = xt2 + xt;
        ghcnd_data2 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data2');
        if Sn.bytes > 2^31 % Submatrix is still too large
            % Remove 1000 weather station .dly files to reduce the submatrix byte size to below 2^31
            while Sn.bytes > 2^31
                xt2 = xt2 - 1000;
                ghcnd_data2 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data2');
            end
        elseif Sn.bytes < 2^31/2 % Submatrix is too small (and subsequent submatrices may thus be too large)
            % Add 5000 weather station .dly files to increase the submatrix byte size
            while Sn.bytes < 2^31/2
                xt2 = xt2 + 5000;
                ghcnd_data2 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data2');
            end
        end
        ghcnd_date_indiv2 = ghcnd_date_indiv(xt1:xt2,1);
        ghcnd_gauge_info2 = ghcnd_gauge_info(xt1:xt2,:);
        if xdiv == 3
            xt1 = xt2 + 1;
            ghcnd_data3 = ghcnd_data(xt1:end,1);
            ghcnd_date_indiv3 = ghcnd_date_indiv(xt1:end,1);
            ghcnd_gauge_info3 = ghcnd_gauge_info(xt1:end,:);

            S = [whos('ghcnd_data1') whos('ghcnd_data2') whos('ghcnd_data3')];
            if  max([S.bytes]) < 2^31
                save([out_dir,'GHCND_day_',char(var_target),'.mat'],...
                    'ghcnd_data1','ghcnd_data2','ghcnd_data3','ghcnd_date_indiv1','ghcnd_date_indiv2',...
                    'ghcnd_date_indiv3','ghcnd_gauge_info1','ghcnd_gauge_info2','ghcnd_gauge_info3',...
                    'date_vec','header_gauge_info','data_unit','year_range',...
                    'ghcnd_Qflag','index_Qflag','-mat')
            else
                disp(['The data have not been saved because ',num2str(max([S.bytes])),' < 2^31. Ensure you create sufficiently small submatrices.'])
            end
        else
            xt1 = xt2 + 1; xt2 = xt2 + xt;
            ghcnd_data3 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data3');
            if Sn.bytes > 2^31 % Submatrix is still too large
                % Remove 1000 weather station .dly files to reduce the submatrix byte size to below 2^31
                while Sn.bytes > 2^31
                    xt2 = xt2 - 1000;
                    ghcnd_data3 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data3');
                end
            elseif Sn.bytes < 2^31/2 % Submatrix is too small (and subsequent submatrices may thus be too large)
                % Add 5000 weather station .dly files to increase the submatrix byte size
                while Sn.bytes < 2^31/2
                    xt2 = xt2 + 5000;
                    ghcnd_data3 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data3');
                end
            end
            ghcnd_date_indiv3 = ghcnd_date_indiv(xt1:xt2,1);
            ghcnd_gauge_info3 = ghcnd_gauge_info(xt1:xt2,:);
            if xdiv == 4
                xt1 = xt2 + 1;
                ghcnd_data4 = ghcnd_data(xt1:end,1);
                ghcnd_date_indiv4 = ghcnd_date_indiv(xt1:end,1);
                ghcnd_gauge_info4 = ghcnd_gauge_info(xt1:end,:);

                S = [whos('ghcnd_data1') whos('ghcnd_data2') whos('ghcnd_data3') whos('ghcnd_data4')];
                if  max([S.bytes]) < 2^31
                    save([out_dir,'GHCND_day_',char(var_target),'.mat'],...
                        'ghcnd_data1','ghcnd_data2','ghcnd_data3','ghcnd_data4',...
                        'ghcnd_date_indiv1','ghcnd_date_indiv2','ghcnd_date_indiv3','ghcnd_date_indiv4',...
                        'ghcnd_gauge_info1','ghcnd_gauge_info2','ghcnd_gauge_info3','ghcnd_gauge_info4',...
                        'date_vec','header_gauge_info','data_unit','year_range',...
                        'ghcnd_Qflag','index_Qflag','-mat')
                else
                    disp(['The data have not been saved because ',num2str(max([S.bytes])),' < 2^31. Ensure you create sufficiently small submatrices.'])
                end
            else %if xdiv == 5
                xt1 = xt2 + 1; xt2 = xt2 + xt;
                ghcnd_data4 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data4');
                if Sn.bytes > 2^31 % Submatrix is still too large
                    % Remove 1000 weather station .dly files to reduce the submatrix byte size to below 2^31
                    while Sn.bytes > 2^31
                        xt2 = xt2 - 1000;
                        ghcnd_data4 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data4');
                    end
                elseif Sn.bytes < 2^31/2 % Submatrix is too small (and subsequent submatrices may thus be too large)
                    % Add 5000 weather station .dly files to increase the submatrix byte size
                    while Sn.bytes < 2^31/2
                        xt2 = xt2 + 5000;
                        ghcnd_data4 = ghcnd_data(xt1:xt2,1); Sn = whos('ghcnd_data4');
                    end
                end
                ghcnd_date_indiv4 = ghcnd_date_indiv(xt1:xt2,1);
                ghcnd_gauge_info4 = ghcnd_gauge_info(xt1:xt2,:);
                xt1 = xt2 + 1; %xt2 = xt2 + xt;
                ghcnd_data5 = ghcnd_data(xt1:end,1);
                ghcnd_date_indiv5 = ghcnd_date_indiv(xt1:end,1);
                ghcnd_gauge_info5 = ghcnd_gauge_info(xt1:end,:);

                S = [whos('ghcnd_data1') whos('ghcnd_data2') whos('ghcnd_data3') whos('ghcnd_data4') whos('ghcnd_data5')];
                if  max([S.bytes]) < 2^31
                    save([out_dir,'GHCND_day_',char(var_target),'.mat'],...
                        'ghcnd_data1','ghcnd_data2','ghcnd_data3','ghcnd_data4','ghcnd_data5',...
                        'ghcnd_date_indiv1','ghcnd_date_indiv2','ghcnd_date_indiv3','ghcnd_date_indiv4','ghcnd_date_indiv5',...
                        'ghcnd_gauge_info1','ghcnd_gauge_info2','ghcnd_gauge_info3','ghcnd_gauge_info4','ghcnd_gauge_info5',...
                        'date_vec','header_gauge_info','data_unit','year_range',...
                        'ghcnd_Qflag','index_Qflag','-mat')
                else
                    disp(['The data have not been saved because ',num2str(max([S.bytes])),' > 2^31. Ensure you create sufficiently small submatrices.'])
                end
            end
        end
    end
end
