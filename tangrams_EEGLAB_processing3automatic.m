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

% 2018-Nov-16 NAB
% Updating for Martyn & me to use for Sara Fernandez Guinea's 'Tangrams'
% project.
clear
clc
%% define some settings
in.user = 'martyn' ;%'nic'%;
% in.user = 'solene';
switch in.user
    case 'martyn'
        in.project_dir = '/Volumes/DATA/NicBadcock/projects/tangrams';
        in.eeglab_dir = fullfile(in.project_dir,'scripts','eeglab14_1_2b');
        %     case 'nic'
        %         in.project_dir = '/Users/mq20111600/Dropbox/nPeople/SoleneHameau/projects/nounnaming';
        %         in.eeglab_dir = '/Applications/eeglab13_4_4b/';
        %     case 'solene'
        %         in.project_dir = 'C:\Users\43105041\Documents\nounnaming\'; %'C:\Users\43105041\Dropbox\SoleneHameau\projects\nounnaming';
        %         in.eeglab_dir = 'C:\Users\43105041\Documents\nounnaming\eeglab14_1_1b';
end


% 

% in.data_type = 'epoc';
in.data_type = 'neuroscan';
in.data_dir = fullfile(in.project_dir,'data','eeglab',in.data_type);

% slightly different electrode selections for neuroscan only
% data.analysis = 'neuroscan';
data.analysis = 'comparison';
switch in.data_type
    case 'epoc'
        % has to be the comparison
data.analysis = 'comparison';
end

in.save_dir_eeglab = fullfile(in.project_dir,'data','eeglab',data.analysis,in.data_type);

if ~exist(in.save_dir_eeglab,'dir')
    mkdir(in.save_dir_eeglab);
end
% in.data_dir = fullfile(in.project_dir,'data','eeglab');

% in.save_dir_eeglab = in.data_dir; %fullfile(in.project_dir,'data','eeglab');
in.save_dir_matlab = fullfile(in.project_dir,'data','matlab',data.analysis,in.data_type);

if ~exist(in.save_dir_matlab,'dir')
    mkdir(in.save_dir_matlab);
end

data.epoch = [-.2 1]; % lower and upper epoch bounds in seconds
data.baseline = [data.epoch(1)*100 0]; %[-100 0]; lower and upper bounds of basline in milliseconds
data.reject_limits = [-100 100];
% data.electrode_labels = {'FP1','FP2','F3','F4','C3','C4','P3','P4',...
%     'O1','O2','F7','F8','T7','T8','P7','P8','FZ','CZ','PZ','OZ',...
%     'FC3','FC4','CP3','CP4','FT7','FT8','TP7','TP8','M2','FCZ',...
%     'HEOG','VEOG','CPZ'};

%% rejection electrodes
% which channels should be considerd when looking for extreme values
% only the ones used for the ERPs
% - this might differ for the system comparisons - different matches for
% the two

switch data.analysis
    case 'neuroscan'
        data.reject_electrodes = {'FC3','FC4','CP3','CP4',...
            'P3','P4','O1','O2'};
        % planning to average P & O here as we don't have a PO channel
    case 'comparison'
        switch in.data_type
            case 'neuroscan'
                data.reject_electrodes = {'FC3','FC4',...
                    'P7','P8','O1','O2'};
            case 'epoc'
                % There's no centroparietal for this system
                data.reject_electrodes = {'F3','F4','P7','P8','O1','O2'};
        end
end

%% first thing: Open EEGLAB
% copied this from the eeglabhist1session.m file

% check if the eeglab m file is on the MATLAB path
if ~exist('eeglab.m','file')
    % If not, change the diretory to it's location, and then it can be run
    cd(in.eeglab_dir);
end
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%% Import a file
% file name - this will eventually be within a loop
% in.file_name = 'NN13.cnt';

in.file_list = dir(fullfile(in.data_dir,'*2ica_pruned.set'));

for i = 1 : numel(in.file_list)
    in.file_name = in.file_list(i).name;
    
    [~,in.file_name_only] = fileparts(in.file_name); % removes the extension
    
    in.fullfile = fullfile(in.data_dir,in.file_name);
    
    
    EEG = eeg_checkset( EEG );
    [~,EEG.setname, ~] = fileparts(in.file_name); %'NN13save0filt';
    EEG = pop_loadset('filename',in.file_name,'filepath',in.data_dir);
    % update the EEG structure variable to include this setname
    EEG = eeg_checkset( EEG );
    eeglab redraw;
    
    
    %      EEG = pop_epoch( EEG, {  }, [-0.1 0.8], 'newname', 'NN13save3ica_pruned_epochs', 'epochinfo', 'yes');
    %     [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    %     EEG = eeg_checkset( EEG );
    %     EEG = pop_rmbase( EEG, [-100    0]);
    %     [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off');
    %     EEG = eeg_checkset( EEG );
    
    
    EEG.setname = [strtok(in.file_name_only,'save'),'save3ica_pruned_epochs']; %'NN13XXX';
    EEG = eeg_checkset( EEG );
    
    
    
    %% epoch + baseline correction
    
    EEG = pop_epoch( EEG, {  }, data.epoch, 'newname', EEG.setname, 'epochinfo', 'yes');
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
    EEG = pop_rmbase( EEG, data.baseline);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off');
    EEG = eeg_checkset( EEG );
    
    %% remove extreme values
    data.channels = [];
    for j = 1 : numel(EEG.chanlocs)
        data.channels{end+1} = EEG.chanlocs(j).labels;
    end
    data.reject_logical = ismember(data.channels,data.reject_electrodes);
    data.reject_numbers = find(data.reject_logical);
    
    %    EEG = pop_eegthresh(EEG,1,[1:30 33] ,-150,150,-0.1,0.799,0,1);
    %    EEG = pop_rejepoch( EEG, [16 34 84 91 131] ,0);
    
    
    EEG = pop_eegthresh(EEG,1,data.reject_numbers,....
        data.reject_limits(1),data.reject_limits(2),...
        data.epoch(1),data.epoch(2)-.001,0,1);
    
    EEG.setname = [strtok(in.file_name_only,'save'),'save4ica_pruned_epochs_extreme']; %'NN13XXX';
    EEG = eeg_checkset( EEG );
    
    %% save the data
    out.save_file = [EEG.setname,'.set'];
    out.save_dir = in.save_dir_eeglab;
    out.save_fullfile = fullfile(out.save_dir,out.save_file);
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',EEG.setname,'savenew',out.save_fullfile,'gui','off');
    
    %     [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','NN13save2ica_pruned','savenew','/Users/mq20111600/Dropbox/nPeople/SoleneHameau/projects/nounnaming/data/eeglab/NN13save2ica_pruned.set','gui','off');
    ALLEEG = pop_delset( ALLEEG, [1:2] );
    eeglab redraw;
    
    
    out.save_file = strtok(in.file_name_only,'save');
    out.save_dir = in.save_dir_matlab;
    if ~exist(out.save_dir,'dir')
        mkdir(out.save_dir);
    end
    out.save_fullfile = fullfile(out.save_dir,out.save_file);
    
    save(out.save_fullfile,'EEG');
    fprintf('EEG data structure saved to ''.mat'' file:\n\t%s\n\t(%s)\n\n',...
        out.save_file,out.save_dir);
    
end
fprintf('Finished running: %s\n',mfilename);
