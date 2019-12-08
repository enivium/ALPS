% Fuel_Cell.m
% A class to represent fuel cells for the ALPS simulation

classdef Fuel_Cell
    properties
        % Definition
        nominal_power

        % Reaction parameters
        hydrogen_consumption % Grams of hydrogen consumed to produce 1W of power
        oxygen_consumption % Grams of oxygen consumed to produce 1W of power
        water_production % Grams of water produced in producing 1W of power

        % Reverse reaction (electrolysis) parameters
        hydrogen_production % Grams of hydrogen produced using 1W of power
        oxygen_production % Grams of oxygen produced using 1W of power
        water_consumption % Grams of water produced from 1W electrolysis

        % State tracking
        percent_degradation % As a decimal
        power_consumption
        regeneration_power
    end

    methods

        %%%%%%%%%% Constructor %%%%%%%%%%

        function obj = Fuel_Cell(nominal_power, forward_efficiency, reverse_efficiency)

            % Define cell
            obj.nominal_power = nominal_power;

            % Calculate forward reaction parameters
            obj.hydrogen_consumption = 1 / (39.58 * forward_efficiency); % Hydrogen has 39.58 Wh/g
            obj.oxygen_consumption = obj.hydrogen_consumption * 7.936; % Ratio is 7.936 gO2/gH2
            obj.water_production = obj.hydrogen_consumption * 8.936; % Ratio is 8.936 gH2O/gH2

            % Calculate reverse reaction parameters
            obj.hydrogen_production = reverse_efficiency * (1 / 39.58);
            obj.oxygen_production = obj.hydrogen_production * 7.936;
            obj.water_consumption = obj.hydrogen_production * 8.936;

            % Start with no degradation
            obj.percent_degradation = 0;

            % Start with no power consumption
            obj.power_consumption = 0;
            obj.regeneration_power = 0;
        end


        %%%%%%%%%% Interaction Methods %%%%%%%%%%

        function obj = reset_power_consumption(obj)
            obj.power_consumption = 0;
            obj.regeneration_power = 0;
        end

        function max_power = max_power(obj)
            max_power = obj.nominal_power * (1 - obj.percent_degradation);
        end

        function available_power = available_power(obj)
            available_power = obj.max_power() - obj.power_consumption;
        end

        function available_regeneration = available_regeneration(obj, water, time)
            if (obj.power_consumption == 0)
                power_limit = obj.max_power();
                water_limit = water / (obj.water_consumption * time);
                available_regeneration = min([power_limit water_limit]);
            else
                available_regeneration = 0;
            end
        end

        function [obj, power, hydrogen_consumed, oxygen_consumed, water_produced] = generate_power(obj, load, time)
            % Produce as much of the load as possible
            power = min([load obj.available_power()]);

            % Calculate chemical reaction
            hydrogen_consumed = obj.hydrogen_consumption * power * time;
            oxygen_consumed = obj.oxygen_consumption * power * time;
            water_produced = obj.water_production * power * time;

            % Track power consumption
            obj.power_consumption = obj.power_consumption + power;
        end

        function [obj, power_used, hydrogen_produced, oxygen_produced, water_consumed] = regenerate_fuel(obj, power, water, time)
            % Use as much power as possible
            power_used = min([power obj.available_regeneration(water, time)]);

            % Calculate chemical reaction
            hydrogen_produced = obj.hydrogen_production * power_used * time;
            oxygen_produced = obj.oxygen_production * power_used * time;
            water_consumed = obj.water_consumption * power_used * time;

            % Track power
            obj.regeneration_power = obj.regeneration_power + power_used;
        end
    end
end
