% total_sunlight_expanded_solar.m
% ALPS simulation script for surface missions in total sunlight with larger solar arrays

%%%%%%%%%% Logistical Setup %%%%%%%%%%

addpath('src');
addpath('src/rainflow')
addpath('output');


%%%%%%%%%% Monte Carlo Runs %%%%%%%%%%

%%% Simulation Parameters %%%
num_runs = 100;
num_years = 5;
output_dir = 'output/total_sunlight_expanded_solar/';
time_step = 0.25;
long_time_step = 24;
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
orbit_length = 357*24;
mean_orbit_load = 500;

%%% Simulation State Tracking %%%
time = 0;
data_managers = [];

%%% Simulate Runs %%%
for run = 1:num_runs
    disp(strcat('Starting run: ', string(run)));

    %%% Object Creation %%%
    lander = Lander(6000, 6000 * 7.936, 0);

    solar_array_1 = Solar_Array(2000, true, true, true);
    solar_array_2 = Solar_Array(2000, true, true, true);
    fuel_cell_1 = Fuel_Cell(1000, 0.6, 0.85);
    fuel_cell_2 = Fuel_Cell(1000, 0.6, 0.85);
    battery_1 = Battery(650, 1);
    battery_2 = Battery(650, 1);

    lander = lander.add_solar_array(solar_array_1);
    lander = lander.add_solar_array(solar_array_2);
    lander = lander.add_fuel_cell(fuel_cell_1);
    lander = lander.add_fuel_cell(fuel_cell_2);
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

    for yr = 1:num_years
        % Coast
        lander = lander.deploy_solar_arrays();

        for step = 1:(coast_length/time_step)
            ss_load = load.generate_steady_state_load(mean_coast_load);
            transient_load = load.generate_transient_load();
            lander = lander.step_cycle(ss_load, transient_load, time_step, sunlight);
            lander.solar_arrays = degradation.degrade_solar_arrays(lander.solar_arrays, time_step);
            lander.fuel_cells = degradation.degrade_fuel_cells(lander.fuel_cells, time_step);
            [degradation, lander.batteries] = degradation.degrade_batteries(lander.batteries, time_step);
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
            [degradation, lander.batteries] = degradation.degrade_batteries(lander.batteries, time_step);
            data_manager = data_manager.log_step(lander, ss_load, transient_load, sunlight, time_step);
            time = time + time_step;
        end

        % Surface Mission
        lander = lander.deploy_solar_arrays();

        for step = 1:(surface_mission_length/time_step)
            ss_load = load.generate_steady_state_load(mean_surface_load);
            transient_load = load.generate_transient_load();
            lander = lander.step_cycle(ss_load, transient_load, time_step, sunlight);
            lander.solar_arrays = degradation.degrade_solar_arrays(lander.solar_arrays, time_step);
            lander.fuel_cells = degradation.degrade_fuel_cells(lander.fuel_cells, time_step);
            [degradation, lander.batteries] = degradation.degrade_batteries(lander.batteries, time_step);
            data_manager = data_manager.log_step(lander, ss_load, transient_load, sunlight, time_step);
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
            [degradation, lander.batteries] = degradation.degrade_batteries(lander.batteries, time_step);
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
            [degradation, lander.batteries] = degradation.degrade_batteries(lander.batteries, time_step);
            data_manager = data_manager.log_step(lander, ss_load, transient_load, sunlight, time_step);
            time = time + time_step;
        end

        % In orbit
        lander = lander.deploy_solar_arrays();

        for step = 1:(orbit_length/long_time_step)
            ss_load = load.generate_steady_state_load(mean_orbit_load);
            transient_load = 0;
            lander = lander.step_cycle(ss_load, transient_load, long_time_step, sunlight);
            lander.solar_arrays = degradation.degrade_solar_arrays(lander.solar_arrays, long_time_step);
            lander.fuel_cells = degradation.degrade_fuel_cells(lander.fuel_cells, long_time_step);
            [degradation, lander.batteries] = degradation.degrade_batteries(lander.batteries, long_time_step);
            data_manager = data_manager.log_step(lander, ss_load, transient_load, sunlight, long_time_step);
            time = time + long_time_step;
        end
    end

    %%% Recording %%%
    data_managers = [data_managers data_manager];
end


%%%%%%%%%% Save Workspace %%%%%%%%%%
save(strcat(output_dir, 'workspace'));


%%%%%%%%%% Create Plots %%%%%%%%%%

% Create load profile plot
load_profile_fig = figure;

% Steady-state load profile
subplot(2, 1, 1);
plot(data_manager.time, data_manager.ss_load);
title('Steady-State Load Profile')
xlabel('Time (hrs)');
ylabel('Load (W)');

% Transient load profile
subplot(2, 1, 2);
plot(data_manager.time, data_manager.t_load);
title('Transient Load Profile')
xlabel('Time (hrs)');
ylabel('Energy (Wh)');

% Save and close figure
saveas(load_profile_fig, strcat(output_dir, 'load_profile.png'));
savefig(load_profile_fig, strcat(output_dir, 'load_profile'));
close(load_profile_fig);

% Create load plot
load_fig = figure;

% Steady-state load
subplot(2, 1, 1);
hold on;
ss_load = [];
for i = 1:length(data_managers)
    ss_load = [ss_load; data_managers(i).ss_load];
end
plot(data_manager.time, max(ss_load));
plot(data_manager.time, mean(ss_load));
plot(data_manager.time, min(ss_load));
title('Steady-State Load');
xlabel('Time (hrs)');
ylabel('Load (W)');
legend('Max', 'Avg', 'Min');

% Transient load
subplot(2, 1, 2);
hold on;
t_load = [];
for i = 1:length(data_managers)
    t_load = [t_load; data_managers(i).t_load];
end
plot(data_manager.time, max(t_load));
plot(data_manager.time, mean(t_load));
plot(data_manager.time, min(t_load));
title('Transient Load');
xlabel('Time (hrs)');
ylabel('Energy (Wh)');
legend('Max', 'Avg', 'Min');

% Save and close figure
saveas(load_fig, strcat(output_dir, 'load.png'));
savefig(load_fig, strcat(output_dir, 'load'));
close(load_fig);

% Create margin profile plots
margin_profile_fig = figure;

% Power margin profile
subplot(2, 1, 1);
max_power = [];
power_used = [];
max_power = data_manager.max_solar_power + data_manager.max_fuel_cell_power ...
    + data_manager.max_battery_power;
power_used = data_manager.solar_power_used + data_manager.fuel_cell_power_used ...
    + data_manager.battery_power_used;
power_margin = max_power - power_used;
plot(data_manager.time, power_margin);
title('Power Margin Profile')
xlabel('Time (hrs)');
ylabel('Margin (W)');

% Battery energy storage profile
subplot(2, 1, 2);
plot(data_manager.time, data_manager.battery_energy);
title('Battery Energy Profile')
xlabel('Time (hrs)');
ylabel('Energy (Wh)');

% Save and close figure
saveas(margin_profile_fig, strcat(output_dir, 'margin_profile.png'));
savefig(margin_profile_fig, strcat(output_dir, 'margin_profile'));
close(margin_profile_fig);

% Create margin plots
margin_fig = figure;

% Power margin
subplot(2, 1, 1);
hold on;
max_power = [];
power_used = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    dm_max_power = dm.max_solar_power + dm.max_fuel_cell_power ...
        + dm.max_battery_power;
    dm_power_used = dm.solar_power_used + dm.fuel_cell_power_used ...
        + dm.battery_power_used;
    max_power = [max_power; dm_max_power];
    power_used = [power_used; dm_power_used];
end
power_margin = max_power - power_used;
plot(data_manager.time, max(power_margin));
plot(data_manager.time, mean(power_margin));
plot(data_manager.time, min(power_margin));
title('Power Margin');
xlabel('Time (hrs)');
ylabel('Margin (W)');
legend('Max', 'Avg', 'Min', 'Location', 'southeast');

% Battery energy storage
subplot(2, 1, 2);
hold on;
energy = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    energy = [energy; dm.battery_energy];
end
plot(data_manager.time, max(energy));
plot(data_manager.time, mean(energy));
plot(data_manager.time, min(energy));
title('Battery Energy');
xlabel('Time (hrs)');
ylabel('Energy (Wh)');
legend('Max', 'Avg', 'Min', 'Location', 'southeast');

% Save and close figure
saveas(margin_fig, strcat(output_dir, 'margin.png'));
savefig(margin_fig, strcat(output_dir, 'margin'));
close(margin_fig);

% Create fluid levels profile plot
fluids_profile_fig = figure;

% Hydrogen profile
subplot(3, 1, 1);
plot(data_manager.time, data_manager.hydrogen);
title('Hydrogen Profile')
xlabel('Time (hrs)');
ylabel('Hydrogen (g)');

% Oxygen profile
subplot(3, 1, 2);
plot(data_manager.time, data_manager.oxygen);
title('Oxygen Profile')
xlabel('Time (hrs)');
ylabel('Oxygen (g)');

% Water profile
subplot(3, 1, 3);
plot(data_manager.time, data_manager.water);
title('Water Profile')
xlabel('Time (hrs)');
ylabel('Water (g)');

% Save and close figure
saveas(fluids_profile_fig, strcat(output_dir, 'fluids_profile.png'));
savefig(fluids_profile_fig, strcat(output_dir, 'fluids_profile'));
close(fluids_profile_fig);

% Create fluids figure
fluids_fig = figure;

% Hydrogen
subplot(3, 1, 1);
hold on;
hydrogen = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    hydrogen = [hydrogen; dm.hydrogen];
end
plot(data_manager.time, max(hydrogen));
plot(data_manager.time, mean(hydrogen));
plot(data_manager.time, min(hydrogen));
title('Hydrogen');
xlabel('Time (hrs)');
ylabel('Hydrogen (g)');
legend('Max', 'Avg', 'Min');

% Oxygen
subplot(3, 1, 2);
hold on;
oxygen = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    oxygen = [oxygen; dm.oxygen];
end
plot(data_manager.time, max(oxygen));
plot(data_manager.time, mean(oxygen));
plot(data_manager.time, min(oxygen));
title('Oxygen');
xlabel('Time (hrs)');
ylabel('Oxygen (g)');
legend('Max', 'Avg', 'Min');

% Water
subplot(3, 1, 3);
hold on;
water = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    water = [water; dm.water];
end
plot(data_manager.time, max(water));
plot(data_manager.time, mean(water));
plot(data_manager.time, min(water));
title('Water');
xlabel('Time (hrs)');
ylabel('Water (g)');
legend('Max', 'Avg', 'Min');

% Save and close figure
saveas(fluids_fig, strcat(output_dir, 'fluids.png'));
savefig(fluids_fig, strcat(output_dir, 'fluids'));
close(fluids_fig);

% Create degradation profile figure
deg_profile_fig = figure;

% Solar array 1 degradation profile
subplot(3, 2, 1);
plot(data_manager.time, (1 - data_manager.solar_deg_1) * 100);
title('Solar Array 1 Degradation Profile')
xlabel('Time (hrs)');
ylabel('Efficiency (%)');

% Solar array 2 degradation profile
subplot(3, 2 , 2);
solar_deg_2 = [];
plot(data_manager.time, (1 - data_manager.solar_deg_2) * 100);
title('Solar Array 2 Degradation Profile')
xlabel('Time (hrs)');
ylabel('Efficiency (%)');

% Fuel cell 1 degradation profile
subplot(3, 2, 3);
plot(data_manager.time, (1 - data_manager.fuel_cell_deg_1) * 100);
title('Fuel Cell 1 Degradation Profile')
xlabel('Time (hrs)');
ylabel('Efficiency (%)');

% Fuel cell 2 degradation profile
subplot(3, 2, 4);
plot(data_manager.time, (1 - data_manager.fuel_cell_deg_2) * 100);
title('Fuel Cell 2 Degradation Profile')
xlabel('Time (hrs)');
ylabel('Efficiency (%)');

% Battery 1 degradation profile
subplot(3, 2, 5);
plot(data_manager.time, (1 - data_manager.battery_deg_1) * 100);
title('Battery 1 Degradation Profile')
xlabel('Time (hrs)');
ylabel('Efficiency (%)');

% Battery 2 degradation profile
subplot(3, 2, 6);
plot(data_manager.time, (1 - data_manager.battery_deg_2) * 100);
title('Battery 2 Degradation Profile')
xlabel('Time (hrs)');
ylabel('Efficiency (%)');

% Save and close figure
saveas(deg_profile_fig, strcat(output_dir, 'degradation_profile.png'));
savefig(deg_profile_fig, strcat(output_dir, 'degradation_profile'));
close(deg_profile_fig);

% Create degradation figure
deg_fig = figure;

% Solar array 1 degradation
subplot(3, 2, 1);
hold on;
solar_deg_1 = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    solar_deg_1 = [solar_deg_1; dm.solar_deg_1];
end
solar_deg_1 = (1 - solar_deg_1) * 100;
plot(data_manager.time, max(solar_deg_1));
plot(data_manager.time, mean(solar_deg_1));
plot(data_manager.time, min(solar_deg_1));
title('Solar Array 1 Degradation');
xlabel('Time (hrs)');
ylabel('Efficiency (%)');
legend('Max', 'Avg', 'Min');

% Solar degradation 2
subplot(3, 2, 2);
hold on;
solar_deg_2 = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    solar_deg_2 = [solar_deg_2; dm.solar_deg_2];
end
solar_deg_2 = (1 - solar_deg_2) * 100;
plot(data_manager.time, max(solar_deg_2));
plot(data_manager.time, mean(solar_deg_2));
plot(data_manager.time, min(solar_deg_2));
title('Solar Array 2 Degradation');
xlabel('Time (hrs)');
ylabel('Efficiency (%)');
legend('Max', 'Avg', 'Min');

% Fuel cell degradation 1
subplot(3, 2, 3);
hold on;
fuel_cell_deg_1 = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    fuel_cell_deg_1 = [fuel_cell_deg_1; dm.fuel_cell_deg_1];
end
fuel_cell_deg_1 = (1 - fuel_cell_deg_1) * 100;
plot(data_manager.time, max(fuel_cell_deg_1));
plot(data_manager.time, mean(fuel_cell_deg_1));
plot(data_manager.time, min(fuel_cell_deg_1));
title('Fuel Cell 1 Degradation');
xlabel('Time (hrs)');
ylabel('Efficiency (%)');
legend('Max', 'Avg', 'Min');

% Fuel cell degradation 2
subplot(3, 2, 4);
hold on;
fuel_cell_deg_2 = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    fuel_cell_deg_2 = [fuel_cell_deg_2; dm.fuel_cell_deg_2];
end
fuel_cell_deg_2 = (1 - fuel_cell_deg_2) * 100;
plot(data_manager.time, max(fuel_cell_deg_2));
plot(data_manager.time, mean(fuel_cell_deg_2));
plot(data_manager.time, min(fuel_cell_deg_2));
title('Fuel Cell 2 Degradation');
xlabel('Time (hrs)');
ylabel('Efficiency (%)');
legend('Max', 'Avg', 'Min');

% Battery 1 degradation
subplot(3, 2, 5);
hold on;
battery_deg_1 = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    battery_deg_1 = [battery_deg_1; dm.battery_deg_1];
end
battery_deg_1 = (1 - battery_deg_1) * 100;
plot(data_manager.time, max(battery_deg_1));
plot(data_manager.time, mean(battery_deg_1));
plot(data_manager.time, min(battery_deg_1));
title('Battery 1 Degradation');
xlabel('Time (hrs)');
ylabel('Efficiency (%)');
legend('Max', 'Avg', 'Min');

% Battery 2 degradation
subplot(3, 2, 6);
hold on;
battery_deg_2 = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    battery_deg_2 = [battery_deg_2; dm.battery_deg_2];
end
battery_deg_2 = (1 - battery_deg_2) * 100;
plot(data_manager.time, max(battery_deg_2));
plot(data_manager.time, mean(battery_deg_2));
plot(data_manager.time, min(battery_deg_2));
title('Battery 2 Degradation');
xlabel('Time (hrs)');
ylabel('Efficiency (%)');
legend('Max', 'Avg', 'Min');

% Save and close figure
saveas(deg_fig, strcat(output_dir, 'degradation.png'));
savefig(deg_fig, strcat(output_dir, 'degradation'));
close(deg_fig);

% Create battery cycles profile figure
cycles_profile_fig = figure;

% Battery 1 cycles profile
subplot(2, 1, 1);
plot(data_manager.time, data_manager.battery_cycles_1);
title('Battery 1 Number of Cycles Profile')
xlabel('Time (hrs)');
ylabel('Number of Cycles');

% Battery 2 cycles profile
subplot(2, 1, 2);
plot(data_manager.time, data_manager.battery_cycles_2);
title('Battery 2 Number of Cycles Profile')
xlabel('Time (hrs)');
ylabel('Number of Cycles');

% Save and close figure
saveas(cycles_profile_fig, strcat(output_dir, 'battery_cycles_profile.png'));
savefig(cycles_profile_fig, strcat(output_dir, 'battery_cycles_profile'));
close(cycles_profile_fig);

% Create battery cycles figure
cycles_fig = figure;

% Battery 1 cycles
subplot(2, 1, 1);
hold on;
battery_cycles_1 = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    battery_cycles_1 = [battery_cycles_1; dm.battery_cycles_1];
end
plot(data_manager.time, max(battery_cycles_1));
plot(data_manager.time, mean(battery_cycles_1));
plot(data_manager.time, min(battery_cycles_1));
title('Battery 1 Number of Cycles');
xlabel('Time (hrs)');
ylabel('Number of Cycles');
legend('Max', 'Avg', 'Min', 'Location', 'southeast');

% Battery 2 cycles
subplot(2, 1, 2);
hold on;
battery_cycles_2 = [];
for i = 1:length(data_managers)
    dm = data_managers(i);
    battery_cycles_2 = [battery_cycles_2; dm.battery_cycles_2];
end
plot(data_manager.time, max(battery_cycles_2));
plot(data_manager.time, mean(battery_cycles_2));
plot(data_manager.time, min(battery_cycles_2));
title('Battery 2 Number of Cycles');
xlabel('Time (hrs)');
ylabel('Number of Cycles');
legend('Max', 'Avg', 'Min', 'Location', 'southeast');

% Save and close figure
saveas(cycles_fig, strcat(output_dir, 'battery_cycles.png'));
savefig(cycles_fig, strcat(output_dir, 'battery_cycles'));
close(cycles_fig);
