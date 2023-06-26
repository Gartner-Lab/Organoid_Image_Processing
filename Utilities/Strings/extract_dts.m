%   26 January 2018
%   Jennifer L Hu
%   extract_dts.m
%
%   Function that extracts a date from namestr (folder/file name).
%	Strain s is actually a CSV namestr of strain, strainM, strainL.

function [d, t, s] = extract_dts(namestr, consts)
    all_strains = consts{strcmp(consts{1}, 'all_strains')};
    all_dates = consts{strcmp(consts{1}, 'all_dates')};
    all_timepts = consts{strcmp(consts{1}, 'all_timepts')};
    n_strains = length(all_strains); 
    n_dates = length(all_dates); 
    n_timepts = length(all_timepts);
	% break up file and folder names
	[folder_name, file_name, ~] = fileparts(namestr);
    d = ''; t = ''; s = '';
	for i=1:n_dates
		s_date = all_dates{i};
		if contains(folder_name, s_date)
			d = s_date;
			% get actual date of experiment for multi-experiments
			if strcmp(d, '2018-03-09')
				if contains(namestr, 'plate #2')
					d = '2018-03-10';
				elseif contains(namestr, 'plate #3')
					d = '2018-03-11';
				end
			elseif strcmp(d, '2018-03-23')
				if contains(namestr, 'plate #2')
					d = '2018-03-24';
				elseif contains(namestr, 'plate #3')
					d = '2018-03-25';
				end
			end
			break
		end
    end
    % go through all_timepts looking for substring in file_name
	for i=1:n_timepts
		s_time = all_timepts{i};
		if contains(file_name, s_time)
			t = s_time;
            if strcmp(t, 'day2') || strcmp(t, '2d') || strcmp(t, 'd2')
                t = '48h';
            end
			break
		end
	end
	% if that didn't work, it might be in folder_name
	if isempty(t)
		for i=1:n_timepts
			s_time = all_timepts{i};
			if contains(folder_name, s_time)
				t = s_time;
                if strcmp(t, 'day2') || strcmp(t, '2d') || strcmp(t, 'd2')
                    t = '48h';
                end
				break
			end
		end
	end
    
	%% Extract strain from file_name
    % convert all chars to uppercase
    file_name = upper(file_name);
	% determine whether L and M strain are different or not
	if (contains(file_name, ' M ') && ~contains(file_name, '100 M'))
		% split on 'M'
		file_strains = strsplit(file_name, ' M ');
		if (length(file_strains)==2)
            % populate MEP and LEP strains
            sM = ''; sL = '';
            for i=1:n_strains
                s_strain = all_strains{i};
                if (isempty(sM) && contains(file_strains{1}, s_strain))
                    sM = s_strain;
                end
                if (isempty(sL) && contains(file_strains{2}, s_strain))
                    sL = s_strain;
                end
            end
            assert(~isempty(sM));
            if isempty(sL)
                % many virus image files are of the form STRAIN M + VIRUS L
                sL = sM;
            end
            if strcmp(sM, sL)
                s = sprintf('%s,%s,%s', sM, sM, sL);
            else
                s = sprintf('%s M + %s L,%s,%s', sM, sL, sM, sL);
            end
        else
            assert(length(file_strains) > 2)
            % should be something like 240L M + GFP M 48h-271.czi
            sM1 = ''; sM2 = '';
            for i=1:n_strains
                s_strain = all_strains{i};
                if (isempty(sM1) && contains(file_strains{1}, s_strain))
                    sM1 = s_strain;
                end
                if (isempty(sM2) && contains(file_strains{2}, s_strain))
                    sM2 = s_strain;
                end
            end
            assert(~isempty(sM1));
            if isempty(sM2)
                % many virus image files are of the form STRAIN M + VIRUS L
                sM2 = sM1;
            end
            if strcmp(sM1, sM2)
                s = sprintf('%s,%s,', sM1, sM1);
            else
                s = sprintf('%s M + %s M,%s+%s,', sM1, sM2, sM1, sM2);
            end
        end
    elseif contains(file_name, '240L+353P+353P')
        s = '240L+353P M + 353P L,240L+353P,353P';
    else
		% go through all strains
        for i=1:n_strains
            s_strain = all_strains{i};
            if contains(file_name, s_strain)
                s = s_strain;
                break
            end
        end
	    if ~isempty(s)
            isMEP = any(contains(file_name, consts{strcmp(consts{1}, 'MEPonly')}));
            isLEP = any(contains(file_name, consts{strcmp(consts{1}, 'LEPonly')}));
            if isLEP
	    	  s = sprintf('%s,,%s', s, s);
            elseif isMEP
              s = sprintf('%s,%s,', s, s);
            else
              s = sprintf('%s,%s,%s', s, s, s);
            end
	    end
    end
end