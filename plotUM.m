clear all
close all
clc

% load extracted file
load('a.mat')

% find max peak amplitude for the plot
offset=0;
for r=1:13
    for c=1:13
        try
            eval(sprintf('Unit=MotorUnits(1).Templates.Template.col_%d_row_%d;',c,r));
            if offset<max(abs(Unit))
                offset=max(abs(Unit));
            end
        end
    end
end

x=(0:length(Unit)-1)/SamplingFrequency;
   
% print motor units
figure
for r=1:13
    for c=1:13
        try
        eval(sprintf('Unit=MotorUnits(1).Templates.Template.col_%d_row_%d;',c,r));
        hold on;
        plot(x+(c-1)*(x(end)*1.1),Unit+offset*(7-r),'b')
        end
    end
end