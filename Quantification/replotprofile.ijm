// uses the same line coordinates to remake profiles by image name
channel_p63 = 1; channel_K7 = 2; 

setBatchMode("hide");
sep = File.separator; run("Select None"); run("Close All"); run("Clear Results");
boxdir = sep+'Users'+sep+'jhu'+sep+'Box'+sep+'Gartnerlab Data'+sep+
	'Individual Folders'+sep+'Vasudha Srivastava'+sep+'DATA'+sep;
	// /Users/jhu/Box/ or C:/Users/Gartner/Box/
savedir = boxdir+'LM_IF_analysis'+sep+'2017-11-23'+sep;
inputdir = savedir+'Composite_Rd2'+sep;
boundaryfile = savedir+'Profiles'+sep+'boundary.csv';
lwd = 10;
savefile = savedir+'Profiles'+sep+'proportions'+lwd+'.csv';

lineTable = Table.open(boundaryfile);
imgs = Table.getColumn('image'); previous_img = '';
nlines = lengthOf(imgs);

for (i = 0; i < nlines; i++) {
	if (imgs[i] == previous_img) {
		
	} else {
		close("*");
		open(inputdir+imgs[i]+'.tiff');
		previous_img = imgs[i];
	}
	xstr = Table.getString('X', i, 'boundary.csv'); xs = split(xstr, '_');
	ystr = Table.getString('Y', i, 'boundary.csv'); ys = split(ystr, '_');
	command = 'makeLine('+xs[0]+','+ys[0];
	for (j = 1; j < lengthOf(xs); j++) {
		command = command + ',' + xs[j] + ',' + ys[j];
	}
	command = command + ');';
	eval(command);
	Roi.setStrokeWidth(5);
	Stack.setChannel(channel_p63); p63_points = getProfile();
	Array.getStatistics(p63_points, min, max, mean, std); p63 = mean;
	Stack.setChannel(channel_K7); K7_points = getProfile();
	Array.getStatistics(K7_points, min, max, mean, std); K7 = mean;
	setResult("image", i, imgs[i]); 
	setResult("line", i, Table.get('line', i, 'boundary.csv'));
	setResult("p63", i, p63); setResult("K7", i, K7);
	setResult("X", i, xstr); setResult("Y", i, ystr);
	run("Select None"); updateResults();
}
updateResults(); saveAs('Results', savefile); run("Close All");
