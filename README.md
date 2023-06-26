# Organoid_Image_Processing
Custom MATLAB and R scripts for the processing and quantification of mammary organoid images

# Image annotation and pre-processing
Summary: Annotation Helper allows the user to view and annotate z-stack images from several folders. The annotation information is used to 1) generate single z-slices for downstream image analysis and 2) build a table of manually assigned organization outcomes for different conditions.
The single z-slices are binarized, cleaned by the user, and quantified. The resulting image data is merged with information on the independent variables and manually assigned organization outcomes.

Main programs:
- constants.m 				  Shared variables
- class_helper.m 			  Manual annotation
- slice_imgs.m 				  Generate center slices
- process_classed.m 		Assign conditions from filename
- learning.m 				    Compile pixel classifier training data
- classify_pixels.m 		 Generate classified masks
- edit_pixels.m 			  Manually refine classified masks
- process_edits.m 			Smoothen edited masks
- quantify.m 				    Generate metrics from masks
- constants.r 				  Shared variables
- identify.r 				    Combine conditions and metrics
- plot_classed.r 			  Plot all annotations
- plot_metrics.r 			  Plot annotations/metrics

Main data files:
- dir_csv 				    dir_info.csv
- savefile 				    classed.csv
- processedfile 			classed_processed.csv
- slicedatafile 			slice_data.csv
- quantifile 				  quantified.csv
- identifile 				  quantified+IDs.csv

----------------------------------------------------------------------------
Setup:
constants.m
Contains shared constants and directory names. Editing this file allows you to change which folders are used for input and output, which models are loaded, which features are used in pixel assignment, which metrics are to be quantified, and so on. Correct parsing of file/folder names requires accurate, up-to-date info in all_strains and all_dates.

dir_csv
All folders to be processed are listed in dir_csv, which lists folder names and identifies channels. Folders can be included or excluded here. Each folder must contain the date, formatted as 'yyyy-MM-dd' ('2016-05-22'). The function dir_csv_builder can be used to generate a list of folders as a starting point. Appending to save files is based on row number (i) within the table(include == 1 && imgtype == imgtype), so:
- any new folder must be added to the end of the list
- any row with include == 0
	- can be deleted without consequence
	- must be re-added to the end if you want to change include == 1
- never change the number or names of files in folders that have been processed

----------------------------------------------------------------------------
Annotation Helper/
Code related to manual assignment of outcomes, identifying center slices, and generating images and information from those annotations. Main outputs are processedfile, slicedatafile, and sliced images.

class_helper.m
Iterates through dir_csv, using row number (i) and file number (j) to identify each image file. Z-stack images are displayed as 20-panel montages with labeled slices, which can be moved by scrolling up and down. The user is prompted to identify the organization outcome, lumenization outcome, and (if applicable) z-slices where only one organoid is visible. Organization and lumenization outcomes, separated by semicolons, should correspond to the same organoid. New results will be appended to the existing savefile: i,j,folder,name,outcomes,lumens,center. Any skipped files can be re-added using fill_skipped, so long as i and j are the same.

process_classed.m
Reads savefile produced by class_helper and pulls up folder/file name. Excludes any rows with no recorded outcomes. Checks names against known constants at the beginning of the file: all_strains, all_dates, all_timepts. If the file name contains strings like ' d', ' s', 'p16', or 'GFP', requests remaining information from user. Information is reused for consecutive files with almost-identical names. Splits lines including multiple annotations into separate lines. Saves new csv in processedfile.
Format of classed.csv = i,j,folder,name,outcomes,lumens,center
Format of classed_processed.csv =
	r,i,j,folder,name,outcome,lumen,center,date,timepoint,strain,
	confluence,MG_density,drug,virus,FDG
confluence [-1,0,1] = under, confluent, over
MG_density [0, 1] = low, high/normal
FDG ['','l','h'] = none, FDG-low, FDG-high

slice_imgs.m
Reads processedfile produced by process_classed. Opens original image files and extracts slices of centers, saved as RGB in the form {name}_r#_s#, recording row in savefile (r) and slice (s). If MG channel is present, save as B channel. Saves slice info (organization and lumenization outcome) in slicedatafile.

----------------------------------------------------------------------------
# Pixel Classification
Pixel Classification was done in Ilastik (https://www.ilastik.org/index.html). Alternatively, code related to assigning LEP, MEP, and MG identities to cells based on fluorescence intensity in MATLAB is included here. Main outputs are edited masks and models.

learning.m
Uses segmented files in maskdir/edited and original images in inputdir/ to generate a training dataset that can be loaded into Matlab's Classification Learner App for easy machine learning training. Metrics are produced by calculate_features and named by constants.

classify_pixels.m
Uses trained model on images and displays results of segmentation side-by-side with original image. Segmentation is further processed by several functions in Region Processing. Saves processed masks & masks file in maskdir.

edit_pixels.m
Reads masks in maskdir/modelname/, /edited, and original files. Skips any masks that already have been added to /edited. Prompts user to edit by drawing to add to L, M, and MG regions. New masks are saved in /edited. (Since I prefer the image files over a single huge editmasks file, I commented out those lines.)

----------------------------------------------------------------------------
# Image post-processing and quantification
Code related to smoothing and filling holes in binary or L/M/MG regions.

clean_masks.m
Removes very small L/M regions, fills in holes/lumens, and smoothens borders of regions. If these result in double-positive pixels, reverts them.

process_segmentation.m
Processes MEP/LEP [0 1 2] images in preparation for quantification. Removes LEPs and MEPs off to the side/not attached to organoid. Fills in "cracks" and holes of organoid by defining a minimal convex hull and using fill_regions.

quantify.m
Iterates through edited+processed and assigns each image a row of metrics produced by quantify_img. Creates quantified.csv and saves the idealized and core/shell images of each organoid.

quantify_img.m
Code for measuring and producing metrics. List of metrics is in constants.m.

identify.r
Uses row and slice # (r and s) as identifying variables to join data from processedfile and quantifile.

----------------------------------------------------------------------------

# Analysis of time lapse microscopy images
Code related to smoothing and filling holes in binary or L/M/MG regions for time lapse images. Segmented multipage tiff files are used as inputs.

process_segmentation_multipage.m
Processes MEP/LEP [0 1 2] images in preparation for quantification. Find 3 center z-slices. Removes LEPs and MEPs off to the side/not attached to organoid. Fills in "cracks" and holes of organoid by defining a minimal convex hull and using fill_regions.

----------------------------------------------------------------------------

# Analysis of human breast tissue sections
Code related to smoothing and filling holes in binary or L/M/MG regions for human tissue sections. 

process_segmentation_multipage.m
Processes MEP/LEP [0 1 2] images in preparation for quantification. Removes LEPs and MEPs off to the side/not attached to organoid. Fills in "cracks" and holes of organoid by defining a minimal convex hull and using fill_regions. Slightly differnt feature sizes are used compared to the code for the processing of organoid images.


----------------------------------------------------------------------------
