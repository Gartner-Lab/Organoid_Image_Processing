// px_sizes.ijm
// First use the R code in px_sizes_append.r to create the toappend.csv file.
run("Clear Results"); run("Close All"); setBatchMode(true);
sep = File.separator;

boxdir = 'C:'+sep+'Users'+sep+'Gartner'+sep+'Box'+sep+'Gartnerlab Data'+sep+
	'Individual Folders'+sep+'Jennifer Hu'+sep;
metadatadir = boxdir+'Data'+sep+'Organization Data'+sep+'Metadata'+sep;
czidir = boxdir+'Microscopy'+sep+'organization'+sep;
// do you want to open every image or assume all in same folder are same?
open_each = true;

run("Table... ", "open=["+metadatadir+"px_sizes_toappend.csv]");
n_imgs = Table.size; step = round(n_imgs/20);

previous_img = ''; previous_folder = ''; previous_i = 0;
for (i = 0; i < n_imgs; i++) {
	folder = Table.getString('folder', i);
	name = Table.getString('name', i);
	if (!File.exists(czidir+folder+sep+name)) {
		print('missing '+folder+sep+name);
		continue;
	}

	if (folder == previous_folder && !open_each) {
		Table.set('nz', i, Table.getString('nz', previous_i));
		Table.set('pxwidth', i, Table.getString('pxwidth', previous_i));
		Table.set('pxheight', i, Table.getString('pxheight', previous_i));
		Table.set('pxdepth', i, Table.getString('pxdepth', previous_i));
		Table.set('unit', i, Table.getString('unit', previous_i));
		previous_img = name; continue;
	}
	if (!File.exists(czidir+folder+sep+name)) {
		continue;
	}
	// sometimes multiple lines of same image; don't close yet
	if (previous_img != name) {
		if (previous_img != '') { close(); }
		open(czidir+folder+sep+name);
		previous_img = name;
	}
	getVoxelSize(pxwidth, pxheight, pxdepth, unit);
	getDimensions(width, height, channels, slices, frames);
	Table.set('nz', i, slices);
	Table.set('pxwidth', i, pxwidth);
	Table.set('pxheight', i, pxheight);
	Table.set('pxdepth', i, pxdepth);
	Table.set('unit', i, unit);
	previous_folder = folder; previous_i = i;
	Table.update();
	if (i % step == 0) { print(i+'/'+n_imgs); }
}
Table.save(metadatadir+'px_sizes_append.csv'); beep(); print('Finished!')
// then run the bottom part of px_sizes_append.r