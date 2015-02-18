function minimize_quantity = func_comsol_driver( varargin )
% MinimizationQuantity = func_comsol_driver( m, fn, kxn, kyn, kin )
% 

inparser=inputParser;   
addRequired(inparser,'m');
addRequired(inparser,'fn',@isnumeric);
addRequired(inparser,'kxn',@isnumeric);
addRequired(inparser,'kyn',@isnumeric);
addRequired(inparser,'kin',@isnumeric);
parse(inparser,varargin{:});
in=inparser.Results;

in.m.param.set('fn', in.fn);
in.m.param.set('kxn', in.kxn);
in.m.param.set('kyn', in.kyn);
in.m.param.set('kin', in.kin );

in.m.study('std3').run;

minimize_quantity = mphglobal(in.m,{'Eav_ratio'});
end