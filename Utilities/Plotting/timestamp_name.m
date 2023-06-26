function [stamped] = timestamp_name(filepath)
	[folder,filename,ext] = fileparts(filepath);
	stamped = sprintf('%s%s_%s%s',folder,filename,datestr(now(),'yymmddHHMM'),ext);
end