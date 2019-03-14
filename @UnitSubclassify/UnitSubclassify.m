classdef UnitSubclassify < matlab.apps.AppBase
    % UnitSubclassify class/figure.
    % A GUI for determining cell type subclassifications of spike sorted 
    % units stored as SingleUnit class within a MultipleUnit class
    %
    % Merricks, EM. 2019-02-07
    
    % Properties that correspond to app components
    properties (Access = public)
        % some of these can become private properties instead, later
        % also, some of these can become structs of the others, e.g. a
        % group of all buttons.
        UIFigure        matlab.ui.Figure
        SelectedUnit    matlab.ui.control.ListBox
        AxWaves         matlab.ui.control.UIAxes
        AxAC            matlab.ui.control.UIAxes
        Fieldname       matlab.ui.control.EditField
        KeyPointSelect  matlab.ui.control.Spinner
        FsSelect        matlab.ui.control.Spinner
        GoButton        matlab.ui.control.Button
        SaveButton      matlab.ui.control.Button
        RSButton        %matlab.ui.control.Button
        FSButton        %matlab.ui.control.Button
        Feedback        matlab.ui.control.Label
        % vector of axes:
        AxSubclass = gobjects(6,1);
        
        % structs of info variables:
        UnitData
        Data
        Settings
    end
    
    % App initialization and construction
    methods (Access = private)
        plotAC(app,ax);
        UnitSelection(app,event);
        
        % Create UIFigure and components
        function createComponents(app)
            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [round(rand(1,1)*100) round(rand(1,1)*100) app.Settings.Width app.Settings.Height];
            app.UIFigure.Name = 'Cell-Type Subclassification | Emerix';
            app.UIFigure.Resize = 'off'; % The figure is *mostly* capable of resizing, but it's not smooth, so I've turned it off. Set fig size when calling function.
            app.UIFigure.AutoResizeChildren = 'off';
            %app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @AppResize, true);
             
            if app.Settings.Fullscreen
                app.UIFigure.WindowState = 'fullscreen';
                ss = get(groot,'ScreenSize');
                app.Settings.Width = ss(3);
                app.Settings.Height = ss(4);
            end
            w = 100;
            h = app.Settings.Height - 22;
            
            app.SelectedUnit = uilistbox(app.UIFigure);
            app.SelectedUnit.Position = [1 1 w app.Settings.Height];
            app.SelectedUnit.ValueChangedFcn = createCallbackFcn(app, @UnitSelection, true);
            
            temp = uilabel(app.UIFigure);
            temp.Position = [w+10 h 60 20];
            temp.Text = 'Fieldname:';
            
            app.Fieldname = uieditfield(app.UIFigure);
            app.Fieldname.Position = [w+75 h w 20];
            app.Fieldname.Value = app.Settings.Fieldname;
            app.Fieldname.Tooltip = 'Field name for wideband waveform to look at';
            
            app.KeyPointSelect = uispinner(app.UIFigure);
            app.KeyPointSelect.Position = app.Fieldname.Position + [w+5 0 0 0];
            app.KeyPointSelect.ValueDisplayFormat = 'Index: %.0f';
            app.KeyPointSelect.Value = app.Data.keypoint;
            app.KeyPointSelect.Tooltip = 'Data point index of spike peak/trough';
            
            app.FsSelect = uispinner(app.UIFigure);
            app.FsSelect.Position = app.KeyPointSelect.Position + [w+5 0 -25 0];
            app.FsSelect.ValueDisplayFormat = '%.0f kHz';
            app.FsSelect.Value = app.Data.fms;
            app.FsSelect.Tooltip = 'Sample Frequency (kHz)';
            
            app.GoButton = uibutton(app.UIFigure);
            app.GoButton.Position = app.FsSelect.Position + [90 0 0 0];
            app.GoButton.Text = 'Go';
            app.GoButton.ButtonPushedFcn = createCallbackFcn(app, @updateBasic, true);
            
            app.SaveButton = uibutton(app.UIFigure);
            app.SaveButton.Position = [app.Settings.Width-95 app.Settings.Height-30 75 24];
            app.SaveButton.Text = 'Save';
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @saveData, true);
            
            app.RSButton = uibutton(app.UIFigure,'state');
            app.RSButton.Position = [3*app.Settings.Width/4 app.Settings.Height-30 100 24];
            app.RSButton.Text = 'Regular Spiking';
            app.RSButton.FontColor = [0.086275 0.32157 0.51765];
            app.RSButton.ValueChangedFcn = createCallbackFcn(app, @setRS, true);
            
            app.FSButton = uibutton(app.UIFigure,'state');
            app.FSButton.Position = [(3*app.Settings.Width/4)+110 app.Settings.Height-30 100 24];
            app.FSButton.Text = 'Fast Spiking';
            app.FSButton.FontColor = [0.51765 0.086275 0.32157];
            app.FSButton.ValueChangedFcn = createCallbackFcn(app, @setFS, true);
            
            app.AxWaves = uiaxes(app.UIFigure);
            app.AxWaves.Position = [w+1 h/2 (app.Settings.Width/2)-(w+1) h/2];
            
            app.AxAC = uiaxes(app.UIFigure);
            app.AxAC.Position = [w+1 1 (app.Settings.Width/2)-(w+1) h/2];
            disableDefaultInteractivity(app.AxAC);
            
            app.Feedback = uilabel(app.UIFigure);
            app.Feedback.Position = [(app.Settings.Width/2)+40 app.Settings.Height-40 250 40];
            app.Feedback.Text = 'Loading...';
            
            h = h - 18; % make room for feedback
            x = zeros(6,1);
            x(1:3) = app.Settings.Width/2;
            x(4:end) = 3*app.Settings.Width/4;
            y = zeros(6,1);
            y([1 4]) = 2*h/3;
            y([2 5]) = h/3;
            y([3 6]) = 1;
            aw = app.Settings.Width/4;
            ah = h/3;
            for a = 1:6
                app.AxSubclass(a) = uiaxes(app.UIFigure);
                app.AxSubclass(a).Position = [x(a) y(a) aw ah];
                disableDefaultInteractivity(app.AxSubclass(a));
            end
            colormap(app.UIFigure,'cool');
            clear x y aw ah w h temp
        end
        % First load:
        function startup(app,~)
            app.SelectedUnit.Items = {'Loading...'};
            wbn = app.Fieldname.Value;
            good = zeros(1,length(app.UnitData.units));
            for u = 1:length(app.UnitData.units)
                if isprop(app.UnitData.units(u),wbn) && length(app.UnitData.units(u).(wbn)) > 1
                    app.SelectedUnit.Items{u} = ['Unit ' num2str(u)];
                    good(u) = 1;
                else
                    app.SelectedUnit.Items{u} = ['[No ' wbn '] Unit ' num2str(u)];
                end
            end
            % use good == 1 to build plot of all widebands etc.
            app.Data.available = find(good == 1);
            if ~isempty(app.Data.available)
                app.Data.selected = app.Data.available(1);
                app.SelectedUnit.Value = ['Unit ' num2str(app.Data.selected)];
                populateWaveforms(app);
                calcMetrics(app);
                makePlots(app);
                metricPlots(app);
            end
            clear wbn good
        end
        % Estimate cell types on currently loaded waveforms:
        function calcMetrics(app)
            all_t = app.UnitData.all_spike_times();
            tlook = floor(min(all_t)):ceil(max(all_t));
            overallFR = histc(all_t,tlook);
            clear all_t tlook
            % ignore sections > 5 seconds no firing across entire 
            % population, to avoid biasing FR against blanked seizures etc.
            transitions = diff([0; overallFR == 0; 0]);
            runstarts = find(transitions == 1);
            runends = find(transitions == -1);
            runlengths = runends - runstarts;
            avail_firing_duration = sum(runlengths);
            
            % Need to populate: vtop, fwhm, aclag, hh
            for a = 1:length(app.Data.available)
                spiketimes = sort(app.UnitData.units(app.Data.available(a)).times);
                % aclag:
                subclass.aclag = meanAC(app,spiketimes);
                % fr:
                subclass.fr = length(spiketimes)/avail_firing_duration;
                % maxpost/vtop:
                [maxpost,vtop] = max(app.Data.waveforms(a,app.Settings.Pre*app.Data.fms*app.Settings.Uprate+1:end));
                subclass.vtop = (vtop-1)/(app.Data.fms*app.Settings.Uprate);
                subclass.maxpost = maxpost;
                % hh:
                subclass.hh = -1+((maxpost+1)/2);
                % fwhm:
                spk = app.Data.waveforms(a,:);
                inds = find(spk > subclass.hh);
                
                pre = inds(inds < app.Settings.Pre*app.Data.fms*app.Settings.Uprate);
                if isempty(pre)
                    subclass.fwhm = NaN;
                    subclass.hwstart = NaN;
                else
                    nextdiff = app.Data.waveforms(a,pre(end)) - app.Data.waveforms(a,pre(end)+1);
                    realdiff = app.Data.waveforms(a,pre(end)) - subclass.hh;
                    pre = pre(end) - 1 + (realdiff/nextdiff);
                    subclass.hwstart = pre/(app.Data.fms*app.Settings.Uprate)- app.Settings.Pre;
                    
                    post = inds(inds > app.Settings.Pre*app.Data.fms*app.Settings.Uprate);
                    if isempty(post)
                        subclass.fwhm = NaN;
                        subclass.hwfinish = NaN;
                    else
                        lastdiff = app.Data.waveforms(a,post(1)) - app.Data.waveforms(a,post(1)-1);
                        realdiff = app.Data.waveforms(a,post(1)) - subclass.hh;
                        post = post(1) - 1 - (realdiff/lastdiff);

                        subclass.fwhm = (post - pre)/(app.Data.fms*app.Settings.Uprate);
                        subclass.hwfinish = post/(app.Data.fms*app.Settings.Uprate) - app.Settings.Pre;
                    end
                end
                app.UnitData.units(app.Data.available(a)).extra.subclass = subclass;
            end
            %% Calculate clusters for subclassification:
            temp = [app.UnitData.units.extra];
            temp = [temp.subclass];
            % group data:
            app.Data.metrics = [
                double([temp.aclag]); 
                [temp.fr]; 
                [temp.vtop];
                [temp.fwhm]
                ];
            app.Data.metric_names = {'AC lag','FR','VtoP','FWHM'};
            app.Data.groups = [1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
            app.Data.names = {
                'AC lag', 'FR';
                'AC lag', 'VtoP';
                'AC lag', 'FWHM';
                'FR', 'VtoP';
                'FR', 'FWHM';
                'VtoP', 'FWHM'
                };
            clear temp
            % cluster:
            app.Data.clus = cell(1,6);
            warning('off','stats:kmeans:MissingDataRemoved');
            for c = 1:6
                app.Data.clus{c} = kmeans(app.Data.metrics(app.Data.groups(c,:), :)',2);
            end
            if isempty(app.Settings.ClusterWith) % auto-use all of them if blank
                app.Settings.ClusterWith = app.Data.metric_names;
            end
            app.Data.clusterable = zeros(1,length(app.Data.metric_names));
            for m = 1:length(app.Data.metric_names)
                if any(strcmpi(app.Settings.ClusterWith,app.Data.metric_names{m}))
                    app.Data.clusterable(m) = 1;
                end
            end
            disp([9 'Doing the full clustering on: ' strjoin(app.Settings.ClusterWith,', ')])
            
            app.Data.fullclus = kmeans(app.Data.metrics(app.Data.clusterable == 1,:)',2);
            app.Data.origclus = app.Data.fullclus;
            warning('on','stats:kmeans:MissingDataRemoved');
            
            meanFR = nan(1,2);
            meanFWHM = nan(1,2);
            for i = 1:2
                meanFR(i) = nanmean(app.Data.metrics(2,app.Data.fullclus==i));
                meanFWHM(i) = nanmean(app.Data.metrics(4,app.Data.fullclus==i));
            end
            oops = false;
            if meanFWHM(1) > meanFWHM(2)
                app.Data.FSid = 2;
                app.Data.RSid = 1;
                if meanFR(1) > meanFR(2)
                    oops = true;
                end
            else
                app.Data.FSid = 1;
                app.Data.RSid = 2;
                if meanFR(1) < meanFR(2)
                    oops = true;
                end
            end
            if oops
                disp('N.B. Faster firing rate cells also had wider waveforms...')
                disp([9 'assuming narrower waveforms are the FS interneurons'])
            end
            
            totCells = length(app.Data.metrics(1,:));
            totIN = length(find(app.Data.fullclus == app.Data.FSid));
            app.Feedback.Text = {[num2str((totIN/totCells*100),'%2.2f') '% autoclassified as FS interneurons'],'Selecting unit...'};
            
            for a = 1:length(app.Data.available)
                if app.Data.fullclus(app.Data.available(a)) == app.Data.FSid
                    app.UnitData.units(app.Data.available(a)).type = 'in';
                else
                    app.UnitData.units(app.Data.available(a)).type = 'pc';
                end
            end
            clear meanF* a i c pre inds spk oops totCells totIN
        end
        % Apply waveforms and time samples to app.Data:
        function populateWaveforms(app)
            wvs = NaN(length(app.Data.available),length(app.UnitData.units(app.Data.available(1)).(app.Fieldname.Value)));
            for a = 1:length(app.Data.available)
                wvs(a,:) = app.UnitData.units(app.Data.available(a)).(app.Fieldname.Value);
            end
            app.Data.waveforms = normWaves(app,wvs);
            app.Data.tt = (-app.Settings.Pre*app.Data.fms*app.Settings.Uprate:app.Settings.Post*app.Data.fms*app.Settings.Uprate)...
                /(app.Data.fms*app.Settings.Uprate);
        end
        % Metric plots:
        function metricPlots(app)
            % Run through twice, foreground as what they were clustered as
            % within just these metrics (larger), background smaller as
            % what they were clustered as across the whole population of
            % user-chosen metrics:
            cols = zeros(size(app.Data.metrics,2),3); % colors for overall scatter
            cols(app.Data.fullclus == app.Data.FSid, 1) = 1; % set FS id red
            cols(app.Data.fullclus == app.Data.RSid, 3) = 1; % set RS id blue
            for c = 1:6
                % overall clustering (background):
                scatter(app.AxSubclass(c),...
                    app.Data.metrics(app.Data.groups(c,1),:),...
                    app.Data.metrics(app.Data.groups(c,2),:),...
                    40,cols,'Filled');
                               
                hold(app.AxSubclass(c),'on')
                 % within group clustering (foreground):
                scatter(app.AxSubclass(c),...
                    app.Data.metrics(app.Data.groups(c,1),:),...
                    app.Data.metrics(app.Data.groups(c,2),:),...
                    12,app.Data.clus{c},'Filled');
                % highlighting the currently selected unit:
                plot(app.AxSubclass(c),...
                    app.Data.metrics(app.Data.groups(c,1),app.Data.selected),...
                    app.Data.metrics(app.Data.groups(c,2),app.Data.selected),...
                    'xk','MarkerSize',16);
                
                hold(app.AxSubclass(c),'off')
                
                xlabel(app.AxSubclass(c),app.Data.names{c,1});
                ylabel(app.AxSubclass(c),app.Data.names{c,2});
                app.AxSubclass(c).XGrid = 'on';
                app.AxSubclass(c).YGrid = 'on';
            end
            thisn = 'RS cell';
            if app.Data.origclus(app.Data.selected) == app.Data.FSid
                thisn = 'FS interneuron';
            end
            if app.Data.fullclus(app.Data.selected) == app.Data.FSid
                app.RSButton.Value = false;
                app.FSButton.Value = true;
            else
                app.FSButton.Value = false;
                app.RSButton.Value = true;
            end
            app.Feedback.Text{2} = ['This unit was autoclassified as ' thisn];
        end
        % Make the plots:
        function makePlots(app)
            subclass = app.UnitData.units(app.Data.selected).extra.subclass;
            %% waveform(s):
            cla(app.AxWaves);
            resetplotview(app.AxWaves);
            plot(app.AxWaves,app.Data.tt,app.Data.waveforms');
            hold(app.AxWaves,'on');
            line(app.AxWaves,[subclass.hwstart subclass.hwfinish],[subclass.hh subclass.hh],'color','r','linewidth',2);
            line(app.AxWaves,[0 0],[-1 subclass.maxpost],'color','r','linewidth',2,'linestyle','--');
            line(app.AxWaves,[0 subclass.vtop],[subclass.maxpost subclass.maxpost],'color','r','linewidth',2);
            plot(app.AxWaves,app.Data.tt,app.Data.waveforms(app.Data.available == app.Data.selected,:)','k','linewidth',3);
            xlabel(app.AxWaves,'Time (ms)')
            ylabel(app.AxWaves,'Normalized voltage');
            title(app.AxWaves,'Normalized wideband waveforms');
            app.AxWaves.XGrid = 'on';
            app.AxWaves.YGrid = 'on';
            %% autocorrelation:
            plotAC(app,app.AxAC);
            hold(app.AxAC,'on');
            plot(app.AxAC,subclass.aclag*1e3,max(app.AxAC.YLim),'pr','markersize',10,'MarkerFaceColor','r');
            app.AxAC.XGrid = 'on';
            app.AxAC.YGrid = 'on';
            title(app.AxAC,['Unit ' num2str(app.Data.selected) ' autocorrelation:']);
        end
        % Normalize waveforms:
        function normed = normWaves(app,wvs)
            keypoint = app.Data.keypoint;
            search_range = (-app.Settings.JitterWidth*app.Data.fms*app.Settings.Uprate):(app.Settings.JitterWidth*app.Data.fms*app.Settings.Uprate);
            prekeep = app.Settings.Pre*app.Data.fms*app.Settings.Uprate;
            postkeep = app.Settings.Post*app.Data.fms*app.Settings.Uprate;
            % TODO: limit prekeep and postkeep to max available data in
            % that direction minus app.Settings.JitterWidth
            normed = NaN(size(wvs,1),length(-prekeep:postkeep));

            for u = 1:size(wvs,1)
                ups = interp(wvs(u,:),app.Settings.Uprate);
                if app.Settings.Smoothing
                    ups = smooth(ups,round(app.Settings.SmoothFactor * app.Data.fms * app.Settings.Uprate));
                end
                [~,ind] = min(ups((keypoint*app.Settings.Uprate)+search_range));
                ind = ind + (keypoint*app.Settings.Uprate)+search_range(1)-1;
                aligned = ups(ind+(-prekeep:postkeep));
                aligned = aligned-mean(aligned);
                normed(u,:) = aligned / -min(aligned);
            end
        end
        % On push of Go button for basic settings:
        function updateBasic(app,~)
            app.Settings.Fieldname = app.Fieldname.Value;
            app.Data.keypoint = app.KeyPointSelect.Value;
            app.Data.fms = app.FsSelect.Value;
            startup(app);
        end
        % Set to RS: (weird use of state button - clicking it will always
        % set it to true. Could use radio buttons, but I like proper
        % buttons)
        function setRS(app,~)
            app.FSButton.Value = false;
            app.UnitData.units(app.Data.selected).type = 'pc';
            app.Data.fullclus(app.Data.selected) = app.Data.RSid;
            app.RSButton.Value = true;
        end
        % Set to FS: (ditto setRS function)
        function setFS(app,~)
            app.RSButton.Value = false;
            app.UnitData.units(app.Data.selected).type = 'in';
            app.Data.fullclus(app.Data.selected) = app.Data.FSid;
            app.FSButton.Value = true;
        end
        % Save back to file, or to a new one if shift held
        function saveData(app,~)
            data = app.UnitData;
            app.UIFigure.Visible = 'off';
            [file,pth] = uiputfile('*.mat','UnitSubclassify file','classified_units.mat');
            % assignin('base','file',file)
            % assignin('base','pth',pth)
            if (length(pth) == 1 && pth == 0) || (length(file) == 1 && file == 0)
                disp([9 'Cancelled, not saving.'])
            else
                svpth = [pth file];
                save(svpth,'data');
                disp(['Saved file at ' svpth]);
            end
            app.UIFigure.Visible = 'on';
        end
    end

    
    methods (Access = public)
        % Construct app
        function app = UnitSubclassify(data,varargin)
            app.UnitData = data;
            
            app.Settings.Fullscreen = 0;
            app.Settings.Height = 900;
            app.Settings.Width = 1440;
            app.Settings.Debugging = false;
            app.Settings.Smoothing = true;
            app.Settings.SmoothFactor = 0.15;
            app.Settings.Uprate = 4;
            app.Settings.JitterWidth = 0.1;
            app.Settings.Pre = 2;
            app.Settings.Post = 2;
            app.Settings.MaxACLag = 0.1;
            app.Settings.Fieldname = 'wideband';
            app.Settings.ClusterWith = [];
            app.Settings.Keypoint = 90;
            
            allowable = fieldnames(app.Settings);
            if nargin > 1 && strcmpi(varargin{1},'help')
                % display allowable, then return
                disp([9 'Allowable input arguments:'])
                for a = 1:length(allowable)
                    disp([9 9 allowable{a}])
                end
                delete(app);
                if nargout == 0
                    clear app
                end
                return;
            end
            
            if mod(length(varargin),2) ~= 0
                error('Inputs must be in name, value pairs');
            end
            for v = 1:2:length(varargin)
                if find(ismember(allowable,varargin{v}))
                    app.Settings.(varargin{v}) = varargin{v+1};
                else
                    disp([9 'Not assigning ''' varargin{v} ''': not a property of SplitMerge class']);
                end
            end
            
            if ~iscell(app.Settings.ClusterWith) % which variables to cluster on
                disp([9 'ClusterWith input should be a cell array including at least 2 of:'])
                disp([9 9 '{''AC lag'', ''FR'', ''VtoP'', ''FWHM''}'])
                disp([9 'Setting to use all 4 this time']);
                app.Settings.ClusterWith = []; % empty auto-fills to them all
            end
            
            app.Data.selected = [];
            app.Data.fms = 30;
            app.Data.keypoint = app.Settings.Keypoint;
            app.Data.shadow = 0.75;
            app.Data.refractory_period = 2;
            app.Data.corr_bin_size = 2;
            
            if ~app.Settings.Debugging
                warning('off','MATLAB:callback:error');
            end
            % Create and configure components
            createComponents(app);
            app.Data.Loader = uiprogressdlg(app.UIFigure,'Title','Please Wait',...
                'Message','Loading...','Indeterminate','on');
            % Register the app with App Designer
            registerApp(app, app.UIFigure);
            
            startup(app);
            
            close(app.Data.Loader);
            
            if nargout == 0
                clear app
            end
        end
        
        % Code that executes before app deletion
        function delete(app)
            warning('on','MATLAB:callback:error'); % turn this back on
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end