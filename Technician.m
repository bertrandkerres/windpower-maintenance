classdef Technician < handle
    % Technician that implements the baseline scenario
    % Create other scenarios by deriving a technician from this class
    
    % Bertrand Kerres, kerres@kth.se, 2014-12-04    
    %% Properties
    properties (SetAccess = public);
        cost_per_workhour = 0;
        cost_per_drivinghour = 0;
    end
    
    properties (GetAccess = public, SetAccess = protected)
        bills;
        
        t_schedule;
    end
    
    properties (Dependent, GetAccess = public)
        driving_bill;
        working_bill;
        material_bill;
        equipment_bill;

        total_bill;
    end
    
    properties (GetAccess = protected)
        year;
    end
    
    %% Protected Methods
    methods (Access = protected)
        
        function Bill (obj, type, amount)
            obj.bills(obj.year, type) = obj.bills(obj.year, type) + amount;
        end
        
        function BillTime (obj, type, hours)
            if type == Constants.TECHNICIAN_BILL_WORK
                amount = obj.cost_per_workhour * hours;
            elseif type == Constants.TECHNICIAN_BILL_DRIVE
                amount = obj.cost_per_drivinghour * hours;
            else
                amount = 0;
            end
            
            obj.bills(obj.year, type) = obj.bills(obj.year, type) + amount;
        end
                    
        function [new_time, new_state] = ChangeComponent (obj, comp, t)
            obj.Bill (Constants.TECHNICIAN_BILL_WORK, 2* comp.install_time* obj.cost_per_workhour);
            obj.Bill (Constants.TECHNICIAN_BILL_MATERIAL, comp.new_cost - comp.used_cost);
            obj.Bill (Constants.TECHNICIAN_BILL_EQUIPMENT, comp.change_equipment_cost);
            
            new_time = t + comp.install_time;
            new_state = Constants.WTCOMPONENT_STATE_GOOD;
            comp.change_scheduled = false;
            comp.Renew (new_time);
        end

        function [new_time, state] = InspectComponent (obj, comp, t)
            obj.Bill (Constants.TECHNICIAN_BILL_WORK, 2*comp.inspection_time* obj.cost_per_workhour);
            new_time = t + comp.inspection_time;
            state = comp.state;
            comp.last_inspection = t;
        end
        
        function new_time = RegularMaintenance (obj, turbine, t)
            new_time = t + turbine.regular_maintenance_time;
            obj.Bill (Constants.TECHNICIAN_BILL_WORK, 2*turbine.regular_maintenance_time* obj.cost_per_workhour);
            obj.Bill (Constants.TECHNICIAN_BILL_MATERIAL, turbine.regular_maintenance_material_cost);
        end
        
        function new_time = DriveToTurbine (obj, windfarm, t)
            obj.Bill (Constants.TECHNICIAN_BILL_DRIVE, 2*windfarm.traveltime* obj.cost_per_drivinghour);
            new_time = t + windfarm.traveltime;
        end
        
        function [new_time, turbine_state] = MainService (obj, turbine, t)
            %disp (['Main Service at time ', num2str(t)])
            turbine_state = turbine.online;
            
            turbine.off (t);
            
            t = obj.RegularMaintenance (turbine, t);
            
            obj.t_schedule.Add ([(t+turbine.main_service_interval), Constants.SCHEDULE_MAIN_SERVICE, turbine.id, 0]);

            if turbine_state
                turbine.on (t);
            end
            new_time = t;
        end
        
    end
    
    methods
        %% Set and Get
        function obj = Technician (timeframe)
            ps = inputParser();
            ps.addRequired ('timeframe', @(x) isscalar(x) && x > 0);
            ps.parse (timeframe);
            
            obj.t_schedule = TechnicianSchedule ();
            obj.bills = zeros (timeframe ,4);
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
        
        function val = get.working_bill (obj)
            val = obj.bills(:,Constants.TECHNICIAN_BILL_WORK);
        end
        
        function val = get.driving_bill (obj)
            val = obj.bills(:,Constants.TECHNICIAN_BILL_DRIVE);
        end
        
        function val = get.material_bill (obj)
            val = obj.bills(:,Constants.TECHNICIAN_BILL_MATERIAL);
        end
        
        function val = get.equipment_bill (obj)
            val = obj.bills(:,Constants.TECHNICIAN_BILL_EQUIPMENT);
        end
        
        function val = get.total_bill (obj)
            val = sum (obj.bills, 2);
        end
        
        %% Public Methods
        function Reset (obj)
            obj.bills = zeros (size(obj.bills));
            
            obj.t_schedule = TechnicianSchedule ();
        end            
        
        
        
        function RespondToComponentEvent (obj, windfarm, event)
            % event = [time type turbine_id component_id]
            t = event(1);
            turb = event(3);
            comp = windfarm.turbines{turb}.components{event(4)};
            
            obj.year = idivide (t, 8760, 'ceil');
            
            % Wait for available service team
            t = t + uint32 (windfarm.mean_wait_time);
            
            t = obj.DriveToTurbine (windfarm, t);
            
            [t, s] = obj.InspectComponent(comp, t);
            
            if s == Constants.WTCOMPONENT_STATE_FAILURE
                if comp.lead_time == 0
                    % Component is directly available
                    [t, ~] = obj.ChangeComponent (comp, t);
                    windfarm.turbines{turb}.on (t);
                else
                    % Component has to be ordered
                    if ~comp.change_scheduled
                        obj.t_schedule.Add ([t + comp.lead_time, ...
                            Constants.SCHEDULE_COMPONENT_CHANGE, windfarm.turbines{turb}.id, comp.id]);
                        comp.change_scheduled = true;
                    end
                end
            end
            
            obj.DriveToTurbine (windfarm, t);
        end
        
        
        function  RespondToTechnicianEvent (obj, windfarm, event)
            % event = [time type turbine_id component_id]
            t = event(1);
            turb = event(3);
            obj.year = idivide (t, 8760, 'ceil');
            
          
            if event(2) == Constants.SCHEDULE_MAIN_SERVICE
                % Main Service
                t = obj.DriveToTurbine (windfarm, t);
                [t, ~]= obj.MainService (windfarm.turbines{turb}, t);
                t = obj.DriveToTurbine (windfarm, t);
            elseif event(2) == Constants.SCHEDULE_COMPONENT_CHANGE
                t = obj.DriveToTurbine (windfarm, t);
                windfarm.turbines{turb}.off (t);
                [t, ~] = obj.ChangeComponent (windfarm.turbines{turb}.components{event(4)}, t);
                windfarm.turbines{turb}.on (t);
                obj.DriveToTurbine (windfarm, t);
            end
            
            obj.t_schedule.ClearTimeFrame (event(1), t);
        end
        
        function ScheduleMainService (obj, time, turbine)
            obj.t_schedule.Add ([time, Constants.SCHEDULE_MAIN_SERVICE, turbine.id, 0]);
        end
    end
end

            