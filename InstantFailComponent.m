classdef InstantFailComponent < WTComponent
    % Implements a component that detoriates according to a binary fail
    % model
    
    % Bertrand Kerres, kerres@kth.se, 2014-12-04    
    methods
        function obj = InstantFailComponent (name, failtype, fail_params)
            ps = inputParser();
            ps.addRequired ('name', @ischar);
            ps.addRequired ('failtype', @(x) any (strcmp (x, {'exp','wbl'})));
            ps.addRequired ('fail_params', @(x) isnumeric(x));
            ps.parse (name, failtype, fail_params);
            
            obj.name = name;
            
            switch failtype
                case 'exp'
                    obj.failure_type = Constants.WTCOMPONENT_FLTYPE_EXP;
                    obj.failure_params = fail_params(1);
                case 'wbl'
                    obj.failure_type = Constants.WTCOMPONENT_FLTYPE_WBL;
                    obj.failure_params = [fail_params(1) fail_params(2)];
                    obj.replacement_age = wblmean (fail_params(1), fail_params(2));
                otherwise
                    obj.failure_type = Constants.WTCOMPONENT_FLTYPE_FIX;
                    obj.failure_params = fail_params(1);
            end
        end
            
        
        function res = ProbGood (obj, ~)
            res = (obj.state == Constants.WTCOMPONENT_STATE_GOOD);
        end
        
        function res = ProbDefect (~, ~)
            res = 0;
        end
        
        function res = ProbFail (obj, ~)
            res = (obj.state == Constants.WTCOMPONENT_STATE_FAILURE);
        end
        
        function Renew (obj, time)
            %disp([obj.name, ' renewed at time ', num2str(time)])
            obj.last_replacement = time;
            obj.last_inspection = time;
            obj.state = Constants.WTCOMPONENT_STATE_GOOD;
            switch obj.failure_type
                case Constants.WTCOMPONENT_FLTYPE_EXP
                    fail_time = time + uint32 (exprnd (obj.failure_params(1)));
                case Constants.WTCOMPONENT_FLTYPE_WBL
                    fail_time = time + uint32 (wblrnd (obj.failure_params(1), ...
                        obj.failure_params(2) ));
                otherwise
                    fail_time = time + obj.failure_params(1);
            end
            
            obj.turbine.c_schedule.Add ([fail_time, Constants.SCHEDULE_COMPONENT_FAILURE, obj.id]);
        end
    end
end

            