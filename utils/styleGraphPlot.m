function styleGraphPlot()    
    ax = gca;
    ax.FontSize = 14;
    
    lines = findobj(gcf,'Type','Line');
    for i = 1:numel(lines)
      lines(i).LineWidth = 1.5;
      lines(i).MarkerSize = 4;
    end
    
    %width=800;
    %height=650;
    %screenSize = get(0,'ScreenSize');
    %center = screenSize(3:4) ./ 2;
    %x0 = center(1) - width / 2;
    %y0 = center(2);
    %set(gcf,'position',[x0,y0,width,height]);
end

