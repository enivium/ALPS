% Data_Manager.m
% The class for recording and plotting data from the ALPS simulation

classdef Data_Manager
    properties

        % Lander variables
        max_solar_power
        max_fuel_cell_power
        max_battery_power
        solar_power_used
        fuel_cell_power_used
        battery_power_used
        battery_energy
        hydrogen
        oxygen
        water
        solar_deg_1
        solar_deg_2
        fuel_cell_deg_1
        fuel_cell_deg_2
        battery_deg_1
        battery_deg_2
        battery_cycles_1
        battery_cycles_2

        % Power demanded by load
        ss_load
        t_load

        % Environment variables
        sun_phi
        sun_theta

        % Simulation variables
        time_step
        time
    end


    methods

        %%%%%%%%%% Logging Methods %%%%%%%%%%

        function obj = log_step(obj, lander, ss_load, t_load, solar_conditions, time_step)
            obj.time_step = [obj.time_step time_step];
            if (length(obj.time) == 0)
                previous_time = 0;
            else
                previous_time = obj.time(end);
            end
            obj.time = [obj.time (previous_time+time_step)];
            obj = obj.log_lander(lander);
            obj = obj.log_load(ss_load, t_load);
            obj = obj.log_solar_conditions(solar_conditions);
        end

        function obj = log_lander(obj, lander)
            obj.max_solar_power = [obj.max_solar_power lander.max_solar_power];
            obj.max_fuel_cell_power = [obj.max_fuel_cell_power lander.max_fuel_cell_power];
            obj.max_battery_power = [obj.max_battery_power lander.max_battery_power];
            obj.solar_power_used = [obj.solar_power_used lander.solar_power_used];
            obj.fuel_cell_power_used = [obj.fuel_cell_power_used lander.fuel_cell_power_used];
            obj.battery_power_used = [obj.battery_power_used lander.battery_power_used];
            obj.battery_energy = [obj.battery_energy lander.battery_energy];
            obj.hydrogen = [obj.hydrogen lander.hydrogen];
            obj.oxygen = [obj.oxygen lander.oxygen];
            obj.water = [obj.water lander.water];
            obj.solar_deg_1 = [obj.solar_deg_1 ...
                lander.solar_arrays(1).percent_degradation];
            obj.solar_deg_2 = [obj.solar_deg_2 ...
                lander.solar_arrays(2).percent_degradation];
            obj.fuel_cell_deg_1 = [obj.fuel_cell_deg_1 ...
                lander.fuel_cells(1).percent_degradation];
            obj.fuel_cell_deg_2 = [obj.fuel_cell_deg_2 ...
                lander.fuel_cells(2).percent_degradation];
            obj.battery_deg_1 = [obj.battery_deg_1 ...
                lander.batteries(1).percent_degradation];
            obj.battery_deg_2 = [obj.battery_deg_2 ...
                lander.batteries(2).percent_degradation];
            obj.battery_cycles_1 = [obj.battery_cycles_1 ...
                lander.batteries(1).num_cycles];
            obj.battery_cycles_2 = [obj.battery_cycles_2 ...
                lander.batteries(2).num_cycles];
        end

        function obj = log_load(obj, ss_load, t_load)
            obj.ss_load = [obj.ss_load ss_load];
            obj.t_load = [obj.t_load t_load];
        end

        function obj = log_solar_conditions(obj, solar_conditions)
            obj.sun_phi = [obj.sun_phi solar_conditions.phi];
            obj.sun_theta = [obj.sun_theta solar_conditions.phi];
        end
    end
end
