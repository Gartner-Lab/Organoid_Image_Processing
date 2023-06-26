if(dir.exists("/Users/Vasudha/Library/CloudStorage/Box-Box/")) {
  box_dir <- "/Users/Vasudha/Library/CloudStorage/Box-Box/Gartnerlab Data"
} else {
  box_dir <- "/Users/Vasudha/Box Sync/Gartnerlab Data"
}

if (!exists("out_to_outcome", mode = "function")) { 
  # source(file.path('/Users/jhu/Box', 'Gartnerlab Data', 'Individual Folders',
  #                  'Jennifer Hu','Analysis','Graphing','constants.r') )
  source(file.path(box_dir, 'Individual Folders',
                   'Jennifer Hu','Analysis','Graphing','constants.r') )
}
classeddata <- read.csv(file.processed, as.is=T, stringsAsFactors=T) %>%
  filter(!is.na(center)) %>%
  mutate(imfilename = paste0(sprintf('%s_r%s_s%s', 
                                     gsub(pattern = '.czi', replacement = '', name),
                                     r, center)))
classeddata[is.na(classeddata$lumen),'lumen'] <- 0

# Create new set of files to size and slice -----------------------------------
rows_to_append <- rep(T, nrow(classeddata))
if (file.exists(file.sizes)) {
  sizedata <- read.csv(file.sizes, as.is=T, stringsAsFactors=T)
  rows_to_append <- !(classeddata$imfilename %in% sizedata$imfilename)
} 
if (any(rows_to_append)) {
  write.csv(classeddata %>% filter(rows_to_append) %>%
              dplyr::select(r, folder, slicedir, name, imgtype, chL, chM, imfilename, center),
            file = file.path(dir.data.org, 'Metadata', 'px_sizes_toappend.csv'),
            quote = F, row.names = F, na = '')
}

# run Ilastik/slice+clean.ijm  ---------------------------------------

append <- read.csv(file.path(dir.data.org, 'Metadata', 'px_sizes_append.csv'), 
                   as.is = T, stringsAsFactors = T, row.names = NULL)
if (file.exists(file.sizes)) {
  sizedata <- rbind(read.csv(file.sizes, as.is = T, stringsAsFactors = T, row.names = NULL), append)
} else { 
  sizedata <- append
}
sizedata <- unique(sizedata)

write.csv(sizedata, file = file.sizes, quote = F, row.names = F, na = '')
rows_to_append <- !(classeddata$imfilename %in% sizedata$imfilename)
if (any(rows_to_append)) {
  write.csv(classeddata %>% filter(rows_to_append) %>%
              select(r, folder, slicedir, name, imgtype, chL, chM, imfilename, center),
            file = file.path(dir.data.org, 'Metadata', 'px_sizes_toappend.csv'),
            quote = F, row.names = F, na = '')
  file.remove(file.path(dir.data.org, 'Metadata', 'px_sizes_append.csv'))
} else {
  file.remove(file.path(dir.data.org, 'Metadata', 'px_sizes_toappend.csv'))
  file.remove(file.path(dir.data.org, 'Metadata', 'px_sizes_append.csv'))
}

# recombine size data with processed annotations, duplicate for adj, and save as new slice file
slicedata <- merge(sizedata, classeddata, all.x = T) %>% mutate(adj = 0)
slicedata <- rbind(slicedata, 
                   slicedata %>% mutate(adj = -1, imfilename = paste0(imfilename,'(-1)')), 
                   slicedata %>% mutate(adj = 1, imfilename = paste0(imfilename,'(+1)'))) %>%
  filter(center+adj > 0, center+adj-nz <= 0) %>% dplyr::arrange(r) %>% unique

file.copy(file.slices,
          file.path(dir.data.org, 'Metadata', 'backups', 'classed_sliced.csv'), overwrite = T)
write.csv(slicedata, file.slices, quote = F, row.names = F, na = '')

