% Technician with age-based inspection decision for gearbox
classdef Technician_GB_ABI < Technician
    methods
        function obj = Technician_GB_ABI (no_of_years)
            obj = obj@Technician (no_of_years);
        end
    end
    methods (Access = protected)
        function [new_time, turbine_state] = MainService (obj, turbine, t)
            turbine_state = turbine.online;
            
            turbine.off (t);
            t = obj.RegularMaintenance (turbine, t);
            
            % Inspect gearbox if it has reached a given age
            % change if it is defect and there is no change already scheduled
            comp = turbine.components{4};
            if comp.DoAgeInspection(t)
                [t, s] = obj.InspectComponent (comp, t);
                if s == Constants.WTCOMPONENT_STATE_DEFECT
                    if comp.lead_time == 0
                        [t, ~] = obj.ChangeComponent (comp, t);
                    else
                        if ~comp.change_scheduled
                            obj.t_schedule.Add ([t + comp.lead_time, ...
                                Constants.SCHEDULE_COMPONENT_CHANGE, ...
                                turbine.id, comp.id]);
                            comp.change_scheduled = true;
                        end
                    end
                end
            end
            
            obj.t_schedule.Add ([(t+turbine.main_service_interval), Constants.SCHEDULE_MAIN_SERVICE, turbine.id, 0]);

            if turbine_state
                turbine.on (t);
            end
            new_time = t;
        end
    end
end
            