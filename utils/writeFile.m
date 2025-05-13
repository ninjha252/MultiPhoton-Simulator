function writeFile(fileName,text)
    fid = fopen(fileName,'wt');
    fprintf(fid,'%s',text);
    fclose(fid);
end

