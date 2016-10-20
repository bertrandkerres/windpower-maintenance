classdef RunEnvironment < handle
    % Fetches next event and calls the respective function until the
    % simulation is finished
    
    % Bertrand Kerres, kerres@kth.se, 2014-12-02    
    properties (SetAccess = protected)
        serviceteam;
        windfarm;
        
        time;
        finish;
        
        initialized;
    end
    
    properties (Dependent, GetAccess = public)
        year;
    end
    
    methods
        function val = get.year (obj)
            val = idivide (obj.time, uint32(8760), 'ceil');
        end
        
        function obj = RunEnvironment (timeframe)
            ps = inputParser();
            ps.addRequired ('timeframe', @(x) isscalar(x) && x > 0);
            ps.parse (timeframe);
            
            obj.time = 1;
            obj.finish = timeframe * 8760;
            
            obj.initialized = false;
        end
        
        function SetWindFarm (obj, wf)
            ps = inputParser();
            ps.addRequired ('wf', @(x) isa (x, 'WindFarm'));
            ps.parse (wf);
            
            obj.windfarm = wf;
        end
       
        function SetServiceTeam (obj, st)
            ps = inputParser();
            ps.addRequired ('st', @(x) isa (x, 'TechnicianTable') || isa (x, 'Technician'));
            ps.parse (st);
            
            obj.serviceteam = st;
        end
        
        function Init (obj)
            obj.time = 1;
            obj.windfarm.Reset();
            obj.serviceteam.Reset();
            for k=1:obj.windfarm.no_turbines
                obj.serviceteam.ScheduleMainService (...
                    obj.windfarm.turbines{k}.main_service_interval + k*24, ...
                    obj.windfarm.turbines{k});
            end
            obj.initialized = true;
        end
        
        function [e_source, event] = NextEvent (obj)
            t_event = obj.serviceteam.t_schedule.NextEvent();
            if ~all(obj.windfarm.online)
                e_source = 0;
                obj.serviceteam.t_schedule.Delete (t_event);
                event = t_event;
            else
                [f_source, farm_event] = obj.windfarm.NextEvent();
                
                if t_event(1) <= farm_event(1)
                    e_source = 0; % Technician
                    obj.serviceteam.t_schedule.Delete (t_event);
                    event = t_event;
                else
                    e_source = f_source; % Component == 1, CMS == -1
                    obj.windfarm.DeleteEvent (f_source, farm_event);
                    event = farm_event;
                end

            end
        end
        
        function Run (obj)
            if ~obj.initialized
                disp ('RunEnvironment is not initialized. Call obj.Init() first!')
                return
            end
            [e_source, event] = obj.NextEvent();
            while event(1) <= obj.finish
                obj.time = event(1);
                
                if e_source == 0 % Technician
                    obj.serviceteam.RespondToTechnicianEvent (obj.windfarm, event);
                else
                    turb = event(3);
                    switch event(2)
                        case Constants.SCHEDULE_COMPONENT_DEFECT
                            obj.windfarm.turbines{turb}.components{event(4)}.Defect (event(1));
                        case Constants.SCHEDULE_COMPONENT_FAILURE
                            obj.windfarm.turbines{turb}.components{event(4)}.Fail (event(1));
                            obj.serviceteam.RespondToComponentEvent (obj.windfarm, event);
                        case Constants.SCHEDULE_CMS_ALERT
                            obj.serviceteam.RespondToComponentEvent (obj.windfarm, event);
                    end
                    
                end
            [e_source, event] = obj.NextEvent();
            end
            for k=1:obj.windfarm.no_turbines
                obj.windfarm.turbines{k}.on (obj.finish);
            end
            obj.initialized = false;
        end
    end
end
      
    