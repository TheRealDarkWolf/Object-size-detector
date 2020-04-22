function new_boundaries= smooth_edges(B)
new_boundaries=cell(length(B),1);
for i=1:length(B)
    current=B{i};
    %get the x and y co-ordinates
    x = current(:, 2);
    y = current(:, 1);
    % Now smooth with a Savitzky-Golay sliding polynomial filter
    windowWidth = 35;
    polynomialOrder = 2;
    smoothX = sgolayfilt(x, polynomialOrder, windowWidth);
    smoothY = sgolayfilt(y, polynomialOrder, windowWidth);
    new_boundaries{i}=double([smoothY,smoothX]);
end