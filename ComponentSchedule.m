classdef ComponentSchedule < Schedule
    % Checks the next event that happens to a component
    
    % Bertrand Kerres, kerres@kth.se, 2014-11-26
    properties (SetAccess = private)
        eventlist;
    end
    
    methods
        function obj = ComponentSchedule (no_listener)
            obj.eventlist = zeros (no_listener, 3, 'uint32');
        end
        
        function Add (obj, event)
            obj.eventlist(event(3),:) = event;
        end
        
        function Delete (obj, comp_id)
            obj.eventlist(comp_id,:) = [0 0 comp_id];
        end
        
        function ev = NextEvent (obj)
            ev_list = obj.eventlist(obj.eventlist(:,1) ~= 0,:);
            [~, t_index] = min (ev_list(:,1));
            ev = ev_list(t_index,:);
        end
        
        function ClearTimeFrame (obj, from, to)
            step = to - from;
            obj.eventlist(obj.eventlist(:,1) >= from & obj.eventlist(:,1) < to) = ...
                obj.eventlist(obj.eventlist(:,1) >= from & obj.eventlist(:,1) < to) + step;
        end
    end
end
