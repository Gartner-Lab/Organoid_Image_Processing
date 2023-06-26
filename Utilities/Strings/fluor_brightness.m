function [brightness] = fluor_brightness(filename)
    dim = {'H1047R','E545K','PIK3CA','mChL\+GFPM','ERBB2','Her2', ...
		' mCh ',' mCh_','mChL+TLN1sh1M','mChL+TLN1shM','TLN1shM+mChL','TLN1sh1M+mChL',...
        ' mCh_CTNND1sh1puro '};
    % dim viruses and any where mCh is treated as GFP
    if any(cellfun(@(x) contains(filename, x), dim))
        brightness = "dim";
    else
        brightness = "bright";
    end
end