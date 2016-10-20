classdef CMS < handle
    % Implements a condition monitoring system
    
    % Bertrand Kerres, kerres@kth.se, 2014-12-04
    properties (SetAccess = private)
        name;
        type;

        alert_event;
    end
    
    properties
        probability = 0.8;
        fixed_time = 50;
        price = 0;
        
        component;
    end
    
    methods        
        function obj = CMS (name, type)
            ps = inputParser();
            ps.addRequired ('name', @ischar);
            ps.addRequired ('type', @(x) any( strcmp(x, {'constant', 'exp'})));
            ps.parse (name, type);
            
            obj.name = name;
            
            switch type
                case 'exp'
                    obj.type = Constants.WTCOMPONENT_FLTYPE_EXP;
                case 'constant'
                    obj.type = Constants.WTCOMPONENT_FLTYPE_FIX;
            end
        end
        
        function set.probability (obj, val)
            ps = inputParser();
            ps.addRequired ('val', @(x) isscalar(x) & x >= 0 & x <= 1);
            ps.parse (val);
            
            obj.probability = val;
        end
        
        function set.price (obj, val)
            ps = inputParser();
            ps.addRequired ('val', @(x) isscalar(x) & x >= 0);
            ps.parse (val);
            
            obj.price = val;
        end

        function set.fixed_time (obj, val)
            ps = inputParser();
            ps.addRequired ('val', @(x) isscalar(x) & x >= 0);
            ps.parse (val);
            
            obj.fixed_time = uint32(val);
        end
        

    end
    
    methods
        function SetComponent (obj, c)
            ps = inputParser();
            ps.addRequired ('c', @(x) isa (x, 'DelayTimeComponent'));
            ps.parse (c);
            
            obj.component = c;
            obj.alert_event = [uint32(0) uint32(0) uint32(c.id)]; 
        end
        
        function Defect (obj, time, fail_time)
            alert_time = uint32(0);
            if obj.type == Constants.WTCOMPONENT_FLTYPE_EXP
                alert_mu = - (double (fail_time) - double (time)) / log (1-obj.probability);
                alert_time = uint32 (time + exprnd (alert_mu));
            elseif obj.type == Constants.WTCOMPONENT_FLTYPE_FIX
                if binornd (1, p) == 1
                    alert_time = uint32 (fail_time-obj.fixed_time);
                else
                    alert_time = uint32 (fail_time + 200000);
                end
            end
                    
            obj.alert_event = [alert_time Constants.SCHEDULE_CMS_ALERT obj.component.id];
            obj.component.turbine.cms_schedule.Add (obj.alert_event);
        end
        
        function DeleteAlert (obj)
            obj.component.turbine.cms_schedule.Delete (obj.alert_event(3));
        end
    end
end
