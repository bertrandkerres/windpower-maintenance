classdef TechnicianTable < handle
    % Does the same as Technician, but stores information about past events
    
    % Bertrand Kerres, kerres@kth.se, 2014-12-02    
   properties (SetAccess = public);
        cost_per_workhour = 0;
        cost_per_drivinghour = 0;
    end
    
    properties (GetAccess = public, SetAccess = protected)
        t_schedule;

        actiontable;
        ac_i;
    end
    
    properties (Dependent, GetAccess = public)
        driving_bill;
        working_bill;
        material_bill;
        equipment_bill;

        total_bill;
    end
    
    methods (Access = protected)
        function [new_time, new_state] = ChangeComponent (obj, comp, t)
            new_time = t + comp.install_time;
            new_state = Constants.WTCOMPONENT_STATE_GOOD;
            comp.change_scheduled = false;
            comp.Renew (new_time);

            obj.actiontable(obj.ac_i,:) = [t, Constants.BA_CHANGE, new_time-t, comp.id, ...
                    comp.new_cost-comp.used_cost, comp.change_equipment_cost];
            obj.ac_i = obj.ac_i + 1;
        end
            
        function [new_time, state] = InspectComponent (obj, comp, t)
            new_time = t + comp.inspection_time;
            state = comp.state;

            obj.actiontable(obj.ac_i,:) = [t, Constants.BA_INSPECT, new_time-t, comp.id, 0, 0];
            obj.ac_i = obj.ac_i + 1;
        end
        
        function new_time = DriveToTurbine (obj, turbine, t)
            obj.actiontable(obj.ac_i,:) = [t, Constants.BA_DRIVE, turbine.drivetime, 0, 0, 0];
            obj.ac_i = obj.ac_i + 1;
            new_time = t + turbine.drivetime;
        end
        
        function [new_time, turbine_state] = MainService (obj, turbine, t)
            %disp (['Main Service at time ', num2str(t)])
            turbine_state = turbine.online;
            
            turbine.off (t);
            
            new_time = t + turbine.regular_maintenance_time;
            obj.actiontable(obj.ac_i,:) = [t, Constants.BA_REGMT, new_time-t, 0, ...
                turbine.regular_maintenance_material_cost, 0];
            obj.ac_i = obj.ac_i +1;
            
            obj.t_schedule.Add ([(new_time+turbine.main_service_intervall), Constants.SCHEDULE_MAIN_SERVICE, 0]);

            if turbine_state
                turbine.on (new_time);
            end
        end
    end
    methods
        function obj = TechnicianTable ()
%             ps = inputParser();
%             ps.addRequired ('timeframe', @(x) isscalar(x) && x > 0);
%             ps.parse (timeframe);
            
            obj.t_schedule = TechnicianSchedule (8760/2);
            obj.ac_i = 1;
            obj.actiontable = zeros (400,6);
        end
        
        function Reset (obj)
            obj.t_schedule = TechnicianSchedule (8760/2);
            obj.actiontable = zeros (400,6);
            obj.ac_i = 1;
        end
            
        function set.cost_per_workhour (obj, val)
            ps = inputParser();
            ps.addRequired ('val', @(x) isscalar(x) && x >= 0);
            ps.parse (val);
            
            obj.cost_per_workhour = val;
        end
        
        function set.cost_per_drivinghour (obj, val)
            ps = inputParser();
            ps.addRequired ('val', @(x) isscalar(x) && x >= 0);
            ps.parse (val);
            
            obj.cost_per_drivinghour = val;
        end
        
        function val = get.total_bill (obj)
            from_to = 8760* [0:1:19; 1:1:20];
            billtable = double (obj.actiontable(obj.actiontable(:,1)~=0, :));
            billtable(billtable(:,2)==Constants.BA_INSPECT,7) = ...
                2* obj.cost_per_workhour * billtable(billtable(:,2)==Constants.BA_INSPECT,3);
            billtable(billtable(:,2)==Constants.BA_CHANGE,7) = ...
                2* obj.cost_per_workhour * billtable(billtable(:,2)==Constants.BA_CHANGE,3);
            billtable(billtable(:,2)==Constants.BA_REGMT,7) = ...
                2* obj.cost_per_workhour * billtable(billtable(:,2)==Constants.BA_REGMT,3);
            billtable(billtable(:,2)==Constants.BA_DRIVE,7) = ...
                2* obj.cost_per_drivinghour * billtable(billtable(:,2)==Constants.BA_DRIVE,3);
            
            bill = zeros (20,3);
            for k = 1:20
                bill (k,:) = sum (billtable (billtable(:,1) > from_to(1,k) &...
                                            billtable(:,1) <= from_to(2,k), 5:7));
            end
            val = sum (bill,2);
        end
        
    end
    
    methods
        
        function t = RespondToComponentEvent (obj, turbine, event)
            comp = turbine.components{event(3)};
            t = event(1);
            
            t = obj.DriveToTurbine (turbine, t);
            
            [t, s] = obj.InspectComponent(comp, t);
            
            if s == Constants.WTCOMPONENT_STATE_FAILURE
                if comp.lead_time == 0
                    % Component is directly available
                    [t, ~] = obj.ChangeComponent (comp, t);
                    turbine.on (t);
                else
                    % Component has to be ordered
                    if ~comp.change_scheduled
                        obj.t_schedule.Add ([t + comp.lead_time, Constants.SCHEDULE_COMPONENT_CHANGE, comp.id]);
                        comp.change_scheduled = true;
                    end
                end
            end
            
            t = obj.DriveToTurbine (turbine, t);
        end
        
        function t = RespondToTechnicianEvent (obj, turbine, event)
            t = event(1);

            t = obj.DriveToTurbine (turbine, t);

            if event(2) == Constants.SCHEDULE_MAIN_SERVICE
                % Main Service
                [t, ~]= obj.MainService (turbine, t);
            elseif event(2) == Constants.SCHEDULE_COMPONENT_CHANGE
                turbine.off (t);
                [t, ~] = obj.ChangeComponent (turbine.components{event(3)}, t);
                turbine.on (t);
            end
                
            t = obj.DriveToTurbine (turbine, t);
        end
        
    end
end    