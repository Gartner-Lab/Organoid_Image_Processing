function [csvTable] = dir_csv_reader(dir_csv)
	if ~exist(dir_csv, 'file')
	    fprintf('Go make channel annotations first.\n%s\n', dir_csv)
	    return
	end

	fprintf('Reading %s...\n', dir_csv);
	csvTable = readtable(dir_csv,'Delimiter',',');
	% only include correct folders
	csvTable = csvTable(csvTable.include == 1, :);

end