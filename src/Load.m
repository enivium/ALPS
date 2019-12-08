% Load.m
% An object to represent the total power load on the system

classdef Load
    properties
        % Percent of mean corresponding to 1 sigma
        ss_sigma_percent % Steady-state
        transient_sigma_percent
        
        transient_mean
        transient_prob
    end


    methods
    
        %%%%%%%%%% Constructor %%%%%%%%%%

        function obj = Load(ss_sigma_percent, transient_sigma_percent, transient_mean, transient_prob)
            obj.ss_sigma_percent = ss_sigma_percent;
            obj.transient_sigma_percent = transient_sigma_percent;
            obj.transient_mean = transient_mean;
            obj.transient_prob = transient_prob;
        end


        %%%%%%%%%% Load Generation %%%%%%%%%%

        function ss_load = generate_steady_state_load(obj, load_mean)
            ss_load = load_mean + (obj.ss_sigma_percent * load_mean)*randn;
        end

        function transient_load = generate_transient_load(obj)
            if (rand > obj.transient_prob)
                transient_load = 0;
                return;
            end

            transient_load = obj.transient_mean + (obj.transient_sigma_percent * obj.transient_mean)*randn;
        end
    end
end
