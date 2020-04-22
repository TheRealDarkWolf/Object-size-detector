image_no=0;
mypath="images\testimage" + num2str(image_no) + ".jpg";
img=imread(mypath);
img=imresize(img,[576 NaN]);
img_gray=rgb2gray(img);
%Different images require different levels of thresholding and different
%disk sizes for morphological opening
if image_no==2
    thres=75;
    s=5;
elseif image_no==0
    thres=50;
    s=9;
else
    thres=55;
    s=5;
end
%morphological opening
se=strel('disk',s);
%generating a grayscale image by removing any non uniform illumination
mask=img_gray-imtophat(img_gray,se);
%thresholding
mask=mask>thres;
figure;subplot(1,2,1);imshow(img_gray);
title("Grayscale Image");
%fill any holes in objects
mask=imfill(mask,'holes');
subplot(1,2,2);
imshow(mask);
title("Generated mask");
ppm=0;
%This is used to generate the areas and bounding boxes of all the objects
blobAnalysis = vision.BlobAnalysis('AreaOutputPort', true,...
    'CentroidOutputPort', false,...
    'BoundingBoxOutputPort', true,...
    'MinimumBlobArea',200,'ExcludeBorderBlobs',true);
[areas,boxes]=step(blobAnalysis,mask);
%Generate the edges/boundaries of the objects
[B,L]=bwboundaries(mask,'noholes');
%call the smooth edges function to smoothen edges using a savitsky-golay
%filter
newB=smooth_edges(B);
%call the plotter function to display old boundaries and new boundaries
plotter(img,newB,B);
%store the areas and centroids
stats = regionprops(L,'Area','Centroid');
%this is the threshold to check if the object is relatively circular
if image_no==0
    threshold=0.71;
else
    threshold = 0.82;
end
%create a cell array to store the lengths of objects
lengths=cell(length(B),1);
figure;
%display the image and freeze it in place using hold, we will be adding the
%new boundaries and detected corners on top of this image
imshow(img);
title('Detected edges and corners');
axis on;
hold on;
grid on;
%length of B is the length of boundaries detected, or the number of objects
%detected
for k=1:length(B)
    C=B{k};
    Z=newB{k};
    %this stores the minimum and maximum column values for each object to
    %detect their corner
    %Since matlab is weird the corner detection part of the code can be a
    %little difficult to grasp, I can explain if you really want to know
    min_values= min(C);
    min_c=min_values(2);
    min_r=min_values(1);
    max_values=max(C);
    max_c=max_values(2);
    max_r=max_values(1);
    M=[];
    Y=[];
    R=[];
    G=[];
    delta_sq = diff(C).^2;    
    perimeter = sum(sqrt(sum(delta_sq,2)));
    
    % obtain the area calculation corresponding to label 'k'
    area = stats(k).Area;
  
    % compute the roundness metric
    metric = 4*pi*area/perimeter^2;
  
    % check if objects are above the threshold
    if metric > threshold
        %this is for objects that are circular and vaguely circular
        centroid = stats(k).Centroid;
        %this is where the centroid is plotted from regionprops in line 46
        %you can notice a black circle at the center of circular objects
        plot(centroid(1),centroid(2),'ko');
        %again, corner detection code, kinda lengthy  to explain
        for i=1:length(C)
            if C(i,2) == min_c
                M=vertcat(M,C(i,:));
            end
            if C(i,2) == max_c
                Y=vertcat(Y,C(i,:));
            end
        end 
        %Z is the smoothened endge, M is the left corner in magenta and Y
        %is the right corner in yellow
        plot(Z(:,2),Z(:,1),'w','LineWidth',2);
        plot(M(:,2),M(:,1),'r','LineWidth',2);
        plot(Y(:,2),Y(:,1),'r','LineWidth',2);
        %Converting the corners detected into real lengths
        temp1=median(M);
        minxy=[temp1(1),min_c];
        temp1=median(Y);
        maxxy=[temp1(1),max_c];
        dist=euclidean(minxy(1),minxy(2),maxxy(1),maxxy(2));
        %ppm is the metric used to convert pixel lengths into actual
        %lengths, if you're interested I can explain how it works
        if k==1
            if image_no==0
                ppm=dist/2.43;
            else
                ppm=dist/2.60;
            end
        end
        real_length=dist/ppm;
        %Store real lengths in lengths to display on top of the bounding
        %boxes
        lengths{k}=['Diameter:' num2str(round(real_length,3)) 'cms'];
        
    else
        %this part is for calculating the square area
        for i=1:length(C)
            if C(i,2) == min_c
                %left corner or set of leftmost pixels
                M=vertcat(M,C(i,:));
            end
            if C(i,2) == max_c
                %right corner or set of rightmost pixels
                Y=vertcat(Y,C(i,:));
            end
            if C(i,1) == min_r
                %top corner or set of topmost pixels
                R=vertcat(R,C(i,:));
            end
            if C(i,1) == max_r
                %bottom corner or set of bottommost pixels
                G=vertcat(G,C(i,:));
            end
        end 
        %myrg
        plot(Z(:,2),Z(:,1),'w','LineWidth',2);
        plot(M(:,2),M(:,1),'r','LineWidth',2);
        plot(Y(:,2),Y(:,1),'r','LineWidth',2);
        plot(R(:,2),R(:,1),'r','LineWidth',2);
        plot(G(:,2),G(:,1),'r','LineWidth',2);
        %magenta is leftmost M
        %yellow is rightmost Y
        %red is topmost R
        %green is bottommost G
        %first metric is topmost magenta - rightmost blue
        %second metric is bottommost yellow- rightmost blue

        if size(M,1)>1
            temp1=max(M);
        else
            temp1=M;
        end
        if size(R,1)>1
            temp2=min(R);
        else
            temp2=R;
        end
        if size(Y,1)>1
            temp3=min(Y);
        else
            temp3=Y;
        end
        length1=euclidean(temp1(1),temp1(2),temp2(1),temp2(2));
        length2=euclidean(temp3(1),temp3(2),temp2(1),temp2(2));
        real_length1=length1/ppm;
        real_length2=length2/ppm;
        lengths{k}=[num2str(round(real_length1,3)) 'x' num2str(round(real_length2,3)) 'cms'];
    end
 
end
%Display the final image with the bounding boxes and the lengths
final_image=insertObjectAnnotation(img,'rectangle',boxes,lengths);
figure;
imshow(final_image);
title("Dimensions of all detected objects");