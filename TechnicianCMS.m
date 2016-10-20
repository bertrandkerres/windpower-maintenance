classdef TechnicianCMS < Technician
    methods
        function obj = TechnicianCMS (no_of_years)
            obj = obj@Technician (no_of_years);
        end
    end
    methods
        function RespondToComponentEvent (obj, windfarm, event)
            % [time type turbine_id component_id] = event
            t = event(1);
            turbine = windfarm.turbines{event(3)};
            comp = turbine.components{event(4)};
            obj.year = idivide (t, 8760, 'ceil');

            % Wait for available service team
            t = t + uint32 (windfarm.mean_wait_time);
            
            t = obj.DriveToTurbine (windfarm, t);
            
            if event(2) == Constants.SCHEDULE_COMPONENT_FAILURE
                [t, ~] = obj.InspectComponent(comp, t);
                if comp.lead_time == 0
                    % Component is directly available
                    [t, ~] = obj.ChangeComponent (comp, t);
                    turbine.on (t);
                else
                    % Component has to be ordered
                    if ~comp.change_scheduled
                        obj.t_schedule.Add ([t + comp.lead_time, ...
                            Constants.SCHEDULE_COMPONENT_CHANGE, ...
                            turbine.id, comp.id]);
                        comp.change_scheduled = true;
                    end
                end
            elseif event(2) == Constants.SCHEDULE_CMS_ALERT
                    turbine.off (t);
                    [t, state] = obj.InspectComponent(comp, t);

                    if state == Constants.WTCOMPONENT_STATE_DEFECT
                        if comp.lead_time == 0
                            [t, ~] = obj.ChangeComponent (comp, t);
                        else
                            if ~comp.change_scheduled
                                obj.t_schedule.Add ([t + comp.lead_time, ...
                                    Constants.SCHEDULE_COMPONENT_CHANGE, ...
                                    turbine.id, comp.id]);
                                comp.change_scheduled = true;
                                % disp ([comp.name, ' change scheduled for time ', num2str(t+comp.lead_time)])
                            end
                        end
                    end
                    turbine.on (t);
            end
                
            obj.DriveToTurbine (windfarm, t);
        
        end
    end
end