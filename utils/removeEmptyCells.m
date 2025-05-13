function result = removeEmptyCells(cells)
%removeEmptyCells Remove empty cells
    result = cells(~cellfun('isempty',cells));
end

