classdef TechnicianSchedule < Schedule
    % Handles the scheduling of Technician events
    
    % Bertrand Kerres, kerres@kth.se, 2014-12-02    
    properties (SetAccess = private)
        eventlist;
    end
    
    methods
        function obj = TechnicianSchedule ()
            obj.eventlist = zeros (20, 4, 'uint32');
            % obj.eventlist(1,:) = [ms_intervall Constants.SCHEDULE_MAIN_SERVICE 1 0];
        end
        
        function Add (obj, event)
            emptyrow = find((obj.eventlist(:,1) == 0),1);
            if ~isempty (emptyrow)
                obj.eventlist(emptyrow,:) = event;
            else
                [el_length, ~] = size(obj.eventlist);
                obj.eventlist(el_length+1,:) = event;
            end
        end
        
        function Delete (obj, event)
            e_time = find((obj.eventlist(:,1) == event(1)));
            if length(e_time) == 1
                obj.eventlist(e_time,:) = [0 0 0 0];
            else
                for k = 1: length(e_time)
                    if obj.eventlist(e_time(k),:) == event
                        obj.eventlist(e_time(k),:) = [0 0 0 0];
                    end
                end
            end
        end
        
        function ev = NextEvent (obj)
            ev_list = obj.eventlist(obj.eventlist(:,1) ~= 0,:);
            [~, t_index] = min (ev_list(:,1));
            ev = ev_list(t_index,:);
        end
        
        function ClearTimeFrame (obj, from, to)
            step = to - from;
            obj.eventlist(obj.eventlist(:,1) >= from & obj.eventlist(:,1) <= to) = ...
                obj.eventlist(obj.eventlist(:,1) >= from & obj.eventlist(:,1) <= to) + step;
        end
        
    end
end