// clean_slices.ijm
run("Close All"); setBatchMode(true);
sep = File.separator;

// edit these -------------------------------------------------------
boxdir = 'C:'+sep+'Users'+sep+'Gartner'+sep+'Box'+sep+'Gartnerlab Data'+sep+
	'Individual Folders'+sep+'Jennifer Hu'+sep; // /Users/jhu/Box/ or C:/Users/Gartner/Box/
rawslicedir = boxdir + "Data"+sep+"Organization Data"+sep+"Slices"+sep+"raw"+sep;
imgtype = 'LSM_FP';

// setting up -------------------------------------------------------

function mkdirs(dir) {
	if (File.exists(dir)) { return; }
	parent = File.getParent(dir);
	while (!(File.exists(parent))) { mkdirs(parent); }
	File.makeDirectory(dir);
}


newrawdir = rawslicedir+imgtype+sep+"new"+sep;
sbgdir = boxdir + "Gartnerlab Data/Individual Folders/Jennifer Hu/Data"+
	sep+"Organization Data"+sep+"Slices"+sep+"SBG"+sep+imgtype+sep;
newsbgdir = sbgdir+"new"+sep; mkdirs(newsbgdir);
donerawdir = rawslicedir+imgtype+sep+"done"+sep; mkdirs(donerawdir);

files = getFileList(newrawdir);
n = lengthOf(files);
for (i = 0; i < n; i++) {
	filename = files[i];
	outpath = newsbgdir+filename; 
	is_placed = (File.exists(sbgdir+'bright'+sep+filename) || 
		File.exists(sbgdir+'dim'+sep+filename) || File.exists(sbgdir+'done'+sep+filename));
	if (File.exists(sbgdir+filename) || File.exists(outpath) || is_placed) {
		File.rename(newrawdir+filename, donerawdir+filename);
		if (is_placed && File.exists(outpath)) {
			// remove this extra copy if already placed in another folder 
			File.delete(outpath); 
		}
		continue;
	}
	print(filename+' - '+i+'/'+n);
	
	open(newrawdir + filename);
	if (matches(imgtype,".*LSM_.*")) {
		run("Gaussian Blur...", "sigma=2"); 
	}
	run("Subtract Background...", "rolling=50 separate");
	save(outpath); File.rename(newrawdir+filename, donerawdir+filename);
 	close();
}


beep();
print('Now run move_slices.m in MATLAB to get the slices to the right folder for ilastik.');