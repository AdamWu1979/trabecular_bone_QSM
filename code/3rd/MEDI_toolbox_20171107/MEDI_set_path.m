function  MEDI_set_path(  )
%MEDI_SET_PATH Summary of this function goes here
%   Detailed explanation goes here
[STR NAM EXT] = fileparts(mfilename('fullpath'));
addpath(fullfile(STR,'MEDI_GUI'),...
    fullfile(STR,'functions'),...
    fullfile(STR,'functions','_LBV'),...
    fullfile(STR,'functions','_spurs_gc'),...
    fullfile(STR,'functions','bet2'));
end
