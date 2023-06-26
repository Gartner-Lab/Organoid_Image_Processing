// clean_stacks.ijm
run("Clear Results"); run("Close All"); setBatchMode(true);
sep = File.separator;

// edit these -------------------------------------------------------
computeruser = "jhu";
stackdir = "positions";
sourcedir = "/Users"+sep+computeruser+sep+"Box"+sep+
	"Gartnerlab Data"+sep+"Individual Folders"+sep+"Jennifer Hu"+sep+
	"Microscopy"+sep+"organization"+sep+"2020-10-28"+sep;

// setting up -------------------------------------------------------

// recursively populate Results table with all files
function listFiles(dir) {
	list = getFileList(dir);
	for (i=0; i < list.length; i++) {
		// File.isDirectory does not work
		if (endsWith(list[i], "/") || endsWith(list[i], "\\")) { 
			listFiles(dir+list[i]); 
		} else {
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

listFiles(sourcedir+stackdir);

n = nResults;
for (i = 0; i < n; i++) {
	filename = getResultString("file", i);
	if (!endsWith(filename, 'f')) { continue; }
	dirname = getResultString("folder", i); // this ends with sep
	if (matches(filename,'.*H1047R.*') || matches(filename,'.*E545K.*') || 
		matches(filename,'.*PIK3CA.*') || matches(filename,'.*mChL\+GFPM.*') || 
		matches(filename,'.*ERBB2.*') || matches(filename,'.*Her2.*') || 
		matches(filename,'.* mCh .*')) { brightness = "dim"; } else {brightness = "bright"; }
	outdir = sourcedir + 'SBG' + sep;
	outpath = outdir + brightness + sep + filename;
	if (File.exists(outpath)) { continue; }
	print(filename+' - '+i+'/'+n);
	mkdirs(outdir);
	open(dirname + filename);
	run("Gaussian Blur...", "sigma=2 stack");
	run("Subtract Background...", "rolling=50 stack");
	save(outpath);run("Close All");
}
