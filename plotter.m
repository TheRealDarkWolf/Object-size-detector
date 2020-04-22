function plotter(img,newb,B)
    figure;
    subplot(1,2,1);
    imshow(img);
    axis on;
    hold on;
    title('Edges without filter');
    for i=1:length(B)
        C=B{i};
        plot(C(:,2),C(:,1),'b','LineWidth',2);
    end
    hold off;
    subplot(1,2,2);
    imshow(img);
    title('Edges after applying filter');
    axis image;
    hold on;
    for i=1:length(newb)
        C=newb{i};
        plot(C(:,2),C(:,1),'b','LineWidth',2);
    end
end