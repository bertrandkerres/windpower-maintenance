%% Class PowerCurve
% Use this class to generate PowerCurve objects. PowerCurve objects can 
% calculate energy production from wind speeds. There are 2 modes for 
% calculation:
%
% # *linear interpolation*, where the power curve is interpolated linearly
% from the 2 closest data points
% # *polynom evaluation*, where the power curve is estimated by a 5th-grade-
% polynom in the non-constant intervall _(faster)_.
%
% Bertrand Kerres, kerres@kth.se, 2013-07-03

classdef PowerCurve < handle
    %% Properties
    % Properties are basically different characteristics of the power
    % curve. They can only be set when creating the object.
    properties (SetAccess = private, GetAccess = public)
        v_in;
        v_rated;
        v_out;
        p_max;
        power_curve_poly;            %for polynom estimation
        power_curve_interp;          %for interpolation
    end
    
    %% Methods
    methods
        %% Constructor
        % The constructor creates a PowerCurve object. Parameters are:
        %
        % # *power_curve_table* as _(m x 2)-matrix_, where the first column
        % vector represents wind speeds and the second column vector the
        % power output
        %.
        function obj = PowerCurve (power_curve_table)
            %check input arguments
            ps = inputParser();
            ps.addRequired('power_curve_table', @isnumeric);
            ps.parse(power_curve_table);
            
            %assign power curve properties. It is assumed that max power is
            %reached at cut-out-speed
            i_in = find (power_curve_table(:,2), 1, 'first');
            i_out = find (power_curve_table(:,2), 1, 'last');
            i_max = find (power_curve_table(:,2) == max (power_curve_table(:,2)));
            
            obj.v_in = power_curve_table(i_in,1);
            obj.v_rated = power_curve_table(i_max(1),1);
            obj.p_max = power_curve_table(i_max(1),2);
            obj.v_out = power_curve_table(i_out,1);
            
            % curve between cut-in and rated speed is modeled as a x^5 -
            % polynom...
            obj.power_curve_poly = polyfit (power_curve_table(i_in:i_max(1),1), ...
                                    power_curve_table(i_in:i_max(1),2),5);
                                
            % ... or is interpolated linearly between the data points
            
            obj.power_curve_interp = [[power_curve_table(1:i_in-1, 1), power_curve_table(1:i_in-1, 2)];
                                    [obj.v_in - 0.1, 0]; 
                                    [power_curve_table(i_in:i_out, 1), power_curve_table(i_in:i_out, 2)];
                                    [obj.v_out + 0.1, 0]; 
                                    [50, 0] ];
        end
        
        %% PlotPowerCurve
        % Plots the turbines output power over the wind speed. Parameter:
        %
        % # *do_linear* as _(optional) boolean_. Set to *true* to use linear
        % interpolation and to *false* to use polynom evaluation. Default
        % is *false*.
        %
        function PlotMe(obj, varargin)
            % check input value
            ps = inputParser();
            ps.addParamValue('do_linear',false, @islogical);
            ps.parse(varargin{:});
            
            INTERVALL = 0.1;
            X_MAX = 35;
            x_data = [0: INTERVALL: X_MAX];
            % y-data =  0 for low wind speeds < cut-in
            %           calculated with polynom/interp for v_in <= v < v_rated
            %           p_max for v_rated <= v < v_out
            %           0 for v > cut-out
            if ps.Results.do_linear
                y_data = interp1(obj.power_curve_interp(:,1), ...
                                obj.power_curve_interp(:,2), ...
                                x_data, 'linear');
                
            else
                y_data = [zeros(1,obj.v_in/INTERVALL) ...
                    polyval(obj.power_curve_poly, [obj.v_in: INTERVALL: obj.v_rated]) ...
                    obj.p_max * ones(1,(obj.v_out-obj.v_rated)/INTERVALL) ...
                    zeros(1,(X_MAX-obj.v_out)/INTERVALL) ];
            end
            plot (x_data, y_data);
        end
        
        %% CalculateEnergy
        % Returns production amounts for given wind speeds. Parameter:
        %
        % # *wind_speeds* as _matrix_, which contains the wind speeds
        % # *do_linear* as _(optional) boolean_. Set to *true* to use linear
        % interpolation and to *false* to use polynom evaluation. Default
        % is *false*.
        %
        % The result is a matrix of the same size as *wind_speeds*,
        % containing energy amounts for each hour.
        function energyM = CalculateEnergy(obj, wind_speeds, varargin)
            ps = inputParser();
            ps.addRequired('wind_speeds', ...
                @(x)validateattributes(x,{'numeric'},{'positive'}));
            ps.addParamValue('do_linear',false, @islogical);
            ps.parse(wind_speeds, varargin{:});
            
            if ps.Results.do_linear
                energyM = interp1(obj.power_curve_interp(:,1), ...
                        obj.power_curve_interp(:,2), wind_speeds, 'linear');
            else
                % energy, wind_speeds_max and wind_speeds_poly = (0, 0, ..., 0)
                energyM = zeros(size(wind_speeds));
                wind_speeds_max = zeros(size(wind_speeds));
                wind_speeds_poly = zeros(size(wind_speeds));

                % wind speeds matrix is divided into three parts:
                %   wind_speeds_max, which is 1 if power output = p_max, i.e. 
                %       v_rated <= wind speed < v_out, else 0
                %   wind_speeds_poly, which equals wind speeds if power output 
                %       is on the curve part, i.e. v_in <= wind speed < v_rated, 
                %       else 0
                %   and the wind speeds where the power output is zero

                wind_speeds_max(wind_speeds >= obj.v_rated & wind_speeds < obj.v_out) = 1;

                wind_speeds_poly(wind_speeds >= obj.v_in & wind_speeds < obj.v_rated) = 1;
                wind_speeds_poly = wind_speeds.*wind_speeds_poly;

                % Calculate the power output with power curve (v_in <= v < v_rated)
                energyM(wind_speeds_poly ~=0) = polyval(obj.power_curve_poly, ...
                                        wind_speeds_poly(wind_speeds_poly ~= 0));

                % Add power output from wind at rated power
                energyM = energyM + obj.p_max * wind_speeds_max;
            end
        end
        
        %% CalculateEnergySum
        % Returns the summarized production for given wind speeds. Much 
        % faster to use this one than using CalculateEnergy and then
        % summarizing.
        % Parameter:
        %
        % # *wind_speeds* as _vector_, which contains the wind speeds
        % # *do_linear* as _(optional) boolean_. Set to *true* to use linear
        % interpolation and to *false* to use polynom evaluation. Default
        % is *false*.
        %
        function energyS = CalculateEnergySum(obj, wind_speeds, varargin)
%             ps = inputParser();
%             ps.addRequired('wind_speeds', @isvector);
%             ps.addParamValue('do_linear',false, @islogical);
%             ps.parse(wind_speeds, varargin{:});
% 
%             if ps.Results.do_linear
%                 energyS = sum (interp1 (obj.power_curve_interp(:,1), ...
%                         obj.power_curve_interp(:,2), wind_speeds, 'linear'));
%             else
                % wind_speeds_poly is a vector containing all wind speeds where
                % v_in <= v < v_rated, i.e. power output has to be calculated
                wind_speeds_poly = wind_speeds(wind_speeds >= obj.v_in & ...
                                               wind_speeds < obj.v_rated);

                % calculate power output from those wind speeds and summarize
                energyS = sum (polyval(obj.power_curve_poly, wind_speeds_poly));

                % count the hours with wind speeds v_rated <= v < v_out, and
                % add the produced energy from those hours
                energyS = energyS + obj.p_max * length( ...
                    wind_speeds(wind_speeds >= obj.v_rated & wind_speeds < obj.v_out));
%            end
        end
                                  
    end
end

        
    