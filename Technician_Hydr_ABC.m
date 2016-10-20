% Technician with age-based change decision for Hydraulic valve
classdef Technician_Hydr_ABC < Technician
    methods
        function obj = Technician_Hydr_ABC (no_of_years)
            obj = obj@Technician (no_of_years);
        end
    end
    methods (Access = protected)
        function [new_time turbine_state] = MainService (obj, turbine, t)
            turbine_state = turbine.online;
            
            turbine.off (t);
            t = obj.RegularMaintenance (turbine, t);
            
            % Change hydraulic if components age > mean failure time
            comp = turbine.components{5};
            if comp.DoAgeChange (t)
                    if comp.lead_time == 0
                        [t, ~] = obj.ChangeComponent (comp, t);
                    else
                        if ~comp.change_scheduled
                            obj.t_schedule.Add ([t + comp.lead_time, ...
                                Constants.SCHEDULE_COMPONENT_CHANGE, comp.id]);
                            comp.change_scheduled = true;
                        end
                    end
            end
            
            obj.t_schedule.Add ([(t+turbine.main_service_intervall), Constants.SCHEDULE_MAIN_SERVICE, 0]);

            if turbine_state
                turbine.on (t);
            end
            new_time = t;
        end
    end
end
            