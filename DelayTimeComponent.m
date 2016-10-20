classdef DelayTimeComponent < WTComponent
    % Implements a component that detoriates acc. to the delay-time model
    
    % Bertrand Kerres, kerres@kth.se, 2014-12-04
    properties (GetAccess = public, SetAccess = public)
        inspection_age;
        inspection_interval;
    end
    
    properties (SetAccess = protected, GetAccess = public)
        defect_type;
        defect_params;
	    failure_time;
        
        has_cms;
        cm_system;
    end
    
    methods
        function AddCMS (obj, cmsystem)
            ps = inputParser();
            ps.addRequired ('cmsystem', @(x) isa(x, 'CMS'));
            ps.parse (cmsystem);
            
            cmsystem.SetComponent (obj);
            obj.cm_system = cmsystem;
            obj.has_cms = true;
        end
        
        function RemoveCMS (obj)
            obj.cm_system = [];
            obj.has_cms = false;
        end
            
        function obj = DelayTimeComponent (name, defecttype, defect_params, failtype, fail_params)
            ps = inputParser();
            ps.addRequired ('name', @ischar);
            ps.addRequired ('defecttype', @ischar);
            ps.addRequired ('defect_params', @(x) isnumeric(x));
            ps.addRequired ('failtype', @ischar);
            ps.addRequired ('fail_params', @(x) isnumeric(x));
            ps.parse (name, defecttype, defect_params, failtype, fail_params);
            
            obj.name = name;
            obj.has_cms = false;
            obj.inspection_interval = 0;
            
            switch defecttype
                case 'exp'
                    obj.defect_type = Constants.WTCOMPONENT_FLTYPE_EXP;
                    obj.defect_params = defect_params(1);
                case 'wbl'
                    obj.defect_type = Constants.WTCOMPONENT_FLTYPE_WBL;
                    obj.defect_params = [defect_params(1) defect_params(2)];
                    obj.inspection_age = wblmean (defect_params(1), defect_params(2));
                otherwise
                    obj.defect_type = Constants.WTCOMPONENT_FLTYPE_FIX;
                    obj.defect_params = defect_params(1);
            end
            
            
            switch failtype
                case 'exp'
                    obj.failure_type = Constants.WTCOMPONENT_FLTYPE_EXP;
                    obj.failure_params = fail_params(1);
                case 'wbl'
                    obj.failure_type = Constants.WTCOMPONENT_FLTYPE_WBL;
                    obj.failure_params = [fail_params(1) fail_params(2)];
                otherwise
                    obj.failure_type = Constants.WTCOMPONENT_FLTYPE_FIX;
                    obj.failure_params = fail_params(1);
            end
        end
    end
    
    methods
        
        function setDefectAlpha (obj, alpha)
	    obj.defect_params(1) = alpha;
	end	    
	
	function val = DoAgeInspection (obj, time)
            val = ( ~isempty (obj.inspection_age) && ...
                    obj.Age(time) >= obj.inspection_age);
        end
        
        function val = DoIntervalInspection (obj, time)
            val = ((obj.Age(time) - obj.last_inspection) > obj.inspection_interval);
        end
        
        function Defect (obj, time)
            % disp([obj.name, ' defect at time ', num2str(time)])
            obj.state = Constants.WTCOMPONENT_STATE_DEFECT;
            
            if obj.has_cms
                obj.cm_system.Defect (time, obj.failure_time);
            end
            obj.turbine.c_schedule.Add([obj.failure_time, Constants.SCHEDULE_COMPONENT_FAILURE, obj.id]);
        end
        
        function Renew (obj, time)
            % disp([obj.name, ' renewed at time ', num2str(time)])
            obj.last_replacement = time;
            obj.last_inspection = time;
            obj.state = Constants.WTCOMPONENT_STATE_GOOD;
            switch obj.defect_type 
                case Constants.WTCOMPONENT_FLTYPE_EXP
                    obj.failure_time = time + uint32 (exprnd (obj.defect_params(1)));
                case Constants.WTCOMPONENT_FLTYPE_WBL
                    obj.failure_time = time + uint32 (wblrnd (obj.defect_params(1), ...
                        obj.defect_params(2) ));
                otherwise
                    obj.failure_time = time + obj.defect_params(1);
            end
	    
            % make sure that defect_time >= time
            defect_time = time - 1;
            while (defect_time < time)
                switch obj.failure_type
                case Constants.WTCOMPONENT_FLTYPE_EXP
                    defect_time = obj.failure_time - uint32 (exprnd (obj.failure_params(1)));
                case Constants.WTCOMPONENT_FLTYPE_WBL
                    defect_time = obj.failure_time - uint32 (wblrnd (obj.failure_params(1), ...
                    obj.failure_params(2) ));
                otherwise
                    defect_time  = obj.failure_time -  obj.failure_params(1);
                end
            end
            
            if obj.has_cms
                obj.cm_system.DeleteAlert ();
            end
            obj.turbine.c_schedule.Add ([defect_time, Constants.SCHEDULE_COMPONENT_DEFECT, obj.id]);
        end
        
        function Fail (obj, time)
            % disp([obj.name, ' failed at time ', num2str(time)])
            Fail@WTComponent (obj, time);
            if obj.has_cms
                obj.cm_system.DeleteAlert ();
            end
        end
        
    end
    methods
        function res = ProbGood (obj, time)
            % MUSS NOCH KORRIGIERT WERDEN: BED WAHRSCHEINLICHKEIT, DA
            % BEKANNT IST DASS STATE ~= FAIL
            switch obj.defect_type
                case Constants.WTCOMPONENT_FLTYPE_EXP
                    res = 1 - expcdf (time, obj.defect_params(1));
                case Constants.WTCOMPONENT_FLTYPE_WBL
                    res = 1 - wblpdf (time, obj.defect_params(1), obj.defect_params(2));
                otherwise
                    res = (obj.state == Constants.WTCOMPONENT_STATE_DEFECT);
            end
        end
        
        function res = ProbDefect (~, ~)
            res = 0;
        end
        
        function res = ProbFail (obj, ~)
            res = (obj.state == Constants.WTCOMPONENT_STATE_FAILURE);
        end
    end
end

            
