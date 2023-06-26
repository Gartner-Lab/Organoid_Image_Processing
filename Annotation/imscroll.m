% Scroll to change z-stack height.
% Very slow. Use sparingly.
function [] = imscroll(source, event)
    source.UserData{1} = source.UserData{1} + event.VerticalScrollCount;
    imsgrid(source);
end