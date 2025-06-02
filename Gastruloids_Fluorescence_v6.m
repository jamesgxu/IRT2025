%% Script developed by David Berlin to analyze the fluorescence intensity of gastruloids as a function of anterior-posterior position of gastruloids.

%Version changes: v5 includes alignment of polarized gastruloids with the respect to the green channel, adaptive default input for user dialogue,
%normalization of the histograms based on the entire data set rather than per image.

%% Clear the workspace, but leave the perviously entered user inputs.

clearvars -except DefaultAnswer DefaultGastruloidMinSize DefaultMarkers; %Clears all saved variables except for the previous user inputs.
clc; clf; %Clear saved functions, the workspace, and figures.
close All; %Close any open figures

%% Start of User Prompts to Locate Files to be Analyzed

fprintf('Beginning Analysis of Gastruloid Image Histograms.\n') %Displays a message to the user that allows the user to know what step the code is on.

FileDirectory_Prompt = "What is the folder directory for the files to be analyzed?"; %User prompt for entering the file directory where the data files are located to be analyzed
FileNameScheme_Prompt = "What is the base name of the files to analyze?"; %User prompt to establish the naming convention of the files to be analyzed
Channel_Prompt = "How many channels are there?"; %User prompt to establish if there are 3 or 4 channels per data set.
DAPI_Prompt = "What is the image suffix for the DAPI image?"; %This is important as DAPI should be positive in all cells and is important for identifying and aligning the aggregate.
Red_Prompt = "What is the image suffix for the Red image?"; %This channel is also very important as the program currently aligns the images so that the red channel is primarily in the right/posterior half.
Red_Marker_Prompt = "What is the marker used for the Red images?";
Green_Prompt = "What is the image suffix for the Green image?"; %This prompts the user to identify the images with the green channel.
Green_Marker_Prompt = "What is the marker used for the Green images?";
Cyan_Prompt = "What is the image suffix for the Cyan image?"; %This prompts the user to identify the images with the cyan channel.
Cyan_Marker_Prompt = "What is the marker used for the Cyan images?";

%% This section checks to see if there are saved variables for the user inputs so that the previous entries can be ran again without reinput.

%This statement is a feedback statement that will allow for the user inputs to become the future default answers when the code is run again.
if exist('DefaultAnswer','var') == 0 %Check to see if the user has already ran the code this session. Thus having this saved variable.
DefaultAnswer = ["/Volumes/Extreme SSD/Matlab/gastruloid/Matlab 48H75  Ecad", "DC","4","CH1","CH3","CH4","CH2"]; %This is the default output of the user prompt, update this line as needed for ease of use.
end

if exist('DefaultMarkers','var') == 0 %Check to see if the user has already ran the code this session. Thus having this saved variable.
DefaultMarkers = ["FOXA2","SOX2","Phalloidin"]; %This is the default output of the user prompt, update this line as needed for ease of use.
end

%% This section will gather the information about where the images are stored and what markers were used.

fprintf('Requesting Information from User.\n') %Displays a message to the user. Will be potentially helpful in troubleshooting.

options.Resize='on'; %This line allows the user prompt dialog box to be resized/stretched by the user
options.WindowStlye='normal'; %This line allows the user to interact with other windows while the prompt dialog box is open

Compiled_Prompt = [FileDirectory_Prompt, FileNameScheme_Prompt, Channel_Prompt, DAPI_Prompt,Red_Prompt,Green_Prompt,Cyan_Prompt]; %Variable that combines all user prompts to be used as an input for the user input dialog GUI
Response = inputdlg(Compiled_Prompt,"File Locator",1,DefaultAnswer,options); %Prompts the user with a GUI of the created prompts with default answers input. It then creates an array from the answers to the user prompts
DefaultAnswer = Response; %Updates the DefaultAnswer variable so the user won't have to reinput their responses next time they run the code.

Marker_Prompt = [Red_Marker_Prompt,Green_Marker_Prompt,Cyan_Marker_Prompt]; %Variable that combines all user prompts to be used as an input for the user input dialog GUI
Marker_Response = inputdlg(Marker_Prompt,"File Locator",1,DefaultMarkers,options); %Prompts the user with a GUI of the created prompts with default answers input. It then creates an array from the answers to the user prompts
DefaultMarkers = Marker_Response; %Updates the DefaultAnswer variable so the user won't have to reinput their responses next time they run the code.

%% This section will convert the user responses to variables.

FileDirectory_User = convertCharsToStrings(Response(1)); %Converts the user's file directory response to a string.
Directory = dir(FileDirectory_User); %Creates a variable with the files located in the location that the user specified.
FileNameScheme_User = convertCharsToStrings(Response(2)); %Converts the user's file naming scheme response to a string.
Number_Channels = str2double(cell2mat(Response(3))); %Converts the user's Number of Channels response to a string.
DAPI_User = convertCharsToStrings(Response(4)); %Converts the user's DAPI channel naming response to a string.
Red_User = convertCharsToStrings(Response(5)); %Converts the user's red channel naming response to a string.
Green_User = convertCharsToStrings(Response(6)); %Converts the user's green channel naming response to a string.
Cyan_User = convertCharsToStrings(Response(7)); %Converts the user's cyan channel naming response to a string.

Red_Marker = convertCharsToStrings(Marker_Response(1)); %Converts the user's red marker response to a string.
Green_Marker = convertCharsToStrings(Marker_Response(2)); %Converts the user's green marker response to a string.
Cyan_Marker = convertCharsToStrings(Marker_Response(3)); %Converts the user's cyan marker response to a string.

%% This section screens out non-files from mac devices and determines the number of image sets.

Directory_File_Bytes = cell2mat({Directory(:).bytes}); %Creates a variable with the file size of all files in the directory
Directory_File_BytesNum = size(Directory_File_Bytes,2); %Creates a variable that is the number of files in the directory
ImageCount = size(Directory_File_Bytes(Directory_File_Bytes>5000),2); %Creates a variable that counts the number of images in the directory, but not the directory information files.

if Number_Channels == 4 %Determines the number of image sets for 4 channel images (4 images per set, 4 channels)
    Number_Image_Sets = ImageCount/4; %Determines the number of files within the folder that the user input.
elseif Number_Channels == 3 %Determines the number of image sets for 3 channel images (3 images per set, 3 channels)
    Number_Image_Sets = ImageCount/3; %Determines the number of files within the folder that the user input.
    fprintf("Running data analysis for a 3-channel image set. Please note that this version only works for images without a cyan channel. \n")
end %Terminates loop

fprintf('There were %d image sets found in the directory (%s).\n',Number_Image_Sets,FileDirectory_User) %Displays the number if images in the directory folder for the user.

FileDirectory_User_Info = struct2cell(Directory)'; %Saves all the file information to a variable. First 2 rows are directory information.
ImageNames = FileDirectory_User_Info(Directory_File_Bytes>5000)'; %Creates a variable matrix with the names of the images in the directory.

%% Determines the minimum size for a gastruloid to ignore smaller debris.

fprintf('Prompting user for a minimum Gastruloid size. \n') %Displays a message to the user in the command window, helpful for indicating what step the code is on.

%This statement is a feedback statement that will allow for the user inputs to become the future default answers when the code is run again.
if exist('DefaultGastruloidMinSize','var') == 0 %Checks to see if the code has already been ran once this session, thus having this variable saved.
DefaultGastruloidMinSize = "6000"; %This is the default output of the user prompt, update this line as needed for ease of use.
end

options = {'OK','Cancel'}; % Defines options for the input dialog buttons.
GastruloidMinSize = inputdlg("What would you like the minimum filter size be for selecting the Gastruloid?","Gastruloid Processing Specifications",1,{DefaultGastruloidMinSize},options); %User input for changing the Gastruloid Filtering Size of small objects, allows for easy reprocessing without changing the source code.
DefaultGastruloidMinSize = GastruloidMinSize; %Updates the default variable for running the code additional times in this session.
GastruloidMinSize = str2double(cell2mat(GastruloidMinSize)); %Converts the user input for the gastruloid min size to a number.

%% Pre-defines arrays prior to use in the loops to speed up the code.

A_Results = cell(Number_Image_Sets+1,5); %Pre-defines a results cell.
Header = {'Image Set','DAPI',Red_Marker,Green_Marker,Cyan_Marker}; %Creates a variable to be used as a "header" row in the results array.
A_Results = [Header; A_Results]; %Adds a "header" row to the results array.
A_Results{Number_Image_Sets+2,1} = 'Average Results'; %Adds a row title for the average results.

Blue_Interpolate = zeros(Number_Image_Sets, 10000); %Pre-defines a variable for the interpolated blue channel results for all image sets.
Red_Interpolate = zeros(Number_Image_Sets, 10000); %Pre-defines a variable for the interpolated red channel results for all image sets.
Green_Interpolate = zeros(Number_Image_Sets, 10000); %Pre-defines a variable for the interpolated green channel results for all image sets.
Cyan_Interpolate = zeros(Number_Image_Sets, 10000); %Pre-defines a variable for the interpolated cyan channel results for all image sets.

%% Begin processing the image sets.

for i = 1:Number_Image_Sets %Begins a loop to start processing the images in a set-by-set basis.

    fprintf('Processing data set %d. \n',i) %Updates the user as to which step the code is on.

    I = num2str(i); %Converts the image set number variable to a string so it can be included in the file location strings.
    Image_Name_i = strcat(FileNameScheme_User,'_',I); %Defines a variable as the current image name
    A_Results{i+1,1} = Image_Name_i; %Assigns the image name to the first column and ith + 1 row. The +1 to the row is necessary to account for the first row where the data type is specified.

    if Number_Channels == 4
        
        %% This sub-section defines the image file location based on if the user is using a mac or windows device.
        
        if ismac == 1
            
            Channel_Blue = imread(strcat(FileDirectory_User,'/',FileNameScheme_User,'_',I,'_',DAPI_User,'.tif')); %Reads the i-th DAPI image based on the directory and image name and saves it as a variable.
            Channel_Red = imread(strcat(FileDirectory_User,'/',FileNameScheme_User,'_',I,'_',Red_User,'.tif')); %Reads the i-th red image based on the directory and image name and saves it as a variable.
            Channel_Green = imread(strcat(FileDirectory_User,'/',FileNameScheme_User,'_',I,'_',Green_User,'.tif')); %Reads the i-th green image based on the directory and image name and saves it as a variable.
            Channel_Cyan = imread(strcat(FileDirectory_User,'/',FileNameScheme_User,'_',I,'_',Cyan_User,'.tif')); %Reads the i-th cyan image based on the directory and image name and saves it as a variable.

        else
           
            Channel_Blue = imread(strcat(FileDirectory_User,'\',FileNameScheme_User,'_',I,'_',DAPI_User,'.tif')); %Reads the i-th DAPI image based on the directory and image name and saves it as a variable.
            Channel_Red = imread(strcat(FileDirectory_User,'\',FileNameScheme_User,'_',I,'_',Red_User,'.tif')); %Reads the i-th red image based on the directory and image name and saves it as a variable.
            Channel_Green = imread(strcat(FileDirectory_User,'\',FileNameScheme_User,'_',I,'_',Green_User,'.tif')); %Reads the i-th green image based on the directory and image name and saves it as a variable.
            Channel_Cyan = imread(strcat(FileDirectory_User,'\',FileNameScheme_User,'_',I,'_',Cyan_User,'.tif')); %Reads the i-th cyan image based on the directory and image name and saves it as a variable.

        end

        %% This sub-section converts the raw DAPI image into a solid binary object so that it can be used to align the image set to an ansterior-posterior axis.

        Channel_Blue_Gray =im2gray(Channel_Blue); %Converts the raw image to gray scale and assigns it to a variable.
        Channel_Blue_BW = imbinarize(Channel_Blue_Gray); %Converts the grayscale image to a binary image and saves it to a variable.
        Channel_Blue_BW = imfill(Channel_Blue_BW,8,"holes"); %Fills in holes to fill in gaps to try to form one solid object.
        se = strel('disk',25); %Defines the object to use to connect objects in the binary image.
        Channel_Blue_BW = imclose(Channel_Blue_BW,se); %Tries to connect nearby objects in the binary image.
        Channel_Blue_BW = imfill(Channel_Blue_BW,8,"holes"); %Fills in any remaining holes to try to form one solid gastruloid.
        Channel_Blue_AreaLim = bwareaopen(Channel_Blue_BW,GastruloidMinSize); %Filters out objects smaller than the previously defined size as specified by the user.

        %% This sub-section processes the binary DAPI image to identify a region of interest (the gastruloid) to determine its orientation in the picture.

        Channel_Blue_Info = struct2cell(regionprops(Channel_Blue_AreaLim,'Area','Orientation')); %Extracts information from the DAPI binary image related to the size and orientation of the detected object.
        [Blue_Max_Area, Blue_Max_Orientation_Location] = max(cell2mat(Channel_Blue_Info(1,:))); %Determines the object in the DAPI binary image with the maximum area and it's corresponding orientation for its longest axis.
        Gastruloid_Orientation = cell2mat(Channel_Blue_Info(2,Blue_Max_Orientation_Location)); %Creates a variable for the orientation of the gastruloid as determined in the previous step.
     
        %% This sub-section rotates each channel's image based on the determined gastruloid orientation.

        Channel_Red = imrotate(Channel_Red,-Gastruloid_Orientation,"loose"); %Rotates the red channel's image.
        Channel_Blue = imrotate(Channel_Blue,-Gastruloid_Orientation,"loose"); %Rotates the blue channel's image.
        Channel_Green = imrotate(Channel_Green,-Gastruloid_Orientation,"loose"); %Rotates the green channel's image.
        Channel_Cyan = imrotate(Channel_Cyan,-Gastruloid_Orientation,"loose"); %Rotates the cyan channel's image.

        %% This sub-section converts the raw green channel image into a solid binary object so that it can be used to determine whether the images need to be flipped horizontally or not.

        Channel_Green_Gray =im2gray(Channel_Green); %Converts the raw green channel image to gray scale and assigns it to a variable.
        Channel_Green_NonZeroPixels = sum(Channel_Green_Gray(:) ~=0); %Counts the number of non-zero pixels in the channel green gray image.
        Channel_Green_AvgInt = sum(sum(Channel_Green_Gray))/(Channel_Green_NonZeroPixels); %Divides the total pixel intensity by the number of positive pixels in the channel green gray image to determine the average intensity.
        Channel_Green_Threshold = 4*Channel_Green_AvgInt/255; %Sets a treshold for binarizing the green channel gray image to convert it to a binary image. The factor of 4 was determined through testing to reliably convert positive signal to an object.
        Channel_Green_BW = imbinarize(Channel_Green, Channel_Green_Threshold); %Converts the green channel image to a binary image based on the threshold determined above.
        Channel_Green_BW = imfill(Channel_Green_BW,8,"holes"); %Fills gaps between objects in the green channel binary image.
        Channel_Green_BW = imclose(Channel_Green_BW,se); %Connects objects close to each other, using the previously defined object, in the green channel binary image.
        Channel_Green_BW = imfill(Channel_Green_BW,8,"holes"); %Fills any remaining gaps between objects in the green channel binary image.
        Channel_Green_AreaLim = bwareaopen(Channel_Green_BW,GastruloidMinSize); %Filters out objects smaller than the size specified by the user.

        %% This sub-section determines whether the images need to be flipped horizontally in order for the green object to be localized on the left side.
        
        Channel_Green_Info = struct2cell(regionprops(Channel_Green_AreaLim,'Centroid','Area')); %Creates an array of detected object's area and center for objects in the green channel binary image.
        [Green_Max_Area, Green_Max_Loc] = max(cell2mat(Channel_Green_Info(1,:))); %Determines which object has the maximum area and creates variables for that area and which object it was for the green channel binary image.
        Channel_Green_Centroid = cell2mat(Channel_Green_Info(2,Green_Max_Loc)); %Creates a variable for the center location of the object with the maximum area in the green channel binary image.
        Channel_Green_X = Channel_Green_Centroid(1); %Creates a variable for only the x-coordinate of the center of the object with the maximum area in the green channel binary image.
        Channel_Green_Width = size(Channel_Green,2); %Determines the size of the green channel raw image.
        Green_Relative_Position = Channel_Green_X/Channel_Green_Width; %Determines whether the green channel object is more localized to the left or right of the image.
       
       %% This sub-section flips each channel's images if the green channel is localized on the right, so that the green channel will be localized on the left. 
        
       if Green_Relative_Position > 0.5 %If the green channel is more localized to the right, then it flips all channel images so that the green channel is localized to the left.
            
            Channel_Red = flip(Channel_Red,2); %Flips the red channel.
            Channel_Blue = flip(Channel_Blue,2); %Flips the blue channel.
            Channel_Green = flip(Channel_Green,2); %Flips the green channel.
            Channel_Cyan = flip(Channel_Cyan,2); %Flips the cyan channel.

        end

        %% This sub-section begins creating the figures to display the results.

        figure(i) %Creates a figure for the current image set.
        
        subplot(3,2,1) %Designates that the next plot/image will be displayed in the first subplot of a 3x2 array.
        imshow(Channel_Blue) %Displays the blue channel's image in the 1st subplot position.
        title('DAPI','fontsize',16,'color','blue','fontweight','bold','fontname','Arial') %Sets the title for DAPI image.

        subplot(3,2,2) %Designates that the next plot/image will be displayed in the second subplot of a 3x2 array.
        imshow(Channel_Green) %Displays the green channel's image in the 2nd subplot position.
        title(Green_Marker,'fontsize',16,'color','green','fontweight','bold','fontname','Arial') %Sets the title for the green channel's image based on the marker defined by the user.

        subplot(3,2,3) %Designates that the next plot/image will be displayed in the third subplot of a 3x2 array.
        imshow(Channel_Red) %Displays the red channel's image in the 3rd subplot position.
        title(Red_Marker,'fontsize',16,'color','red','fontweight','bold','fontname','Arial') %Sets the title for the red channel's image based on the marker defined by the user.
       
        subplot(3,2,4) %Designates that the next plot/image will be displayed in the fourth subplot of a 3x2 array.
        imshow(Channel_Cyan) %Displays the cyan channel's image in the 4th subplot position.
        title(Cyan_Marker,'fontsize',16,'color','cyan','fontweight','bold','fontname','Arial') %Sets the title for the cyan channel's image based on the marker defined by the user.
        
        %% This sub-section converts the realigned channel images into gray scale.
        
        Channel_Blue_GS = im2gray(Channel_Blue); %Converts the realigned blue image to gray scale.
        Channel_Red_GS = im2gray(Channel_Red); %Converts the realigned red image to gray scale.
        Channel_Green_GS = im2gray(Channel_Green); %Converts the realigned green image to gray scale.
        Channel_Cyan_GS = im2gray(Channel_Cyan); %Converts the realigned cyan image to gray scale.

        %% This sub-section begins to identify the gastruloid boundaries based off of the nuclei signal.

        Channel_Blue_GS_BW = logical(Channel_Blue_GS); %Converts the gray scale DAPI image to a binary image for where there is signal.
        Channel_Blue_ROIs = bwconncomp(Channel_Blue_GS_BW,4); %Finds objects based on connected pixels in the logical image.
        Channel_Blue_Found_ROIs = regionprops(Channel_Blue_ROIs,'SubarrayIdx'); %Indexes the found objects.
        Channel_Blue_Found_ROIs_cell = struct2cell(Channel_Blue_Found_ROIs); %Converts the found objects to an array.
        Channel_Blue_Isolated_ROIs = arrayfun(@(s)Channel_Blue_GS(s.SubarrayIdx{:}),Channel_Blue_Found_ROIs,'uniform',0); %Extracts info about the found objects.
        [ROIs_RowLength,ROIs_ColLength] = cellfun(@size,Channel_Blue_Isolated_ROIs); %Extracts the sizes of the found objects.
        [Nuclei_Width,Nuclei_Cell_Index] = max(ROIs_ColLength); %Finds the largest ROI based on width.
        Nuclei_Position_Matrix = Channel_Blue_Found_ROIs_cell{Nuclei_Cell_Index}; %Creates a matrix with the pixel locations of the ROI.

       %% This sub-section defines the positions of the gastruloid boundaries.

        Nuclei_XAxis_Positions = cell2mat(Nuclei_Position_Matrix(2)); %Creates a variable with the x-axis positions of the pixels in the ROI.
        Nuclei_YAxis_Positions = cell2mat(Nuclei_Position_Matrix(1)); %Creates a variable with the y-axis positions of the pixels in the ROI.
        Top_Y = Nuclei_YAxis_Positions(1); %Creates a variable for the upper limit of the detected gastruloid.
        Bottom_Y = Nuclei_YAxis_Positions(end); %Creates a variable for the lower limit of the detected gastruloid.
        Left_X = Nuclei_XAxis_Positions(1); %Creates a variable for the left limit of the detected gastruloid.
        Right_X = Nuclei_XAxis_Positions(end); %Creates a variable for the right limit of the detected gastruloid.
        XScale = length(Nuclei_XAxis_Positions); %Determines the length of the gastruloid.
        XScale = 1:XScale; %Creates a variable the size of the length of the gastruloid.
        XScale = XScale/length(XScale); %Normalizes the size variable to the size of the gastruloid so that it spans from 0 to 1.
        xScale2 = linspace(0,1,10000); %Creates a length scale from 0 to 10000.

        %% This sub-section begins to quantify the fluorescence intensity as a function of the position along the anterior-posterior axis.

        Channel_Blue_GS = Channel_Blue_Isolated_ROIs{Nuclei_Cell_Index}; %Creates an image of the isolated ROI.
        Blue_Total_Col = sum(Channel_Blue_GS,1); %Sums the fluorescence intensity in each column.
        Blue_Interpolate(i,:) = interp1(XScale, Blue_Total_Col, xScale2); %Interpolates the fluorescence intensity per column over a consistent 10000 range space.
        
        Channel_Red_Object = Channel_Red_GS(Top_Y:Bottom_Y, Left_X:Right_X); %Creates an image of the red channel using the isolated DAPI ROI.
        Red_Total_Col = sum(Channel_Red_Object,1); %Sums the fluorescence intensity in each column.
        Red_Interpolate(i,:) = interp1(XScale,Red_Total_Col, xScale2); %Interpolates the data from the red channel into a consistent 10000 length array.

        Channel_Green_Object = Channel_Green_GS(Top_Y:Bottom_Y, Left_X:Right_X); %Creates an image of the green channel using the isolated DAPI ROI.
        Green_Total_Col = sum(Channel_Green_Object,1); %Sums the fluorescence intensity in each column.
        Green_Interpolate(i,:) = interp1(XScale,Green_Total_Col, xScale2); %Interpolates the data from the green channel into a consistent 10000 length array.

        Channel_Cyan_Object = Channel_Cyan_GS(Top_Y:Bottom_Y, Left_X:Right_X); %Creates an image of the cyan channel using the isolated DAPI ROI.       
        Cyan_Total_Col = sum(Channel_Cyan_Object,1); %Sums the fluorescence intensity in each column.
        Cyan_Interpolate(i,:) = interp1(XScale,Cyan_Total_Col, xScale2); %Interpolates the data from the cyan channel into a consistent 10000 length array.
    
    %% This section is for processing 3-channel image sets.
   
    elseif Number_Channels == 3
                
        %% This sub-section defines the image file location based on if the user is using a mac or windows device.
        
        if ismac == 1
            
            Channel_Blue = imread(strcat(FileDirectory_User,'/',FileNameScheme_User,'_',I,'_',DAPI_User,'.tif')); %Reads the i-th DAPI image based on the directory and image name and saves it as a variable.
            Channel_Red = imread(strcat(FileDirectory_User,'/',FileNameScheme_User,'_',I,'_',Red_User,'.tif')); %Reads the i-th red image based on the directory and image name and saves it as a variable.
            Channel_Green = imread(strcat(FileDirectory_User,'/',FileNameScheme_User,'_',I,'_',Green_User,'.tif')); %Reads the i-th green image based on the directory and image name and saves it as a variable.

        else
           
            Channel_Blue = imread(strcat(FileDirectory_User,'\',FileNameScheme_User,'_',I,'_',DAPI_User,'.tif')); %Reads the i-th DAPI image based on the directory and image name and saves it as a variable.
            Channel_Red = imread(strcat(FileDirectory_User,'\',FileNameScheme_User,'_',I,'_',Red_User,'.tif')); %Reads the i-th red image based on the directory and image name and saves it as a variable.
            Channel_Green = imread(strcat(FileDirectory_User,'\',FileNameScheme_User,'_',I,'_',Green_User,'.tif')); %Reads the i-th green image based on the directory and image name and saves it as a variable.

        end

        %% This sub-section converts the raw DAPI image into a solid binary object so that it can be used to align the image set to an ansterior-posterior axis.

        Channel_Blue_Gray =im2gray(Channel_Blue); %Converts the raw image to gray scale and assigns it to a variable.
        Channel_Blue_BW = imbinarize(Channel_Blue_Gray); %Converts the grayscale image to a binary image and saves it to a variable.
        Channel_Blue_BW = imfill(Channel_Blue_BW,8,"holes"); %Fills in holes to fill in gaps to try to form one solid object.
        se = strel('disk',25); %Defines the object to use to connect objects in the binary image.
        Channel_Blue_BW = imclose(Channel_Blue_BW,se); %Tries to connect nearby objects in the binary image.
        Channel_Blue_BW = imfill(Channel_Blue_BW,8,"holes"); %Fills in any remaining holes to try to form one solid gastruloid.
        Channel_Blue_AreaLim = bwareaopen(Channel_Blue_BW,GastruloidMinSize); %Filters out objects smaller than the previously defined size as specified by the user.

        %% This sub-section processes the binary DAPI image to identify a region of interest (the gastruloid) to determine its orientation in the picture.

        Channel_Blue_Info = struct2cell(regionprops(Channel_Blue_AreaLim,'Area','Orientation')); %Extracts information from the DAPI binary image related to the size and orientation of the detected object.
        [Blue_Max_Area, Blue_Max_Orientation_Location] = max(cell2mat(Channel_Blue_Info(1,:))); %Determines the object in the DAPI binary image with the maximum area and it's corresponding orientation for its longest axis.
        Gastruloid_Orientation = cell2mat(Channel_Blue_Info(2,Blue_Max_Orientation_Location)); %Creates a variable for the orientation of the gastruloid as determined in the previous step.
     
        %% This sub-section rotates each channel's image based on the determined gastruloid orientation.

        Channel_Red = imrotate(Channel_Red,-Gastruloid_Orientation,"loose"); %Rotates the red channel's image.
        Channel_Blue = imrotate(Channel_Blue,-Gastruloid_Orientation,"loose"); %Rotates the blue channel's image.
        Channel_Green = imrotate(Channel_Green,-Gastruloid_Orientation,"loose"); %Rotates the green channel's image.

        %% This sub-section converts the raw green channel image into a solid binary object so that it can be used to determine whether the images need to be flipped horizontally or not.

        Channel_Green_Gray =im2gray(Channel_Green); %Converts the raw green channel image to gray scale and assigns it to a variable.
        Channel_Green_NonZeroPixels = sum(Channel_Green_Gray(:) ~=0); %Counts the number of non-zero pixels in the channel green gray image.
        Channel_Green_AvgInt = sum(sum(Channel_Green_Gray))/(Channel_Green_NonZeroPixels); %Divides the total pixel intensity by the number of positive pixels in the channel green gray image to determine the average intensity.
        Channel_Green_Threshold = 4*Channel_Green_AvgInt/255; %Sets a treshold for binarizing the green channel gray image to convert it to a binary image. The factor of 4 was determined through testing to reliably convert positive signal to an object.
        Channel_Green_BW = imbinarize(Channel_Green, Channel_Green_Threshold); %Converts the green channel image to a binary image based on the threshold determined above.
        Channel_Green_BW = imfill(Channel_Green_BW,8,"holes"); %Fills gaps between objects in the green channel binary image.
        Channel_Green_BW = imclose(Channel_Green_BW,se); %Connects objects close to each other, using the previously defined object, in the green channel binary image.
        Channel_Green_BW = imfill(Channel_Green_BW,8,"holes"); %Fills any remaining gaps between objects in the green channel binary image.
        Channel_Green_AreaLim = bwareaopen(Channel_Green_BW,GastruloidMinSize); %Filters out objects smaller than the size specified by the user.

        %% This sub-section determines whether the images need to be flipped horizontally in order for the green object to be localized on the left side.
        
        Channel_Green_Info = struct2cell(regionprops(Channel_Green_AreaLim,'Centroid','Area')); %Creates an array of detected object's area and center for objects in the green channel binary image.
        [Green_Max_Area, Green_Max_Loc] = max(cell2mat(Channel_Green_Info(1,:))); %Determines which object has the maximum area and creates variables for that area and which object it was for the green channel binary image.
        Channel_Green_Centroid = cell2mat(Channel_Green_Info(2,Green_Max_Loc)); %Creates a variable for the center location of the object with the maximum area in the green channel binary image.
        Channel_Green_X = Channel_Green_Centroid(1); %Creates a variable for only the x-coordinate of the center of the object with the maximum area in the green channel binary image.
        Channel_Green_Width = size(Channel_Green,2); %Determines the size of the green channel raw image.
        Green_Relative_Position = Channel_Green_X/Channel_Green_Width; %Determines whether the green channel object is more localized to the left or right of the image.
       
       %% This sub-section flips each channel's images if the green channel is localized on the right, so that the green channel will be localized on the left. 
        
       if Green_Relative_Position > 0.5 %If the green channel is more localized to the right, then it flips all channel images so that the green channel is localized to the left.
            
            Channel_Red = flip(Channel_Red,2); %Flips the red channel.
            Channel_Blue = flip(Channel_Blue,2); %Flips the blue channel.
            Channel_Green = flip(Channel_Green,2); %Flips the green channel.

        end

        %% This sub-section begins creating the figures to display the results.

        figure(i) %Creates a figure for the current image set.
        
        subplot(3,2,1) %Designates that the next plot/image will be displayed in the first subplot of a 3x2 array.
        imshow(Channel_Blue) %Displays the blue channel's image in the 1st subplot position.
        title('DAPI','fontsize',16,'color','blue','fontweight','bold','fontname','Arial') %Sets the title for DAPI image.

        subplot(3,2,2) %Designates that the next plot/image will be displayed in the second subplot of a 3x2 array.
        imshow(Channel_Green) %Displays the green channel's image in the 2nd subplot position.
        title(Green_Marker,'fontsize',16,'color','green','fontweight','bold','fontname','Arial') %Sets the title for the green channel's image based on the marker defined by the user.

        subplot(3,2,3) %Designates that the next plot/image will be displayed in the third subplot of a 3x2 array.
        imshow(Channel_Red) %Displays the red channel's image in the 3rd subplot position.
        title(Red_Marker,'fontsize',16,'color','red','fontweight','bold','fontname','Arial') %Sets the title for the red channel's image based on the marker defined by the user.
        
        %% This sub-section converts the realigned channel images into gray scale.
        
        Channel_Blue_GS = im2gray(Channel_Blue); %Converts the realigned blue image to gray scale.
        Channel_Red_GS = im2gray(Channel_Red); %Converts the realigned red image to gray scale.
        Channel_Green_GS = im2gray(Channel_Green); %Converts the realigned green image to gray scale.

        %% This sub-section begins to identify the gastruloid boundaries based off of the nuclei signal.

        Channel_Blue_GS_BW = logical(Channel_Blue_GS); %Converts the gray scale DAPI image to a binary image for where there is signal.
        Channel_Blue_ROIs = bwconncomp(Channel_Blue_GS_BW,4); %Finds objects based on connected pixels in the logical image.
        Channel_Blue_Found_ROIs = regionprops(Channel_Blue_ROIs,'SubarrayIdx'); %Indexes the found objects.
        Channel_Blue_Found_ROIs_cell = struct2cell(Channel_Blue_Found_ROIs); %Converts the found objects to an array.
        Channel_Blue_Isolated_ROIs = arrayfun(@(s)Channel_Blue_GS(s.SubarrayIdx{:}),Channel_Blue_Found_ROIs,'uniform',0); %Extracts info about the found objects.
        [ROIs_RowLength,ROIs_ColLength] = cellfun(@size,Channel_Blue_Isolated_ROIs); %Extracts the sizes of the found objects.
        [Nuclei_Width,Nuclei_Cell_Index] = max(ROIs_ColLength); %Finds the largest ROI based on width.
        Nuclei_Position_Matrix = Channel_Blue_Found_ROIs_cell{Nuclei_Cell_Index}; %Creates a matrix with the pixel locations of the ROI.

       %% This sub-section defines the positions of the gastruloid boundaries.

        Nuclei_XAxis_Positions = cell2mat(Nuclei_Position_Matrix(2)); %Creates a variable with the x-axis positions of the pixels in the ROI.
        Nuclei_YAxis_Positions = cell2mat(Nuclei_Position_Matrix(1)); %Creates a variable with the y-axis positions of the pixels in the ROI.
        Top_Y = Nuclei_YAxis_Positions(1); %Creates a variable for the upper limit of the detected gastruloid.
        Bottom_Y = Nuclei_YAxis_Positions(end); %Creates a variable for the lower limit of the detected gastruloid.
        Left_X = Nuclei_XAxis_Positions(1); %Creates a variable for the left limit of the detected gastruloid.
        Right_X = Nuclei_XAxis_Positions(end); %Creates a variable for the right limit of the detected gastruloid.
        XScale = length(Nuclei_XAxis_Positions); %Determines the length of the gastruloid.
        XScale = 1:XScale; %Creates a variable the size of the length of the gastruloid.
        XScale = XScale/length(XScale); %Normalizes the size variable to the size of the gastruloid so that it spans from 0 to 1.
        xScale2 = linspace(0,1,10000); %Creates a length scale from 0 to 10000.

        %% This sub-section begins to quantify the fluorescence intensity as a function of the position along the anterior-posterior axis.

        Channel_Blue_GS = Channel_Blue_Isolated_ROIs{Nuclei_Cell_Index}; %Creates an image of the isolated ROI.
        Blue_Total_Col = sum(Channel_Blue_GS,1); %Sums the fluorescence intensity in each column.
        Blue_Interpolate(i,:) = interp1(XScale, Blue_Total_Col, xScale2); %Interpolates the fluorescence intensity per column over a consistent 10000 range space.
        
        Channel_Red_Object = Channel_Red_GS(Top_Y:Bottom_Y, Left_X:Right_X); %Creates an image of the red channel using the isolated DAPI ROI.
        Red_Total_Col = sum(Channel_Red_Object,1); %Sums the fluorescence intensity in each column.
        Red_Interpolate(i,:) = interp1(XScale,Red_Total_Col, xScale2); %Interpolates the data from the red channel into a consistent 10000 length array.

        Channel_Green_Object = Channel_Green_GS(Top_Y:Bottom_Y, Left_X:Right_X); %Creates an image of the green channel using the isolated DAPI ROI.
        Green_Total_Col = sum(Channel_Green_Object,1); %Sums the fluorescence intensity in each column.
        Green_Interpolate(i,:) = interp1(XScale,Green_Total_Col, xScale2); %Interpolates the data from the green channel into a consistent 10000 length array.

    end %Ends the if loop.

end %Ends the for loop.

%% This section normalizes the data to the max intensity from the entire imaging set per channel.

fprintf('Normalizing the data to the max intensity of all of the images per channel. \n') %Updates the user to what stage the code is on.

Blue_Interpolate(isnan(Blue_Interpolate)) = 0; %This converts any results that are NaN to zero.
Blue_All_Max = max(max(Blue_Interpolate)); %Determines the max intensity of the DAPI channel from all of the image sets.
A_Blue_Results = Blue_Interpolate/Blue_All_Max; %Normalizes the DAPI data to the max DAPI intensity.
Blue_All_Col_Total = sum(A_Blue_Results); %Sums the intensity of all the DAPI image columns.
Blue_All_Col_Avg = Blue_All_Col_Total/Number_Image_Sets; %Averages the DAPI image column intensity by the number of image sets.
A_Results{Number_Image_Sets+2,2} = Blue_All_Col_Avg; %Saves the average DAPI data to the results array.

Red_Interpolate(isnan(Red_Interpolate)) = 0; %This converts any results that are NaN to zero.
Red_All_Max = max(max(Red_Interpolate)); %Determines the max intensity of the red channel from all of the image sets.
A_Red_Results = Red_Interpolate/Red_All_Max; %Normalizes the red data to the max red intensity.
Red_All_Col_Total = sum(A_Red_Results); %Sums the intensity of all the red image columns.
Red_All_Col_Avg = Red_All_Col_Total/Number_Image_Sets; %Averages the red image column intensity by the number of image sets.
A_Results{Number_Image_Sets+2,3} = Red_All_Col_Avg; %Saves the average red data to the results array.

Green_Interpolate(isnan(Green_Interpolate)) = 0; %This converts any results that are NaN to zero.
Green_All_Max = max(max(Green_Interpolate)); %Determines the max intensity of the green channel from all of the image sets.
A_Green_Results = Green_Interpolate/Green_All_Max; %Normalizes the green data to the max green intensity.
Green_All_Col_Total = sum(A_Green_Results); %Sums the intensity of all the green image columns.
Green_All_Col_Avg = Green_All_Col_Total/Number_Image_Sets; %Averages the green image column intensity by the number of image sets.
A_Results{Number_Image_Sets+2,4} = Green_All_Col_Avg; %Saves the average green data to the results array.

if Number_Channels == 4 %Determines whether or not to process a 4th channel.
    
    Cyan_Interpolate(isnan(Cyan_Interpolate)) = 0; %This converts any results that are NaN to zero.
    Cyan_All_Max = max(max(Cyan_Interpolate)); %Determines the max intensity of the cyan channel from all of the image sets.
    A_Cyan_Results = Cyan_Interpolate/Cyan_All_Max; %Normalizes the cyan data to the max cyan intensity.
    Cyan_All_Col_Total = sum(A_Cyan_Results); %Sums the intensity of all the cyan image columns.
    Cyan_All_Col_Avg = Cyan_All_Col_Total/Number_Image_Sets; %Averages the cyan image column intensity by the number of image sets.
    A_Results{Number_Image_Sets+2,5} = Cyan_All_Col_Avg; %Saves the average cyan data to the results array.

end %Ends the if statement.

%% This section plots the normalized data onto the individual image figures.

fprintf('Plotting the histograms. \n') %Updates the user to what stage the code is on.

for i = 1:Number_Image_Sets %Begins loop to plot the normalized data on each data sets' individual figure.

    figure(i) %Defines the figure to plot the data to.
    sgtitle(A_Results(i+1,1),'fontsize',16,'fontweight','bold','fontname','Arial','interpreter','none') %Titles the figure with the image name
    subplot(3,2,[5,6]) %Defines the region of the subplots to plot the data to.
    hold on %Allows multiple plots to be generated on the same graph.
    plot(xScale2,A_Blue_Results(i,:),'b') %Plots the blue normalized data.
    plot(xScale2,A_Red_Results(i,:),'r') %Plots the red normalized data.
    plot(xScale2,A_Green_Results(i,:),'g') %Plots the green normalized data.
    if Number_Channels == 4 %Checks to see if there is a cyan channel.
    plot(xScale2,A_Cyan_Results(i,:),'c') %Plots the cyan normalized data.
    end %Ends if statement.
    ylim([0 1]) %Sets the y-axis to go from 0 to 1.
    ylabel('Normalized Intensity') %Labels the y-axis.
    xlabel('Relative Length (Anterior to Posterior)') %Labels the x-axis.
    if Number_Channels == 4 %Checks to see if there is a cyan channel.
        legend('DAPI',Red_Marker, Green_Marker, Cyan_Marker) %Generates the legend based on the markers.
    else
        legend('DAPI',Red_Marker, Green_Marker) %Generates the legend based on the markers.
    end %Ends if statement.
    hold off %Ends the plot hold so that new graphs will overwrite the next plot.
    
    %% This sub-section saves the normalized data to the results array.

    A_Results{i+1,2} = A_Blue_Results(i,:); %Saves the DAPI normalized results for the individual images to the results array.
    A_Results{i+1,3} = A_Red_Results(i,:); %Saves the red normalized results for the individual images to the results array.
    A_Results{i+1,4} = A_Green_Results(i,:); %Saves the green normalized results for the individual images to the results array.
    if Number_Channels == 4 %Checks to see if there is a cyan channel.
        A_Results{i+1,5} = A_Cyan_Results(i,:); %Saves the cyan normalized results for the individual images to the results array.
    end %Ends the if statement.
    
end %Ends the for loop.

%% Plots the normalized data and average data for each channel.

fprintf('Generating final plots. \n')

xScale2 = linspace(0, 10, 10000)
figure(Number_Image_Sets+1) %Creates a new figure to plot all of the DAPI data.
hold on %Allows multiple data sets to be plotted on one graph without overwriting each other.
plot(xScale2,A_Blue_Results,'LineWidth',0.5,'Color','black') %Plots the individual image set data as black lines.
plot(xScale2,Blue_All_Col_Avg,'LineWidth',4,'Color','blue') %Plots the average data set as a blue line.
title('DAPI','color','blue','FontSize',32) %Defines the title for the figure.
xlabel('Relative Length (Anterior to Posterior)') %Defines the x-axis label.
ylabel('Normalized Intensity') %Defines the y-axis label.
hold off %Ends the graph hold.

figure(Number_Image_Sets+2) %Creates a new figure.
hold on %Allows multiple data sets to be plotted on one graph without overwriting each other.
plot(xScale2,A_Red_Results,'LineWidth',0.5,'Color','black') %Plots the individual image set data as black lines.
plot(xScale2,Red_All_Col_Avg,'LineWidth',4,'Color','red') %Plots the average data set as a red line.
title(Red_Marker,'color','red','FontSize',32) %Defines the title for the figure.
xlabel('Relative Length (Anterior to Posterior)') %Defines the x-axis label.
ylabel('Normalized Intensity') %Defines the y-axis label.
hold off %Ends the graph hold.

figure(Number_Image_Sets+3) %Creates a new figure.
hold on %Allows multiple data sets to be plotted on one graph without overwriting each other.
plot(xScale2,A_Green_Results,'LineWidth',0.5,'Color','black') %Plots the individual image set data as black lines.
plot(xScale2,Green_All_Col_Avg,'LineWidth',4,'Color','green') %Plots the average data set as a green line.
title(Green_Marker,'color','green','FontSize',32) %Defines the title for the figure.
xlabel('Relative Length (Anterior to Posterior)') %Defines the x-axis label.
ylabel('Normalized Intensity') %Defines the y-axis label.
hold off %Ends the graph hold.

if Number_Channels == 4 %Checks to see if there is a cyan channel.
    figure(Number_Image_Sets+4) %Creates a new figure.
    hold on %Allows multiple data sets to be plotted on one graph without overwriting each other.
    plot(xScale2,A_Cyan_Results,'LineWidth',0.5,'Color','black') %Plots the individual image set data as black lines.
    plot(xScale2,Cyan_All_Col_Avg,'LineWidth',4,'Color','cyan') %Plots the average data set as a cyan line.
    title(Cyan_Marker,'color','cyan','FontSize',32) %Defines the title for the figure.
    xlabel('Relative Length (Anterior to Posterior)') %Defines the x-axis label.
    ylabel('Normalized Intensity') %Defines the y-axis label.
    hold off %Ends the graph hold.
end %Ends the if statement.

fprintf('Analysis complete. \n')
