classdef Schedule < handle
    properties (Constant)
        MAIN_SERVICE = 1;
        COMPONENT_DEFECT = 2;
        COMPONENT_FAILURE = 3;
        COMPONENT_CHANGE = 4;
        CMS_ALERT = 5;
    end
    methods (Abstract)
        res = Add (obj, event);
        res = Delete (obj, event);
        ClearTimeFrame (obj, from, to);
        res = NextEvent (obj);
    end
end