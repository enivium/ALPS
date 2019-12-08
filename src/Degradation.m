% Degradation.m
% Degrades the power components of the Lander

classdef Degradation
    properties
        solar_degradation_mean % Percent per hour
        solar_degradation_sigma
        fuel_cell_degradation_mean % Percent per W
        fuel_cell_degradation_sigma

        % Nonlinear battery degradation
        a_sei
        b_sei

        % Battery DoD stress model
        k_d1
        k_d2
        k_d3

        % Battery SoC stress model
        k_sig
        sig_ref

        % Battery temperature stress model
        k_T
        T_ref

        % Battery calendar aging model
        k_t

        % State Tracking
        time
        num_cycles
    end


    methods

        %%%%%%%%%% Constructor %%%%%%%%%%

        function obj = Degradation(...
                solar_degradation_mean, solar_degradation_sigma, ...
                fuel_cell_degradation_mean, fuel_cell_degradation_sigma)
            obj.solar_degradation_mean = solar_degradation_mean;
            obj.solar_degradation_sigma = solar_degradation_sigma;
            obj.fuel_cell_degradation_mean = fuel_cell_degradation_mean;
            obj.fuel_cell_degradation_sigma = fuel_cell_degradation_sigma;

            obj.a_sei = 5.75e-2;
            obj.b_sei = 121;
            obj.k_d1 = 1.4e5;
            obj.k_d2 = -5.01e-1;
            obj.k_d3 = -1.23e5;
            obj.k_sig = 1.04;
            obj.sig_ref = 0.5;
            obj.k_T = 6.93e-2;
            obj.T_ref = 25;
            obj.k_t = 1.4904e-6;

            obj.time = 0;
        end


        %%%%%%%%%% Degradation Methods %%%%%%%%%%

        function solar_arrays = degrade_solar_arrays(obj, solar_arrays, time_step)
            for i = 1:length(solar_arrays)
                degradation_rate = obj.solar_degradation_mean ...
                    + (obj.solar_degradation_sigma * randn);
                solar_arrays(i).percent_degradation = solar_arrays(i).percent_degradation ...
                    + (1 - solar_arrays(i).percent_degradation) ...
                    * degradation_rate * time_step;
            end
        end

        function fuel_cells = degrade_fuel_cells(obj, fuel_cells, time_step)
            for i = 1:length(fuel_cells)
                if (fuel_cells(i).power_consumption > 0 || fuel_cells(i).regeneration_power > 0)
                    degradation_rate = obj.fuel_cell_degradation_mean ...
                        + (obj.fuel_cell_degradation_sigma * randn);
                    fuel_cells(i).percent_degradation = fuel_cells(i).percent_degradation ...
                        + degradation_rate * time_step;
                end
            end
        end

        function [obj, batteries] = degrade_batteries(obj, batteries, time_step)
            obj.time = [obj.time obj.time(end)+time_step];
            for j = 1:length(batteries)
                % Calculate cycles with rainflow algorithm
                [ext, exttime] = sig2ext(batteries(j).SoC, obj.time);
                rf = rainflow(ext, exttime);
                cycle_amplitudes = rf(1,:);
                cycle_means = rf(2,:);
                cycle_nums = rf(3,:);
                cycle_begin_times = rf(4,:);
                cycle_periods = rf(5,:);

                % Convert into stress parameters
                t = cycle_periods;
                d = cycle_amplitudes * 2;
                sig = cycle_means;
                T = obj.T_ref * ones(1,length(t));

                % Calculate degradation
                f_d = 0;
                for i = 1:length(t)
                    f_d = f_d + obj.linearized_degradation(t(i), d(i), sig(i), T(i));
                end
                L = 1 - (obj.a_sei * exp(-obj.b_sei * f_d)) - ((1 - obj.a_sei) * exp(-f_d));

                batteries(j).percent_degradation = L;
                batteries(j).num_cycles = length(cycle_amplitudes);

                % Reduce charge if necessary
                if (batteries(j).energy_stored > (batteries(j).capacity * (1 - L)))
                    batteries(j).energy_stored = batteries(j).capacity * (1 - L);
                end
            end
        end


        %%%%%%%%%% Helper Methods %%%%%%%%%%

        function f_d = linearized_degradation(obj, t, d, sig, T)
            % Compute stress factors
            S_T = exp(obj.k_T * (T - obj.T_ref) * (obj.T_ref / T));
            S_sig = exp(obj.k_sig * (sig - obj.sig_ref));
            S_t = obj.k_t * t;
            S_d = 1 / ((obj.k_d1 * (d^obj.k_d2)) + obj.k_d3);

            % Compute degradations
            f_c = S_d * S_sig * S_T;
            f_t = S_t * S_sig * S_T;
            f_d = f_c + f_t;
        end
    end
end
