// slice+clean.ijm
run("Clear Results"); run("Close All"); setBatchMode(true);
sep = File.separator;

// edit these -------------------------------------------------------
//boxdir = "C:"+sep+"Users"+sep+"Vasudha"+sep+"Box"+sep+"Gartnerlab Data"+sep+"Individual Folders"+sep+"Jennifer Hu"+sep;
boxdir = "/Users/Vasudha/Library/CloudStorage/Box-Box/Gartnerlab Data/Individual Folders/Jennifer Hu/";
slicedir = boxdir+"Data"+sep+"Organization Data"+sep+"Slices"+sep;
metadatadir = boxdir+"Data"+sep+"Organization Data"+sep+"Metadata"+sep;
czidir = boxdir+sep+"Microscopy"+sep+"organization"+sep;

// setting up -------------------------------------------------------

run("Table... ", "open=["+metadatadir+"px_sizes_toappend.csv]");
outtable = metadatadir+'px_sizes_append.csv';
n = Table.size;

previous_img = ''; previous_folder = ''; previous_i = 0; opened = 0;
for (i = 0; i < n; i++) {
	folder = Table.getString('folder', i);
	name = Table.getString('name', i);
	print(name);
	if (!File.exists(czidir+folder+sep+name)) {
		print('missing '+folder+sep+name);
		continue;
	}

	// sometimes multiple lines of same image; don't close yet
	if (previous_img != name) {
		if (previous_img != '') { close(); }
		run("Bio-Formats Windowless Importer", "open=["+czidir+folder+sep+name+"]");
		previous_img = name; cleaned = 0; opened = 1;
	}
	getDimensions(width, height, channels, slices, frames);
	getVoxelSize(pxwidth, pxheight, pxdepth, unit);

	Table.set('nz', i, slices);
	Table.set('pxwidth', i, pxwidth);
	Table.set('pxheight', i, pxheight);
	Table.set('pxdepth', i, pxdepth);
	Table.set('unit', i, unit);
	previous_folder = folder; previous_i = i;

	imgtype = Table.getString('imgtype', i);
	center = Table.get('center',i);
	slicename = Table.getString('imfilename',i);
	// check if slices already exist
	for (j = -1; j < 2; j++) {
		if (center+j > 0 && center+j <= slices) {
			if (j == 0) { ending = '.png'; } else { ending = String.format('(%+.0f).png', j); }
			donepath = slicedir+'SBG'+sep+imgtype+sep+'done'+sep+slicename+ending;
			outpath = slicedir+Table.getString('slicedir',i)+sep+slicename+ending;
			if (!File.exists(donepath) && !File.exists(outpath)) {
				if (!opened) { run("Bio-Formats Windowless Importer", "open=["+czidir+folder+sep+name+"]"); opened = 1; }
				if (!cleaned) {
					cleaned = 1;
					run("Split Channels");
					run("Merge Channels...", "c1=[C"+Table.get('chM',i)+"-"+name+"]"+
						" c2=[C"+Table.get('chL',i)+"-"+name+"] create");
					run("Stack to RGB", "slices");
				
					if (matches(imgtype,".*LSM_.*")) {
						run("Gaussian Blur...", "sigma=2 stack"); 
					}
					run("Subtract Background...", "rolling=50 stack");
				}
				// saving as PNG saves only the current slice
				setSlice(center+j);
				saveAs('PNG', outpath);
				print(imgtype+': '+slicename+ending+' - '+i+'/'+n);
			} else if (File.exists(donepath) && File.exists(outpath)) {
				File.delete(outpath); // for some reason this prints '1'
			}
		}
	}
	if (i % 100 == 0) {
		print(i+'/'+n); 
		Table.update; Table.save(outtable);
	}
}

Table.update; Table.save(outtable);
beep();
print('Now run move_slices.m in MATLAB to ensure the slices are in the right folder for ilastik.');