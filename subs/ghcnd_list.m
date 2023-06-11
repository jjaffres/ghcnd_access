function p34 = ghcnd_list(chk) %,pos_rel_alldats,txt_rows)
%% ghcnd_list.m
% This function lists the individual subvariables for 'SN**', 'SX**', 'WT**' and 'WV**'.
% This function is only invoked if one of the above variable types was selected.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     J. Jaffrés - 14 Apr 2018

if strcmp(chk(1),'S') % Both 'SN**' and 'SX**' have the same potential affixes.
    p3 = 0:8; p4 = 1:7; % Any variation of these two (in position 3 and 4) may be possible.
    p34 = repmat(' ',[length(p3)*length(p4),2]);
    x1 = 0; x2 = 1;
    for x = 1:size(p34,1)
        x1 = x1 + 1;
        p34(x,:) = [sprintf('%01d',p3(x1)) num2str(p4(x2))];
        if x1 == length(p3)
            x1 = 0; x2 = x2 + 1;
        end
    end
elseif strcmp(chk,'WT')
    pboth = (1:22)';
    p34 = repmat(' ',[length(pboth),2]);
    for x = 1:length(pboth)
        p34(x,:) = sprintf('%02d',pboth(x));
    end; clear pboth
elseif strcmp(chk,'WV')
    p34 = ['01';'03';'07';'18';'20';];
end
