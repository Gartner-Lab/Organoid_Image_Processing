% Jennifer Hu
% July 13, 2017
% Given figure, plots gallery view (with maximum of 20 or 8)
% Figure contains UserData cell array, {first_img,rgbdata}
% rgbdata is a double array of size [z X Y 3]
function [h] = imsgrid(h)
    imdata = h.UserData;
    first_img = imdata{1};
    % array of image data
    rgbdata = imdata{2};
    % highest z position possible
    nz = size(rgbdata,1);
    % keep image in bounds
    if nz <= 20
        first_img = 1;
    elseif (first_img < 1)
        first_img = 1;
        imdata{1} = first_img;
        h.UserData = imdata;
    elseif (first_img+20-1 > nz)
        first_img = nz-20+1;
    end
    
    figure(h);
    % figure margins: small
    margins = [0.01,0.01];
    if nz > 9
        for i=1:20
            z = first_img+i-1;
            if z > nz
                break
            end
            subplot_tight(4,5,i,margins);
            imshow(squeeze(rgbdata(z,:,:,:)));
            % add slice number in bottom right corner
            ntitle(num2str(z),'location','southeast','fontsize',20,'color','w');
        end
    elseif nz == 9
        for i=1:9
            z = first_img+i-1;
            if z > nz
                break
            end
            subplot_tight(3,3,i,margins);
            imshow(squeeze(rgbdata(z,:,:,:)));
            % add slice number in bottom right corner
            ntitle(num2str(z),'location','southeast','fontsize',20,'color','w');
        end
    else
        for i=1:8
            z = first_img+i-1;
            if z > nz
                break
            end
            subplot_tight(2,4,i,margins);
            imshow(squeeze(rgbdata(z,:,:,:)));
            % add slice number in bottom right corner
            ntitle(num2str(z),'location','southeast','fontsize',20,'color','w');
        end
    end
end