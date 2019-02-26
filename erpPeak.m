function peak = erpPeak(waveform,times,labels,ranges,manual,average,id,title)
% erpPeak
% - automatically calculate and manually inspect/adjust event-related 
%   potential peak estimation
%
% use:
%e.g. peak = erpPeak(diffRHonetimbre(:,i),xdata,{'n1'},[150 250],1,100,i,['DiffRHOneTimbre', i]) ;
%   peak = erpPeak(waveform,times,labels,ranges,manual,title)
%
% example code:
%
%   peak = erpPeak(waveform,times,{'p1','p2'},[50 150; 100 200],1,100,'subject1','my_erp');
%
% test example: missing auto/default filled
%
%   peak = erpPeak([],[],[],[],1,[],[],'test name');
%
% where:
%
% > INPUTS
%
% - waveform: numeric array of data of average event related potential
%   (y-data)
% - times: numeric array of time data (x-data)
% - labels: cell array of peak names
% - ranges: X by 2 numeric matrix of lower and upper time intervals to
%   search for peaks within, each row corresponding to peak name in the
%   labels variables
% - manual: logical variable to plot waveform and manual adjust peaks
% - title: axis title name - e.g., participant identifier
%
% > OUTPUTS
%
% - peak: structure array containing everything in function
%   Most relevant are 'peak.data' and 'peak.table'
%
%   - peak.data
%       > holds following for each peak:
%        - 'name'
%        - 'range'
%        - 'auto_magnitude'
%        - 'auto_latency'
%        - 'adj_magnitude'
%        - 'adj_latency',...
%        - 'use_magnitude'
%        - 'use_latency'
%        - 'comment'
%
%   - peak.table = table of the above (peak.data) information
%         where 'range' is separated into 'lower_range' and 'upper_range'
%
% When graphing - following keyboard shortcuts maybe use:
%
% - 'u' : undo last manual adjustment
%
% - 'q' or 'f' : quit/finish, close figure, and refresh output data
%
% - 'x' : for some young children, the n1 & p2 will not be developed. The
%       'x' key automatically sets these peaks to -50 for exclusion
%
% Created: October-2015 Nic Badcock - based on scripts from emotiv kiddy
%   processing from 2014
if ~exist('waveform','var') || isempty(waveform)
    waveform = erpPeakEmbeddedWaveform;
end
if ~exist('times','var') || isempty(times)
    times = -102:7.8:500;
end
if ~exist('labels','var') || isempty(labels)
    labels = {'p1','n1','p2','n2','p3'};
end
if ~exist('ranges','var') || isempty(ranges)
    ranges = [...
        50 140;
        70 150;
        140 200;
        150 320;
        260 400];
end
if ~exist('manual','var') || isempty(manual)
    manual = 0;
end
% if ~exist('graph','var') || isempty(graph)
%     graph = 0;
% end
if ~exist('average','var') || isempty(average)
    average = 0;
end
if ~exist('id','var') || isempty(id)
    id = 'test';
end
if ~exist('title','var') || isempty(title)
    title = 'erp title';
end
peak.labels = labels;
peak.waveform = waveform;
peak.times = times;
peak.name = 'ERP waveform: Peak check';
peak.title = title;
peak.valence = [-1 1]; % valence options
peak.cols = {'g','m'}; % auto, manual
peak.data = [];
peak.average = average;
peak.id = id;

for i = 1 : numel(peak.labels)
    peak.data.(peak.labels{i}).id = peak.id;
    peak.data.(peak.labels{i}).k = i; % counter
    peak.data.(peak.labels{i}).n = i; % number... same as counter
    peak.data.(peak.labels{i}).name = peak.labels{i};
    peak.data.(peak.labels{i}).range = ranges(i,:);
    peak.data.(peak.labels{i}).comment = 'no comment';
    %% auto peak calculation
    peak.data.(peak.labels{i}).filt = and(peak.times >= peak.data.(peak.labels{i}).range(1),...
        peak.times <= peak.data.(peak.labels{i}).range(2));
    peak.data.(peak.labels{i}).search = 'max';
    peak.data.(peak.labels{i}).valence = 1; % positive, graph line goes to the top of graph
    if strfind(peak.labels{i},'n')
        peak.data.(peak.labels{i}).search = 'min';
        peak.data.(peak.labels{i}).valence = -1; % negative, graph line goes to the bottom of graph
    end
    [peak.data.(peak.labels{i}).auto_magnitude,...
        peak.data.(peak.labels{i}).auto_magnitude_sample] = ...
        eval([peak.data.(peak.labels{i}).search,'(peak.waveform(peak.data.(peak.labels{i}).filt))']);
    peak.data.(peak.labels{i}).auto_magnitude_sample = ...
        peak.data.(peak.labels{i}).auto_magnitude_sample + find(peak.data.(peak.labels{i}).filt,1,'first') - 1;
    peak.data.(peak.labels{i}).auto_latency = peak.times(peak.data.(peak.labels{i}).auto_magnitude_sample);
    peak.data.(peak.labels{i}).adj_magnitude = -999;
    peak.data.(peak.labels{i}).adj_latency = peak.data.(peak.labels{i}).adj_magnitude;
    peak.data.(peak.labels{i}).use_magnitude = peak.data.(peak.labels{i}).auto_magnitude;
    peak.data.(peak.labels{i}).use_latency = peak.data.(peak.labels{i}).auto_latency;
    
     peak.data.(peak.labels{i}).auto_magnitude_avg = -999;
     peak.data.(peak.labels{i}).adj_magnitude_avg = -999;
     
    if peak.average
        peak.data.(peak.labels{i}).avg_range = peak.data.(peak.labels{i}).auto_latency + [-1 1]*peak.average*.5;
        peak.tmp.filter = and(peak.times >= peak.data.(peak.labels{i}).avg_range(1),peak.times <= peak.data.(peak.labels{i}).avg_range(2));
        peak.data.(peak.labels{i}).auto_magnitude_avg = mean(peak.waveform(peak.tmp.filter));
    end
    peak.data.(peak.labels{i}).use_magnitude_avg = peak.data.(peak.labels{i}).auto_magnitude_avg;
    
end

%% plot
if manual %|| graph
    peak.plot.h = figure('Name',peak.name,'Units','Normalized','Position',[.2 .2 .6 .7],...
        'keyPressFcn',@keyboardInstruction);
    % peak.plot.h = h;
    set(peak.plot.h,'WindowButtonDownFcn',@selectPeak)
    set(peak.plot.h,'CloseRequestFcn',@CloseCallBack)
    % WindowButtonDownFcn =
    % 	WindowButtonMotionFcn =
    % 	WindowButtonUpFcn =
    
    peak.plot.wave.h = plot(peak.times,peak.waveform);
    
    peak.plot.axes.h = gca;
    % get some extra room below
    peak.plot.pos = [.13 .21 .505 .7150];
    set(peak.plot.axes.h,'Position',peak.plot.pos)
    peak.plot.YLim = [-25 15];
    peak.plot.XLim = [-100 500];
    set(peak.plot.axes.h,'XLim',peak.plot.XLim,'YLim',peak.plot.YLim);
    % tmp_title = sprintf('%u: %s - %s - %s - %s - %s',n.k,n.code,n.sys,n.cond, n.tone,n.electrode);
    set(get(peak.plot.axes.h,'Title'),'String',peak.title);
    hold;
    % 0 lines
    plot([0 0],get(peak.plot.axes.h,'YLim'),'k');
    plot(get(peak.plot.axes.h,'XLim'),[0 0],'--k');
    % add peak labels
    peak = peakLabels(peak);
    peak = peakButtons(peak);
    peak.plot.filename = 'erpPeakData.mat';
    set(peak.plot.h,'UserData',peak);
    
    uiwait(peak.plot.h);
    try
        load(peak.plot.filename);
        delete(peak.plot.filename);
    catch err
        warndlg('Updated information not available to output - please use ''Finish'' button\n');
    end
end

%% collect information in table
% create variables first
peak.tmp.table.variables = {'id','name','lower_range','upper_range',...
    'auto_magnitude','auto_latency','auto_magnitude_avg',...
    'adj_magnitude','adj_latency','adj_magnitude_avg',...
    'use_magnitude','use_latency','use_magnitude_avg','comment'};
 if peak.average
        peak.tmp.table.variables{end+1} = 'average';
        peak.tmp.table.variables{end+1} = 'average_note';
 end
for i = 1 : numel(peak.labels)
    if peak.average
        peak.data.(peak.labels{i}).average = peak.average;
        peak.data.(peak.labels{i}).average_note = sprintf('average around the peak = half this time either side: (%2.2f msec)',peak.average*.5);
    end
    for j = 1 : numel(peak.tmp.table.variables)
        switch peak.tmp.table.variables{j}
            case {'id','name','comment','average_note'}
                peak.tmp.table.(peak.tmp.table.variables{j}){i} = peak.data.(peak.labels{i}).(peak.tmp.table.variables{j});
            case 'lower_range'
                peak.tmp.table.(peak.tmp.table.variables{j})(i) = peak.data.(peak.labels{i}).range(1);
            case 'upper_range'
                peak.tmp.table.(peak.tmp.table.variables{j})(i) = peak.data.(peak.labels{i}).range(2);
            otherwise
                peak.tmp.table.(peak.tmp.table.variables{j})(i) = peak.data.(peak.labels{i}).(peak.tmp.table.variables{j});
        end
    end
end
if exist('table','file')
    peak.table = cell2table({});
    for j = 1 : numel(peak.tmp.table.variables)
        peak.table = [peak.table,...
            table(peak.tmp.table.(peak.tmp.table.variables{j})','VariableNames',{peak.tmp.table.variables{j}})];
    end
    fprintf('\nReporting peak table:\n')
    disp(peak.table);
end
end % end of function
%% embedded functions
function peak = peakLabels(peak)
for i = 1 : numel(peak.labels)
    %     for ij = 1 : numel(peak.data.clear_info.labels)
    %         n.(peak.data.clear_info.labels{ij}) = peak.data.clear_info.(peak.data.clear_info.labels{ij});
    %     end
    n.peak = peak.labels{i};
    n.k = peak.data.(n.peak).k;
    
    n.range = peak.data.(n.peak).range;
    
    n.Ynum = peak.valence == peak.data.(n.peak).valence;
    peak.data.(n.peak).Ynum = n.Ynum;
    n.Yadj = peak.valence(peak.valence ~= peak.data.(n.peak).valence); % multiple by to get off top/bottom of Y-axis
    plot(n.range,[peak.plot.YLim(n.Ynum)+i*n.Yadj %peak.data.(n.peak).valence ...
        peak.plot.YLim(n.Ynum )+i*n.Yadj],'--k');
    %     area(n.range,peak.plot.YLim)
    % line: vertical
    peak.data.(n.peak).x = ones(1,2)*peak.data.(n.peak).auto_latency;
    peak.data.(n.peak).y = [peak.data.(n.peak).auto_magnitude peak.plot.YLim(n.Ynum)];
    peak.data.(n.peak).h = plot(peak.data.(n.peak).x,peak.data.(n.peak).y,peak.cols{1},'UserData',[n.peak,'_auto']);
    % text
    peak.data.(n.peak).text.x = peak.data.(n.peak).auto_latency;
    peak.data.(n.peak).text.y =  peak.plot.YLim(n.Ynum)+(i*2*n.Yadj); %peak.data.(n.peak).valence;
    text(peak.data.(n.peak).text.x,peak.data.(n.peak).text.y,n.peak);
    
    % add
    peak.data.(n.peak).xman = ones(1,2)*peak.plot.XLim(1) - 10; %peak.data.(n.peak).adj_latency;
    peak.data.(n.peak).yman = [peak.data.(n.peak).adj_magnitude peak.plot.YLim(n.Ynum)];
    peak.data.(n.peak).hman = plot(peak.data.(n.peak).xman,peak.data.(n.peak).yman,peak.cols{2},'UserData',[n.peak,'_man']);
    % always add an adjusted
    % version off the graph to the
    % negative
    %     if peak.data.(n.peak).adjust
    %         peak.data.(n.peak).xman = ones(1,2)*peak.data.(n.peak).adj_latency;
    %         peak.data.(n.peak).yman = [peak.data.(n.peak).adj_magnitude peak.plot.YLim(n.Ynum)];
    %         set(peak.data.(n.peak).hman,'XData',peak.data.(n.peak).xman,'YData',peak.data.(n.peak).yman);
    %         %         peak.data.(n.peak).hman = plot(peak.data.(n.peak).xman,peak.data.(n.peak).yman,peak.cols{2});
    %         peak.data.(n.peak).text.x = peak.data.(n.peak).adj_latency;
    %         peak.data.(n.peak).text.y = peak.plot.YLim(n.Ynum)+(4+i*3)*peak.data.(n.peak).valence;
    %         peak.data.(n.peak).text.h = text(peak.data.(n.peak).text.x,peak.data.(n.peak).text.y,n.peak);
    %         drawnow;
    %     end
    % comment
    peak.edit.height = (sum(peak.plot.pos([2 4]))-peak.plot.pos(2))*.9/numel(peak.labels);
    peak.edit.y_height = (sum(peak.plot.pos([2 4]))-peak.plot.pos(2))/numel(peak.labels);
    peak.edit.(n.peak).pos = [sum(peak.plot.pos([1 3]))*1.1 sum(peak.plot.pos([2 4]))-peak.edit.y_height*(i)  ...
        (1 - peak.plot.pos(3))*.5 peak.edit.height];
    
    peak.edit.(n.peak).h = uicontrol('Parent',peak.plot.h,... % parent
        'Units','Normalized',...
        'Style','edit',...
        'ToolTipString',n.peak,...
        'Tag',[n.peak,'_edit'],'Position',peak.edit.(n.peak).pos,...
        'Callback',@getComment,...
        'String',peak.data.(n.peak).comment,...
        'HorizontalAlignment','Left',...
        'Max',10); % multiple lines if we want it, will wrap when you click off
    %          set(peak.edit.(n.peak).h,'String',textwrap(peak.edit.(n.peak).h,{n.comment}));%,...
    peak.edit.(n.peak).pos_text =  peak.edit.(n.peak).pos;
    peak.edit.(n.peak).pos_text(1) = sum(peak.plot.pos([1 3]))*1.05;
    peak.edit.(n.peak).pos_text(2) = peak.edit.(n.peak).pos_text(2) + peak.edit.y_height*.5;
    peak.edit.(n.peak).pos_text(3) = .025;
    peak.edit.(n.peak).pos_text(4) = .05;
    peak.edit.(n.peak).h_text = uicontrol('Parent',peak.plot.h,... % parent
        'Units','Normalized',...
        'HorizontalAlignment','left',...
        'Style','text',....
        'Tag',[n.peak,'_title'],'Position',peak.edit.(n.peak).pos_text,...
        'String',n.peak,...
        'BackgroundColor',get(peak.plot.h,'Color'));
end
end
%% peak buttons
function peak = peakButtons(peak)
%% add some buttons
peak.but.labels = {'Undo','Immature','Finish'};
peak.but.width = .8/numel(peak.but.labels); %(sum(peak.plot.pos([1 3]))/numel(peak.but.labels))*.8;
peak.but.width_space = .2/(numel(peak.but.labels)-1);%(sum(peak.plot.pos([1 3]))/numel(peak.but.labels)) - peak.but.width;
peak.but.height = peak.plot.pos(2)*.5;
peak.but.height_y= peak.plot.pos(2)*.1;

for i = 1 : numel(peak.but.labels)
    f.label = peak.but.labels{i};
    peak.but.(f.label).pos = ...
        [peak.but.width_space*.5 + peak.but.width*(i-1) + peak.but.width_space*.5 ...
        peak.but.height_y peak.but.width peak.but.height];
    peak.but.(f.label).h = uicontrol('Parent',peak.plot.h,... % parent
        'Units','Normalized',...
        'Style','pushbutton',...
        'Tag',f.label,'Position',peak.but.(f.label).pos,...
        'String',f.label,...
        'Callback',eval(['@',f.label,'Callback']));
    
end
drawnow;
end
%% drag functions
%% > selectPeak
function selectPeak(obj,event)

ci = dbstack; % call information
fprintf('Running %s\n',ci.name);
n.Cxy = get (gca, 'CurrentPoint');
n.Cx = n.Cxy(1,1);
n.Cy = n.Cxy(1,2);
peak = get(get(gca,'Parent'),'UserData');
for i = 1 : numel(peak.labels)
    n.peak = peak.labels{i};
    n.X = get(peak.data.(n.peak).h,'XData');
    n.Y = get(peak.data.(n.peak).h,'YData');
    n.okay = [0 0];
    if and(n.Cx > n.X(1) - 5, n.Cx < n.X(1) + 5)
        n.okay(1) = 1;
        switch n.peak
            case {'p1','p2','p3'}
                if n.Cy > peak.waveform(find(peak.times == n.X(1),1,'first'))
                    n.okay(2) = 1;
                end
            case {'n1','n2','mmn'}
                if n.Cy < peak.waveform(find(peak.times == n.X(1),1,'first'))
                    n.okay(2) = 1;
                end
        end
        if sum(n.okay) == numel(n.okay)
            fprintf('\tProbably %s\n',n.peak);
            peak.tmp.peak = n.peak;
            break
        end
    end
end
if sum(n.okay) == numel(n.okay) %and(Cx > n.X(1) - 5, Cx < n.X(1) + 5)
    %     set(peak.h,'WindowButtonUpFcn')
    % WindowButtonDownFcn =
    set(peak.plot.h,'UserData',peak);
    set(peak.plot.h,'WindowButtonMotionFcn',@movePeak);
    set(peak.plot.h,'WindowButtonUpFcn',@setPeak);
else
    fprintf('\tCan''t find what you''re clicking for...\n')
end
end
%% > movePeak
function movePeak(obj,event)
% try
ci = dbstack; % call information
% fprintf('Running %s\n',ci.name);
%% draw the line wherever the cursor is
Cxy = get(gca, 'CurrentPoint');
% disp(Cxy)
peak = get(get(gca,'Parent'),'UserData');
n.peak = peak.tmp.peak;
peak.data.(n.peak).xman = ones(1,2)*Cxy(1,1);%peak.data.(n.peak).manual_latency;

peak.data.(n.peak).yman = [peak.waveform(find(and(peak.times > peak.data.(n.peak).xman(1)-5,peak.times < peak.data.(n.peak).xman(1)+5),1,'first')) ...
    peak.plot.YLim(peak.data.(n.peak).Ynum)];
set(peak.data.(n.peak).hman,'XData',peak.data.(n.peak).xman,'YData',peak.data.(n.peak).yman);
% peak.data.(n.peak).hman = plot(peak.data.(n.peak).xman,peak.data.(n.peak).yman,peak.cols{2});
drawnow;
%         peak.data.(n.peak).text.x = peak.data.(n.peak).manual_latency;
%         peak.data.(n.peak).text.y = YLim(peak.data.(n.peak).Ynum)+(4+peak.data.(n.peak).n*3)*peak.data.(n.peak).valence;
%         peak.data.(n.peak).text.h = text(peak.data.(n.peak).text.x,peak.data.(n.peak).text.y,n.peak);
% catch err
%     set(peak.h,'WindowButtonMotionFcn',[]);
%     keyboard
% end
set(peak.plot.h,'UserData',peak);
end
%% > setPeak
function setPeak(obj,event)

ci = dbstack; % call information
fprintf('Running %s\n',ci.name);
peak = get(get(gca,'Parent'),'UserData');
set(peak.plot.h,'WindowButtonMotionFcn',[]);
n.peak = peak.tmp.peak;
n.k = peak.data.(n.peak).k;
peak.data.(n.peak).adjust = 1;
% n.comment = peak.data.(n.peak).comment;

peak.data.(n.peak).manual_magnitude = peak.data.(n.peak).yman(1);%n.manual_magnitude;
peak.data.(n.peak).manual_latency = peak.data.(n.peak).xman(1);% n.manual_latency;

peak.data.(n.peak).adj_magnitude = peak.data.(n.peak).manual_magnitude;
peak.data.(n.peak).adj_latency = peak.data.(n.peak).manual_latency;

if peak.average
    peak.data.(n.peak).avg_range = peak.data.(n.peak).adj_latency + [-1 1]*peak.average*.5;
    peak.tmp.filter = and(peak.times >= peak.data.(n.peak).avg_range(1),peak.times <= peak.data.(n.peak).avg_range(2));
    peak.data.(n.peak).adj_magnitude_avg = mean(peak.waveform(peak.tmp.filter));
end
peak.data.(n.peak).use_magnitude_avg = peak.data.(n.peak).adj_magnitude_avg;

peak.data.(n.peak).use_magnitude = peak.data.(n.peak).manual_magnitude;%n.manual_magnitude;
peak.data.(n.peak).use_latency = peak.data.(n.peak).manual_latency;% n.manual_latency;

peak.data.(n.peak).text.x = peak.data.(n.peak).manual_latency;%peak.data.(n.peak).manual_latency;
peak.data.(n.peak).text.y = peak.plot.YLim(peak.data.(n.peak).Ynum)+(4+peak.data.(n.peak).n*3)*peak.data.(n.peak).valence;
% if isfield(peak.data.(n.peak).text,'h')
try
    set(peak.data.(n.peak).text.h,'Position',[ peak.data.(n.peak).text.x peak.data.(n.peak).text.y 0],'String',n.peak);
catch err
    try; delete(peak.data.(n.peak).text.h); end
    peak.data.(n.peak).text.h = text(peak.data.(n.peak).text.x,peak.data.(n.peak).text.y,n.peak);
end

fprintf('\t%s manually set to latency = %3.2f, magniude = %3.2f\n',...
    n.peak,peak.data.(n.peak).manual_latency,peak.data.(n.peak).manual_magnitude);
peak.tmp.last_peak = n.peak;
peak.tmp.last_immature = [];
set(peak.plot.h,'UserData',peak);
end
%% keyboardInstruction
function keyboardInstruction(obj,event)
ci = dbstack; % call information
fprintf('Running %s\n',ci.name);
peak = get(get(gca,'Parent'),'UserData');
switch event.Character
    case 'u'
        UndoCallback;
        %     case 'b'
        %         BackCallback;
        %     case {'f','n','c'};
        %         ContinueCallback;
    case {'q','f'}
        FinishCallback;
    case {'i','x'}
        ImmatureCallback;
        
end
end
%% Button callbacks
% function BackCallback(varargin)
%
% ci = dbstack; % call information
% fprintf('Running %s\n',ci.name);
% peak = get(get(gca,'Parent'),'UserData');
% peak.back = 1;
% fprintf('\tHopefully moving back 1 = displaying previous graph\n');
% close(peak.h);
% end
% function ContinueCallback(varargin)
% global evnka
% ci = dbstack; % call information
% fprintf('Running %s\n',ci.name);
% close(peak.h);
% end
function UndoCallback(varargin)

ci = dbstack; % call information
peak = get(get(gca,'Parent'),'UserData');
if isfield(peak.tmp,'last_immature') || isfield(peak.tmp,'last_peak') %%&& ~isempty(peak.tmp.last_peak)
    if isfield(peak.tmp,'last_immature') && ~isempty(peak.tmp.last_immature)
        n.peaks = peak.tmp.last_immature;%{'p2','n2'};
        
    elseif ~isempty(peak.tmp.last_peak)
        n.peaks = {peak.tmp.last_peak};
    else
        return
    end
    for i = 1 : numel(n.peaks)
        n.peak = n.peaks{i}; % peak.tmp.last_peak;
        n.k = peak.data.(n.peak).k;
        % peak.data.(n.peak).comment = n.last_comment;
        
        fprintf('Running %s\nResetting %s adjusted peak\n',ci.name,n.peak);
        
        
        delete(peak.data.(n.peak).hman);
        if isfield(peak.data.(n.peak).text,'h')
            set(peak.data.(n.peak).text.h,'String','');
        end
        peak.data.(n.peak).adjust = 0;
        % n.commment = peak.data.(n.peak).comment;
        
        peak.data.(n.peak).manual_magnitude = 0;
        peak.data.(n.peak).manual_latency = 0;
        
        peak.data.(n.peak).use_magnitude =  peak.data.(n.peak).auto_magnitude;
        peak.data.(n.peak).use_latency = peak.data.(n.peak).auto_latency;
        
        % peak.data.(n.peak).manual_magnitude = n.manual_magnitude;
        % peak.data.(n.peak).manual_latency = n.manual_latency;
        
        % add off the graph again
        peak.data.(n.peak).xman = ones(1,2)*peak.plot.XLim(1) - 10; %peak.data.(n.peak).manual_latency;
        peak.data.(n.peak).yman = [peak.data.(n.peak).manual_magnitude peak.plot.YLim(peak.data.(n.peak).Ynum)];
        peak.data.(n.peak).hman = plot(peak.data.(n.peak).xman,peak.data.(n.peak).yman,peak.cols{2},'UserData',[n.peak,'_man']);
        if isfield(peak.tmp,'last_immature') &&  ~isempty(peak.tmp.last_immature)
            peak.data.(n.peak).comment = 'no comment';
            set(peak.edit.(n.peak).h,'String',peak.data.(n.peak).comment);
        end
    end
    peak.tmp.last_immature = [];
    set(get(gca,'Parent'),'UserData',peak);
    % saveMATdata; % continuously save this information
else
    fprintf('No ''last_peak'' variable\n');
    peak.tmp.last_peak = [];
end
end
function FinishCallback(varargin)
% global evnka n
ci = dbstack; % call information
fprintf('Running %s\n',ci.name);
peak = get(gcf,'UserData');
delete(gcf);
try; save(peak.plot.filename,'peak'); end
% peak.quit = 1;
fprintf('Closing %s figure\n',mfilename);
% evalin('caller','peak_out = peak;');

% peak.electrodes_n = n.electrodes;
% n.cond = n.cond_label;
% %                 peak.restart_info.labels = {'code','sys','cond_label','tone','electrode'};
% %                 peak.restart_info.vars = {'code_list','systems','conds','tones','electrodes_n'};
% n.k = peak.k.peak;% + numel(peak.data.labels);
% peak.restart_info.restart = sprintf('peak.restart = struct(''k'',%u,',n.k);
%
% for q = 1 : numel(peak.restart_info.labels)
%     peak.restart_info.j = find(strcmp(n.(peak.restart_info.labels{q}),peak.(peak.restart_info.vars{q})),1,'first');
%     fprintf('\t%s: %s = %u\n',peak.restart_info.labels{q},n.(peak.restart_info.labels{q}),...
%         peak.restart_info.j);
%     peak.restart_info.restart = sprintf('%s''%s'',%u,''%s'',%u,',peak.restart_info.restart,...
%         peak.restart_info.labels{q},peak.restart_info.j,...
%         [peak.restart_info.labels{q},'_k'],peak.k.(peak.restart_info.labels{q}));
% end
% peak.restart_info.restart(end:end+1) = ');';
% restart_string = peak.restart_info.restart;
% quit_option = questdlg('Save restart info?','Save Restart:','Yes','No','Cancel','Yes');
% switch quit_option
%     case 'Yes'
%         fprintf('Saving restart information:\n');
%         fprintf('\tSaved to:\n\t%s\n\n',peak.save.restartfnl2save);
%         save(peak.save.restartfnl2save,'restart_string');
%         close(peak.h);
%     case 'No'
%         close(peak.h);
%     case 'Cancel'
%         peak.quit = 0;
% end
end
function getComment(obj,event)
tag = get(obj,'Tag');
n.peak = strtok(tag,'_');%tag(1:2);
peak = get(gcf,'UserData');
peak.data.(n.peak).comment = get(obj,'String');
% set(obj,'String',textwrap(obj,{n.comment}));
% peak.data.comment{peak.data.(n.peak).k} = n.comment;
fprintf('%s: %s peak comment (n.k = %u) = %s\n','@getComment',n.peak,peak.data.(n.peak).k,peak.data.(n.peak).comment);
set(gcf,'UserData',peak);
end
%% ImmatureCallBack
function ImmatureCallback(obj,event)
ci = dbstack; % call information
fprintf('Running %s\n',ci.name);
peak = get(gcf,'UserData');
tmp.labels = {'p2','n1'};
tmp.value = -50;

for i = 1 : numel(tmp.labels)
    n.peak = tmp.labels{i};
    
    peak.data.(n.peak).xman = ones(1,2)*tmp.value;%peak.data.(n.peak).manual_latency;
    
    peak.data.(n.peak).yman = [peak.waveform(find(and(peak.times > peak.data.(n.peak).xman(1)-5,peak.times < peak.data.(n.peak).xman(1)+5),1,'first')) ...
        peak.plot.YLim(peak.data.(n.peak).Ynum)];
    set(peak.data.(n.peak).hman,'XData',peak.data.(n.peak).xman,'YData',peak.data.(n.peak).yman);
    
    %             peak.data.(n.peak).yman(1) = 999;% % n.manual_magnitude =
    %             n.manual_latency = -50;%peak.data.(n.peak).xman(1);
    peak.tmp.peak = n.peak;
    peak.data.(n.peak).comment = sprintf(...
        'immature ERP waveform: %s set to %i',n.peak,tmp.value);
    set(peak.edit.(n.peak).h,'String',peak.data.(n.peak).comment);
    set(get(gca,'Parent'),'UserData',peak);
    
    setPeak;
end
peak.tmp.last_immature = tmp.labels;
set(get(gca,'Parent'),'UserData',peak);
end
%% CloseCallBack
function CloseCallBack(obj,event)
ci = dbstack; % call information
fprintf('Running %s\n',ci.name);
% FinishCallback(varargin)
fprintf('Updated information might not be included in output...\n');
delete(gcf);
% return
end
%% erpPeakEmbeddedWaveform
function data = erpPeakEmbeddedWaveform

data = [-0.20819
    0.03596
    0.16272
    0.22407
    0.30116
    0.35279
    0.26043
    0.012322
    -0.24227
    -0.34222
    -0.27236
    -0.15763
    -0.12681
    -0.19693
    -0.28122
    -0.28606
    -0.1853
    -0.022757
    0.12211
    0.18954
    0.21451
    0.33553
    0.65193
    1.051
    1.2498
    1.063
    0.59315
    0.12428
    -0.11911
    -0.061712
    0.28426
    0.83233
    1.3744
    1.6524
    1.5497
    1.1596
    0.62869
    -0.015426
    -0.84449
    -1.8892
    -3.0658
    -4.219
    -5.2101
    -5.9874
    -6.5943
    -7.0961
    -7.4935
    -7.7285
    -7.7648
    -7.6214
    -7.3216
    -6.8503
    -6.1894
    -5.3832
    -4.5512
    -3.8285
    -3.2881
    -2.909
    -2.6217
    -2.3863
    -2.2147
    -2.1215
    -2.0929
    -2.1278
    -2.2581
    -2.4768
    -2.6909
    -2.8164
    -2.879
    -2.9344
    -2.9269
    -2.7502
    -2.4483
    -2.2244
    -2.199
    -2.2651
    -2.2592
    -2.1857];
end