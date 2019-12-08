% Lander.m
% Definition file for the Lander class

classdef Lander
    properties
        % Arrays for power units
        solar_arrays
        fuel_cells
        batteries

        % Fluid reserves
        hydrogen
        oxygen
        water

        % Status variables (set for each phase, then reset)
        max_solar_power
        max_fuel_cell_power
        max_battery_power
        battery_energy
        solar_power_used
        fuel_cell_power_used
        battery_power_used
        battery_energy_used
    end


    methods

        %%%%%%%%%% Constructor %%%%%%%%%%

        function obj = Lander(hydrogen, oxygen, water)
            % Define starting fluids
            obj.hydrogen = hydrogen;
            obj.oxygen = oxygen;
            obj.water = water;

            % Set status variables to 0
            obj.max_solar_power= 0;
            obj.max_fuel_cell_power = 0;
            obj.max_battery_power = 0;
            obj.battery_energy = 0;
            obj.solar_power_used = 0;
            obj.fuel_cell_power_used = 0;
            obj.battery_power_used = 0;
            obj.battery_energy_used = 0;
        end


        %%%%%%%%%% Adding Power Unit Methods %%%%%%%%%%

        function obj = add_solar_array(obj, new_array)
            obj.solar_arrays = [obj.solar_arrays new_array];
        end

        function obj = add_fuel_cell(obj, new_fuel_cell)
            obj.fuel_cells = [obj.fuel_cells new_fuel_cell];
        end

        function obj = add_battery(obj, new_battery)
            obj.batteries = [obj.batteries new_battery];
        end


        %%%%%%%%%% Main Phase Cycle Method %%%%%%%%%%

        function obj = step_cycle(obj, steady_state_load, transient_load, time, solar_conditions)

            % Set status variables to 0
            obj.max_solar_power = 0;
            obj.max_fuel_cell_power = 0;
            obj.max_battery_power = 0;
            obj.battery_energy = 0;
            obj.solar_power_used = 0;
            obj.fuel_cell_power_used = 0;
            obj.battery_power_used = 0;
            obj.battery_energy_used = 0;

            % Unpack and set conditions for the solar arrays
            phi = solar_conditions.phi;
            theta = solar_conditions.theta;
            r = solar_conditions.r;
            percent_eclipse = solar_conditions.percent_eclipse;
            for i = 1:length(obj.solar_arrays)
                obj.solar_arrays(i) = obj.solar_arrays(i).set_conditions(phi, theta, r, percent_eclipse);
            end

            % Reset power consumption tracking
            for i = 1:length(obj.solar_arrays)
                obj.solar_arrays(i) = obj.solar_arrays(i).reset_power_consumption();
            end
            for i = 1:length(obj.fuel_cells)
                obj.fuel_cells(i) = obj.fuel_cells(i).reset_power_consumption();
            end
            for i = 1:length(obj.batteries)
                obj.batteries(i) = obj.batteries(i).reset_power_consumption();
            end

            % Log max power that can be generated and battery energy
            for i = 1:length(obj.solar_arrays)
                obj.max_solar_power = obj.max_solar_power + obj.solar_arrays(i).max_power();
            end
            for i = 1:length(obj.fuel_cells)
                obj.max_fuel_cell_power = obj.max_fuel_cell_power + obj.fuel_cells(i).max_power();
            end
            for i = 1:length(obj.batteries)
                obj.max_battery_power = obj.max_battery_power + obj.batteries(i).max_power();
                obj.battery_energy = obj.battery_energy + obj.batteries(i).energy_stored;
            end

            % Supply steady-state power
            obj = obj.supply_steady_state_power(steady_state_load, time);

            % Supply transient power
            obj = obj.supply_transient_power(transient_load);

            % Charge batteries
            obj = obj.charge_batteries(time);

            % Regenerate fuel with fuel cells
            obj = obj.regenerate_fuel(time);
        end


        %%%%%%%%%% Solar Array State Methods %%%%%%%%%%

        function obj = deploy_solar_arrays(obj)
            % Fixed arrays are always deployed
            for i = 1:length(obj.solar_arrays)
                obj.solar_arrays(i) = obj.solar_arrays(i).deploy();
            end
        end

        function obj = retract_solar_arrays(obj)
            % Fixed arrays are always deployed
            for i = 1:length(obj.solar_arrays)
                obj.solar_arrays(i) = obj.solar_arrays(i).retract();
            end
        end

        function obj = set_solar_conditions(obj, phi, theta, r, percent_eclipse)
            obj.solar_arrays = obj.solar_arrays.set_conditions(phi, theta, r, percent_eclipse);
        end


        %%%%%%%%%% Power System Interaction Methods %%%%%%%%%%

        function obj = supply_steady_state_power(obj, load, time)

            % Generate solar power
            for i = 1:length(obj.solar_arrays)
                [obj.solar_arrays(i), array_supply] = obj.solar_arrays(i).supply_power(load);
                load = load - array_supply;
                obj.solar_power_used = obj.solar_power_used + array_supply;
            end

            % Check if load is satisfied
            if (load <= 0)
                return;
            end

            % If not, generate fuel cell power
            for i = 1:length(obj.fuel_cells)
                [obj, cell_supply] = obj.generate_fuel_cell_power(i, load, time);
                load = load - cell_supply;
                obj.fuel_cell_power_used = obj.fuel_cell_power_used + cell_supply;
            end

            % Check if load is satisfied
            if (load <= 0)
                return;
            end

            % If not, generate battery power
            [obj batteries_supply] = obj.draw_battery_power(load, time);
            load = load - batteries_supply;
            obj.battery_power_used = obj.battery_power_used + batteries_supply;
            obj.battery_energy_used = obj.battery_energy_used + (batteries_supply * time);

            % If power is still not supplied, throw an error
            if (load > 0)
                error('SIMULATION ERROR: Lander cannot supply enough power to satisfy steady-state load');
            end
        end

        function obj = supply_transient_power(obj, load)
            % Supply battery power
            [obj batteries_supply] = obj.draw_battery_power(load, 1);
            load = load - batteries_supply;
            obj.battery_power_used = obj.battery_power_used + batteries_supply;
            obj.battery_energy_used = obj.battery_energy_used + (batteries_supply * 1);

            % If power is still not supplied, throw an error
            if (load > 0)
                error('SIMULATION ERROR: Lander cannot supply enough power to satisfy transient load');
            end
        end

        function obj = charge_batteries(obj, time)

            charging_power = 0;
            for i = 1:length(obj.batteries)
                charging_power = charging_power + obj.batteries(i).charging_power(time);
            end
            power_required = charging_power;

            % Generate solar power
            for i = 1:length(obj.solar_arrays)
                [obj.solar_arrays(i), array_supply] = ...
                    obj.solar_arrays(i).supply_power(power_required);
                power_required = power_required - array_supply;
                obj.solar_power_used = obj.solar_power_used + array_supply;
            end

            % Generate fuel cell power
            for i = 1:length(obj.fuel_cells)
                [obj, cell_supply] = obj.generate_fuel_cell_power(i, power_required, time);
                power_required = power_required - cell_supply;
                obj.fuel_cell_power_used = obj.fuel_cell_power_used + cell_supply;
            end

            % Charge the batteries
            charging_power = charging_power - power_required;
            for i = 1:length(obj.batteries)
                [obj.batteries(i) power_used] = obj.batteries(i).charge(charging_power, time);
                charging_power = charging_power - power_used;
            end
        end

        function obj = regenerate_fuel(obj, time)
            % Determine how much power can be used for regeneration
            regen_power = 0;
            regen_water = obj.water;
            for i = 1:length(obj.fuel_cells)
                cell_power = obj.fuel_cells(i).available_regeneration(regen_water, time);
                regen_power = regen_power + cell_power;
                regen_water = regen_water - (cell_power * time ...
                    * obj.fuel_cells(i).water_consumption);
            end

            % Supply as much of this as possible with solar arrays
            power_required = regen_power;
            for i = 1:length(obj.solar_arrays)
                [obj.solar_arrays(i), array_supply] = ...
                    obj.solar_arrays(i).supply_power(power_required);
                power_required = power_required - array_supply;
                obj.solar_power_used = obj.solar_power_used + array_supply;
            end

            regen_power = regen_power - power_required;
            for i = 1:length(obj.fuel_cells)
                [obj.fuel_cells(i), power_used, hydrogen_produced, oxygen_produced, water_consumed] = ...
                    obj.fuel_cells(i).regenerate_fuel(regen_power, obj.water, time);
                regen_power = regen_power - power_used;
                obj.hydrogen = obj.hydrogen + hydrogen_produced;
                obj.oxygen = obj.oxygen + oxygen_produced;
                obj.water = obj.water - water_consumed;
            end
        end


        %%%%%%%%%% Power System Interaction Helper Methods %%%%%%%%%%

        function [obj power] = draw_battery_power(obj, load, time)
            power_draw_per_battery = load / length(obj.batteries);
            power = 0;
            for i = 1:length(obj.batteries)
                [obj.batteries(i) power_draw] = obj.batteries(i).draw_power(power_draw_per_battery, time);
                power = power + power_draw;
            end
        end

        function [obj power] = generate_fuel_cell_power(obj, idx, load, time)
            [obj.fuel_cells(idx), power, hydrogen_consumed, oxygen_consumed, water_produced] = ...
                obj.fuel_cells(idx).generate_power(load, time);
            obj.hydrogen = obj.hydrogen - hydrogen_consumed;
            obj.oxygen = obj.oxygen - oxygen_consumed;
            obj.water = obj.water + water_produced;

            % Check for fuel depletion
            if (obj.hydrogen < 0)
                error('SIMULATION ERROR: Hydrogen has been depleted');
            end
            if (obj.oxygen < 0)
                error('SIMULATION ERROR: Oxygen has been depleted');
            end
        end
    end
end
