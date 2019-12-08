% initial_test.m
% ALPS simulation script for an initial test of the framework

%%%%%%%%%% Logistical Setup %%%%%%%%%%

addpath('src');
addpath('src/rainflow')
addpath('output');


%%%%%%%%%% Monte Carlo Runs %%%%%%%%%%

%%% Simulation Parameters %%%
num_runs = 1;
output_dir = 'output/initial_test';
data_managers = [];
time_step = 0.25;
coast_length = 24;
mean_coast_load = 1500;
descent_length = 0.25;
mean_descent_load = 3000;
surface_mission_length = 156;
mean_surface_load = 800;
ascent_length = 0.25;
mean_ascent_load = 2600;
docking_coast_length = 24;
mean_docking_load = 1000;
recharging_length = 24;
mean_recharging_load = 500;

%%% Simulation State Tracking %%%
time = 0;

%%% Simulate Runs %%%
for run = 1:num_runs

    %%% Object Creation %%%
    lander = Lander(6000, 6000 * 7.936, 0);

    solar_array_1 = Solar_Array(1000, true, true, true);
    solar_array_2 = Solar_Array(1000, true, true, true);
    fuel_cell_1 = Fuel_Cell(1000, 0.6, 0.85);
    fuel_cell_2 = Fuel_Cell(1000, 0.6, 0.85);
    fuel_cell_3 = Fuel_Cell(1000, 0.6, 0.85);
    battery_1 = Battery(75, 1);
    battery_2 = Battery(75, 1);

    lander = lander.add_solar_array(solar_array_1);
    lander = lander.add_solar_array(solar_array_2);
    lander = lander.add_fuel_cell(fuel_cell_1);
    lander = lander.add_fuel_cell(fuel_cell_2);
    lander = lander.add_fuel_cell(fuel_cell_3);
    lander = lander.add_battery(battery_1);
    lander = lander.add_battery(battery_2);

    data_manager = Data_Manager();
    load = Load(0.02, 0.1, 50, 0.05);
    degradation = Degradation(3.425e-6, 1.713e-7, 9.231e-6, 4.616e-7);

    %%% Solar conditions
    sunlight.phi = 0;
    sunlight.theta = 0;
    sunlight.r = 1;
    sunlight.percent_eclipse = 0;

    darkness.phi = 0;
    darkness.theta = 0;
    darkness.r = 1;
    darkness.percent_eclipse = 1;

    %%% Simulation %%%
    time = 0;

    % Coast
    lander = lander.deploy_solar_arrays();

    for step = 1:(coast_length/time_step)
        ss_load = load.generate_steady_state_load(mean_coast_load);
        transient_load = load.generate_transient_load();
        lander = lander.step_cycle(ss_load, transient_load, time_step, sunlight);
        lander.solar_arrays = degradation.degrade_solar_arrays(lander.solar_arrays, time_step);
        lander.fuel_cells = degradation.degrade_fuel_cells(lander.fuel_cells, time_step);
        lander.batteries = degradation.degrade_batteries(lander.batteries, time_step);
        data_manager = data_manager.log_step(lander, ss_load, transient_load, sunlight, time_step);
        time = time + time_step;
    end

    % Descent
    lander = lander.retract_solar_arrays();

    for step = 1:(descent_length/time_step)
        ss_load = load.generate_steady_state_load(mean_descent_load);
        transient_load = load.generate_transient_load();
        lander = lander.step_cycle(ss_load, transient_load, time_step, sunlight);
        lander.solar_arrays = degradation.degrade_solar_arrays(lander.solar_arrays, time_step);
        lander.fuel_cells = degradation.degrade_fuel_cells(lander.fuel_cells, time_step);
        lander.batteries = degradation.degrade_batteries(lander.batteries, time_step);
        data_manager = data_manager.log_step(lander, ss_load, transient_load, sunlight, time_step);
        time = time + time_step;
    end

    % Surface Mission
    lander = lander.deploy_solar_arrays();

    for step = 1:(surface_mission_length/time_step)
        ss_load = load.generate_steady_state_load(mean_surface_load);
        transient_load = load.generate_transient_load();
        lander = lander.step_cycle(ss_load, transient_load, time_step, darkness);
        lander.solar_arrays = degradation.degrade_solar_arrays(lander.solar_arrays, time_step);
        lander.fuel_cells = degradation.degrade_fuel_cells(lander.fuel_cells, time_step);
        lander.batteries = degradation.degrade_batteries(lander.batteries, time_step);
        data_manager = data_manager.log_step(lander, ss_load, transient_load, darkness, time_step);
        time = time + time_step;
    end

    % Ascent
    lander = lander.retract_solar_arrays();

    for step = 1:(ascent_length/time_step)
        ss_load = load.generate_steady_state_load(mean_ascent_load);
        transient_load = load.generate_transient_load();
        lander = lander.step_cycle(ss_load, transient_load, time_step, sunlight);
        lander.solar_arrays = degradation.degrade_solar_arrays(lander.solar_arrays, time_step);
        lander.fuel_cells = degradation.degrade_fuel_cells(lander.fuel_cells, time_step);
        lander.batteries = degradation.degrade_batteries(lander.batteries, time_step);
        data_manager = data_manager.log_step(lander, ss_load, transient_load, sunlight, time_step);
        time = time + time_step;
    end

    % Docking coast
    lander = lander.deploy_solar_arrays();

    for step = 1:(docking_coast_length/time_step)
        ss_load = load.generate_steady_state_load(mean_docking_load);
        transient_load = load.generate_transient_load();
        lander = lander.step_cycle(ss_load, transient_load, time_step, sunlight);
        lander.solar_arrays = degradation.degrade_solar_arrays(lander.solar_arrays, time_step);
        lander.fuel_cells = degradation.degrade_fuel_cells(lander.fuel_cells, time_step);
        lander.batteries = degradation.degrade_batteries(lander.batteries, time_step);
        data_manager = data_manager.log_step(lander, ss_load, transient_load, sunlight, time_step);
        time = time + time_step;
    end

    % Recharging
    lander = lander.deploy_solar_arrays();

    for step = 1:(recharging_length/time_step)
        ss_load = load.generate_steady_state_load(mean_recharging_load);
        transient_load = load.generate_transient_load();
        lander = lander.step_cycle(ss_load, transient_load, time_step, sunlight);
        lander.solar_arrays = degradation.degrade_solar_arrays(lander.solar_arrays, time_step);
        lander.fuel_cells = degradation.degrade_fuel_cells(lander.fuel_cells, time_step);
        lander.batteries = degradation.degrade_batteries(lander.batteries, time_step);
        data_manager = data_manager.log_step(lander, ss_load, transient_load, sunlight, time_step);
        time = time + time_step;
    end

    %%% Recording %%%
    data_managers = [data_managers data_manager];
end


%%%%%%%%%% Create Plots %%%%%%%%%%


%%%%%%%%%% Save Workspace %%%%%%%%%%
