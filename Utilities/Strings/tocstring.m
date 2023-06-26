function [s] = tocstring()
    s = datestr(seconds(toc),'HH:MM:SS');
end