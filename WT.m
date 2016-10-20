classdef WT < handle
    % Implements a wind turbine
    
    % Bertrand Kerres, kerres@kth.se, 2014-12-04    
    properties (GetAccess = public, SetAccess = protected)
        model;
        id;
        comp_types;

        lifetime;
                
        offline_hrs;
        last_off;
        online;
    end
    properties (GetAccess = public, SetAccess = public)
        main_service_interval;
        regular_maintenance_time;
        regular_maintenance_material_cost;
        
        power_curve;

        components;
        
        c_schedule;
        cms_schedule;
    end
    
    properties (Dependent)
        gearbox;
        generator;
    end
        
    methods
        function obj = WT (model, lifetime, id)
            ps = inputParser();
            ps.addRequired ('model', @(x) ischar(x)); 
            ps.addRequired ('lifetime', @(x) isscalar(x) && x > 0);
            ps.addRequired ('id', @(x) isscalar(x) && x > 0);
            ps.parse (model, lifetime, id);
            
            obj.model = model;
            obj.lifetime = lifetime;
            obj.id = id;
            
            obj.components = {};
            obj.comp_types = {};
            
            obj.offline_hrs = zeros (8760*lifetime, 1, 'uint8');
            obj.last_off = uint32(0);
            obj.online = true;
        end
        
        function val = get.gearbox (obj)
            for k=1:length(obj.comp_types)
                if strcmp('gearbox', obj.comp_types{k})
                    val = obj.components{k};
                    break
                end
            end
        end
        
        function val = get.generator (obj)
            for k=1:length(obj.comp_types)
                if strcmp('generator', obj.comp_types{k})
                    val = obj.components{k};
                    break
                end
            end
        end        
        
        function val = get.offline_hrs (obj)
            if length(obj.offline_hrs) > obj.lifetime*8760
                val = obj.offline_hrs(1:obj.lifetime*8760);
            else
                val = obj.offline_hrs;
            end
        end
        
        function set.main_service_interval (obj, interval)
            ps = inputParser();
            ps.addRequired ('intervall', @(x) isscalar(x) && x > 0);
            ps.parse (interval);
            
            obj.main_service_interval = interval;
        end
        
        function set.regular_maintenance_time (obj, t)
            ps = inputParser();
            ps.addRequired ('t', @(x) isscalar(x) && x > 0);
            ps.parse (t);
            
            obj.regular_maintenance_time = t;
        end
        
        function set.power_curve (obj, pc)
            ps = inputParser();
            ps.addRequired ('pc', @(x) isa(x, 'PowerCurve'));
            ps.parse (pc);
            
            obj.power_curve = pc;
        end
        
        function Reset (obj)
            obj.offline_hrs = zeros (8760*obj.lifetime, 1, 'uint8');
            obj.last_off = uint32(0);
            obj.online = true;
            obj.c_schedule = ComponentSchedule (length (obj.components));
            obj.cms_schedule = ComponentSchedule (length (obj.components));
            for k = 1: length (obj.components)
                obj.components{k}.Renew (1);
                obj.components{k}.change_scheduled = false;
            end
        end
        
        function off (obj, time)
            if obj.online && time > obj.last_off
                %disp (['Turbine off at time ', num2str(time)])
                obj.last_off = time;
                obj.online = false;
            end
        end
        
        function on (obj, time)
            if obj.online == false && time > obj.last_off
                obj.offline_hrs(obj.last_off:time-1) = ones(time-obj.last_off, 1, 'uint8'); 
                obj.online = true;
                obj.c_schedule.ClearTimeFrame (obj.last_off, time-1);
                %disp (['Turbine on at time ', num2str(time), '; last off was at ', num2str(obj.last_off)])
            end
        end
        
        function AddComponent (obj, c, name)
            ps = inputParser();
            ps.addRequired ('c', @(x) isa (x, 'WTComponent'));
            ps.addRequired ('name', @(x) ischar(x));
            ps.parse (c, name);
            
            if isa (c.turbine, 'WT')
                disp ('Component is already part of a turbine')
                return;
            end
            c.turbine = obj;
            c.id = length(obj.components) + 1;
            obj.components{c.id} = c;
            obj.comp_types{c.id} = name;
        end
        
        function [source, event] = NextEvent (obj)
            ev_com = obj.c_schedule.NextEvent();
            ev_cms = obj.cms_schedule.NextEvent();
            if isempty (ev_cms) || ev_com(1) <= ev_cms(1)
                event = [ev_com(1) ev_com(2) obj.id ev_com(3)];
                source = Constants.WTEVENTSOURCE_COMPONENT;
            else
                event = [ev_cms(1) ev_cms(2) obj.id ev_cms(3)];
                source = Constants.WTEVENTSOURCE_CMS;
            end
        end
        
        function DeleteEvent (obj, source, event)
            if source == Constants.WTEVENTSOURCE_COMPONENT
                obj.c_schedule.Delete (event);
            elseif source == Constants.WTEVENTSOURCE_CMS
                obj.cms_schedule.Delete (event);
            else
                error ('Trying to delete invalid event');
            end
        end

        
        function energy = CalculateEnergy (obj, wind)
            ps = inputParser();
            ps.addRequired ('wind', @(x) isvector(x) && length(x) <= length(obj.offline_hrs));
            ps.parse (wind);
            
            online_hrs = not (obj.offline_hrs(1:length(wind)));
            wind = wind .* double(online_hrs);
            
            no_of_years = length(wind) / 8760;
            
            energy = zeros(no_of_years,1);
            
            for k = 0: no_of_years-1
                energy(k+1) = obj.power_curve.CalculateEnergySum (wind(k*8760+1:(k+1)*8760));
            end
        end
        
        function energy = CalculateLostProduction (obj, wind)
            ps = inputParser();
            ps.addRequired ('wind', @(x) isvector(x) && length(x) <= length(obj.offline_hrs));
            ps.parse (wind);
            
            wind = wind .* double(obj.offline_hrs(1:length(wind)));
            
            no_of_years = length(wind) / 8760;
            
            energy = zeros(no_of_years,1);
            
            for k = 0: no_of_years-1
                energy(k+1) = obj.power_curve.CalculateEnergySum (wind(k*8760+1:(k+1)*8760));
            end
        end

            
    end
end
        