classdef WindFarm < handle
    % WindFarm Class to simulate a wind farm
    %   More convenient to use than an array of turbines
    
    % Bertrand Kerres, kerres@kth.se, 2014-12-04    
    
    properties (GetAccess = public, SetAccess = public)
        traveltime = 0;
        mean_wait_time = 0;
    end
    
    
    properties (GetAccess = public, SetAccess = private)
        turbines = {};
    end
    
    properties (Dependent = true)
        no_turbines;
        online;
        
        offline_hrs;
    end
    
    methods
        %% Set properties
        function set.traveltime (obj, val)
            ps = inputParser();
            ps.addRequired ('val', @(x) isnumeric (x) && isscalar(x) && x >= 0);
            ps.parse (val);
            
            obj.traveltime = val;
        end
        
        function set.mean_wait_time (obj, val)
            ps = inputParser();
            ps.addRequired ('val', @(x) isnumeric (x) && isscalar(x) && x >= 0);
            ps.parse (val);
            
            obj.mean_wait_time = val;
        end
        
        %% Get properties
        function val = get.no_turbines (obj)
            val = length(obj.turbines);
        end
        
        function val = get.online (obj)
            val = zeros (1, obj.no_turbines, 'uint8');
            for k=1:obj.no_turbines
                val(k) = obj.turbines{k}.online;
            end
        end
        
        function val = get.offline_hrs (obj)
            val = zeros (length(obj.turbines{1}.offline_hrs), obj.no_turbines, 'uint8');
            for k=1:obj.no_turbines
                val(:,k) = obj.turbines{k}.offline_hrs;
            end
        end
        
        %% Initialization functions
        function AddTurbine (obj, wt)
            ps = inputParser();
            ps.addRequired ('wt', @(x) isa (x, 'WT'));
            ps.parse (wt);
            
            obj.turbines{obj.no_turbines+1} = wt;
        end
        
        
        function Reset (obj)
            for k=1:obj.no_turbines
                obj.turbines{k}.Reset();
            end
        end
        
        %% Wind Farm Calculations
        
        function val = LostProduction (obj, wind)
            val = zeros (obj.turbines{1}.lifetime, obj.no_turbines);
            for k=1:obj.no_turbines
                val(:,k) = obj.turbines{k}.CalculateLostProduction (wind);
            end
        end        
        
        %% Event handling
        
        function [ev_source, event] = NextEvent (obj)
            event = zeros(1, 4, 'uint32');
            
            % Max time so that all real events are before this
            event(1) = intmax('uint32');    
            ev_source = 0;
            
            for k=1:obj.no_turbines
                if obj.turbines{k}.online
                    [s, ev] = obj.turbines{k}.NextEvent();
                    if ev(1) < event(1)
                        ev_source = s;
                        event = ev;
                    end
                end
            end
        end
        
        function DeleteEvent (obj, ev_source, event)
            obj.turbines{event(3)}.DeleteEvent (ev_source, event(4));
        end
            
               
            
    end
    
end

