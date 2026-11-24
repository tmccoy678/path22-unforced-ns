function render_sections()
% Render three literature-standard vorticity sections on one common scale.

here = fileparts(mfilename('fullpath'));
out = fullfile(here,'output');
paper = fullfile(here,'paper');
if ~isfolder(paper)
    mkdir(paper);
end

files = {'horizontal.tsv','vertical_chord.tsv','carrier_normal.tsv'};
titles = {'(a) horizontal section','(b) vertical chord section', ...
          '(c) carrier-normal section'};
xlabels = {'$\Delta x$','$\ell$','$n_1$'};
ylabels = {'$\Delta y$','$\Delta z$','$n_2$'};

ink = [0.08 0.08 0.08];
fig = figure('Visible','off','Color','w','Units','inches', ...
    'Position',[0.5 0.5 7.25 2.75],'Renderer','painters');
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');

axes_list = gobjects(1,3);
for panel = 1:3
    T = readtable(fullfile(out,files{panel}),'FileType','text','Delimiter','\t');
    av = unique(T.a,'stable');
    bv = unique(T.b,'stable');
    C = reshape(T.normalized,[numel(av),numel(bv)])';
    axes_list(panel) = nexttile(layout,panel);
    imagesc(axes_list(panel),av,bv,C);
    set(axes_list(panel),'YDir','normal');
    axis(axes_list(panel),'image');
    clim(axes_list(panel),[0 1]);
    hold(axes_list(panel),'on');
    plot(axes_list(panel),0,0,'+','Color','k','MarkerSize',8,'LineWidth',1.8);
    plot(axes_list(panel),0,0,'+','Color','w','MarkerSize',6,'LineWidth',0.9);
    xlabel(axes_list(panel),xlabels{panel},'Interpreter','latex');
    ylabel(axes_list(panel),ylabels{panel},'Interpreter','latex');
    title(axes_list(panel),titles{panel},'Interpreter','latex');
end

colormap(fig,parula(256));
for ax = axes_list
    set(ax,'FontName','Times New Roman','FontSize',8,'LineWidth',0.65, ...
        'TickDir','out','Box','off','XColor',ink,'YColor',ink);
    set(ax.Title,'Color',ink,'FontSize',8.5,'FontWeight','normal');
    set(ax.XLabel,'Color',ink);
    set(ax.YLabel,'Color',ink);
end
cb = colorbar(axes_list(3),'Location','eastoutside');
cb.Label.String = '$|\omega|/\omega_{\rm max}$';
cb.Label.Interpreter = 'latex';
cb.FontName = 'Times New Roman';
cb.FontSize = 7.5;
cb.Color = ink;

base = fullfile(paper,'Path22_Unforced_NS_Initial_Vorticity_Sections');
exportgraphics(fig,[base '.pdf'],'ContentType','vector','BackgroundColor','white');
exportgraphics(fig,[base '.png'],'Resolution',600,'BackgroundColor','white');
try
    exportgraphics(fig,[base '.svg'],'ContentType','vector','BackgroundColor','white');
catch
    print(fig,[base '.svg'],'-dsvg','-painters');
end
close(fig);
fprintf('NS_SECTION_FIGURE=%s\n',base);
end
