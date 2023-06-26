// clean_slices.ijm
run("Clear Results"); run("Close All"); setBatchMode(true);
sep = File.separator;

// edit these -------------------------------------------------------
sourcedir = "/Volumes/JenniferHD"+sep+"timelapse"+sep+"2019-06-14 timelapse"+sep+"Reaggregated"+sep;
outdir = "/Volumes/JenniferHD"+sep+"timelapse"+sep+"2019-06-14 timelapse"+sep+"SBG"+sep;

// setting up -------------------------------------------------------

// recursively populate Results table with all files
function listFiles(dir) {
	list = getFileList(dir);
	for (i=0; i < list.length; i++) {
		// File.isDirectory does not work
		if ((endsWith(list[i], "/")) || (endsWith(list[i], "\\"))) { listFiles(dir+list[i]); }
		else {
			row = nResults;
			setResult("folder", row, dir);
			setResult("file", row, list[i]);
		}
	}
	updateResults();
}
function mkdirs(dir) {
	if (File.exists(dir)) { return; }
	parent = File.getParent(dir);
	while (!(File.exists(parent))) { mkdirs(parent); }
	File.makeDirectory(dir);
}

listFiles(sourcedir);

n = nResults;
for (i = 0; i < n; i++) {
	filename = getResultString("file", i);
	dirname = getResultString("folder", i);
	mkdirs(outdir+filename+sep);
	open(dirname + filename);
	run("Median...", "radius=2 stack");
	// 2019-06-14 is already re-ordered to ch1=red
	run("Make Composite"); run("Stack to RGB", "slices frames keep");
	run("Subtract Background...", "rolling=50 separate stack");
	// split into separate RGB images for ilastik
	run("Image Sequence... ", "format=TIFF name=["+filename+"] save=["+outdir+filename+sep+"]");
	close("*");
}