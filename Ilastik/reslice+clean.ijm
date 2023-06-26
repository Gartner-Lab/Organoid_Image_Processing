// clean_slices.ijm
run("Clear Results"); run("Close All"); setBatchMode(true);
sep = File.separator;

// edit these -------------------------------------------------------
boxdir = "C:/Users/Gartner/Box/Gartnerlab Data/Individual Folders/Jennifer Hu/";
slicedir = boxdir+"Data"+sep+"Organization Data"+sep+"Slices"+sep;
metadatadir = boxdir+'Data/Organization Data/Metadata/';
czidir = boxdir+'Microscopy/organization/';

// setting up -------------------------------------------------------

run("Table... ", "open=["+metadatadir+"classed_sliced.csv]");
n = Table.size;

previous_img = ''; previous_folder = ''; previous_i = 0; opened = 0;
for (i = 0; i < n; i++) {
	folder = Table.getString('folder', i);
	imfile = Table.getString('imfilename', i);
	if (!File.exists(slicedir+'SBG'+sep+'LSM_FP'+sep+'renew'+sep+imfile+'.png')) {
		continue;
	}
	name = Table.getString('name', i);
	if (!File.exists(czidir+folder+sep+name)) {
		print('missing '+folder+sep+name);
		continue;
	}
	slicesubdir = Table.getString('slicedir', i);
	imgtype = Table.getString('imgtype',i);
	donepath = slicedir+'SBG'+sep+imgtype+sep+'done'+sep+imfile+'.png';
	outpath = slicedir+slicesubdir+sep+imfile+'.png';
	if (!File.exists(donepath) && !File.exists(outpath)) {
		// sometimes multiple lines of same image; don't close yet
		if (previous_img != name) {
			if (previous_img != '') { close(); }
		}
		if (!opened) { 
			run("Bio-Formats Windowless Importer", 
				"open=["+czidir+folder+sep+name+"]");
			previous_img = name; cleaned = 0; opened = 1;
		}
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
		setSlice(Table.get('center', i)+Table.get('adj', i));
		saveAs('PNG', outpath);
		print(imgtype+': '+imfile+' - '+i+'/'+n);
	} else if (File.exists(donepath) && File.exists(outpath)) {
		File.delete(donepath); // for some reason this prints '1'
	}
	if (i % 100 == 0) {
		print(i+'/'+n);
	}
}

beep();
print('Now run move_slices.m in MATLAB to ensure the slices are in the right folder for ilastik.');