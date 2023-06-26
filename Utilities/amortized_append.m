function [out] = amortized_append(original,to_append,nrow)
	if (isempty(original) || nrow == 1) 
		out = to_append;
		return
	end
	ncol = size(original,2);
	assert(ncol == size(to_append,2))
	original_nrow = size(original,1);
	if nrow == original_nrow + 1
		% double the size of the original, padding with empty values
		switch class(original)
		case 'cell'
			new_section = cell(original_nrow,ncol);
		case 'double'
			new_section = zeros(original_nrow,ncol);
		case 'table'
            assert(false,'Do not use tables.');
			new_section = cell2table(cell(original_nrow,ncol), ...
				'VariableNames',original.Properties.VariableNames);
			to_append = cell2table(to_append, ...
                'VariableNames',original.Properties.VariableNames);
		end
		out = vertcat(original,to_append,new_section);
	else
		assert (nrow <= original_nrow,'Wrong size.');
		original(nrow,:) = to_append;
		out = original;
	end
end