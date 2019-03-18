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
in.data_type = 'epoc';
% in.data_type = 'neuroscan';
in.data_dir = fullfile(in.project_dir,'data','eeglab',in.data_type);
% switch in.data_type
%     case 'epoc'
%         
%     case 'neuroscan'
%         in.data_dir = fullfile(in.project_dir,'data','eeglab',in.data_type);
% end

in.save_dir_eeglab = fullfile(in.project_dir,'data','eeglab',in.data_type);
if ~exist(in.save_dir_eeglab,'dir')
    mkdir(in.save_dir_eeglab);
end

step.eye_blink_timing = 1;
step.ica_remove = 1;

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

in.file_list = dir(fullfile(in.data_dir,'*1ica.set'));

for i = 20:21 % numel(in.file_list) %27 %21:23 %7:9 %1 : numel(in.file_list)
    in.file_name = in.file_list(i).name;
    
    [~,in.file_name_only] = fileparts(in.file_name); % removes the extension
    
    in.fullfile = fullfile(in.data_dir,in.file_name);
    
    
    EEG = eeg_checkset( EEG );
    [~,EEG.setname, ~] = fileparts(in.file_name); %'NN13save0filt';
    EEG = pop_loadset('filename',in.file_name,'filepath',in.data_dir);
    % update the EEG structure variable to include this setname
    EEG = eeg_checkset( EEG );
    
    % EEG = eeg_checkset( EEG );
    % EEG.setname='NN13save0filt';
    % EEG = pop_loadset('filename','NN13save0filt.set','filepath','/Users/mq20111600/Dropbox/nPeople/SoleneHameau/projects/nounnaming/data/eeglab/');
    % EEG = eeg_checkset( EEG );
    
    
    %% plot the data to check for eyeblink timing/location
    % Note: This is a manual step.
    if step.eye_blink_timing
        pop_eegplot( EEG, 1, 1, 1);
        waitfor(gcf);
    end
    
    %% Check Independent Components Analysis
    % see if we can find eyeblinks
    if step.ica_remove
        while 1
            fprintf('Opening ICA component plots:\n');
            eeglab redraw;
            switch size(EEG.data,1)
%                 case 34
%             EEG = pop_selectcomps(EEG, [1:33] );
                case {34,66}
                    ch_list = []; for j = 1 : numel(EEG.chanlocs); ch_list{end+1} = EEG.chanlocs(j).labels; end
                    ch_select = ~ismember(ch_list,{'HEOG','VEOG'});
                    EEG = pop_selectcomps(EEG, find(ch_select) );
                otherwise % epoc
                    EEG = pop_selectcomps(EEG,1:12);
            end
            waitfor(gcf);
            
            fprintf('\tClosed ICA compnent plots - storing EEGLAB data\n');
            [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
            EEG = eeg_checkset( EEG );
            %         waitfor(gcf);
            eeglab redraw;
            fprintf('Opening ICA reject window:\n');
            tmp_rejected = sprintf('%i components rejected',numel(find(EEG.reject.gcompreject)));
            
            EEG = pop_subcomp(EEG, find(EEG.reject.gcompreject),1);
%             fprintf('\twaiting for window to close...\n');
%             fprintf('\tNow accept\n');
%             waitfor(gcf);
%             waitfor(gcf);
%             fprintf('\tDon''t save...\n');
%             waitfor(gcf);
            
            fprintf('\tchecking whether rejection worked\n');
            % check if it has worked - correctly rejected eyeblinks
            pop_eegplot( EEG, 1, 1, 1);
            waitfor(gcf);
            
            eeglab redraw;
            
            % check if it's okay to move on
            tmp_rejected = sprintf('%i components rejected',numel(find(EEG.reject.gcompreject)));
            fprintf('%s\n',tmp_rejected);
            save_data = questdlg('Okay to save?','ICA rejected okay:','Yes','No','Yes');
            
            % if yes, save the data - and 'break' (end) the while loop,
            % moving on to next participant
            switch save_data
                case 'Yes'
                    
                    EEG.setname = [strtok(in.file_name_only,'save'),'save2ica_pruned']; %'NN13XXX';
                    EEG = eeg_checkset( EEG );
                    
                    out.save_file = [EEG.setname,'.set'];
                    out.save_dir = in.save_dir_eeglab;
                    out.save_fullfile = fullfile(out.save_dir,out.save_file);
                    
                    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',EEG.setname,'savenew',out.save_fullfile,'gui','off');
                    fprintf('Saved to: %s (%s)\n',out.save_file,out.save_fullfile);
                    
                    %                     [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','NN13save2ica_pruned','savenew','/Users/mq20111600/Dropbox/nPeople/SoleneHameau/projects/nounnaming/data/eeglab/NN13save2ica_pruned.set','gui','off');
                    ALLEEG = pop_delset( ALLEEG, [1:2] );
                    eeglab redraw;
                    break
                case 'No'
                    % refresh the data
                    ALLEEG = pop_delset( ALLEEG, [1] );
                    EEG = pop_loadset('filename',in.file_name,'filepath',in.data_dir);
                    % update the EEG structure variable to include this setname
                    EEG = eeg_checkset( EEG );
                    eeglab redraw;
            end
        end
        
    end
    
    % out.save_dir = in.save_dir_eeglab;
    % out.save_file = [EEG.setname,'.set'];
    % out.save_fullfile = fullfile(out.save_dir,out.save_file);
    % % and then save the data
    % [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',EEG.setname,...
    %     'savenew',out.save_fullfile,'overwrite','on','gui','off');
    % % [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','NN13save0filt','savenew','/Users/mq20111600/Dropbox/nPeople/SoleneHameau/projects/nounnaming/data/eeglab/NN13save0filt.set','overwrite','on','gui','off');
    % eeglab redraw;
    
end
fprintf('Finished running: %s\n',mfilename);
