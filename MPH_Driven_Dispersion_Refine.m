function output_refine = MPH_Driven_Dispersion_Refine( varargin )
% output = MPH_Driven_Dispersion_Refine( model_filename, kx, ky, fn, Nbands, block_inv, [optional arguments] )
% 

import com.comsol.model.*
import com.comsol.model.util.*
ModelUtil.showProgress(true);

inparser=inputParser;   
addRequired(inparser,'model_filename');
addRequired(inparser,'kx',@isnumeric);
addRequired(inparser,'ky',@isnumeric);
addRequired(inparser,'fn',@isnumeric);
addRequired(inparser,'Nbands',@isnumeric);
addRequired(inparser,'block_inv',@isnumeric);
addParamValue(inparser,'MaxIter',50,@isnumeric);
addParamValue(inparser,'TolX',1e-3,@isnumeric);
addParamValue(inparser,'TolFun',1e-3,@isnumeric);
addParamValue(inparser,'FuncComsolDriver',@func_comsol_driver);
parse(inparser,varargin{:});
in=inparser.Results;

Nbands = in.Nbands;

if ischar(in.model_filename)
    m       = mphload_enhanced(in.model_filename);
    [~,name_mph,~]=fileparts(in.model_filename);
else
    m=in.model_filename;
    name_mph='mph';
end

PN=PushoverNotifier(name_mph);

a       = mphglobal(m,{'a'},'Dataset','dset1','Outersolnum',1,'Solnum',1);
c_const = mphglobal(m,{'c_const'},'Dataset','dset1','Outersolnum',1,'Solnum',1);

output_refine.fn_bands = NaN(Nbands,length(in.ky));
output_refine.ki_bands = NaN(Nbands,length(in.ky));
output_refine.fval     = NaN(Nbands,length(in.ky));
output_refine.exitflag = NaN(Nbands,length(in.ky));

fminsearchOptions = optimset(...
    'Display','off',...
    'MaxIter',in.MaxIter,...
    'TolX',   in.TolX,...
    'TolFun', in.TolFun );

for i=1:length(in.ky)
    [~,fi]=findpeaks( in.block_inv(:,i) );
    fprintf('( kx = %.3f; ky = %.3f ) --->\n', in.kx(i), in.ky(i));
    if length(fi) > Nbands
        output_refine.fn_bands=[ output_refine.fn_bands;  NaN(length(fi)-Nbands, length(in.ky)) ];
        output_refine.ki_bands=[ output_refine.ki_bands;  NaN(length(fi)-Nbands, length(in.ky)) ];
        output_refine.fval    =[ output_refine.fval;      NaN(length(fi)-Nbands, length(in.ky)) ];
        output_refine.exitflag=[ output_refine.exitflag;  NaN(length(fi)-Nbands, length(in.ky)) ];
        Nbands=length(fi);
    end
    
    for f=1:length(fi)
        tic_freq = tic();
        f0  = in.fn( fi(f) );
        ki0 = -sqrt( in.kx(i)^2+in.ky(i)^2 )/50;
        
        opt_func           = @(x) in.FuncComsolDriver( m, x(1), in.kx(i), in.ky(i), x(2) );
        [fn_ki__min, output_refine.fval(f,i), output_refine.exitflag(f,i)] = fminsearch(opt_func,[f0 ki0],fminsearchOptions);
        
        output_refine.fn_bands(f,i) = fn_ki__min(1);
        output_refine.ki_bands(f,i) = fn_ki__min(2);
        
        fprintf('   #%d ( f = %.6f; ki = %.6f; fval = %d; time = %d; flag = %d )\n', f, output_refine.fn_bands(f,i), output_refine.ki_bands(f,i), output_refine.fval(f,i), toc(tic_freq), output_refine.exitflag(f,i));
    end
end

output_refine.in=in;
output_refine.Nbands=Nbands;
output_refine.a=a;
output_refine.c_const=c_const;

fprintf('# Saving results... \n');
saveTime=clock();
save( ['./data/','REFINE_',name_mph,'_',sprintf( '%d-%d-%d_%d-%d',saveTime(1),saveTime(2),saveTime(3),saveTime(4),saveTime(5) ),'.mat'], 'output_refine' );

PN.TimedNotify();
end