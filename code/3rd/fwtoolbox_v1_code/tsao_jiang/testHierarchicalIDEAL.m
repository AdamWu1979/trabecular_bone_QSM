function outParams = testHierarchicalIDEAL();

% Add path 
[BASEPATH,tmpfile] = fileparts(mfilename('fullpath'));clear tmpfile;
tmp = BASEPATH; addpath(tmp); fprintf('Adding to path: %s\n',tmp); clear tmp;
tmp = fullfile(BASEPATH,'test'); addpath(tmp); fprintf('Adding to path: %s\n',tmp); clear tmp;

% Dialog box
str1 = 'Test with simulation';
str2 = 'Test with data';
str_about = 'About...';
while 1
  button=questdlg({'Testing hierarchical IDEAL...','Which test to run?'},'Hierarchical IDEAL',str_about,str1,str2,str2);

  if isequal(button,str1),
    outParams = testHierarchicalIDEALwithSynthetic();
    break;
  elseif isequal(button,str2),
    outParams = testHierarchicalIDEALwithData();
    break;
  elseif isequal(button,str_about),
    uiwait(msgbox({'Hierarchical IDEAL is an MRI method for fat-water separation',...
                 'by hierarchical decomposition and direct estimation of phase',...
                 'offsets.',...
                 ' ',...
                 'The method is partly described in:',...
                 ' ',...
                 '   Tsao J, Jiang Y. Hierarchical IDEAL: robust water-fat separation',...
                 '   at high field by multiresolution field map estimation. In: ',...
                 '   Proceedings of the 18th Annual Meeting of ISMRM, Toronto, ON, ',...
                 '   Canada, 2008. p 653'...
                 '   Jiang Y, Tsao J. Fast and Robust Separation of Multiple',...
                 '   Chemical Species from Arbitrary Echo Times  with Complete',...
                 '   Immunity to Phase Wrapping. In: Proceedings of the 20th ',...
                 '   Annual Meeting of ISMRM, Melbourne, Australia 2012'}, 'About...','modal'));
  else % Cancel
     break;
  end
end
clear str1 str2 str_about button;
  
if nargout<1, clear outParams; end