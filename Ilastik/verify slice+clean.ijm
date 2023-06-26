// clean_slices.ijm
run("Clear Results"); run("Close All"); setBatchMode(true);
sep = File.separator;

// edit these -------------------------------------------------------
boxdir = "C:/Users/Gartner/Box/Gartnerlab Data/Individual Folders/Jennifer Hu/";
slicedir = boxdir+"Data"+sep+"Organization Data"+sep+"Slices"+sep;
metadatadir = boxdir+'Data/Organization Data/Metadata/';
czidir = boxdir+'Microscopy/organization/';

// setting up -------------------------------------------------------

run("Table... ", "open=["+metadatadir+"classed_sliced.csv]");
n = Table.size; j = 0;
if (File.exists(metadatadir+"SBG diffs.csv")) {
	run("Table... ", "open=["+metadatadir+"SBG diffs.csv]");
	wait(1000);
	Table.rename("SBG diffs.csv", "Results"); j = 0; m = nResults;
} else { m = 0; }

previous_img = ''; previous_folder = ''; previous_i = 0; opened = 0;
for (i = 0; i < n; i++) {
	folder = Table.getString('folder', i, "classed_sliced.csv");
	name = Table.getString('name', i, "classed_sliced.csv");
	if (!File.exists(czidir+folder+sep+name)) {
		print('missing '+folder+sep+name);
		continue;
	}
	imfile = Table.getString('imfilename', i, "classed_sliced.csv");
	if (j < m) {
		if (getResultString('imfilename', j) == imfile+'.png') {
			// skip ones already added
			j++; continue;
		}
	}
	// sometimes multiple lines of same image; close when name changes
	if (previous_img != name) {
		if (previous_img != '') { close(); opened = 0; cleaned = 0; }
	}
	imgtype = Table.getString('imgtype', i, "classed_sliced.csv");
	if (imgtype != 'LSM_FP' && imgtype != 'FP') { continue; }
	outdir = Table.getString('slicedir', i, "classed_sliced.csv");
	donepath = slicedir+'SBG'+sep+imgtype+sep+'done'+sep+imfile+'.png';
	outpath = slicedir+outdir+sep+imfile+'.png';
	if (!opened) { 
		run("Bio-Formats Windowless Importer", 
			"open=["+czidir+folder+sep+name+"]"); 
		previous_img = name; cleaned = 0; opened = 1;
	}
	if (!cleaned) {
		cleaned = 1;
		run("Split Channels");
		run("Merge Channels...", "c1=[C"+Table.get('chM',i, "classed_sliced.csv")+"-"+name+"]"+
			" c2=[C"+Table.get('chL',i, "classed_sliced.csv")+"-"+name+"] create ignore");
		run("Stack to RGB", "slices");
	
		if (matches(imgtype,".*LSM_.*")) {
			run("Gaussian Blur...", "sigma=2 stack"); 
		}
		run("Subtract Background...", "rolling=50 stack");
	}
	setSlice(Table.get("center", i, "classed_sliced.csv")+Table.get("adj", i, "classed_sliced.csv"));
	run("Duplicate...", " "); // makes a new image with just this slice
	rename('new.png');
	// compare current slice to existing
	if (File.exists(donepath) || File.exists(outpath)) {
		if (File.exists(outpath)) {
			if (File.exists(donepath)) {
				File.delete(donepath); // for some reason this prints '1'	
			}
			open(outpath);
		} else { open(donepath); }
		imageCalculator("Difference create", imfile+'.png', 'new.png');
		run("Statistics");
		sd = getResult("StdDev", nResults-1);
		max = getResult("Max", nResults-1);
		setResult("imfilename", nResults-1, imfile+'.png');
		if (sd > 10 || max > 50) {
			// move the old file to renew folder
			// delete the existing Simple and Cleaned masks that correspond to this image
			print(imgtype+' renew: '+imfile+' - '+i+'/'+n);
		}
		close("*.png");
		j++;
	} else {
		saveAs('PNG', outpath);
		print(imgtype+': '+imfile+' - '+i+'/'+n);
	}
	if (i > 0 && i % 100 == 0) {
		print(i+'/'+n);
		if (nResults > 0) {
			updateResults();
			saveAs("Results", metadatadir+'SBG diffs.csv');
		}
	}
}

if (nResults > 0) {
	updateResults();
	saveAs("Results", metadatadir+'SBG diffs.csv');
}

beep();
print('Now run move_slices.m in MATLAB to ensure the slices are in the right folder for ilastik.');