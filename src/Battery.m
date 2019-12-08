% Battery.m
% The Battery class for the ALPS simulation

classdef Battery
    properties
        % Definition
        capacity
        e_rate % 1E is the power discharge that would empty the battery in 1 hour

        % State tracking
        percent_degradation % As a decimal
        energy_stored
        power_consumption
        SoC
        num_cycles
    end

    methods

        %%%%%%%%%% Constructor %%%%%%%%%%

        function obj = Battery(capacity, e_rate)
            % Define battery
            obj.capacity = capacity;
            obj.e_rate = e_rate;

            % Start with no degradation
            obj.percent_degradation = 0;

            % Start fully charged
            obj.energy_stored = capacity;

            % Start with no power consumption
            obj.power_consumption = 0;

            % Initial SoC
            obj.SoC = [obj.energy_stored/obj.capacity];
        end


        %%%%%%%%%% Interaction Methods %%%%%%%%%

        function obj = reset_power_consumption(obj)
            % First, record the SoC
            obj.SoC = [obj.SoC (obj.energy_stored/obj.capacity)];

            obj.power_consumption = 0;
        end

        function max_power = max_power(obj)
            max_power = obj.capacity * obj.e_rate;
        end

        function available_power = available_power(obj)
            available_power = obj.max_power() - obj.power_consumption;
        end

        function [obj, power] = draw_power(obj, load, time)
            % Produce as much of the load as possible
            power = min([load obj.available_power()]);

            % Calculate energy draw
            energy = power * time;
            obj.energy_stored = obj.energy_stored - energy;

            % Track power consumption
            obj.power_consumption = obj.power_consumption + power;

            % Check for overdraw
            if (obj.energy_stored < 0)
                error('SIMULATION ERROR: Battery has been depleted');
            end
        end

        function charging_power = charging_power(obj, time)
            if (obj.power_consumption == 0)
                % Figure out whether energy or power is limiting factor
                energy_to_fill = (obj.capacity * (1 - obj.percent_degradation)) - obj.energy_stored;
                charging_power = min([(energy_to_fill/time) obj.max_power()]);
            else
                % Cannot charge if discharging
                charging_power = 0;
            end
        end

        function [obj, power_used] = charge(obj, power, time)
            energy_supplied = power * time;
            energy_added = min([energy_supplied (obj.charging_power(time)*time)]);
            obj.energy_stored = obj.energy_stored + energy_added;
            power_used = energy_added / time;
        end
    end
end
