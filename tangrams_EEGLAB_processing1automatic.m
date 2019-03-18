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

% 2018-Nov-14 NAB
% Updating for Martyn & me to use for Sara Fernandez Guinea's 'Tangrams'
% project.

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
in.data_type = 'epoc';
% in.data_type = 'neuroscan';
switch in.data_type
    case 'epoc'
        in.data_dir = fullfile(in.project_dir,'data','mat',in.data_type);
    case 'neuroscan'
        in.data_dir = fullfile(in.project_dir,'data','raw',in.data_type);
end

in.save_dir_eeglab = fullfile(in.project_dir,'data','eeglab',in.data_type);
if ~exist(in.save_dir_eeglab,'dir')
    mkdir(in.save_dir_eeglab);
end

% set the channel location file for later import
% in.channel_dir = fullfile(in.project_dir,'setup_files');
% in.channel_file = 'EasyCap33withCPz.asc';
% in.channel_fullfile = fullfile(in.channel_dir,in.channel_file);

% filter settings
epoc.Hertz = 253.4;
data.filter = [.1 30];
data.downsample = 256;

% which steps should we run?
step.filter = 1;
step.downsample = 1;
switch in.data_type
    case 'epoc'
        step.downsample = 0;
end
%% first thing: Open EEGLAB
% copied this from the eeglabhist1session.m file

% check if the eeglab m file is on the MATLAB path
if ~exist('eeglab.m','file')
    % If not, change the diretory to it's location, and then it can be run
    cd(in.eeglab_dir);
    addpath(genpath(in.eeglab_dir));
end
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%% Import a file
% file name - this will eventually be within a loop
% in.file_name = 'NN13.cnt';
switch in.data_type
    case 'epoc'
       in.file_list_all = dir(fullfile(in.data_dir,'*.mat'));
    case 'neuroscan'
in.file_list_all = dir(fullfile(in.data_dir,'*.dap'));
end
in.file_list = [];
for i = 1 : numel(in.file_list_all)
    if isempty(strfind(in.file_list_all(i).name,'._'))
        in.file_list{end+1} = in.file_list_all(i).name;
    end
end

for i = 3 : numel(in.file_list)
    fprintf('Importing: %s\n',in.file_list{i});
    in.file_name = in.file_list{i}; %in.file_list(i).name;
    
    [~,in.file_name_only] = fileparts(in.file_name); % removes the extension
    
    in.fullfile = fullfile(in.data_dir,in.file_name);
    %     EEG = loadcurry('/Users/mq20111600/Google Drive/nPeople/SaraFernandezGuinea/projects/vis_memory/data/raw/neuroscan/PY32003.dap', 'CurryLocations', 'False');
    
    switch in.data_type
        case 'epoc'
%             EEG = pop_importdata('dataformat','matlab','nbchan',15,'data',n.fnl2open,'setname',n.set_name,'srate',epoc.Hertz,'pnts',0,'xmin',0);
            
            EEG = pop_importdata('dataformat','matlab','nbchan',15,'data',in.fullfile,'srate',254.3,'pnts',0,'xmin',0);
            %         [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','test','gui','off');
            EEG = eeg_checkset( EEG );
            EEG = pop_chanevent(EEG, 15,'edge','leading','edgelen',0);
            %         [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
            EEG = eeg_checkset( EEG );
            EEG = pop_editset(EEG, 'chanlocs', '/Volumes/DATA/NicBadcock/projects/tangrams/setup_files/emotiv.ced');
            %         [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
            %         EEG = eeg_checkset( EEG );
        case 'neuroscan'
            EEG = loadcurry(fullfile(in.data_dir,in.file_name), 'CurryLocations', 'False');
    end%     EEG = pop_loadcnt(in.fullfile, 'dataformat', 'auto', 'memmapfile', '');
    % EEG = pop_loadcnt('/Users/mq20111600/Dropbox/nPeople/SoleneHameau/projects/nounnaming/data/raw/NN13.cnt' , 'dataformat', 'auto', 'memmapfile', '');
    % rename the set
    
    EEG.setname = in.file_name_only;
    % EEG.setname = 'NN13';
    % update the EEG structure variable to include this setname
    EEG = eeg_checkset( EEG );
    
    %% Downsample
    if step.downsample
        EEG = pop_resample( EEG, data.downsample);
    end
    %     %% Set the channel names
    %     EEG = pop_editset(EEG, 'chanlocs', in.channel_fullfile);
    %
    %     % EEG = pop_editset(EEG, 'chanlocs', '/Users/mq20111600/Dropbox/nPeople/SoleneHameau/projects/nounnaming/setup_files/EasyCap33withCPz.asc');
    %     EEG = eeg_checkset( EEG );
    %
    %     eeglab redraw;
    
    %% Bandpass filter
    if step.filter
        EEG = pop_eegfiltnew(EEG, [], data.filter(end), 440, 0, [], 0);
        EEG = eeg_checkset( EEG );
        EEG = pop_eegfiltnew(EEG, [], data.filter(1), 33000, true, [], 0);
    end
    EEG.setname = [in.file_name_only,'save0filt']; %'NN13save0filt';
    EEG = eeg_checkset( EEG );
    
    out.save_dir = in.save_dir_eeglab;
    out.save_file = [EEG.setname,'.set'];
    out.save_fullfile = fullfile(out.save_dir,out.save_file);
    % and then save the data
       [ALLEEG, EEG] = pop_newset(ALLEEG, EEG, 1,'setname',EEG.setname,...
           'savenew',out.save_fullfile,'overwrite','on','gui','off');
    % [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','NN13save0filt','savenew','/Users/mq20111600/Dropbox/nPeople/SoleneHameau/projects/nounnaming/data/eeglab/NN13save0filt.set','overwrite','on','gui','off');
    %     eeglab redraw;
    
    %% Independent Components Analysis
    % see if we can find eyeblinks
    switch in.data_type
        case 'epoc'
            in.data_dir = fullfile(in.project_dir,'data','mat',in.data_type);
            %             [1:4 6:9 11:14]; % skipping T7 & T8
            %             '1   2   3   4   6   7   8   9  11  12  13  14'
            
            EEG = pop_runica(EEG, 'icatype','runica','chanind',[1:4 6:9 11:14]);
            % 2013 evn adults auditory syntax
            %             EEG = pop_runica(EEG, 'icatype','runica','dataset',1,'options',{'extended' 1},'chanind',[1:6 9:14]);
        case 'neuroscan'
            EEG = pop_runica(EEG, 'extended',1,'interupt','on');
    end
    %    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    
    EEG.setname = [in.file_name_only,'save1ica']; %'NN13save0filt';
    EEG = eeg_checkset( EEG );
    
    out.save_file = [EEG.setname,'.set'];
    out.save_fullfile = fullfile(out.save_dir,out.save_file);
    
    EEG = pop_saveset( EEG, 'filename',out.save_file,'filepath',out.save_dir);
    %    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    % EEG = pop_saveset( EEG, 'filename','NN13save1ica.set','filepath','/Users/mq20111600/Dropbox/nPeople/SoleneHameau/projects/nounnaming/data/eeglab/');
    % [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    %     eeglab redraw;
    %% close the file/data at the end of each loop
    % might not need this
end
%% plot the data to check for eyeblink timing/location
% Note: This is a manual step.
% pop_eegplot( EEG, 1, 1, 1);