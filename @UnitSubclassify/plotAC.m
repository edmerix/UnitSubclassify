% plot AC: 
function plotAC(app,ax)
    cla(ax)
    spiketimes = sort(app.UnitData.units(app.Data.selected).times);

    shadow             = app.Data.shadow;
    rp                 = app.Data.refractory_period;
    corr_bin_size      = app.Data.corr_bin_size;

    maxlag = app.Settings.MaxACLag;

    % calculate autocorrelation
    if length(spiketimes) > 1
      [cross,lags] = pxcorr(spiketimes,spiketimes,round(1000/corr_bin_size),maxlag);
    else
        cross = 0;
        lags = 0;
    end
    cross(lags==0) = 0;
    
    % place patches to represent shadow and refractory period
    ymax = max(cross) + 1;
    patch(ax,shadow*[-1 1 1 -1], [0 0 ymax ymax], [.5 .5 .5],'EdgeColor', 'none');
    patch(ax,[shadow [rp rp] shadow ], [0 0 ymax ymax], [0.5725 0.1333 0.0863],'EdgeColor','none');
    patch(ax,-[shadow [rp rp] shadow ], [0 0 ymax ymax], [0.5725 0.1333 0.0863],'EdgeColor','none');

    % plot autocorrelation histogram
    hold(ax,'on');
    bb = bar(ax,lags*1000,cross,1.0);
    hold(ax,'off');  
    set(bb,'FaceColor',[0 0.2314 0.2745],'EdgeColor',[0 0.2314 0.2745])

    % set axes
    set(ax, 'XLim', maxlag*1000*[-1 1]);
    set(ax,'YLim',[0 ymax])
    xlabel(ax,'Time lag (ms)')
    ylabel(ax,'Autocorrelation (Hz)')
end