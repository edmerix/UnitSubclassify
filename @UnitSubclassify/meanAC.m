function res = meanAC(app,spiketimes)
    % calculate autocorrelation
    if length(spiketimes) > 1
        ac = [];
        for t = 1:length(spiketimes)-1
            onwards = spiketimes(t+1:end) - spiketimes(t);
            onwards(onwards > app.Settings.MaxACLag) = [];
            ac = [ac; onwards];
        end
        res = mean(ac);
    else
        res = NaN;
    end
end