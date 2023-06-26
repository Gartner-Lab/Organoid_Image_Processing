# Code for fetching images and moving them to the desired Example Images folder

# Set up directories ----
box_parent_dir <- '/Users/Vasudha/Box Sync/Gartnerlab Data/Individual Folders/'
if (!dir.exists(box_parent_dir)) { box_parent_dir <- '/Users/jhu/Box/Gartnerlab Data/Individual Folders/' }
box_dir <- file.path(box_parent_dir, "Vasudha Srivastava/codes/")
setwd(file.path(box_dir, "self_organization"))
save_dir <- file.path(box_dir, "Paper figures/")
robj_dir <- paste0(save_dir,"R_objects/")
new_quant_id <- readRDS(file = paste0(robj_dir, "new_quant_id.rds"))

source(file.path(box_parent_dir, 'Jennifer Hu', 'Analysis', 'Graphing', 'constants.r'))
imsource_dir <- file.path(dir.data.org, 'Slices', 'SBG')
imdest_dir <- file.path(dir.data.org, 'Examples')

# Set up indices for subsetting ----
clean_idx <- between(new_quant_id$Edge_LEP_Fraction,0,1) & 
  new_quant_id$timepoint %in% c("1d","2d") & new_quant_id$Circularity > 0.7 & 
  new_quant_id$lumen == 0
# a list of standards to mix and match
idx <- list(strain = (new_quant_id$strain == '240L'), size = between(new_quant_id$uArea,3000,10000),
            ECM = new_quant_id$ECM %in% c(1,-1), drug = new_quant_id$drug %in% c('', 'DMSO', 'TFA'),
            MF = between(new_quant_id$MEP_Fraction, 0.4, 0.6))
# don't exclude conditions if you want to plot them
subidx_ECM <- clean_idx & idx[['size']] & idx[['strain']] & idx[['MF']] & idx[['drug']]
subidx_strains <- clean_idx & idx[['size']] & idx[['ECM']] & idx[['MF']] & idx[['drug']]
subidx_sizes <- clean_idx & idx[['strain']] & idx[['ECM']] & idx[['MF']] & idx[['drug']]
subidx_MF <- clean_idx & idx[['strain']] & idx[['size']] & idx[['ECM']] & idx[['drug']] &
  between(new_quant_id$uArea,3000,9000) # MF is more susceptible to error w/size
subidx_drug <- clean_idx & idx[['strain']] & idx[['size']] & idx[['MF']] & new_quant_id$ECM == 1
# most of the time you just want the controls though
subidx <- clean_idx & idx[['strain']] & idx[['size']] & idx[['ECM']] & idx[['MF']] & idx[['drug']]

# Decide on subsets of the data and how many (max) to sample ----
max_images = 10
typenames <- c('GFP Matrigel', 'GFP agarose', 'MEP Matrigel', 'MEP agarose',
               'TLN1shMM Matrigel', 'TLN1shMM agarose', 'CTNND1shMM Matrigel', 'CTNND1shMM agarose',
               'H1047R DMSO', 'H1047R MK2206', 'H1047R puro', 'H1047R TLN1sh');
typesets <- list(
  which(subidx & new_quant_id$virus %in% c("GFP") & new_quant_id$ECM==1 & new_quant_id$timepoint=='2d' & !grepl('mCh', new_quant_id$name)),
  which(subidx & new_quant_id$virus %in% c("GFP") & new_quant_id$ECM==-1 & new_quant_id$timepoint=='1d' & !grepl('mCh', new_quant_id$name)),
  which(subidx & new_quant_id$virus %in% c("GFPM+mChM","GFP_puroM+mCh_puroM") & new_quant_id$ECM==1 & new_quant_id$timepoint=='2d'),
  which(subidx & new_quant_id$virus %in% c("GFPM+mChM","GFP_puroM+mCh_puroM") & new_quant_id$ECM==-1 & new_quant_id$timepoint=='1d'),
  which(subidx & new_quant_id$virus %in% c("TLN1sh1M+mChM","GFP_TLN1sh1puroM+mCh_puroM") & new_quant_id$ECM==1 & new_quant_id$timepoint=='2d'),
  which(subidx & new_quant_id$virus %in% c("TLN1sh1M+mChM","GFP_TLN1sh1puroM+mCh_puroM") & new_quant_id$ECM==-1 & new_quant_id$timepoint=='1d'),
  which(subidx & new_quant_id$virus %in% c("CTNND1sh1M+mChM","GFP_CTNND1sh1puroM+mCh_puroM") & new_quant_id$ECM==1 & new_quant_id$timepoint=='2d'),
  which(subidx & new_quant_id$virus %in% c("CTNND1sh1M+mChM","GFP_CTNND1sh1puroM+mCh_puroM") & new_quant_id$ECM==-1 & new_quant_id$timepoint=='1d'),
  which(subidx_drug & new_quant_id$virus %in% c("H1047R","H1047R_puro") & new_quant_id$drug %in% "DMSO" & new_quant_id$timepoint=='2d'),
  which(subidx_drug & new_quant_id$virus %in% c("H1047R","H1047R_puro") & new_quant_id$drug %in% "MK2206" & new_quant_id$timepoint=='2d'),
  which(subidx & new_quant_id$virus %in% c("H1047R_puro") & new_quant_id$ECM==1 & new_quant_id$timepoint=='2d'),
  which(subidx & new_quant_id$virus %in% c("H1047R_TLN1sh1puro") & new_quant_id$ECM==1 & new_quant_id$timepoint=='2d')
); names(typesets) <- typenames
# create the destination directories
outdirs <- c(file.path(imdest_dir, 'SBG', typenames), file.path(imdest_dir, 'Cleaned', typenames), 
             file.path(imdest_dir, 'czi', typenames))
if (any(!dir.exists(outdirs))) { sapply(outdirs[!dir.exists(outdirs)], function(x) {dir.create(x, recursive = T)}) }

# Collect rows to sample ----
examples_quant_id <- bind_rows(lapply(typenames, FUN = function(type) {
  idx <- typesets[[type]]
  sub_data <- new_quant_id[idx,]
  sub_data$typename <- type
  if (length(idx) <= max_images) {
    example_data <- sub_data
  } else {
    # otherwise, choose a subset that most resembles the average EL and MF = 0.5
    vars <- c('MEP_Fraction', 'Edge_LEP_Fraction')
    avgs <- colMeans(sub_data[, vars]);  diffs <- rowSums((sub_data[,vars] - avgs)^2)
    # select the first max_images in ascending order of diffs
    idx <- order(diffs)[1:10]
    example_data <- sub_data[idx,]
    print(type); print(avgs)
  }
  # Copy images into Examples folder ----
  file.copy(from = file.path(imsource_dir, example_data$imgtype, 'done', paste0(example_data$imfilename,'.png')),
            to = file.path(imdest_dir, 'SBG', type, paste0(example_data$imfilename,'.png')))
  file.copy(from = file.path(dir.data.org, 'Slices', 'masks', 'Cleaned', paste0(example_data$imfilename,'.png')),
            to = file.path(imdest_dir, 'Cleaned', type, paste0(example_data$imfilename,'.png')))
  file.copy(from = file.path(dir.Box, 'Microscopy', 'organization', example_data$folder, paste0(example_data$name)),
            to = file.path(imdest_dir, 'czi', type, paste0(example_data$name)))
  # Return
  return(example_data)
}))

write.csv(examples_quant_id, file.path(imdest_dir, 'example_images.csv'), quote = F, row.names = F)
