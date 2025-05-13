classdef Router < matlab.mixin.Heterogeneous & handle
    %ROUTER Abstract class

    methods (Abstract)
      name = getName(obj)
      links = route(obj, network, connectedNodes)
    end
end

