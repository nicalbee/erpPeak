%% Solene's Noun Naming EEGLAB script
%
% date:
%   Wednesday 5th of July
%
% authors:
%   Solene Hameau
%   Nic Badcock
%
% Aim:
%   Working with the EEGLAB GUI, create a script that will process our Noun
%   Naming data - resulting in a ERP waveform.
%
%   This involes:
%   * importing data
%   * setting channel information
%   * filter the data - getting rid of frequencies of activity we're not
%       interested in
%   * remove eye-blinks (using ICA = independent components analysis)
%   - epoch
%   - exclude epochs with values outside certain limits
%   - calculate means for different conditions/circumstances (exlude based
%       on behaviour)
%

% Wed 19th July 2017
% - decided that we'll just set this script to do the automated things
% (import, channel assignmnet, filter, and ICA), then we'll create two more
% scripts, 1 for manual ICA removal, and another for automated epoching and
% epoch exclusion + ERP calculation.
%
% Wed 9th of August 2017
% - this is the third script with the final automated steps - the second
% script does the manual eye-blink check and rejection of the ICA
% components.
%
% Wednesday 16th of August 2017
% - now we've got some .mat files so we need to read these in and visualise
% as ERPs or something. Trial selection sorts of activities.

%% clear everything first
clear
clc
close all
%% define some settings
in.user = 'nic'; % 'solene'; %
% in.user = 'solene';
switch in.user
    case 'nic'
        in.project_dir = '/Users/mq20111600/Dropbox/nPeople/SoleneHameau/projects/nounnaming';
        in.eeglab_dir = '/Applications/eeglab13_4_4b/';
    case 'solene'
        in.project_dir = 'C:\Users\43105041\Dropbox\SoleneHameau\projects\nounnaming';
        in.eeglab_dir = 'C:\Users\43105041\Documents\nounnaming\eeglab14_1_1b';
end
in.data_dir = fullfile(in.project_dir,'data','mat');

in.save_dir_eeglab = in.data_dir; %fullfile(in.project_dir,'data','eeglab');
in.save_dir_matlab = fullfile(in.project_dir,'data','summary');

% data.epoch = [-.1 .8]; % lower and upper epoch bounds in seconds
% data.baseline = [data.epoch(1)*100 0]; %[-100 0]; lower and upper bounds of basline in milliseconds
% data.reject_limits = [-150 150];
% % data.electrode_labels = {'FP1','FP2','F3','F4','C3','C4','P3','P4',...
% %     'O1','O2','F7','F8','T7','T8','P7','P8','FZ','CZ','PZ','OZ',...
% %     'FC3','FC4','CP3','CP4','FT7','FT8','TP7','TP8','M2','FCZ',...
% %     'HEOG','VEOG','CPZ'};
%
% data.reject_electrodes = {'F3','F4',...
%     'O1','O2','F7','F8','T7','T8','P7','P8','FZ','CZ','PZ','OZ',...
%     'FC3','FC4'};

data.use_channels = {'FZ','CZ','CPZ','PZ','OZ'};

data.ylimits = [-10 15];

data.conds = 1:5;

    data.separate_plots = 1;
% Script 4: Don't need to open EEGLAB anymore :)
% %% first thing: Open EEGLAB
% % copied this from the eeglabhist1session.m file
%
% % check if the eeglab m file is on the MATLAB path
% if ~exist('eeglab.m','file')
%     % If not, change the diretory to it's location, and then it can be run
%     cd(in.eeglab_dir);
% end
% [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%% Import a file
% file name - this will eventually be within a loop
% in.file_name = 'NN13.cnt';

in.file_list = dir(fullfile(in.data_dir,'*.mat'));

for i = 1 : numel(in.file_list)
    in.file_name = in.file_list(i).name;
    
    [~,in.file_name_only] = fileparts(in.file_name); % removes the extension
    
    in.fullfile = fullfile(in.data_dir,in.file_name);
    
    % load the data
    load(in.fullfile);
    
    %% list the channels
    in.channels = [];
    for j = 1 : numel(EEG.chanlocs)
        in.channels{end+1} = EEG.chanlocs(j).labels;
    end
    %% list the conditions
    in.conditions = [];
    for j = 1 : numel(EEG.event)
        in.conditions(end+1) = EEG.event(j).type;
    end
    %     in.unique_conds = sort(unique(in.conditions));
    % use data.conds in case there are missing conditions for a particular
    % individual
    
    %% make some plots
    data.h = figure('Units','Normalized','Position',[.1 .1 .7 .8]);
    k = 0;
    for jj = 1 : numel(data.conds)
        for j = 1 : numel(data.use_channels)
            
            k = k + 1;
            if data.separate_plots
                subplot(numel(data.conds),numel(data.use_channels),k);
            else
                subplot(1,numel(data.use_channels),j);
            end
            
%             if ~data.separate_plots && jj > 1
%                 hold;
%             end
            
            tmp.channel_select = ismember(in.channels,data.use_channels{j});
            tmp.condition_select = in.conditions == data.conds(jj);
            tmp.erp = mean(EEG.data(tmp.channel_select,:,tmp.condition_select),3);
            plot(EEG.times,tmp.erp);
            
            if data.separate_plots || and(~data.separate_plots,jj == 1)
                hold;
                data.xlimits = [min(EEG.times) max(EEG.times)];
                
                set(gca,'YLim',data.ylimits,'Xlim',data.xlimits);
                set(get(gca,'Title'),'String',...
                    sprintf('%s: cond = %i, n = %i',data.use_channels{j},data.conds(jj),sum(tmp.condition_select)));
                set(get(gca,'XLabel'),'String','Latency (msec)');
                %             if j == 1 % this worked for the first plot when there were just two graphs
                if mod(k,2) % if it's an odd number
                    set(get(gca,'YLabel'),'String','Voltage (uV)');
                end
                % zero lines
                plot(data.xlimits,[0 0],'color',[.7 .7 .7],'LineStyle','-');
                plot([0 0],data.ylimits,'color',[.7 .7 .7],'LineStyle','-');
            end
        end
    end
    waitfor(data.h); % wait for the figure to be closed
    %% save the data?
    %     out.save_file = strtok(in.file_name_only,'save');
    %     out.save_dir = in.save_dir_matlab;
    %     if ~exist(out.save_dir,'dir')
    %         mkdir(out.save_dir);
    %     end
    %     out.save_fullfile = fullfile(out.save_dir,out.save_file);
    %
    %     save(out.save_fullfile,'EEG');
    %     fprintf('EEG data structure saved to ''.mat'' file:\n\t%s\n\t(%s)\n\n',...
    %         out.save_file,out.save_dir);
    
end
fprintf('Finished running: %s\n',mfilename);
