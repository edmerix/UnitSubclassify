% Select unit in the side panel:
function UnitSelection(app,event)
    selected = strrep(event.Value, 'Unit ','');
    app.Data.selected = str2double(selected);
    if ~isempty(app.Data.selected)
        makePlots(app);
        metricPlots(app);
    end
end