% Solar_Array.m
% Class for ALPS Solar_Arrays

classdef Solar_Array
    properties
        % Definition
        nominal_power % At 1 AU, 0 AM
        deployable
        azimuth_tracking
        altitude_tracking

        % State tracking
        percent_degradation % As a decimal
        deployed
        power_consumption

        % Conditions
        phi % Azimuth to sun (degrees)
        theta % Altitude to sun (degrees)
        r % Distance to sun (AU)
        percent_eclipse % As a decimal (partial for partial shadow, total for dark side)
    end

    methods

        %%%%%%%%%% Constructor %%%%%%%%%%

        function obj = Solar_Array(nominal_power, deployable, azimuth_tracking, altitude_tracking)
            % Define array
            obj.nominal_power = nominal_power;
            obj.deployable = deployable;
            obj.azimuth_tracking = azimuth_tracking;
            obj.altitude_tracking = altitude_tracking;

            % Start with no degradation
            obj.percent_degradation = 0;

            if (obj.deployable == true)
                % Start retracted if deployable
                obj.deployed = false;
            else
                % Always deployed if fixed
                obj.deployed = true;
            end

            % Start with no power consumption
            obj.power_consumption = 0;

            % Initialize conditions
            obj.phi = 0;
            obj.theta = 0;
            obj.r = 1;
            obj.percent_eclipse = 0;
        end


        %%%%%%%%%% State and Conditions Manipulation %%%%%%%%%%

        function obj = deploy(obj)
            if (obj.deployable == true)
                obj.deployed = true;
            end
        end

        function obj = retract(obj)
            if (obj.deployable == true)
                obj.deployed = false;
            end
        end

        function obj = set_conditions(obj, phi, theta, r, percent_eclipse)
            obj.phi = phi;
            obj.theta = theta;
            obj.r = r;
            obj.percent_eclipse = percent_eclipse;
        end


        %%%%%%%%%% Interaction Methods %%%%%%%%%%

        function obj = reset_power_consumption(obj)
            obj.power_consumption = 0;
        end

        function max_power = max_power(obj)
            % If not deployed, no power
            if (obj.deployed == false)
                max_power = 0;
                return;
            end

            % Calculate efficiency
            efficiency = (1 - obj.percent_eclipse) * (1 - obj.percent_degradation);
            if (obj.azimuth_tracking == false)
                efficiency = efficiency * cosd(phi);
            end
            if (obj.altitude_tracking == false)
                efficiency = efficiency * cosd(theta);
            end
            efficiency = efficiency / (obj.r^2);

            max_power = obj.nominal_power * efficiency;
        end

        function available_power = available_power(obj)
            available_power = obj.max_power() - obj.power_consumption;
        end

        function [obj, power] = supply_power(obj, load)
            % Produce as much of the load as possible
            power = min([load obj.available_power()]);
            obj.power_consumption = obj.power_consumption + power;
        end
    end
end
