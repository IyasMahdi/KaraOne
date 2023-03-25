
%PRE-PROCEESING OF RAW EEG RECORDINGS FOR KARA ONE DATASET

addpath(genpath('C:\Users\Mahdi Rabih Berair\Desktop\KARA\Recordings'));
addpath(genpath('C:\Users\Mahdi Rabih Berair\Desktop\KARA\Attached code'))

folders = {'MM05','MM10','MM11','MM16','MM18','MM19', 'MM21','P02'};


data_path = 'C:\Users\Mahdi Rabih Berair\Desktop\KARA\Recordings' ;


for x=1:length(folders)


    % Loading raw data (cnt) of the SUBJECT
    disp(['Pre-processing raw data of suject: ' folders{x}]);
    folder = [data_path '/' folders{x}];
    D = dir([folder '/*.cnt']);
    cnt_fn = [folder '/' D(1).name];
    EEG = pop_loadcnt(cnt_fn);

    % Removing unwanted channels 
    
    EEG.data(69, :) = [];
    EEG.data(68, :) = [];
    EEG.data(67, :) = [];
    EEG.data(43, :) = [];
    EEG.data(33, :) = [];
    EEG.data = EEG.data(1:64, :);
    EEG.nbchan = 64;
    
    %Filtering the DATA, Band pass 1-50hz
    EEG = pop_eegfiltnew(EEG,1,50);

    pop_eegplot(EEG,1,1,1);
    % EYE-MOVEMENT CORRECTION USING Hinfinity REGRESSION
    EEG = pop_hinftv_regression(EEG,[63 64],3,5e-3,1e-5,1.5,[]);

    % REMOVAL OF OCCULAR CHANNELS (VEO HEO = 63 64 after first channel
    % removal************
    EEG.data(64, :) = [];
    EEG.data(63, :) = [];
    EEG.data = EEG.data(1:62, :);
    EEG.nbchan = 62;
    
    pop_eegplot(EEG,1,1,1);

    % ADDING CHANNEL LOCATIONS, a window will pop-op, it is recommended to
    % optimize head centre
    chanlocs = struct('labels', {'FP1' 'FPZ' 'FP2' 'AF3' 'AF4' 'F7' 'F5' 'F3' 'F1' 'FZ' 'F2' 'F4' 'F6' 'F8' 'FT7' 'FC5' 'FC3' 'FC1' 'FCZ' 'FC2' 'FC4' 'FC6' 'FT8' 'T7' 'C5' 'C3' 'C1' 'CZ' 'C2' 'C4' 'C6' 'T8' 'TP7' 'CP5' 'CP3' 'CP1' 'CPZ' 'CP2' 'CP4' 'CP6' 'TP8' 'P7' 'P5' 'P3' 'P1' 'PZ' 'P2' 'P4' 'P6' 'P8' 'PO7' 'PO5' 'PO3' 'POZ' 'PO4' 'PO6' 'PO8' 'CB1' 'O1' 'OZ' 'O2' 'CB2'});
    EEG.chanlocs.labels
    EEG.chanlocs = pop_chanedit(chanlocs);
    

    


    % Subtracting the mean values from the channels to reeuce noise (Common
    % Average Reference)
    data = EEG.data;
    data = detrend(data, 'constant');
    EEG.data = data;
    

    % Decomposing using ICA
    EEG = pop_runica(EEG,'runica', 'extended',1);


    % Labelling and ploting artifacts for visual inspection NOTE DOWN
    % ARTIFACTS
    EEG = iclabel(EEG);
    pop_viewprops( EEG, 0,[1:62], {'freqrange', [1 50]}, {}, 1, 'ICLabel'); %#ok<NBRAK2>


    % Removing artifacts
    EEG = pop_subcomp(EEG);


    pop_eegplot(EEG,1,1,1);


    % Segmenting the data using only thinking_inds and creating a structure
    % with prompts, EEG(thinking indices),DATA

    kinect_folder = [folder '/kinect_data']; %Required for extracting prompts
    labels_fn = [kinect_folder '/labels.txt'];

    data = EEG.data;
    load([folder '/epoch_inds.mat']);
    
    thinking_mats = split_data(thinking_inds, data); %EEG data segemnted by trial
    epoch_data.thinking_mats = thinking_mats;

    % Getting the prompts.
    prompts = table2cell(readtable(labels_fn,'Delimiter',' ','ReadVariableNames',false));


     % Creating  the struct. ADD SAVING
    EEG_Data = struct();
    EEG_Data.prompts = prompts;
    EEG_Data.EEG = thinking_mats;
    EEG_Data.Data = data;

    % WINDOWING to 500ms frames with 250ms overlap
    Data = EEG_Data.EEG; 

    samples = 5000; %expected samples per trial
    window_size = .1; 
    window_samples = samples*window_size; %expected samples per window
    window_ratio = samples/window_samples;
    n_windows = window_ratio*2 - 1; %Total no. of windows
    

    for i = 1:length(Data) 
        
        trial = Data(i); %iterates through trials
        trial_data = cell2mat(trial); %data conversion

        for p = 1:(n_windows)
            
            n_bins = round(length(trial_data)/window_ratio); %actual no. of samples in window
            ovlp = n_bins/2; %overlap
            
            window_vec{1} = trial_data(1:62,1:n_bins);%Compute first window 
            
            j = round((n_bins/2) + 1);
            k = round(n_bins + ovlp);
            m = 1;
            
            for l = 1:(n_windows - 2)
                %Compute window 2 to n_windows - 1
                n = l + 1;
                window_vec{n} = trial_data(1:62,j:k);
                
                j = ovlp*(m+1); 
                j = round(j + 1);
                k =  round(k + n_bins/2); 
               
                
                m = m+1;
            end
            
            window_vec{n_windows} = trial_data(1:62,j:end); %Add final window to vector
            all_trials{i} = window_vec; %iterates to provide full vector 
           
            
        end
          
    end

    %creating a folder to save windowed dataset
    mkdir([data_path '/' folders{x} '/PP-WDATA']);
    output_folder = [data_path '/' folders{x}];
    save([output_folder '/PP-WDATA/P1WDATA.mat'], 'all_trials'); %Trial


end
