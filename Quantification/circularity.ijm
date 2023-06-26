/*	Jennifer Hu
 *	2 May 2018
 *	
 *	Opens every image file in MIP folder, identifies organoid, and records circularity.
 *  
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
run("Clear Results");
// microns^2
min_area = 500;
// prompt info from user
dir = getDirectory("Choose directory to process:");
dir_mask = dir+"mask"+File.separator;
dir_data = "C:/Users/jhu/Documents/Box Sync/Gartnerlab Data/Individual Folders/Jennifer Hu/Analysis/Datafiles/Organoid Circularity/";
list = getFileList(dir_mask);
setBatchMode(true);
k = list.length;
r = 0;
for (i=0; i<k; i++) {
	filename = list[i];
	open(dir_mask+filename);
	name = File.nameWithoutExtension;
	// smooth
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Erode");
	run("Erode");
	run("Dilate");
	run("Dilate");
	// analyze
	run("Set Measurements...", "area centroid perimeter shape redirect=None decimal=3");
	run("Analyze Particles...", "size=500-8000 show=Overlay display exclude");
	// add filename to results
	print(filename);
	for (j=r; j < nResults; j++) {
		setResult("file",j,name);
	}
	r=nResults;
	updateResults();
	run("Close All"); // doesn't affect Results table
}
saveAs("results",dir_data+"particles/"+File.getName(dir)+".csv");
beep();