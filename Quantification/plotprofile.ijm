// 2021 04 20
// Line coordinates and plot profile for tissue section.
channel_p63 = 1; channel_K7 = 2; 

setBatchMode(false);
sep = File.separator; run("Select None"); run("Close All"); run("Clear Results");
boxdir = sep+'Users'+sep+'jhu'+sep+'Box'+sep+'Gartnerlab Data'+sep+
	'Individual Folders'+sep+'Vasudha Srivastava'+sep+'DATA'+sep;
	// /Users/jhu/Box/ or C:/Users/Gartner/Box/
savedir = boxdir+'LM_IF_analysis'+sep+'2017-11-23'+sep;
inputdir = savedir+'Composite_Rd2'+sep;
savepathprefix = savedir+'Profiles'+sep+'profiles';

start = 0; filelist = getFileList(inputdir);
if (File.exists(savepathprefix+'.csv')) {
	savefile = savepathprefix+'1.csv';
	Table.open(savepathprefix+'.csv');
	previous_ims = Table.getColumn('image','profiles.csv');
} else { 
	savefile = savepathprefix+'.csv'; 
	previous_ims = newArray(0);
}
r = 0;

for (i = 0; i < lengthOf(filelist); i++) {
    if (!endsWith(filelist[i], ".tiff")) { continue; }
    imname = File.getNameWithoutExtension(filelist[i]);
    count = 0; open(inputdir + sep + filelist[i]);

	selecting = true;
	while (selecting) {
		setTool('polyline'); setLineWidth(10);
		waitForUser('Draw a polyline selection and hit OK.');
		if (selectionType != 6) { break; }
		// get selected points
		getSelectionCoordinates(xpoints, ypoints);
		xstr = String.join(xpoints,'_');
		ystr = String.join(ypoints,'_');
		Stack.setChannel(channel_p63); p63_points = getProfile();
		Array.getStatistics(p63_points, min, max, mean, std); p63 = mean;
		Stack.setChannel(channel_K7); K7_points = getProfile();
		Array.getStatistics(K7_points, min, max, mean, std); K7 = mean;
		setResult("image", r, imname); setResult("line", r, count);
		setResult("p63", r, p63); setResult("K7", r, K7);
		setResult("X", r, xstr); setResult("Y", r, ystr);
		count++; r++; run("Select None"); updateResults();
	}
	close("*");
	updateResults(); saveAs('Results', savefile);
}
