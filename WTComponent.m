classdef WTComponent < handle
    % Abstract superclass for wind turbine components
    
    % Bertrand Kerres, kerres@kth.se, 2013-07-03    
    properties (Constant)
        FLTYPE_FIX = 0;
        FLTYPE_EXP = 1;
        FLTYPE_WBL = 2;
        
        STATE_GOOD = 2;
        STATE_DEFECT = 1;
        STATE_FAILURE = 0;
    end
    
    properties (GetAccess = public, SetAccess = public)
        name = 'GenericComponent';
        id = 0;
        change_scheduled = false;
        
        install_time = uint32(5);
        inspection_time = uint32(1);
        lead_time = uint32(100);
        replacement_age = uint32(0);
        
        new_cost = 100000;
        used_cost = 30000;
        change_equipment_cost = 500;
        
        last_inspection;
        
        turbine;
    end
    
    properties (GetAccess = public, SetAccess = protected)
        last_replacement = 0;
        state = uint8(Constants.WTCOMPONENT_STATE_GOOD);
    end
    
    properties (GetAccess = public, SetAccess = protected)
        failure_type;
        failure_params;
    end
    
    methods
        function val = DoAgeChange (obj, time)
            val = (obj.failure_type == Constants.WTCOMPONENT_FLTYPE_WBL && ...
                    (time - obj.last_replacement) >= obj.replacement_age);
        end
        
        function val = Age (obj, time)
            val = time - obj.last_replacement;
        end
        
        function Fail (obj, time)
            %disp([obj.name, ' failed at time ', num2str(time)])
            obj.state = Constants.WTCOMPONENT_STATE_FAILURE;
            obj.turbine.off (time);
        end
        
    end
    
    methods (Abstract)
        res = ProbGood (obj, time);
        res = ProbDefect (obj, time);
        res = ProbFail (obj, time);
        Renew (obj, time);
    end
        
    
end
    
    
    