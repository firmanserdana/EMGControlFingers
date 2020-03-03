classdef SimoneQuattrocentoMod < handle
    
    properties(GetAccess = 'public', SetAccess = 'public')
        %% EMG channel
        GainFactor = 5/2^16/150*1000;       % Provide amplitude in mV
        % 5 is the ADC input swing
        % 2^16 is the resolution
        % 150 is the gain
        % 1000 to get the mV
        AuxGainFactor = 5/2^16/0.5;         % Gain factor to convert Aux Channels in V
        
        %property to store the number of column of the  correspondent EMG
        %Channel
        Autoclock=[];
        Autoclock2=[];
        y = audioread('Sound.wav');
        IN12 = [];
        IN34 = [];
        IN56 = [];
        IN78 = [];
        MLT1 = [];
        MLT2 = [];
        MLT3 = [];
        MLT4 = [];
        
        SaveData            % Property that will store the Recording Data after Loading
        fsamp             % Sample Frequency in Hz       
        NumEMGChannel       % Number of EMG Channel used in the acquisition  
        EMGChannel          % Vector store all the column coordinates of the active channel
        
        bufferSize = 2;   % length in seconds of the visualization and recording buffer 
        bufferSample;       % length in sample of the tcpip buffer
        
        % Visualization Buffer
        bufferEMG           % size of each buffer in seconds = bufferSize
        bufferAUX
        bufferAccesories
        buffer  % bufferEMG + bufferAUX + bufferAccesories , for myoDynamics
      
        
        % GUI
        isPlot = true;       % Do you want to use the GUI ?
        GUI         % store all the GUI element
        GUIsett     % store all the Synchronization GUI element 
        Dir = 'savedData';        % Path and folder to save data
        LineChannel % Line object for the real time plot of each EMG
        LineAux     % line object for the real time plot of each AUX
        Figure      % real time plot EMG figure 
        FigureAux   % real time plot AUX figure 
        TimePlot = 1;        % time that you want to see in the figure, MAXIMUM EQUAL TO bufferSize 
         
        %Acquisition and Recording Flag
        isAcquiring = false;
        isRecording = false;
        isConnected = false;
        isConnectedDevice = false;
        isSync = false;
        isVisualizing = false;
        
        %% Property to set the 400 msg (Configuration String)
        
        %F samp selector for Fsamp (ConfigString) and FsampVal (BufferSetting)
        FSsel = 2;              
        % FSsel  = 1 -> 512 Hz
        % FSsel  = 2 -> 2048 Hz
        % FSsel  = 3 -> 5120 Hz
        % FSsel  = 4 -> 10240 Hz
        % Channels numbers selector for NumChan (ConfigString) and NumChanVal (BufferSetting)
        NCHsel = 1;             
        % NCHsel = 1 -> IN1, IN2, MULTIPLE IN1, AUX IN
        % NCHsel = 2 -> IN1..IN4, MULTIPLE IN1, MULTIPLE IN2, AUX IN
        % NCHsel = 3 -> IN1..IN6, MULTIPLE IN1..MULTIPLE IN3, AUX IN
        % NCHsel = 4 -> IN1..IN8, MULTIPLE IN1..MULTIPLE IN4, AUX IN
        
        %ActiveString, not used?
        
%--------------------- AN_OUT_IN_SEL BYTE -------------------%
        AnOutSource = 12;        % Source input for analog output:
        % 0 = the analog output signal came from IN1
        % 1 = the analog output signal came from IN2
        % 2 = the analog output signal came from IN3
        % 3 = the analog output signal came from IN4
        % 4 = the analog output signal came from IN5
        % 5 = the analog output signal came from IN6
        % 6 = the analog output signal came from IN7
        % 7 = the analog output signal came from IN8
        % 8 = the analog output signal came from MULTIPLE IN1
        % 9 = the analog output signal came from MULTIPLE IN2
        % 10 = the analog output signal came from MULTIPLE IN3
        % 11 = the analog output signal came from MULTIPLE IN4
        % 12 = the analog output signal came from AUX IN
        AnOutGain = bin2dec('00000000');
        % bin2dec('00000000') = Gain on the Analog output equal to 1
        % bin2dec('00010000') = Gain on the Analog output equal to 2
        % bin2dec('00100000') = Gain on the Analog output equal to 4
        % bin2dec('00110000') = Gain on the Analog output equal to 16
 %------------------AN_OUT_CH_SEL BYTE----------------------------    
        AnOutChan = 0; %Channel for analog output from 0 to 63 max--> 0 means first channel of the IN/MLT, 63 last channel   

        % initialization of the Configuration String
        ConfString; % Store the Configuration String during the setting phase 
        SettingString; % store the Final Configuration String sent to the 400
        isSet = false; % flag to monitor if the Configuration string is set or not
        
        %% TCP data
        tcpScoket % store the TCPIP SocKet object used in the comunication 
        numCall = 0;         % count the number of Callback from the TCPIP BufferFull, inizialized on each save
        CallTimes = 0;       % count the number of CallBack from the Start Recording
        StopRecCall = false; % Flag to save One last tcpip buffer, after Recording STOP
        StopRecNum = 0;      % counter to save two more message from the 400 when the Rec is stopped to consider the delay;
        
        % Synchronization
        Arduino
        isArduinoConnect
        AcqClock = zeros(2,6);  % first row Start Acq and second row Stop
        RecClock = zeros(2,6);
       
        % file
        File
        FileHeader      % HEADER:  NChannel, Nsamples, fsamp. 
                        % first 3 element of the file 
        FileName
        Path
        
        % myoDynamics interfacing
        acqConfig
        extSave = false;
        appendSave = false;
        prot
        prot_flag = false;
        countData = 0;
        duration = 0;
        saving = false;
    end
    
    properties(Constant)
        %% TCP data
        TCPPort = 23456;
        IPaddress = '169.254.1.10';
        %% SaveData
        SaveDataLabel ={['IN1','IN2','MULTIPLE1','AUX 1-16','8 CH_ACCESSORIES'],...
            ['IN1','IN2','IN3','IN4','MULTIPLE1','MULTIPLE 2','AUX 1-16','8 CH_ACCESSORIES'],...
            ['IN1','IN2','IN3','IN4','IN5','IN6','MULTIPLE1','MULTIPLE 2','MULTIPL 3','AUX 1-16','8 CH_ACCESSORIES'],...
            ['IN1','IN2','IN3','IN4','IN5','IN6','IN7','IN8','MULTIPLE1','MULTIPLE 2','MULTIPL 3','MULTIPLE 4','AUX 1-16','8 CH_ACCESSORIES']};
        
        %% Quattrocento msg
        Stop=bin2dec('10000000');     %ConfString(1) to STOP data transfer
        RecOn=bin2dec('00100000');    % add to ConfString(1) not active, to activate Trigger OUT='00100000'
        FreqMode= bin2dec('00010100');
         
        %--------------------- ACQ_SETT BYTE -------------------%
        % Sampling frequency values
        FsampVal = [512 2048 5120 10240];           %USEFUL FOR TCP BUFFER DIMENSION
        Fsamp = [0 8 16 24];    % Codes to set the sampling frequency
        NumChanVal = [120 216 312 408];             %USEFUL FOR TCP BUFFER DIMENSION
        NumChan = [0 2 4 6];    % Codes to set the number of channels
        NumAUXChannel = 16;
        NumAccessoriesCh = 8;
          
    end
    
    methods (Access = public)
        %% Costructor
        function obj = SimoneQuattrocentoMod(varargin)
            
            if nargin > 0
                if isstruct(varargin{1})
                    acqConfig = varargin{1};
                    for jjj = 1:numel(acqConfig)
                        if strcmp(acqConfig(jjj).Device,'Quattrocento EMG Amp')
                            obj.isPlot = acqConfig(jjj).useGUI;
                        end
                    end
                end
            end
            
            % Creation of the dir in which Data will be saved
            if isempty(dir('savedData'))
                mkdir 'savedData'
            end            
            obj.Path = pwd;
            obj.Path = [obj.Path '\savedData\'];
            
            % Main GUI creation 
            obj.GUI=QuattrocentoGUI(obj); 
            %wait until the user want too close the App
%             uiwait(obj.GUI.UIFigure);
            obj.isConnected = true;
        end
        
         %% Create MAIN GUI: UIFigure and components 
        function GUI=QuattrocentoGUI(obj)
          
            % Create UIFigure
            GUI.UIFigure = uifigure;
            GUI.UIFigure.Position = [100 100 1014 622];
            GUI.UIFigure.Name = 'UI Figure';

            % Create TabGroup
            GUI.TabGroup = uitabgroup(GUI.UIFigure);
            GUI.TabGroup.Position = [1 0 1013 623];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                      Setting Tab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Create SettingsTab
            GUI.SettingsTab = uitab(GUI.TabGroup);
            GUI.SettingsTab.Title = 'Settings';

            % Create SensorSelectionandConfigurationPanel
            GUI.SensorSelectionandConfigurationPanel = uipanel(GUI.SettingsTab);
            GUI.SensorSelectionandConfigurationPanel.Title = 'Sensor Selection and Configuration';
            GUI.SensorSelectionandConfigurationPanel.Position = [9 58 997 530];

            % Create ChooseSingleandMultipleInputAdaptorLabel
            GUI.ChooseSingleandMultipleInputAdaptorLabel = uilabel(GUI.SensorSelectionandConfigurationPanel);
            GUI.ChooseSingleandMultipleInputAdaptorLabel.Position = [430 486 229 22];
            GUI.ChooseSingleandMultipleInputAdaptorLabel.Text = 'Choose Single and Multiple Input Adaptor';

            % Create IN1
            GUI.IN1 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.IN1.Text = 'IN 1';
            GUI.IN1.Position = [54 464 44 22];

            % Create IN2
            GUI.IN2 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.IN2.Text = 'IN 2';
            GUI.IN2.Position = [127 464 44 22];

            % Create IN3
            GUI.IN3 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.IN3.Text = 'IN 3';
            GUI.IN3.Position = [200 464 44 22];

            % Create IN4
            GUI.IN4 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.IN4.Text = 'IN 4';
            GUI.IN4.Position = [273 464 44 22];

            % Create IN5
            GUI.IN5 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.IN5.Text = 'IN 5';
            GUI.IN5.Position = [346 464 44 22];

            % Create IN6
            GUI.IN6 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.IN6.Text = 'IN 6';
            GUI.IN6.Position = [418 464 44 22];

            % Create IN7
            GUI.IN7 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.IN7.Text = 'IN 7';
            GUI.IN7.Position = [490 464 44 22];

            % Create IN8
            GUI.IN8 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.IN8.Text = 'IN 8';
            GUI.IN8.Position = [562 464 44 22];

            % Create MULTI1
            GUI.MULTI1 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.MULTI1.Text = 'MULTI 1';
            GUI.MULTI1.Position = [626 464 67 22];

            % Create MULTI2
            GUI.MULTI2 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.MULTI2.Text = 'MULTI 2';
            GUI.MULTI2.Position = [720 464 67 22];

            % Create MULTI3
            GUI.MULTI3 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.MULTI3.Text = 'MULTI 3';
            GUI.MULTI3.Position = [814 464 67 22];

            % Create MULTI4
            GUI.MULTI4 = uicheckbox(GUI.SensorSelectionandConfigurationPanel);
            GUI.MULTI4.Text = 'MULTI 4';
            GUI.MULTI4.Position = [907 464 67 22];

            % Create AnalogFilterPanel
            GUI.AnalogFilterPanel = uipanel(GUI.SensorSelectionandConfigurationPanel);
            GUI.AnalogFilterPanel.Title = 'Analog Filter';
            GUI.AnalogFilterPanel.Position = [12 8 240 223];

            % Create LowpassCutoffHzDropDownLabel
            GUI.LowpassCutoffHzDropDownLabel = uilabel(GUI.AnalogFilterPanel);
            GUI.LowpassCutoffHzDropDownLabel.HorizontalAlignment = 'right';
            GUI.LowpassCutoffHzDropDownLabel.Position = [49 142 116 22];
            GUI.LowpassCutoffHzDropDownLabel.Text = 'Low pass Cutoff [Hz]';

            % Create LPcutoff
            GUI.LPcutoff = uidropdown(GUI.AnalogFilterPanel);
            GUI.LPcutoff.Items = {'4400', '900', '500', '130'};
            GUI.LPcutoff.ItemsData = {3, 2, 1, 0};
            GUI.LPcutoff.Position = [57 117 100 22];
            GUI.LPcutoff.Value = 1;

            % Create HighpassCutoffHzDropDownLabel
            GUI.HighpassCutoffHzDropDownLabel = uilabel(GUI.AnalogFilterPanel);
            GUI.HighpassCutoffHzDropDownLabel.HorizontalAlignment = 'right';
            GUI.HighpassCutoffHzDropDownLabel.Position = [47 66 119 22];
            GUI.HighpassCutoffHzDropDownLabel.Text = 'High pass Cutoff [Hz]';

            % Create HPcutoff
            GUI.HPcutoff = uidropdown(GUI.AnalogFilterPanel);
            GUI.HPcutoff.Items = {'0.3', '10', '100', '200'};
            GUI.HPcutoff.ItemsData = {0, 1, 2, 3};
            GUI.HPcutoff.Position = [57 41 100 22];
            GUI.HPcutoff.Value = 1;

            % Create AcquisitionParameterPanel
            GUI.AcquisitionParameterPanel = uipanel(GUI.SensorSelectionandConfigurationPanel);
            GUI.AcquisitionParameterPanel.Title = 'Acquisition Parameter';
            GUI.AcquisitionParameterPanel.Position = [755 8 229 223];

            % Create AcquisitionModeDropDownLabel
            GUI.AcquisitionModeDropDownLabel = uilabel(GUI.AcquisitionParameterPanel);
            GUI.AcquisitionModeDropDownLabel.HorizontalAlignment = 'right';
            GUI.AcquisitionModeDropDownLabel.Position = [67 142 97 22];
            GUI.AcquisitionModeDropDownLabel.Text = 'Acquisition Mode';

            % Create AcquisitionMode
            GUI.AcquisitionMode = uidropdown(GUI.AcquisitionParameterPanel);
            GUI.AcquisitionMode.Items = {'Monopolar', 'Differential', 'Bipolar'};
            GUI.AcquisitionMode.ItemsData = {0, 1, 2};
            GUI.AcquisitionMode.Position = [65 117 100 22];
            GUI.AcquisitionMode.Value = 0;

            % Create SampleFrequencyDropDownLabel
            GUI.SampleFrequencyDropDownLabel = uilabel(GUI.AcquisitionParameterPanel);
            GUI.SampleFrequencyDropDownLabel.HorizontalAlignment = 'right';
            GUI.SampleFrequencyDropDownLabel.Position = [62 66 106 22];
            GUI.SampleFrequencyDropDownLabel.Text = 'Sample Frequency';

            % Create SampleF
            GUI.SampleF = uidropdown(GUI.AcquisitionParameterPanel);
            GUI.SampleF.Items = {'512', '2048', '5120', '10240'};
            GUI.SampleF.ItemsData = {1, 2, 3, 4};
            GUI.SampleF.Position = [65 41 100 22];
            GUI.SampleF.Value = 2;
%----------------------------- Channel Input Setting ---------------------%
            
            % Create SingleInputSettingPanel
            GUI.SingleInputSettingPanel = uipanel(GUI.SensorSelectionandConfigurationPanel);
            GUI.SingleInputSettingPanel.Title = 'Single Input Setting';
            GUI.SingleInputSettingPanel.Position = [12 238 972 221];

            % Create IN1Label
            GUI.IN1Label = uilabel(GUI.SingleInputSettingPanel);
            GUI.IN1Label.Position = [84 170 28 22];
            GUI.IN1Label.Text = 'IN 1';

            % Create IN2Label
            GUI.IN2Label = uilabel(GUI.SingleInputSettingPanel);
            GUI.IN2Label.Position = [193 170 28 22];
            GUI.IN2Label.Text = 'IN 2';

            % Create IN3Label
            GUI.IN3Label = uilabel(GUI.SingleInputSettingPanel);
            GUI.IN3Label.Position = [304 170 28 22];
            GUI.IN3Label.Text = 'IN 3';

            % Create IN4Label
            GUI.IN4Label = uilabel(GUI.SingleInputSettingPanel);
            GUI.IN4Label.Position = [415 170 28 22];
            GUI.IN4Label.Text = 'IN 4';

            % Create IN5Label
            GUI.IN5Label = uilabel(GUI.SingleInputSettingPanel);
            GUI.IN5Label.Position = [528 170 28 22];
            GUI.IN5Label.Text = 'IN 5';

            % Create IN6Label
            GUI.IN6Label = uilabel(GUI.SingleInputSettingPanel);
            GUI.IN6Label.Position = [641 170 28 22];
            GUI.IN6Label.Text = 'IN 6';

            % Create IN7Label
            GUI.IN7Label = uilabel(GUI.SingleInputSettingPanel);
            GUI.IN7Label.Position = [754 170 28 22];
            GUI.IN7Label.Text = 'IN 7';

            % Create IN8Label
            GUI.IN8Label = uilabel(GUI.SingleInputSettingPanel);
            GUI.IN8Label.Position = [869 170 28 22];
            GUI.IN8Label.Text = 'IN 8';

            % Create SensorTypeDropDownLabel_13
            GUI.SensorTypeDropDownLabel_13 = uilabel(GUI.SingleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_13.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_13.Position = [60 144 76 22];
            GUI.SensorTypeDropDownLabel_13.Text = 'Sensor Type:';

            % Create SensorTypeIN1
            GUI.SensorTypeIN1 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.SensorTypeIN1.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeIN1.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeIN1.Position = [48 119 100 22];
            GUI.SensorTypeIN1.Value = 12;

            % Create AdapterTypeDropDownLabel_13
            GUI.AdapterTypeDropDownLabel_13 = uilabel(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_13.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_13.Position = [60 94 80 22];
            GUI.AdapterTypeDropDownLabel_13.Text = 'Adapter Type:';

            % Create AdapterTypeIN1
            GUI.AdapterTypeIN1 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeIN1.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeIN1.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeIN1.Position = [48 69 100 22];
            GUI.AdapterTypeIN1.Value = 4;

            % Create MuscleSelectionDropDownLabel_13
            GUI.MuscleSelectionDropDownLabel_13 = uilabel(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_13.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_13.Position = [48 44 100 22];
            GUI.MuscleSelectionDropDownLabel_13.Text = 'Muscle Selection:';

            % Create MuscleSelectionIN1
            GUI.MuscleSelectionIN1 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionIN1.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionIN1.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionIN1.Position = [48 19 100 22];
            GUI.MuscleSelectionIN1.Value = 36;

            % Create SensorTypeDropDownLabel_14
            GUI.SensorTypeDropDownLabel_14 = uilabel(GUI.SingleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_14.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_14.Position = [169 144 76 22];
            GUI.SensorTypeDropDownLabel_14.Text = 'Sensor Type:';

            % Create SensorTypeIN2
            GUI.SensorTypeIN2 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.SensorTypeIN2.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeIN2.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeIN2.Position = [157 119 100 22];
            GUI.SensorTypeIN2.Value = 12;

            % Create AdapterTypeDropDownLabel_14
            GUI.AdapterTypeDropDownLabel_14 = uilabel(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_14.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_14.Position = [169 94 80 22];
            GUI.AdapterTypeDropDownLabel_14.Text = 'Adapter Type:';

            % Create AdapterTypeIN2
            GUI.AdapterTypeIN2 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeIN2.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeIN2.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeIN2.Position = [157 69 100 22];
            GUI.AdapterTypeIN2.Value = 4;

            % Create MuscleSelectionDropDownLabel_14
            GUI.MuscleSelectionDropDownLabel_14 = uilabel(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_14.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_14.Position = [157 44 100 22];
            GUI.MuscleSelectionDropDownLabel_14.Text = 'Muscle Selection:';

            % Create MuscleSelectionIN2
            GUI.MuscleSelectionIN2 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionIN2.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionIN2.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionIN2.Position = [157 19 100 22];
            GUI.MuscleSelectionIN2.Value = 36;

            % Create SensorTypeDropDownLabel_15
            GUI.SensorTypeDropDownLabel_15 = uilabel(GUI.SingleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_15.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_15.Position = [280 144 76 22];
            GUI.SensorTypeDropDownLabel_15.Text = 'Sensor Type:';

            % Create SensorTypeIN3
            GUI.SensorTypeIN3 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.SensorTypeIN3.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeIN3.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeIN3.Position = [268 119 100 22];
            GUI.SensorTypeIN3.Value = 12;

            % Create AdapterTypeDropDownLabel_15
            GUI.AdapterTypeDropDownLabel_15 = uilabel(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_15.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_15.Position = [280 94 80 22];
            GUI.AdapterTypeDropDownLabel_15.Text = 'Adapter Type:';

            % Create AdapterTypeIN3
            GUI.AdapterTypeIN3 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeIN3.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeIN3.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeIN3.Position = [268 69 100 22];
            GUI.AdapterTypeIN3.Value = 4;

            % Create MuscleSelectionDropDownLabel_15
            GUI.MuscleSelectionDropDownLabel_15 = uilabel(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_15.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_15.Position = [268 44 100 22];
            GUI.MuscleSelectionDropDownLabel_15.Text = 'Muscle Selection:';

            % Create MuscleSelectionIN3
            GUI.MuscleSelectionIN3 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionIN3.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionIN3.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionIN3.Position = [268 19 100 22];
            GUI.MuscleSelectionIN3.Value = 36;

            % Create SensorTypeDropDownLabel_16
            GUI.SensorTypeDropDownLabel_16 = uilabel(GUI.SingleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_16.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_16.Position = [391 144 76 22];
            GUI.SensorTypeDropDownLabel_16.Text = 'Sensor Type:';

            % Create SensorTypeIN4
            GUI.SensorTypeIN4 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.SensorTypeIN4.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeIN4.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeIN4.Position = [379 119 100 22];
            GUI.SensorTypeIN4.Value = 12;

            % Create AdapterTypeDropDownLabel_16
            GUI.AdapterTypeDropDownLabel_16 = uilabel(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_16.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_16.Position = [391 94 80 22];
            GUI.AdapterTypeDropDownLabel_16.Text = 'Adapter Type:';

            % Create AdapterTypeIN4
            GUI.AdapterTypeIN4 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeIN4.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeIN4.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeIN4.Position = [379 69 100 22];
            GUI.AdapterTypeIN4.Value = 4;

            % Create MuscleSelectionDropDownLabel_16
            GUI.MuscleSelectionDropDownLabel_16 = uilabel(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_16.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_16.Position = [379 44 100 22];
            GUI.MuscleSelectionDropDownLabel_16.Text = 'Muscle Selection:';

            % Create MuscleSelectionIN4
            GUI.MuscleSelectionIN4 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionIN4.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionIN4.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionIN4.Position = [379 19 100 22];
            GUI.MuscleSelectionIN4.Value = 36;

            % Create SensorTypeDropDownLabel_17
            GUI.SensorTypeDropDownLabel_17 = uilabel(GUI.SingleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_17.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_17.Position = [504 144 76 22];
            GUI.SensorTypeDropDownLabel_17.Text = 'Sensor Type:';

            % Create SensorTypeIN5
            GUI.SensorTypeIN5 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.SensorTypeIN5.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeIN5.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeIN5.Position = [492 119 100 22];
            GUI.SensorTypeIN5.Value = 12;

            % Create AdapterTypeDropDownLabel_17
            GUI.AdapterTypeDropDownLabel_17 = uilabel(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_17.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_17.Position = [504 94 80 22];
            GUI.AdapterTypeDropDownLabel_17.Text = 'Adapter Type:';

            % Create AdapterTypeIN5
            GUI.AdapterTypeIN5 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeIN5.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeIN5.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeIN5.Position = [492 69 100 22];
            GUI.AdapterTypeIN5.Value = 4;

            % Create MuscleSelectionDropDownLabel_17
            GUI.MuscleSelectionDropDownLabel_17 = uilabel(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_17.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_17.Position = [492 44 100 22];
            GUI.MuscleSelectionDropDownLabel_17.Text = 'Muscle Selection:';

            % Create MuscleSelectionIN5
            GUI.MuscleSelectionIN5 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionIN5.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionIN5.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionIN5.Position = [492 19 100 22];
            GUI.MuscleSelectionIN5.Value = 32;

            % Create SensorTypeDropDownLabel_18
            GUI.SensorTypeDropDownLabel_18 = uilabel(GUI.SingleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_18.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_18.Position = [617 144 76 22];
            GUI.SensorTypeDropDownLabel_18.Text = 'Sensor Type:';

            % Create SensorTypeIN6
            GUI.SensorTypeIN6 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.SensorTypeIN6.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeIN6.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeIN6.Position = [605 119 100 22];
            GUI.SensorTypeIN6.Value = 12;

            % Create AdapterTypeDropDownLabel_18
            GUI.AdapterTypeDropDownLabel_18 = uilabel(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_18.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_18.Position = [617 94 80 22];
            GUI.AdapterTypeDropDownLabel_18.Text = 'Adapter Type:';

            % Create AdapterTypeIN6
            GUI.AdapterTypeIN6 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeIN6.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeIN6.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeIN6.Position = [605 69 100 22];
            GUI.AdapterTypeIN6.Value = 4;

            % Create MuscleSelectionDropDownLabel_18
            GUI.MuscleSelectionDropDownLabel_18 = uilabel(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_18.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_18.Position = [605 44 100 22];
            GUI.MuscleSelectionDropDownLabel_18.Text = 'Muscle Selection:';

            % Create MuscleSelectionIN6
            GUI.MuscleSelectionIN6 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionIN6.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionIN6.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionIN6.Position = [605 19 100 22];
            GUI.MuscleSelectionIN6.Value = 32;

            % Create SensorTypeDropDownLabel_19
            GUI.SensorTypeDropDownLabel_19 = uilabel(GUI.SingleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_19.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_19.Position = [730 144 76 22];
            GUI.SensorTypeDropDownLabel_19.Text = 'Sensor Type:';

            % Create SensorTypeIN7
            GUI.SensorTypeIN7 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.SensorTypeIN7.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeIN7.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeIN7.Position = [718 119 100 22];
            GUI.SensorTypeIN7.Value = 12;

            % Create AdapterTypeDropDownLabel_19
            GUI.AdapterTypeDropDownLabel_19 = uilabel(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_19.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_19.Position = [730 94 80 22];
            GUI.AdapterTypeDropDownLabel_19.Text = 'Adapter Type:';

            % Create AdapterTypeIN7
            GUI.AdapterTypeIN7 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeIN7.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeIN7.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeIN7.Position = [718 69 100 22];
            GUI.AdapterTypeIN7.Value = 4;

            % Create MuscleSelectionDropDownLabel_19
            GUI.MuscleSelectionDropDownLabel_19 = uilabel(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_19.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_19.Position = [718 44 100 22];
            GUI.MuscleSelectionDropDownLabel_19.Text = 'Muscle Selection:';

            % Create MuscleSelectionIN7
            GUI.MuscleSelectionIN7 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionIN7.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionIN7.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionIN7.Position = [718 19 100 22];
            GUI.MuscleSelectionIN7.Value = 32;

            % Create SensorTypeDropDownLabel_20
            GUI.SensorTypeDropDownLabel_20 = uilabel(GUI.SingleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_20.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_20.Position = [845 144 76 22];
            GUI.SensorTypeDropDownLabel_20.Text = 'Sensor Type:';

            % Create SensorTypeIN8
            GUI.SensorTypeIN8 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.SensorTypeIN8.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeIN8.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeIN8.Position = [833 119 100 22];
            GUI.SensorTypeIN8.Value = 12;

            % Create AdapterTypeDropDownLabel_20
            GUI.AdapterTypeDropDownLabel_20 = uilabel(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_20.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_20.Position = [845 94 80 22];
            GUI.AdapterTypeDropDownLabel_20.Text = 'Adapter Type:';

            % Create AdapterTypeIN8
            GUI.AdapterTypeIN8 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.AdapterTypeIN8.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeIN8.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeIN8.Position = [833 69 100 22];
            GUI.AdapterTypeIN8.Value = 4;

            % Create MuscleSelectionDropDownLabel_20
            GUI.MuscleSelectionDropDownLabel_20 = uilabel(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_20.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_20.Position = [833 44 100 22];
            GUI.MuscleSelectionDropDownLabel_20.Text = 'Muscle Selection:';

            % Create MuscleSelectionIN8
            GUI.MuscleSelectionIN8 = uidropdown(GUI.SingleInputSettingPanel);
            GUI.MuscleSelectionIN8.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionIN8.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionIN8.Position = [833 19 100 22];
            GUI.MuscleSelectionIN8.Value = 32;

            % Create MultipleInputSettingPanel
            GUI.MultipleInputSettingPanel = uipanel(GUI.SensorSelectionandConfigurationPanel);
            GUI.MultipleInputSettingPanel.Title = 'Multiple Input Setting';
            GUI.MultipleInputSettingPanel.Position = [261 8 485 223];

            % Create MULTI1Label
            GUI.MULTI1Label = uilabel(GUI.MultipleInputSettingPanel);
            GUI.MULTI1Label.Position = [48 171 51 22];
            GUI.MULTI1Label.Text = 'MULTI 1';

            % Create MULTI2Label
            GUI.MULTI2Label = uilabel(GUI.MultipleInputSettingPanel);
            GUI.MULTI2Label.Position = [161 171 51 22];
            GUI.MULTI2Label.Text = 'MULTI 2';

            % Create MULTI3Label
            GUI.MULTI3Label = uilabel(GUI.MultipleInputSettingPanel);
            GUI.MULTI3Label.Position = [278 171 51 22];
            GUI.MULTI3Label.Text = 'MULTI 3';

            % Create MULTI4Label
            GUI.MULTI4Label = uilabel(GUI.MultipleInputSettingPanel);
            GUI.MULTI4Label.Position = [387 171 51 22];
            GUI.MULTI4Label.Text = 'MULTI 4';

            % Create SensorTypeDropDownLabel_9
            GUI.SensorTypeDropDownLabel_9 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_9.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_9.Position = [36 150 76 22];
            GUI.SensorTypeDropDownLabel_9.Text = 'Sensor Type:';

            % Create SensorTypeMLT1
            GUI.SensorTypeMLT1 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.SensorTypeMLT1.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeMLT1.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeMLT1.Position = [24 125 100 22];
            GUI.SensorTypeMLT1.Value = 12;

            % Create AdapterTypeDropDownLabel_9
            GUI.AdapterTypeDropDownLabel_9 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_9.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_9.Position = [36 100 80 22];
            GUI.AdapterTypeDropDownLabel_9.Text = 'Adapter Type:';

            % Create AdapterTypeMLT1
            GUI.AdapterTypeMLT1 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.AdapterTypeMLT1.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeMLT1.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeMLT1.Position = [24 75 100 22];
            GUI.AdapterTypeMLT1.Value = 4;

            % Create MuscleSelectionDropDownLabel_9
            GUI.MuscleSelectionDropDownLabel_9 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_9.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_9.Position = [24 50 100 22];
            GUI.MuscleSelectionDropDownLabel_9.Text = 'Muscle Selection:';

            % Create MuscleSelectionMLT1
            GUI.MuscleSelectionMLT1 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.MuscleSelectionMLT1.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionMLT1.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionMLT1.Position = [24 25 100 22];
            GUI.MuscleSelectionMLT1.Value = 36;

            % Create SensorTypeDropDownLabel_10
            GUI.SensorTypeDropDownLabel_10 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_10.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_10.Position = [147 150 76 22];
            GUI.SensorTypeDropDownLabel_10.Text = 'Sensor Type:';

            % Create SensorTypeMLT2
            GUI.SensorTypeMLT2 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.SensorTypeMLT2.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeMLT2.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeMLT2.Position = [135 125 100 22];
            GUI.SensorTypeMLT2.Value = 12;

            % Create AdapterTypeDropDownLabel_10
            GUI.AdapterTypeDropDownLabel_10 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_10.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_10.Position = [147 100 80 22];
            GUI.AdapterTypeDropDownLabel_10.Text = 'Adapter Type:';

            % Create AdapterTypeMLT2
            GUI.AdapterTypeMLT2 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.AdapterTypeMLT2.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeMLT2.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeMLT2.Position = [135 75 100 22];
            GUI.AdapterTypeMLT2.Value = 4;

            % Create MuscleSelectionDropDownLabel_10
            GUI.MuscleSelectionDropDownLabel_10 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_10.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_10.Position = [135 50 100 22];
            GUI.MuscleSelectionDropDownLabel_10.Text = 'Muscle Selection:';

            % Create MuscleSelectionMLT2
            GUI.MuscleSelectionMLT2 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.MuscleSelectionMLT2.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionMLT2.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionMLT2.Position = [135 25 100 22];
            GUI.MuscleSelectionMLT2.Value = 33;

            % Create SensorTypeDropDownLabel_11
            GUI.SensorTypeDropDownLabel_11 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_11.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_11.Position = [264 150 76 22];
            GUI.SensorTypeDropDownLabel_11.Text = 'Sensor Type:';

            % Create SensorTypeMLT3
            GUI.SensorTypeMLT3 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.SensorTypeMLT3.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeMLT3.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeMLT3.Position = [252 125 100 22];
            GUI.SensorTypeMLT3.Value = 12;

            % Create AdapterTypeDropDownLabel_11
            GUI.AdapterTypeDropDownLabel_11 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_11.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_11.Position = [264 100 80 22];
            GUI.AdapterTypeDropDownLabel_11.Text = 'Adapter Type:';

            % Create AdapterTypeMLT3
            GUI.AdapterTypeMLT3 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.AdapterTypeMLT3.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeMLT3.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeMLT3.Position = [252 75 100 22];
            GUI.AdapterTypeMLT3.Value = 4;

            % Create MuscleSelectionDropDownLabel_11
            GUI.MuscleSelectionDropDownLabel_11 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_11.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_11.Position = [252 50 100 22];
            GUI.MuscleSelectionDropDownLabel_11.Text = 'Muscle Selection:';

            % Create MuscleSelectionMLT3
            GUI.MuscleSelectionMLT3 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.MuscleSelectionMLT3.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionMLT3.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionMLT3.Position = [252 25 100 22];
            GUI.MuscleSelectionMLT3.Value = 24;

            % Create SensorTypeDropDownLabel_12
            GUI.SensorTypeDropDownLabel_12 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.SensorTypeDropDownLabel_12.HorizontalAlignment = 'right';
            GUI.SensorTypeDropDownLabel_12.Position = [373 150 76 22];
            GUI.SensorTypeDropDownLabel_12.Text = 'Sensor Type:';

            % Create SensorTypeMLT4
            GUI.SensorTypeMLT4 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.SensorTypeMLT4.Items = {'Not define', '16 Monopolar EEG', 'Mon. intram.el', 'Bip. el - CoDe', '8 Accelerometer', 'Bipolar el. - DE1', 'Bipolar el. - CDE', 'Bip. el. - other', '4 el. Array 10mm', '8 el. Array 5mm', '8 el. Array 10mm', '64el. Gr. 2.54mm', '64 el. Grid 8mm', '64 el. Grid 10mm', '64 el.Gr. 12.5mm', '16 el.Array 2.5mm', '16 el.Array 5mm', '16 el. Array 10mm', '16 el. Array 10mm', '16 el. rectal pr.', '48 el. rectal pr.', '12 el. Armband', '16 el. Armband', 'Other sensor'};
            GUI.SensorTypeMLT4.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23};
            GUI.SensorTypeMLT4.Position = [361 125 100 22];
            GUI.SensorTypeMLT4.Value = 12;

            % Create AdapterTypeDropDownLabel_12
            GUI.AdapterTypeDropDownLabel_12 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.AdapterTypeDropDownLabel_12.HorizontalAlignment = 'right';
            GUI.AdapterTypeDropDownLabel_12.Position = [373 100 80 22];
            GUI.AdapterTypeDropDownLabel_12.Text = 'Adapter Type:';

            % Create AdapterTypeMLT4
            GUI.AdapterTypeMLT4 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.AdapterTypeMLT4.Items = {'Not defined', '16ch AD1x16', '8ch AD2x8', '4ch AD4x4', '64ch AD1x64', '16ch AD8x2', 'Other'};
            GUI.AdapterTypeMLT4.ItemsData = {0, 1, 2, 3, 4, 5, 6};
            GUI.AdapterTypeMLT4.Position = [361 75 100 22];
            GUI.AdapterTypeMLT4.Value = 4;

            % Create MuscleSelectionDropDownLabel_12
            GUI.MuscleSelectionDropDownLabel_12 = uilabel(GUI.MultipleInputSettingPanel);
            GUI.MuscleSelectionDropDownLabel_12.HorizontalAlignment = 'right';
            GUI.MuscleSelectionDropDownLabel_12.Position = [361 50 100 22];
            GUI.MuscleSelectionDropDownLabel_12.Text = 'Muscle Selection:';

            % Create MuscleSelectionMLT4
            GUI.MuscleSelectionMLT4 = uidropdown(GUI.MultipleInputSettingPanel);
            GUI.MuscleSelectionMLT4.Items = {'Not defined', 'Temporalis Anterior', 'Superfic. Masseter', 'Splenius Capitis', 'Upper Trapezius', 'Lower Trapezius', 'Rhomboideus Major', 'Rhomboideus Minor', 'Anterior Deltoid', 'Posterior Deltoid', 'Lateral Deltoid', 'Infraspinatus', 'Teres Major', 'Erector Spinae', 'Latissimus Dorsi', 'Bic Br. Long Head', 'Bic Br. Short Head', 'Tric. Br. Lat Head', 'Tric. Br Med Head', 'Pronator Teres', 'Flex. Carpi Radial', 'Flex Carpi Ulnaris', 'Palmaris Longus', 'Ext. Carpi Radialis', 'Ext. Carpi Ulnaris', 'Ext.DigCommunis', 'Brachioradialis', 'Abd. Pollicis Brev', 'Abd Pollicis Long', 'Opponens Pollicis', 'Adductor Pollicis', 'Flex. Poll. Brevis', 'Abd. Digiti Minimi', 'Flex. Digiti Minimi', 'Opp. Digiti Minimi', 'Dorsal Interossei', 'Palmar Interossei', 'Lumbrical', 'Rectus Abdominis', 'Ext. Abdom Obliq', 'Serratus Anterior', 'Pectoralis Major', 'Sternc Ster Head', 'SternocClav Head', 'Anterior Scalenus', 'Tensor Fascia Latae', 'Gastocn. Lateralis', 'Gastrocn. Mediali', 'Biceps Femoris', 'Soleus', 'Semitendinosus', 'Glutes Maximus', 'Gluteus medius', 'Vastus lateralis', 'Vastus medialis', 'Rectus femoris', 'Tibialis anterior', 'Peroneus longus', 'Semimembranosus', 'Gracialis', 'Ext. Anal Sphincte', 'Puborectalis', 'Urethral Sphincter', 'Not a Muscle'};
            GUI.MuscleSelectionMLT4.ItemsData = {0, 1, 2, 3, 4, 5, 6,7, 8,9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,27, 28, 29, 30, 31, 32, 33, 34, 35, 36,37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUI.MuscleSelectionMLT4.Position = [361 25 100 22];
            GUI.MuscleSelectionMLT4.Value = 26;

            % Create SetupCompleteButton
            GUI.SetupCompleteButton = uibutton(GUI.SettingsTab, 'push');
            GUI.SetupCompleteButton.Position = [829 22 102 22];
            GUI.SetupCompleteButton.Text = 'Setup Complete';

            % Create CancelButton
            GUI.CancelButton = uibutton(GUI.SettingsTab, 'push');
            GUI.CancelButton.Position = [78 22 102 22];
            GUI.CancelButton.Text = 'Cancel';
            
             % Create LoadSetupButton
            GUI.LoadSetupButton = uibutton(GUI.SettingsTab, 'push');
            GUI.LoadSetupButton.Position = [296 22 102 22];
            GUI.LoadSetupButton.Text = 'Load Setup';
            
             % Create SaveSetupButton
            GUI.SaveSetupButton = uibutton(GUI.SettingsTab, 'push');
            GUI.SaveSetupButton.Position = [631 22 102 22];
            GUI.SaveSetupButton.Text = 'Save Setup';
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   % RECORDING TAB %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Create RecordingTab
            GUI.RecordingTab = uitab(GUI.TabGroup);
            GUI.RecordingTab.Title = 'Recording';
            
%             % Create UIAxes
%             GUI.UIAxes = uiaxes(GUI.RecordingTab);
%             xlabel(GUI.UIAxes, 'Time')
%             ylabel(GUI.UIAxes, 'Emg CH')
%             GUI.UIAxes.Position = [1 53 638 376];
            
            % Create SynchronizationSwitchLabel
            GUI.SynchronizationSwitchLabel = uilabel(GUI.RecordingTab);
            GUI.SynchronizationSwitchLabel.HorizontalAlignment = 'center';
            GUI.SynchronizationSwitchLabel.Position = [32 20 91 22];
            GUI.SynchronizationSwitchLabel.Text = 'Synchronization';

            % Create SynchronizationSwitch
            GUI.SynchronizationSwitch = uiswitch(GUI.RecordingTab, 'slider');
            GUI.SynchronizationSwitch.Position = [52 41 45 20];
            GUI.SynchronizationSwitch.ItemsData = {0, 1};

                        % Create ChannelDropDown
            GUI.ChannelDropDown = uidropdown(GUI.RecordingTab);
            GUI.ChannelDropDown.Position = [370 30 100 22];
            GUI.ChannelDropDown.Items = {'IN 1-4', 'IN 5-8', 'MULTI 1', 'MULTI 2','MULTI 3','MULTI 4'};
            GUI.ChannelDropDown.ItemsData = {0, 1, 2, 3, 4, 5};
            GUI.ChannelDropDown.Value = 0;

            % Create VisualizeButton
            GUI.VisualizeButton = uibutton(GUI.RecordingTab, 'state');
            GUI.VisualizeButton.Position = [507 30 100 22];
            GUI.VisualizeButton.Text = 'Visualize';

            % Create RecordButton
            GUI.RecordButton = uibutton(GUI.RecordingTab, 'state');
            GUI.RecordButton.Position = [161 30 100 22];
            GUI.RecordButton.Text = 'Record';
            
            % Create ChannelDropDownLabel
            GUI.ChannelDropDownLabel = uilabel(GUI.RecordingTab);
            GUI.ChannelDropDownLabel.HorizontalAlignment = 'right';
            GUI.ChannelDropDownLabel.Position = [298 30 57 22];
            GUI.ChannelDropDownLabel.Text = 'Channel: ';

            
        %% callback
        GUI.TabGroup.SelectionChangedFcn = @(SimoneQuattrocentoMod,event)InitPlot (obj);
        GUI.RecordButton.ValueChangedFcn = @(SimoneQuattrocentoMod,event)RecordingData (obj);
        GUI.RecordButton.Interruptible = 'off';
        GUI.VisualizeButton.ValueChangedFcn = @(SimoneQuattrocentoMod,event)VisualizeData (obj);
        GUI.VisualizeButton.Interruptible = 'off';
        GUI.SynchronizationSwitch.ValueChangedFcn = @(SimoneQuattrocentoMod,event)Synch(obj);
        GUI.CancelButton.ButtonPushedFcn = @(SimoneQuattrocentoMod,event)Cancel(obj);
        GUI.SetupCompleteButton.ButtonPushedFcn = @(SimoneQuattrocentoMod,event)SetupComplete (obj);
        GUI.LoadSetupButton.ButtonPushedFcn = @(SimoneQuattrocentoMod,event)LoadSetup (obj);
        GUI.SaveSetupButton.ButtonPushedFcn = @(SimoneQuattrocentoMod,event)SaveSetup (obj);
        GUI.UIFigure.CloseRequestFcn = @(SimoneQuattrocentoMod,event)Cancel(obj);
        
        end
        
        %% Create Synch GUI: UIFigure to settings the synchronization
        function GUIsett=synchGUI(obj)

            % Create UIFigure
            GUIsett.UIFigure = uifigure;
            GUIsett.UIFigure.Position = [100 100 416 247];
            GUIsett.UIFigure.Name = 'UI Figure';

            % Create ChannelDropDownLabel
            GUIsett.ChannelDropDownLabel = uilabel(GUIsett.UIFigure);
            GUIsett.ChannelDropDownLabel.HorizontalAlignment = 'right';
            GUIsett.ChannelDropDownLabel.Position = [120 105 60 22];
            GUIsett.ChannelDropDownLabel.Text = 'Channel : ';

            % Create ChannelDropDown
            GUIsett.ChannelDropDown = uidropdown(GUIsett.UIFigure);
            GUIsett.ChannelDropDown.Items = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', '50', '51', '52', '53', '54', '55', '56', '57', '58', '59', '60', '61', '62', '63', '64'};
            GUIsett.ChannelDropDown.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63};
            GUIsett.ChannelDropDown.Position = [195 105 100 22];
            GUIsett.ChannelDropDown.Value = 0;

            % Create SourceDropDownLabel
            GUIsett.SourceDropDownLabel = uilabel(GUIsett.UIFigure);
            GUIsett.SourceDropDownLabel.HorizontalAlignment = 'right';
            GUIsett.SourceDropDownLabel.Position = [124 148 54 22];
            GUIsett.SourceDropDownLabel.Text = 'Source : ';

            % Create SourceDropDown
            GUIsett.SourceDropDown = uidropdown(GUIsett.UIFigure);
            GUIsett.SourceDropDown.Items = {'IN1', 'IN2', 'IN3', 'IN4', 'IN5', 'IN6', 'IN7', 'IN8', 'MULTI1', 'MULTI2', 'MULTI3', 'MULTI4', 'AUX'};
            GUIsett.SourceDropDown.ItemsData = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};
            GUIsett.SourceDropDown.Position = [193 148 100 22];
            GUIsett.SourceDropDown.Value = 0;

            % Create GainDropDownLabel
            GUIsett.GainDropDownLabel = uilabel(GUIsett.UIFigure);
            GUIsett.GainDropDownLabel.HorizontalAlignment = 'right';
            GUIsett.GainDropDownLabel.Position = [131 62 41 22];
            GUIsett.GainDropDownLabel.Text = 'Gain : ';

            % Create GainDropDown
            GUIsett.GainDropDown = uidropdown(GUIsett.UIFigure);
            GUIsett.GainDropDown.Items = {'1', '2', '4', '16'};
            GUIsett.GainDropDown.ItemsData = {0, 16, 32, 48};
            GUIsett.GainDropDown.Position = [187 62 100 22];
            GUIsett.GainDropDown.Value = 0;

            % Create OutputchannelselectionandsettingLabel
            GUIsett.OutputchannelselectionandsettingLabel = uilabel(GUIsett.UIFigure);
            GUIsett.OutputchannelselectionandsettingLabel.Position = [108 192 201 22];
            GUIsett.OutputchannelselectionandsettingLabel.Text = 'Output channel selection and setting';

            % Create OkButton
            GUIsett.OkButton = uibutton(GUIsett.UIFigure, 'push');
            GUIsett.OkButton.Position = [286 21 100 22];
            GUIsett.OkButton.Text = 'Ok';
            GUIsett.OkButton.ButtonPushedFcn = @(SimoneQuattrocentoMod,event)synchbutton(obj,GUIsett);   
            
            %create Arduino button
            GUIsett.ArduinoButton = uibutton(GUIsett.UIFigure, 'push');
            GUIsett.ArduinoButton.Position = [32 21 100 22];
            GUIsett.ArduinoButton.Text = 'Arduino';
            GUIsett.ArduinoButton.ButtonPushedFcn = @(SimoneQuattrocentoMod,event)ArduinoConnection(obj);
            
        end
        
        %% callback setup complete button of the MAIN GUI
        function SetupComplete(obj)
                %% Channel Setup setting
                % evaluate each Channel CheckBox to see if the channel is active
                % if it is active, the code set the Configuration String for the Channel
                %
                % if it is not active, the code set the non-set bytes for
                % the Configuration String
                %
                % Refer to Quattrocento configuration protocol v1.5 Word
                % File for more info about the ConfigurationString
                
                %% CheckBox Channel selection
                % set the Number of Channel active for the Configuration
                % String; 
                
                if obj.GUI.IN7.Value || obj.GUI.IN8.Value || obj.GUI.MULTI4.Value 
                    obj.NCHsel=4;
                elseif obj.GUI.IN5.Value || obj.GUI.IN6.Value || obj.GUI.MULTI3.Value
                    obj.NCHsel=3;
                elseif obj.GUI.IN3.Value || obj.GUI.IN4.Value || obj.GUI.MULTI2.Value
                    obj.NCHsel=2;
                else
                    obj.NCHsel=1;
                end
                
 %% Configuration String preparation for each active Channel
 % in adiction, save the column coordinate for each Input Channel
                
                 % IN 1
                 if obj.GUI.IN1.Value 
                    obj.ConfString(4) = obj.GUI.MuscleSelectionIN1.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(5) = bin2dec([dec2bin(obj.GUI.SensorTypeIN1.Value,5) dec2bin(obj.GUI.AdapterTypeIN1.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN12 = 1:16;
                 else                                                                                                  % ADAPTER (TABLE WORD)
                   obj.ConfString(4) = 0;
                   obj.ConfString(5) = 0;
                 end
                % IN 2
                 if obj.GUI.IN2.Value 
                    obj.ConfString(7) = obj.GUI.MuscleSelectionIN2.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(8) = bin2dec([dec2bin(obj.GUI.SensorTypeIN2.Value,5) dec2bin(obj.GUI.AdapterTypeIN2.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN12 = [obj.IN12 17:32];
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(7) = 0;
                    obj.ConfString(8) = 0;
                 end
                % IN 3
                 if obj.GUI.IN3.Value 
                    obj.ConfString(10) = obj.GUI.MuscleSelectionIN3.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(11) = bin2dec([dec2bin(obj.GUI.SensorTypeIN3.Value,5) dec2bin(obj.GUI.AdapterTypeIN3.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN34 = 33:48; 
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(10) = 0;
                    obj.ConfString(11) = 0;
                 end
                % IN 4
                 if obj.GUI.IN4.Value 
                    obj.ConfString(13) = obj.GUI.MuscleSelectionIN4.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(14) = bin2dec([dec2bin(obj.GUI.SensorTypeIN4.Value,5) dec2bin(obj.GUI.AdapterTypeIN4.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN34 = [obj.IN34 49:64];
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(13) = 0;
                    obj.ConfString(14) = 0;
                 end
                % IN 5
                 if obj.GUI.IN5.Value 
                    obj.ConfString(16) = obj.GUI.MuscleSelectionIN5.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(17) = bin2dec([dec2bin(obj.GUI.SensorTypeIN5.Value,5) dec2bin(obj.GUI.AdapterTypeIN5.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN56 = 65:80;
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(16) = 0;
                    obj.ConfString(17) = 0;
                 end
                % IN 6
                 if obj.GUI.IN6.Value 
                    obj.ConfString(19) = obj.GUI.MuscleSelectionIN6.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(20) = bin2dec([dec2bin(obj.GUI.SensorTypeIN6.Value,5) dec2bin(obj.GUI.AdapterTypeIN6.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN56 = [obj.IN56 81:96];
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(19) = 0;
                    obj.ConfString(20) = 0;
                 end
                % IN 7
                 if obj.GUI.IN7.Value 
                    obj.ConfString(22) = obj.GUI.MuscleSelectionIN7.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(23) = bin2dec([dec2bin(obj.GUI.SensorTypeIN7.Value,5) dec2bin(obj.GUI.AdapterTypeIN7.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN78 = 97:112;
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(22) = 0;
                    obj.ConfString(23) = 0;
                 end
                % IN 8
                 if obj.GUI.IN8.Value 
                    obj.ConfString(25) = obj.GUI.MuscleSelectionIN8.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(26) = bin2dec([dec2bin(obj.GUI.SensorTypeIN8.Value,5) dec2bin(obj.GUI.AdapterTypeIN8.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN78 = [obj.IN78 113:128];
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(25) = 0;
                    obj.ConfString(26) = 0;
                 end
                % MULTI 1
                 if obj.GUI.MULTI1.Value 
                    obj.ConfString(28) = obj.GUI.MuscleSelectionMLT1.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(29) = bin2dec([dec2bin(obj.GUI.SensorTypeMLT1.Value,5) dec2bin(obj.GUI.AdapterTypeMLT1.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    %verify which configuraton of channel is active
                    switch obj.NCHsel
                        case 1
                            obj.MLT1 = 33:96;
                        case 2
                            obj.MLT1 = 65:128;
                        case 3
                            obj.MLT1 = 97:160;
                        case 4
                            obj.MLT1 = 129:192;
                    end
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(28) = 0;
                    obj.ConfString(29) = 0;
                 end
                 % MULTI 2
                 if obj.GUI.MULTI2.Value 
                    obj.ConfString(31) = obj.GUI.MuscleSelectionMLT2.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(32) = bin2dec([dec2bin(obj.GUI.SensorTypeMLT2.Value,5) dec2bin(obj.GUI.AdapterTypeMLT2.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                     switch obj.NCHsel
                        case 2
                            obj.MLT2 = 129:192;
                        case 3
                            obj.MLT2 = 161:224;
                        case 4
                            obj.MLT2 = 193:256;
                    end
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(31) = 0;
                    obj.ConfString(32) = 0;
                 end
                 % MULTI 3
                 if obj.GUI.MULTI3.Value 
                    obj.ConfString(34) = obj.GUI.MuscleSelectionMLT3.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(35) = bin2dec([dec2bin(obj.GUI.SensorTypeMLT3.Value,5) dec2bin(obj.GUI.AdapterTypeMLT3.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    switch obj.NCHsel
                        case 3
                            obj.MLT3 = 225:288;
                        case 4
                            obj.MLT3 = 257:320;
                    end
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(34) = 0;
                    obj.ConfString(35) = 0;
                 end
                 % MULTI 4
                 if obj.GUI.MULTI4.Value 
                    obj.ConfString(37) = obj.GUI.MuscleSelectionMLT4.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(38) = bin2dec([dec2bin(obj.GUI.SensorTypeMLT4.Value,5) dec2bin(obj.GUI.AdapterTypeMLT4.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.MLT4 = 321:384;
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(37) = 0;
                    obj.ConfString(38) = 0;
                 end
                
                %% Configuration String
                % set the 3 main Bytes of the Configuration String 
                obj.ConfString(1) = bin2dec('10000000') + obj.Fsamp(obj.FSsel) + obj.NumChan(obj.NCHsel)+1; %Setting configuration: Channel, fsamp, Acqisition ON ecc..
                obj.ConfString(2) = obj.AnOutGain + obj.AnOutSource;  %out analog config 
                obj.ConfString(3) = obj.AnOutChan;  % out analog channel

                obj.ConfString(6:3:39) = bin2dec([dec2bin(obj.GUI.HPcutoff.Value,2) dec2bin(obj.GUI.LPcutoff.Value,2) dec2bin(obj.GUI.AcquisitionMode.Value,2)]); %BIT 7-6=INSERTION SIDE OF THE MATRIX, BIT 5-4=HIGH PASS CUT OFF FREQ,
                                                     %BIT 3-2=LOW PASS CUT OFF FREQ,
                                                     %BIT 1-0= MODE: MONOPOLAR/DIFF/BIPOLAR 
                % ---------- CRC8 ---------- %
                obj.ConfString(40) = obj.CRC8(obj.ConfString, 39); % static Method to evaluate the last Byte of the ConfigurationString
                obj.isSet = true; % configuration String set
                
                %saving of the msg to send to 400 about the setting 
                obj.SettingString=obj.ConfString; % String Saved and Ready to start the Visualization
                
                % Main information set in the Configuration string saves in appropriate Property  
                obj.fsamp= obj.FsampVal(obj.FSsel);
                obj.NumEMGChannel=obj.NumChanVal(obj.NCHsel)- obj.NumAUXChannel-obj.NumAccessoriesCh;
                obj.EMGChannel = [obj.IN12 obj.IN34 obj.IN56 obj.IN78 obj.MLT1 obj.MLT2 obj.MLT3 obj.MLT4];
                %setup complete vai a Recording
                f1 = msgbox('Setup Saved, move to Recording Tab');
        end
        
        %% callback function SaveSetup
        function SaveSetup(obj)          
                % Channel Setup
                % This Function is equal to Setup complete function but
                % instead of saving the Configuration string only in the
                % SettingString property, It save also the String as a mat
                % File to future utilization
    
           if not(obj.isSet)
               
                %% CheckBox Channel selection
                % set the Number of Channel active for the Configuration
                % String; 
                
                if obj.GUI.IN7.Value || obj.GUI.IN8.Value || obj.GUI.MULTI4.Value 
                    obj.NCHsel=4;
                elseif obj.GUI.IN5.Value || obj.GUI.IN6.Value || obj.GUI.MULTI3.Value
                    obj.NCHsel=3;
                elseif obj.GUI.IN3.Value || obj.GUI.IN4.Value || obj.GUI.MULTI2.Value
                    obj.NCHsel=2;
                else
                    obj.NCHsel=1;
                end
                
 %% Configuration String preparation for each active Channel
 % in adiction, save the column coordinate for each Input Channel
                
                 % IN 1
                 if obj.GUI.IN1.Value 
                    obj.ConfString(4) = obj.GUI.MuscleSelectionIN1.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(5) = bin2dec([dec2bin(obj.GUI.SensorTypeIN1.Value,5) dec2bin(obj.GUI.AdapterTypeIN1.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN12 = 1:16;
                 else                                                                                                  % ADAPTER (TABLE WORD)
                   obj.ConfString(4) = 0;
                   obj.ConfString(5) = 0;
                 end
                % IN 2
                 if obj.GUI.IN2.Value 
                    obj.ConfString(7) = obj.GUI.MuscleSelectionIN2.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(8) = bin2dec([dec2bin(obj.GUI.SensorTypeIN2.Value,5) dec2bin(obj.GUI.AdapterTypeIN2.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN12 = [obj.IN12 17:32];
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(7) = 0;
                    obj.ConfString(8) = 0;
                 end
                % IN 3
                 if obj.GUI.IN3.Value 
                    obj.ConfString(10) = obj.GUI.MuscleSelectionIN3.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(11) = bin2dec([dec2bin(obj.GUI.SensorTypeIN3.Value,5) dec2bin(obj.GUI.AdapterTypeIN3.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN34 = 33:48; 
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(10) = 0;
                    obj.ConfString(11) = 0;
                 end
                % IN 4
                 if obj.GUI.IN4.Value 
                    obj.ConfString(13) = obj.GUI.MuscleSelectionIN4.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(14) = bin2dec([dec2bin(obj.GUI.SensorTypeIN4.Value,5) dec2bin(obj.GUI.AdapterTypeIN4.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN34 = [obj.IN34 49:64];
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(13) = 0;
                    obj.ConfString(14) = 0;
                 end
                % IN 5
                 if obj.GUI.IN5.Value 
                    obj.ConfString(16) = obj.GUI.MuscleSelectionIN5.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(17) = bin2dec([dec2bin(obj.GUI.SensorTypeIN5.Value,5) dec2bin(obj.GUI.AdapterTypeIN5.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN56 = 65:80;
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(16) = 0;
                    obj.ConfString(17) = 0;
                 end
                % IN 6
                 if obj.GUI.IN6.Value 
                    obj.ConfString(19) = obj.GUI.MuscleSelectionIN6.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(20) = bin2dec([dec2bin(obj.GUI.SensorTypeIN6.Value,5) dec2bin(obj.GUI.AdapterTypeIN6.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN56 = [obj.IN56 81:96];
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(19) = 0;
                    obj.ConfString(20) = 0;
                 end
                % IN 7
                 if obj.GUI.IN7.Value 
                    obj.ConfString(22) = obj.GUI.MuscleSelectionIN7.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(23) = bin2dec([dec2bin(obj.GUI.SensorTypeIN7.Value,5) dec2bin(obj.GUI.AdapterTypeIN7.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN78 = 97:112;
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(22) = 0;
                    obj.ConfString(23) = 0;
                 end
                % IN 8
                 if obj.GUI.IN8.Value 
                    obj.ConfString(25) = obj.GUI.MuscleSelectionIN8.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(26) = bin2dec([dec2bin(obj.GUI.SensorTypeIN8.Value,5) dec2bin(obj.GUI.AdapterTypeIN8.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.IN78 = [obj.IN78 113:128];
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(25) = 0;
                    obj.ConfString(26) = 0;
                 end
                % MULTI 1
                 if obj.GUI.MULTI1.Value 
                    obj.ConfString(28) = obj.GUI.MuscleSelectionMLT1.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(29) = bin2dec([dec2bin(obj.GUI.SensorTypeMLT1.Value,5) dec2bin(obj.GUI.AdapterTypeMLT1.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    %verify which configuraton of channel is active
                    switch obj.NCHsel
                        case 1
                            obj.MLT1 = 33:96;
                        case 2
                            obj.MLT1 = 65:128;
                        case 3
                            obj.MLT1 = 97:160;
                        case 4
                            obj.MLT1 = 129:192;
                    end
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(28) = 0;
                    obj.ConfString(29) = 0;
                 end
                 % MULTI 2
                 if obj.GUI.MULTI2.Value 
                    obj.ConfString(31) = obj.GUI.MuscleSelectionMLT2.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(32) = bin2dec([dec2bin(obj.GUI.SensorTypeMLT2.Value,5) dec2bin(obj.GUI.AdapterTypeMLT2.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                     switch obj.NCHsel
                        case 2
                            obj.MLT2 = 129:192;
                        case 3
                            obj.MLT2 = 161:224;
                        case 4
                            obj.MLT2 = 193:256;
                    end
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(31) = 0;
                    obj.ConfString(32) = 0;
                 end
                 % MULTI 3
                 if obj.GUI.MULTI3.Value 
                    obj.ConfString(34) = obj.GUI.MuscleSelectionMLT3.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(35) = bin2dec([dec2bin(obj.GUI.SensorTypeMLT3.Value,5) dec2bin(obj.GUI.AdapterTypeMLT3.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    switch obj.NCHsel
                        case 3
                            obj.MLT3 = 225:288;
                        case 4
                            obj.MLT3 = 257:320;
                    end
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(34) = 0;
                    obj.ConfString(35) = 0;
                 end
                 % MULTI 4
                 if obj.GUI.MULTI4.Value 
                    obj.ConfString(37) = obj.GUI.MuscleSelectionMLT4.Value; % MUSCLE SELECTION (TABLE WORD)       
                    obj.ConfString(38) = bin2dec([dec2bin(obj.GUI.SensorTypeMLT4.Value,5) dec2bin(obj.GUI.AdapterTypeMLT4.Value,3)]); % MATRIX/SENSORS(TABLE WORD), 
                    obj.MLT4 = 321:384;
                 else                                                                                                  % ADAPTER (TABLE WORD)
                    obj.ConfString(37) = 0;
                    obj.ConfString(38) = 0;
                 end
                
                %% Configuration String
                % set the 3 main Bytes of the Configuration String 
                obj.ConfString(1) = bin2dec('10000000') + obj.Fsamp(obj.FSsel) + obj.NumChan(obj.NCHsel)+1; %Setting configuration: Channel, fsamp, Acqisition ON ecc..
                obj.ConfString(2) = obj.AnOutGain + obj.AnOutSource;  %out analog config 
                obj.ConfString(3) = obj.AnOutChan;  % out analog channel

                obj.ConfString(6:3:39) = bin2dec([dec2bin(obj.GUI.HPcutoff.Value,2) dec2bin(obj.GUI.LPcutoff.Value,2) dec2bin(obj.GUI.AcquisitionMode.Value,2)]); %BIT 7-6=INSERTION SIDE OF THE MATRIX, BIT 5-4=HIGH PASS CUT OFF FREQ,
                                                     %BIT 3-2=LOW PASS CUT OFF FREQ,
                                                     %BIT 1-0= MODE: MONOPOLAR/DIFF/BIPOLAR 
                % ---------- CRC8 ---------- %
                obj.ConfString(40) = obj.CRC8(obj.ConfString, 39); % static Method to evaluate the last Byte of the ConfigurationString
                obj.isSet = true; % configuration String set
                
                %saving of the msg to send to 400 about the setting 
                obj.SettingString=obj.ConfString; % String Saved and Ready to start the Visualization
                
                % Main information set in the Configuration string saves in appropriate Property  
                obj.fsamp= obj.FsampVal(obj.FSsel);
                obj.NumEMGChannel=obj.NumChanVal(obj.NCHsel)- obj.NumAUXChannel-obj.NumAccessoriesCh;
                obj.EMGChannel = [obj.IN12 obj.IN34 obj.IN56 obj.IN78 obj.MLT1 obj.MLT2 obj.MLT3 obj.MLT4];
                %setup complete vai a Recording
           end   
                % Save Setting in m file
                setup = obj.SettingString;
                nchsel = obj.NCHsel;
                fssel = obj.FSsel;
                fsample = obj.fsamp;
                nEMGch = obj.NumEMGChannel;
                in12 = obj.IN12; in34 = obj.IN34; in56 =obj.IN56; in78 =obj.IN78;
                multi1 = obj.MLT1; multi2=obj.MLT2; multi3=obj.MLT3; multi4=obj.MLT4;
                EMGch = obj.EMGChannel;
                [file,path] = uiputfile('*.mat','Save Setup Settings','Setup.mat');
                save([path, file],'setup','nchsel','fssel','fsample','nEMGch','EMGch',...
                    'in12','in34','in56','in78','multi1','multi2','multi3','multi4');
        end
        
        %% callback function LoadSetup
        function LoadSetup(obj)
            % Load the Setup/Configuration String saved with the SaveSetup
            % function
      
             [fname,path] = uigetfile('*.mat','Choose the Setup file');
             S=load([path, fname]);
             obj.SettingString=S.setup;
             obj.ConfString =S.setup;
             obj.NCHsel = S.nchsel;
             obj.FSsel = S.fssel;
             obj.fsamp = S.fsample;
             obj.NumEMGChannel = S.nEMGch;
             obj.EMGChannel = S.EMGch;
             obj.IN12 = S.in12;
             obj.IN34 = S.in34;
             obj.IN56 = S.in56;
             obj.IN78 = S.in78;
             obj.MLT1 = S.multi1;
             obj.MLT2 = S.multi2;
             obj.MLT3 = S.multi3;
             obj.MLT4 = S.multi4;
             
             %setup complete vai a Recording
             f1 = msgbox('Setup Loaded, move to Recording Tab');
        end
        
        %% Visualize Button callback, Start the visualization calling startAcq 
        function VisualizeData(obj) %callback visualize button
            obj.isAcquiring = false; %This button is a STATE button. The flag will be already false at the first call and will be active the second call
%              pause(2);
            if obj.GUI.VisualizeButton.Value % if is the first click: from On-->Off 
                %start Connection in order to visualize the data
                startAcq(obj);
            else
%                 pause(1);
                %stop acquisition with sending the msg to 400
                 stopAcq(obj);     
            end
        end
       
        %% Recording Button callback, Activate the isRecording Flag to start the recording 
        function RecordingData(obj) %callback record button
            if obj.GUI.RecordButton.Value
                    if obj.prot_flag
                        obj.countData = 0;
                        obj.duration = obj.prot.duration;
                    end
                    obj.isRecording = true;
                    disp('obj.isRecording = true;')
                    
                    % start Rec Clock for Synch
                    obj.RecClock(1,:) = clock;
                    obj.numCall = 0;    %starting counting each callback from 400 to save buffer each time needed;  
                    obj.CallTimes = 0;
                    %choice file name
                    obj.FileName =['Recording' datestr(clock,'ddmmyyyyHHMM')];
           
                    if obj.isArduinoConnect                     %if u want to synch with other device
                        writeDigitalPin(obj.Arduino,'D10',1);
                        writeDigitalPin(obj.Arduino,'D11',1);
                        %writePWMDutyCycle(obj.Arduino,'D11',0.5);
                    end
                    
                    % Starting to save Data
                    obj.File=fopen([obj.Path, obj.FileName],'a');
                    fwrite(obj.File,zeros(1,18),'double');
                   
                    pause(0.6);
                    sound(obj.y);
                    pause(0.4);
                    clear sound;
                    pause(1.6);
                    sound(obj.y);
                    pause(0.4);
                    clear sound;
                    pause(1);
                    
%             else
                    if obj.isArduinoConnect
                        writeDigitalPin(obj.Arduino,'D10',0);
                        writeDigitalPin(obj.Arduino,'D11',0);          
                    end
                    %save 2 more tcpip buffer for the acquisition delay
                    %obj.isRecording = false;
                    obj.StopRecCall =true;
                    obj.GUI.RecordButton.Value=0;
            end
        end
        
        %% Function for Acquisition and Recording
        function startAcq(obj)
            %call from Visualize button, start the connection with the 400
            
            obj.isAcquiring = true;
            obj.bufferSample = obj.fsamp/4; % set the dimension ofthe tcpip buffer in samples
                                          % the number of sample for this
                                          % bufferSample modify also the refresh period of the real time plot
                                          % as u can see in readData
                                          % function
            %% Open the TCP socket comunication
             obj.tcpScoket = tcpip('169.254.1.10', obj.TCPPort, 'NetworkRole', 'client');
             obj.tcpScoket.InputBufferSize = 2*obj.NumChanVal(obj.NCHsel)*obj.bufferSample;
             set(obj.tcpScoket, 'ByteOrder', 'littleEndian');
             % Define a callback function to be executed when desired number of bytes
             % are available in the input buffer
             obj.tcpScoket.BytesAvailableFcnMode = 'byte';
             obj.tcpScoket.BytesAvailableFcnCount = 2*obj.NumChanVal(obj.NCHsel)*obj.bufferSample;
             obj.tcpScoket.BytesAvailableFcn = @(SimoneQuattrocentoMod,event)ReadData(obj);
             
             % open the connection
             fopen(obj.tcpScoket);
             obj.isConnectedDevice = true;
             
             % Send the configuration to quattrocento, the Visualization
             % Start now
             fwrite(obj.tcpScoket, obj.SettingString, 'uint8');
             %start Clock Acq for Synch
             obj.AcqClock(1,:) = clock;       
        end
        
        function stopAcq(obj)
             %% Stop data transfer.
             % always modify the Configuration string in ConfString property in order to mantain the Setup string in the SettingString 
             obj.ConfString(1) = obj.Stop;    % First byte that stop the data transer
             obj.ConfString(40) = obj.CRC8(obj.ConfString, 39);  % Estimates the new CRC
             % send the msg to the 400 to stop the visualization and the
             % comunication
             fwrite(obj.tcpScoket, obj.ConfString, 'uint8');
             % stop clock Acq for Synch
             obj.AcqClock(2,:) = clock;
             % flag Acq
             obj.isAcquiring = false;              
        end
              
        % tcp ip callback when number of bytes in the tcpipBuffer are ready to read
        function ReadData(obj)
            %verify that the visualization is active
            if obj.isAcquiring
                    % Read the desired number of data bytes
                    obj.tcpScoket.UserData = fread(obj.tcpScoket, [obj.NumChanVal(obj.NCHsel), obj.bufferSample], 'int16')';
                    % Visualization Buffer filling
                    obj.bufferEMG=[obj.bufferEMG(obj.bufferSample+1:end,:); obj.GainFactor*obj.tcpScoket.UserData(:,1:obj.NumEMGChannel)];
                    obj.bufferAUX=[obj.bufferAUX(obj.bufferSample+1:end,:); obj.AuxGainFactor*obj.tcpScoket.UserData(:,end-(obj.NumAccessoriesCh+obj.NumAUXChannel)+1:end-obj.NumAccessoriesCh)];
                    
                    if obj.prot_flag && obj.isRecording
                        obj.countData = obj.countData + obj.bufferSample;
                        disp(obj.countData)
                    end
                    
                    % Real time plot 
                    if obj.isPlot
                        plotEMG(obj);
                    end
                    
                    %Data saving if the Recording is active 
                    obj.numCall = obj.numCall+1; %count the number of ReadData call to verify if the whole VisualizationBuffer is changed 
                    if obj.isRecording && obj.numCall>(obj.bufferSize/(obj.bufferSample/obj.fsamp))-1 %verify that the whole Visualization buffer is changed
                              obj.CallTimes = obj.CallTimes +1;
                              obj.numCall = 0;   
                              fwrite(obj.File,[obj.bufferEMG(:,obj.EMGChannel) obj.bufferAUX],'double');
                              disp('Save...');
                    end
                  % condition to save the last tcpip buffer, when the recording has been stopped 
                    if obj.StopRecCall % verify if the StopRecording have been called
                       obj.StopRecNum = obj.StopRecNum +1; 
                       if (obj.isRecording) && (obj.StopRecNum > 2)
                           obj.isRecording = false;
                           disp('isRecording False...');
                       elseif not(obj.isRecording)
                          % stop Rec Clock for Synch
                          obj.RecClock(2,:) = clock;
                          %  Save one more tcpip buffer after the Stop  recording
                          if obj.numCall>0
                                 fwrite(obj.File,[obj.bufferEMG((end-obj.bufferSample*obj.numCall)+1:end,obj.EMGChannel) obj.bufferAUX((end-obj.bufferSample*obj.numCall)+1:end,:)],'double');
                          end
                          obj.StopRecCall= false; % to do this condition only immediatly after StopRec
                          fclose(obj.File);
                    
                          % rewrite File header
                          obj.File=fopen([obj.Path obj.FileName],'r+');
                          fwrite(obj.File, (length(obj.EMGChannel)+obj.NumAUXChannel),'double');
                          fwrite(obj.File, (obj.CallTimes),'double');
                          fwrite(obj.File, (obj.numCall),'double');
                          fwrite(obj.File, obj.fsamp,'double');
                          fwrite(obj.File, obj.bufferSample,'double');
                          fwrite(obj.File, obj.bufferSize,'double');
                          fwrite(obj.File, [obj.GUI.IN1.Value obj.GUI.IN2.Value obj.GUI.IN3.Value obj.GUI.IN4.Value...
                              obj.GUI.IN5.Value obj.GUI.IN6.Value obj.GUI.IN7.Value obj.GUI.IN8.Value...
                              obj.GUI.MULTI1.Value obj.GUI.MULTI2.Value obj.GUI.MULTI3.Value obj.GUI.MULTI4.Value],'double');
                          fclose(obj.File);
                          disp('Header...');
                       end
                       
                    end
%                     if obj.isRecording && obj.prot_flag && obj.duration > 0 && (obj.countData >= obj.duration * obj.fsamp)
%                         obj.GUI.RecordButton.Value = 0;
%                         obj.RecordingData;
%                         pause(1) % We added a pause and we need to debug the code to see if it enters here
%                         obj.GUI.VizualizeButton.Value = 0;
%                         obj.VisualizeData;
%                     end
            end
        end
        
        %% Synchronization Function
        % synch switch callback on change state
        function Synch(obj)
            if obj.GUI.SynchronizationSwitch.Value
                % open synch setting gui
                obj.GUIsett = synchGUI(obj);
                waitfor(obj,'isSync',true); % wait for synchbutton() function executed
                % activate REC ON
                obj.ConfString(1) = obj.ConfString(1) + obj.RecOn;
                % select the channel that u want in the trigger out from
                % the SynchGUI
                obj.ConfString(2) = obj.AnOutGain + obj.AnOutSource;  %out analog config 
                obj.ConfString(3) = obj.AnOutChan;  % out analog channel
                obj.ConfString(40) = obj.CRC8(obj.ConfString(1:39), 39);  % Estimates the new CRC
            else
                obj.ConfString(1) = obj.ConfString(1) - obj.RecOn;  %turn down the output trigger
                obj.ConfString(40) = obj.CRC8(obj.ConfString(1:39), 39);  % Estimates the new CRC
                if obj.isArduinoConnect
                    delete(obj.Arduino);
                    %fclose(obj.Arduino);
                    obj.isArduinoConnect = false; 
                end
            end
        end
        
        % okbutton callback in synch gui
        function obj = synchbutton(obj,GUIsett)
            %set the information to the ConfigurationString for the
            %Synch/AuxOut
            obj.AnOutSource = GUIsett.SourceDropDown.Value;
            obj.AnOutChan = GUIsett.ChannelDropDown.Value;
            obj.AnOutGain = GUIsett.GainDropDown.Value;
            delete(GUIsett.UIFigure);
            obj.isSync = true;
            %close(GUIsett.UIFigure);
            %uiresume(UIFigure);
        end
        
        function Cancel(obj)
            if obj.isRecording || obj.isAcquiring
                msgbox('Remember to stop acquisition and recording before to close!','Closing Error');
                if obj.isRecording
                    obj.RecordingData;
                    pause(1)
                end
                if obj.isAcquiring
                    obj.VisualizeData;
                    pause(2)
                end
            end %else
            if obj.isConnectedDevice
                % Close the communication
                fclose(obj.tcpScoket);
                % Clean up the interface object
                delete(obj.tcpScoket);
                obj.isConnectedDevice = false; 
            end
             if obj.isArduinoConnect
                % Clean up the object
                fclose(serial('COM5'));
                % delete obj.Arduino;
                obj.isArduinoConnect = false; 
            end
                %close figure
%                     uiresume(obj.GUI.UIFigure);
                delete(obj.GUI.UIFigure);
                %close(obj.GUI.UIFigure);
                %delete figure
                delete(obj.Figure)
                delete(obj.FigureAux);
%                     close(obj.Figure)
%                     close(obj.FigureAux);
%             end
        end
        
        %% methods useful in Post Processing that load the data inside the object
        function [XX Header]= OpenData(obj)
            head={'NumEMGChannel+obj.NumAUXChannel' 'CallTimes'...
              'numCall' 'fsamp' 'bufferSample' 'bufferSize'...
              'IN1' 'IN2' 'IN3' 'IN4' 'IN5' 'IN6' 'IN7' 'IN8'...
              'MLT1' 'MLT2' 'MLT3' 'MLT4'};
            %function 
             [fname,path] = uigetfile('*','choose EMG file');
              file=fopen([path,fname],'r');
              obj.FileHeader=fread(file,18,'double');
              for i=1:18 
               Header{i,2}=obj.FileHeader(i);
               Header{i,1}=head{i};
              end
              %FileHeader: (1)NumEMGChannel+obj.NumAUXChannel (2)CallTimes
              % (3)numCall (4)fsamp (5) bufferSample (6)bufferSize
              % (7:14)AS 0-1 Channel actived IN1 IN2 IN3 IN4 .... MLT1 MLT2...
              for j=1:obj.FileHeader(2)
                XX((j-1)*obj.FileHeader(4)*obj.FileHeader(6)+1:j*obj.FileHeader(4)*obj.FileHeader(6),1:obj.FileHeader(1))=...
                    fread(file,[obj.FileHeader(4)*obj.FileHeader(6) obj.FileHeader(1)],'double');
              end
              temp = fread(file,[obj.FileHeader(3)*obj.FileHeader(5), obj.FileHeader(1)],'double');
              XX = [XX; temp];
              obj.SaveData= XX;
              fclose(file);
        end
       
        
      %% plot 
      function plotEMG(obj)
            switch obj.GUI.ChannelDropDown.Value
                case 0
                    ch=[obj.IN12 obj.IN34];
                    tit='IN12-IN34';
                    obj.isVisualizing =true;
                    if isempty(ch)
                        ch=[1 0];
                        obj.isVisualizing =false;
                    end
                case 1
                    ch=[obj.IN56 obj.IN78];
                    tit='IN56-IN78';
                    obj.isVisualizing =true;
                    if isempty(ch)
                        ch=[1 0];
                        obj.isVisualizing =false;
                    end
                case 2
                    ch=obj.MLT1;
                    tit='MULTIPLE 1';
                    obj.isVisualizing =true;
                    if isempty(ch)
                        ch=[1 0];
                        obj.isVisualizing =false;
                    end
                case 3
                    ch=obj.MLT2;
                    tit='MULTIPLE 2';
                    obj.isVisualizing =true;
                    if isempty(ch)
                        ch=[1 0];
                        obj.isVisualizing =false;
                    end
                case 4
                    ch=obj.MLT3;
                    tit='MULTIPLE 3';
                    obj.isVisualizing =true;
                    if isempty(ch)
                        ch=[1 0];
                        obj.isVisualizing =false;
                    end
                case 5
                    ch=obj.MLT4;
                    tit='MULTIPLE 4';
                    obj.isVisualizing =true;
                    if isempty(ch)
                        ch=[1 0];
                        obj.isVisualizing =false;
                    end
            end
            % obj.TimeShift=obj.TimeShift+(obj.bufferSample/obj.fsamp);
            t = (0:obj.fsamp*obj.TimePlot-1)/obj.fsamp;       % TimePlot define xlim, TimeShift and Period how much increase in the grafh and each time refresh 
            set(obj.Figure.CurrentAxes,'Xlim',[0 obj.TimePlot],'Ylim',[ch(1)-1 ch(end)+1]);
            obj.Figure.CurrentAxes.Title.String = tit;
            % draw line
            if obj.isVisualizing
                for j=ch
                set(obj.LineChannel(j),'XData',t,...
                    'YData',obj.bufferEMG((end-obj.fsamp*obj.TimePlot)+1:end,j)+(j-1),...   
                    'Color','k','Linewidth',1);
                end 
            end        
            for j=1:16
            set(obj.LineAux(j),'XData',t,...
                'YData',obj.bufferAUX((end-obj.fsamp*obj.TimePlot)+1:end,j)+(j-1),...   
                'Color','k','Linewidth',1);
            end 
      end
      
      % initialize plot
      function InitPlot(obj) 
            
            switch obj.GUI.TabGroup.SelectedTab.Title
                case 'Recording'
                    t = (0:(obj.fsamp*obj.bufferSize-1))/obj.fsamp;                
                    % Initialise buffer
                    obj.bufferEMG=NaN*ones(obj.fsamp*obj.bufferSize,obj.NumEMGChannel);
                    obj.bufferAUX=NaN*ones(obj.fsamp*obj.bufferSize,obj.NumAUXChannel);
                    % prepare figure line
                    figure
                    obj.LineAux = line(t',obj.bufferAUX,'Color','k','Linewidth',1);
                    % set figure Aux limit and Tick
                    obj.FigureAux = gcf;
                    set(obj.FigureAux,'MenuBar','none','ToolBar','none','Position',[10 200 1250 550]);
                    set(obj.FigureAux.CurrentAxes,'Ytick',1:16);
                    set(obj.FigureAux.CurrentAxes,'Xlim',[0 obj.TimePlot],'Ylim',[0 17]); 
                    % EMG Channel figure
                    figure
                    obj.LineChannel=line(t',obj.bufferEMG,'Color','k','Linewidth',1);
                    % set figure Channel EMG limit and Tick
                    obj.Figure = gcf;
                    set(obj.Figure,'MenuBar','none','ToolBar','none','Position',[10 200 1250 550]);
                    set(obj.Figure.CurrentAxes,'Ytick',1:obj.NumEMGChannel);
                    set(obj.Figure.CurrentAxes,'Xlim',[0 obj.TimePlot],'Ylim',[0 obj.NumEMGChannel]);                    
                    obj.GUI.UIFigure.Position = [350 45 640 116];
                    obj.GUI.TabGroup.Position = [1 2 640 115];            
                case 'Settings'
                    obj.GUI.UIFigure.Position = [100 100 1014 622];
                    obj.GUI.TabGroup.Position = [1 0 1013 623];
                    delete(obj.Figure);
                    delete(obj.FigureAux);
            end
            
        end
        
      % synch with oder device
      function ArduinoConnection(obj)
            obj.Arduino = arduino('COM5','Uno');    %Obj arduino of the toolbox
            obj.isArduinoConnect = true;
        end
          
    end
    
    methods(Static)
        
    function crc = CRC8(Vector, Len)

            crc = 0;
            j = 1;

            while(Len > 0)
                Extract = Vector(j);
                for i = 8:-1:1

                    Sum = xor(mod(crc,2), mod(Extract,2));
                    crc = floor(crc/2);

                    if(Sum > 0)
                        str = zeros(1,8);
                        a = dec2bin(crc,8);
                        b = dec2bin(140,8);
                        for k = 1 : 8
                             str(k) = ~((a(k) == b(k)));
                        end

                        crc = bin2dec(strrep(num2str(str),' ',''));
                    end

                    Extract = floor(Extract/2); 
                end

                Len = Len - 1;

                j=j+1;
            end
        
    end
    
       % open tdf Kinematics file
        function [fSampleKin,R,T,Labels,Link,markerTrack,fRef,Signref]=tdfOpen()
                [file path]=uigetfile('*.tdf','select tdf file');
             if file==0
                    f = errordlg('File not selected','File Error');
             else
                [fSampleKin,D,R,T,Labels,Link,markerTrack] = SimoneQuattrocentoMod.tdfReadData3D([path file]);  %for marker signals
                [startTime,fRef,labe,Signref,ChMap] = SimoneQuattrocentoMod.tdfReadDataGenPurpose([path file]);   %for Analog signals

                % file save dialog
                prompt = {'Enter file name:'};
                title = 'Save .mat file';
                dims = [1 35];
                definput = {file(1:end-4)};
                name = inputdlg(prompt,title,dims,definput);

                % save mat
                old=cd('savedData'); 
                save([name{1},'.mat'],'fSampleKin','R','T','Labels','Link','markerTrack','fRef','Signref');
                cd(old);  
                f1 = msgbox('file saved');
             end
        end
        
        %% function usefull for tdfOpen
        function [frequency,D,R,T,labels,links,tracks] = tdfReadData3D(filename)
        %TDFREADDATA3D   Read 3D data sequence from TDF-file.
        %   [FREQUENCY,D,R,T,LABELS,LINKS,TRACKS] = TDFREADDATA3D (FILENAME) retrieves 
        %   frequency ([Hz]), calibrated volume info, tracks, links and labels 
        %   of the 3D data sequence stored in FILENAME.
        %   D is the dimension vector, R the rotation matrix, T the translation vector of the
        %   calibrated volume
        %   LINKS is a [2,nLinks] adjacency list of links: if exists linkIdx such that 
        %   links(:,linkIdx) == [track1;track2] then a link exists connecting track1 with track2.
        %   TRACKS is a matrix where each row represents a frame: TRACKS(FRM,:) is the frame FRM.
        %   3D coordinates of each frame are stored following the order X1 Y1 Z1 X2 Y2 Z2 ...
        %   LABELS is a matrix whith the text strings of the labels as rows.
        %
        %   See also TDFWRITEDATA3D, TDFPLOTDATA3D.
        %
        %   Copyright (c) 2000 by BTS S.p.A.
        %   $Revision: 6 $ $Date: 14/07/06 11.42 $

        frequency=[]; D=[]; R=[]; T=[]; labels=[]; links=[]; tracks=[];

        [fid,tdfBlockEntries] = SimoneQuattrocentoMod.tdfFileOpen (filename);   % open the file
        if fid == -1
           return
        end

        tdfData3DBlockId = 5;
        blockIdx = 0;
        for e = 1 : length (tdfBlockEntries)
           if (tdfData3DBlockId == tdfBlockEntries(e).Type) & (0 ~= tdfBlockEntries(e).Format)
              blockIdx = e;
              break
           end
        end
        if blockIdx == 0
           disp ('Data 3D not found in the file specified.')
           fclose (fid);
           return
        end

        if (-1 == fseek (fid,tdfBlockEntries(blockIdx).Offset,'bof'))
           disp ('Error: the file specified is corrupted.')
           tdfFileClose (fid);
           return
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % read header information
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        nFrames   = fread (fid,1,'int32');
        frequency = fread (fid,1,'int32');
        startTime = fread (fid,1,'float32');
        nTracks   = fread (fid,1,'int32');
        D         = fread (fid,3,'float32');
        R         = (fread (fid,[3,3],'float32'))';
        T         = fread (fid,3,'float32');
        fseek (fid,4,'cof'); %skip Flags field

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % read links information
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if (1 == tdfBlockEntries(blockIdx).Format) | (3 == tdfBlockEntries(blockIdx).Format)        % with links
           nLinks = fread (fid,1,'int32');
           fseek (fid,4,'cof');
           links  = fread (fid,[2,nLinks],'int32');
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % read tracks information
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        labels = char (zeros (nTracks,256));
        tracks = NaN * ones (nFrames,3*nTracks);

        if (1 == tdfBlockEntries(blockIdx).Format) | (2 == tdfBlockEntries(blockIdx).Format)         % by track
           for trk=1:nTracks
              label      = strtok (char ((fread (fid,256,'uchar'))'), char (0));
              labels (trk,1:length (label)) = label;
              nSegments  = fread (fid,1,'int32');
              fseek (fid,4,'cof');
              segments   = fread (fid,[2,nSegments],'int32');
              for s = 1 : nSegments
                 for f = segments(1,s)+1 : (segments(1,s)+segments(2,s))
                    tracks(f,3*(trk-1)+1:3*(trk-1)+3) = (fread (fid,3,'float32'))';
                 end
              end
           end
        elseif (3 == tdfBlockEntries(blockIdx).Format) | (4 == tdfBlockEntries(blockIdx).Format)     % by frame
           for trk=1:nTracks
              label      = strtok (char ((fread (fid,256,'uchar'))'), char (0));
              labels (trk,1:length (label)) = label;
           end
           tracks = (fread (fid,[3*nTracks,nFrames],'float32'))';
        end
        labels = deblank (labels);

        fclose(fid);
        end
        
        function [startTime,frequency,labels,Data,ChMap] = tdfReadDataGenPurpose (filename)
        %TDFREADDATAGENPURPOSE Read Data from a General Purpose Datablock in a TDF-file.
        %   [STARTTIME,FREQUENCY,LABELS,DATA,CHMAP] = TDFREADDATAGENPURPOSE (FILENAME) retrieves
        %   the data sampling start time ([s]) and sampling rate ([Hz]), 
        %   and the data of the GENPURP datablock stored in FILENAME.
        %   LABELS is a matrix with the text strings of the data tracks as rows.
        %   DATA is a [nTracks,nSamples] array such that DATA(s,:) stores 
        %   the samples of the track s. 
        %   CHMAP is a [nSignals,1] array such that CHMAP(logical channel) == physical channel. 
        %
        %   See also TDFWRITEDATAGENPURPOSE
        %
        %   Copyright (c) 2000 by BTS S.p.A.
        %   $Revision: 2 $ $Date: 27/07/06 12.26 $

            Data  = [];
            ChMap = [];
            frequency=0;
            startTime=0;
            labels = [];

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Open the file
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [fid,tdfBlockEntries] = SimoneQuattrocentoMod.tdfFileOpen (filename);   
            if fid == -1
               return
            end

            tdfDataVolumeBlockId = 14;
            blockIdx = 0;
            for e = 1 : length (tdfBlockEntries)
               if (tdfDataVolumeBlockId == tdfBlockEntries(e).Type) & (0 ~= tdfBlockEntries(e).Format)
                  blockIdx = e;
                  break
               end
            end
            if blockIdx == 0
               disp ('Data not found in the file specified.')
               fclose (fid);
               return
            end

            if (-1 == fseek (fid,tdfBlockEntries(blockIdx).Offset,'bof'))
               disp ('Error: the file specified is corrupted.')
               fclose (fid);
               return
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % read header information
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            nSignals  = fread (fid,1,'int32');
            frequency = fread (fid,1,'int32');
            startTime = fread (fid,1,'float32');
            nFrames   = fread (fid,1,'int32');  

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Read channel map information
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            ChMap = fread (fid,nSignals,'int16');

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Read data
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            labels   = char (zeros (nSignals,256));
            Data     = NaN * ones(nSignals,nFrames);

            if (1 == tdfBlockEntries(blockIdx).Format)         

              % by track
              % --------
               for e = 1 : nSignals
                  label      = strtok (char ((fread (fid,256,'uchar'))'), char (0));
                  labels (e,1:length (label)) = label;
                  nSegments  = fread (fid,1,'int32');
                  fseek (fid,4,'cof');
                  segments   = fread (fid,[2,nSegments],'int32');
                  for s = 1 : nSegments
                    Data(e,segments(1,s)+1 : (segments(1,s)+segments(2,s))) = (fread (fid,segments(2,s),'float32'))';
                  end
               end
            elseif (2 == tdfBlockEntries(blockIdx).Format)     

              % by frame
              % --------
               for e = 1 : nSignals
                  label = strtok (char ((fread (fid,256,'uchar'))'), char (0));
                  labels (e,1:length (label)) = label;
               end
               Data = (fread (fid,[nSamples,nSignals],'float32'))';
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Close the file
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fclose(fid);
        end
    
        function [fid,tdfBlockEntries] = tdfFileOpen (tdfFilename)

        tdfBlockEntries = struct ( ...
           'Type',{}, ...
           'Format',{}, ...
           'Offset',{}, ...
           'Size',{});

        tdfSignature = '41604B82CA8411D3ACB60060080C6816';

        [fid,msg] = fopen (tdfFilename,'r');                  % open the file
        if fid == -1
           disp(msg)
           return
        end
        ID = dec2hex (fread (fid,1,'uint32'),8);              % check the ID
        for i = 1:3
           ID = strcat (ID,dec2hex (fread (fid,1,'uint32'),8));
        end
        if ~strcmp (ID,tdfSignature)
           disp ('Error: invalid binary file.')
           fclose (fid);
           fid = -1;
           return
        end

        version = fread (fid,1,'uint32');
        nEntries = fread (fid,1,'int32');

        if (nEntries <= 0)
           disp ('The file specified contains no data.');
           fclose (fid);
           fid = -1;
           return
        end

        tdfVoidBlockEntries = tdfBlockEntries;
        tdfBlockEntries = struct ( ...
           'Type',cell (1,nEntries), ...
           'Format',cell (1,nEntries), ...
           'Offset',cell (1,nEntries), ...
           'Size',cell (1,nEntries));

        nextEntryOffset = 40;
        for e = 1:nEntries
           if (-1 == fseek (fid,nextEntryOffset,'cof'))
              disp ('Error: the file specified is corrupted.');
              fclose (fid);
              fid = -1;
              tdfBlockEntries = tdfVoidBlockEntries;
              return
           end
           tdfBlockEntries(e).Type = fread (fid,1,'uint32');
           tdfBlockEntries(e).Format = fread (fid,1,'uint32');
           tdfBlockEntries(e).Offset = fread (fid,1,'int32');
           tdfBlockEntries(e).Size = fread (fid,1,'int32');
           nextEntryOffset = 16+256;
        end
        end
        
        function [Y]=PrepareData(XX,Signref,markerTrack,Labels,Link,R,T) 
            
            [nsigref nsampsref]=size(Signref);
            [nsampsemg nelet]=size(XX);
            nmarker=size(markerTrack,2)/3;
            nsampsmark=size(markerTrack,1);

            %% Preprocessing
            k=1;
            for c=1:(nmarker*3)
                %eliminate the initial and finale part of the signals where the data
                %are missed
                    beg=find(not(isnan(markerTrack(:,c))),1,'first'); 
                    last=nsampsmark-find(not(isnan(fliplr(markerTrack(:,c)'))),1,'first')+1; 
                    %verify if there are NaN in the middle if the signals and
                    %interpolate it
                    if sum(isnan(markerTrack(beg:last,c)))>0 
                        %find NaN in the signals 
                        x=beg-1+find(not(isnan(markerTrack(beg:last,c))));
                        y=markerTrack(x,c);
                        xx=beg-1+(1:length(markerTrack(beg:last,c)))';
                        % interpolate adjacent data to eliminate the NaN
                        yy=interp1(x,y,xx,'spline');
                        markerTrack((beg-1+find(isnan(markerTrack(beg:last,c)))),c)=yy(find(isnan(markerTrack(beg:last,c))));
                    end
            end  
            
            %subdivide the data
            for i=1:nmarker
                Y.Data.Label{i}=Labels(i,:);    %which marker
                Temp{i}=markerTrack(:,k:k+2)';  %[X; Y; Z;] recording vector for each marker, with resample at EMG fsamp
                Y.Data.Marker{i}(1,:)=interp(Temp{i}(1,:),2); % resample a 500 Hz 
                Y.Data.Marker{i}(2,:)=interp(Temp{i}(2,:),2); 
                Y.Data.Marker{i}(3,:)=interp(Temp{i}(3,:),2);
                k=k+3;
            end
            
            Y.Reference{1,1}='ref_motion';
            Y.Reference{2,1}=Signref(1:nsigref,:); %ref resample in f_otb
            %Y.EMGlabel{1}='Raw_EMG';
            Y.EMG.raw{1}=XX(:,1:end-16);
            Y.Reference{1,2}='Ref_emg';
            Y.Reference{2,2}=XX(:,end-15:end);
            Y.MarkerLink = Link;
            Y.R = R;
            Y.T = T;
            
            
            %% Sync
            %find the cut sample for marker resample
            samCutMarker(1)=find(Y.Reference{2,1}(1,:)>4,1,'first');
            samCutMarker(2)=find(Y.Reference{2,1}(1,:)>4,1,'last');

            %find the cut sample for EMG
            samCutEMG(1)=find(Y.Reference{2,2}(:,1)>4,1,'first');
            samCutEMG(2)=find(Y.Reference{2,2}(:,1)>4,1,'last');
            
            % cut
            for i=1:nmarker
                Y.Data.Marker{i}=resample((Y.Data.Marker{i}(1:3,samCutMarker(1):samCutMarker(2)))',diff(samCutEMG)+1,diff(samCutMarker)+1);    
            end
            Y.Reference{2,1}=resample((Y.Reference{2,1}(:,samCutMarker(1):samCutMarker(2)))',diff(samCutEMG)+1,diff(samCutMarker)+1);
            Y.EMG.raw{1}=Y.EMG.raw{1}(samCutEMG(1):samCutEMG(2),:);
            Y.Reference{2,2}=Y.Reference{2,2}(samCutEMG(1):samCutEMG(2),:);

        end
        
        function PlotLineChannel(Data,fsample,tit)
            % Data matrix of EMG signals
            
            %Verify if the columns are the number of channel 
            [nsamps nch]=size(Data);
            if nch>nsamps
                Data=Data';
                [nsamps nch]=size(Data);
            end
            t=(0:(nsamps-1))./fsample;
            figure
            hold on
            for i=1:nch
                plot(t,Data(:,i)./max(Data(:))+i);
            end
            title(tit);
            
        end
        
        function [mask]= TimeMatrixPlot(sig, fsample, tit)
            % sig= matrix of column signals
            % t= time vector
            % tit=name of the matrix 
                mask = [];
                [nsamps nch]=size(sig);
                if nch>nsamps
                    sig=sig';
                    [nsamps nch]=size(sig);
                end
                row=8;
                if nch<64
                    row=7;
                    if nch<56
                        row=6;
                    end
                end
                t=(0:(nsamps-1))./fsample;
                do=1;
                while do
                vp=max(sig(:));
                n=1;
                figure
                for c=1:8 %number of column of the matrix
                    for r=1:row   %number of row of the matrix
                        plot(t/max(t)+(c*1.25),(sig(:,n))/vp+row-(r*1.05));
                        hold on
                        n=n+1;
                    end
                end
                title(['time signals from:' tit]);

                str=input('wich signals want to remove? [count from upper left corner in column], empty to close ','s');
                if isempty(str2num(str));
                    do=0;
                else
                    mask=[mask str2num(str)];
                    sig(:,mask)=zeros(nsamps,length(mask));
                    delete(gcf);
                end

                end  %end of the while
        end
            
        function [mask]=FreqMatrixPlot(sig,fs,tit)
        % sig= matrix of signals
        % fs= sample frequency
        % tit=name of the matrix 
            mask = [];
             [nsamps nch]=size(sig);
             if nch>nsamps
                    sig=sig';
                    clear nsamps nchs;
             end
            row=8;
            if nch<64
                    row=7;
                    if nch<63
                        row=6;
                    end
            end
            do=1;
            [Pxx,f] = pwelch(sig,rectwin(256),128,512,fs);
            [nsamps nch]=size(Pxx);
            while do

                %subplot(1,2,2),plot(f,Pxx/max(Pxx)),hold on;    
                maxpx=max(max(Pxx));
                n=1;
                figure
                for c=1:8 %number of column of the matrix
                    for r=1:row   %number of row of the matrix
                        plot(f/max(f)+(c*1.25),(Pxx(:,n))/maxpx+row-(r*1.05));
                        hold on
                        n=n+1;
                    end
                end
                title(['PSD from:' tit])

                str=input('wich PSD want to remove? [count from upper left corner in column], empty to close ','s');
                if isempty(str2num(str));
                    do=0;
                else
                    mask=[mask str2num(str)];
                    Pxx(:,mask)=zeros(nsamps,length(mask));
                    delete(gcf);
                end

            end  %end of the while
        end
        
        function [Z] = PreProcessing(Y,fs,nmatrix)
            % Band pass filtering 10-500
            % stop band 50 Hz
            % reorganize channel and estimation SD
             
             sig=Y.EMG.raw{1};
             [nsamps ch]=size(sig);
             if ch>nsamps
                    sig=sig';
                    [nsamps ch]=size(sig);
             end
             nelet = (ch)/nmatrix;
             
             Z=Y;
           
            %PREPROCESSING
            %band pass filtering
            cut_high= 10;
            cut_low= 500;
            [b,a] = butter(4,[cut_high/(fs/2) cut_low/(fs/2)]);
            sig = filtfilt(b,a,sig);
            
            %notch filter
%             [b,a]=rico(0.01,2,50,1/fs);
%             sig = filtfilt(b,a,sig);
            
             %Reorganize the channels
            ch_order= [1:8 16:-1:9 17:24 32:-1:25 33:40 48:-1:41 49:56 64:-1:57];
            for i=1:nmatrix 
               %Z.EMGlabel{i+1} = ['Mono matrix' num2str(i)];
               Z.EMG.mono{i} = sig(:,ch_order+(nelet*(i-1)))- mean(sig(:,ch_order+(nelet*(i-1))));
            end
            % Signle differential
            % mask for eliminate the wrong sd
            mask=[1:7 9:15 17:23 25:31 33:39 41:47 49:55 57:63];
            mask2=[1:6 9:14 17:22 25:30 33:38 41:46 49:54 57:62 ];
            %single differential
            for i=1:nmatrix
                temp=diff(Z.EMG.mono{i},1,2);
                temp2=diff(temp,1,2);
                %Z.EMGlabel{nmatrix+1+i} = ['SD matrix' num2str(i)]; 
                Z.EMG.sd{i} = temp(:,mask);
                Z.EMG.dd{i} = temp2(:,mask2);
            end
            
        end
        
                %% methods useful in Post Processing that load the data inside the object
        function [XX Header]= OpenFile(fname,path)
            head={'NumEMGChannel+obj.NumAUXChannel' 'CallTimes'...
              'numCall' 'fsamp' 'bufferSample' 'bufferSize'...
              'IN1' 'IN2' 'IN3' 'IN4' 'IN5' 'IN6' 'IN7' 'IN8'...
              'MLT1' 'MLT2' 'MLT3' 'MLT4'};
            %function 
%             [fname,path] = uigetfile('*','choose EMG file');
              file=fopen([path,fname],'r');
              FileHeader=fread(file,18,'double');
              for i=1:18 
               Header{i,2}=FileHeader(i);
               Header{i,1}=head{i};
              end
              %FileHeader: (1)NumEMGChannel+obj.NumAUXChannel (2)CallTimes
              % (3)numCall (4)fsamp (5) bufferSample (6)bufferSize
              % (7:14)AS 0-1 Channel actived IN1 IN2 IN3 IN4 .... MLT1 MLT2...
              for j=1:FileHeader(2)
                XX((j-1)*FileHeader(4)*FileHeader(6)+1:j*FileHeader(4)*FileHeader(6),1:FileHeader(1))=...
                    fread(file,[FileHeader(4)*FileHeader(6) FileHeader(1)],'double');
              end
              temp = fread(file,[FileHeader(3)*FileHeader(5), FileHeader(1)],'double');
              XX = [XX; temp];
              SaveData= XX;
              fclose(file);
        end
 end
       
    
end

