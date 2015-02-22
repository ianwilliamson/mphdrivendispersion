function output_refine = MPH_Driven_Dispersion_Refine( varargin )
% output = MPH_Driven_Dispersion_Refine( model_filename, kx, ky, fn, Nbands, block_inv, [optional arguments] )
% 

import com.comsol.model.*
import com.comsol.model.util.*
ModelUtil.showProgress(false);

inparser=inputParser;   
addRequired(inparser,'model_filename');
addRequired(inparser,'kx',@isnumeric);
addRequired(inparser,'ky',@isnumeric);
addRequired(inparser,'fn',@isnumeric);
addRequired(inparser,'Nbands',@isnumeric);
addRequired(inparser,'block_inv',@isnumeric);
addParamValue(inparser,'MaxIter',50,@isnumeric);
addParamValue(inparser,'TolX',1e-5,@isnumeric);
addParamValue(inparser,'TolFun',1e-5,@isnumeric);
addParamValue(inparser,'FuncComsolDriver',@func_comsol_driver);
addParamValue(inparser,'SeparateFmin',0,@isnumeric);
addParamValue(inparser,'RecomputeMask',nan);
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

a       = mphglobal(m,{'a'},'Dataset','dset1','Outersolnum',1,'Solnum',1);
c_const = mphglobal(m,{'c_const'},'Dataset','dset1','Outersolnum',1,'Solnum',1);

output_refine.fn_bands  = NaN(Nbands,length(in.ky));
output_refine.ki_bands  = NaN(Nbands,length(in.ky));
output_refine.fval1     = NaN(Nbands,length(in.ky));
output_refine.exitflag1 = NaN(Nbands,length(in.ky));
output_refine.fval2     = NaN(Nbands,length(in.ky));
output_refine.exitflag2 = NaN(Nbands,length(in.ky));

fminsearchOptions = optimset(...
    'Display','off',...
    'MaxIter',in.MaxIter,...
    'TolX',   in.TolX,...
    'TolFun', in.TolFun );

if isnan( in.RecomputeMask )
    in.RecomputeMask = ones( 1,length(in.ky) );
end

for i=1:length(in.ky)
    if ~in.RecomputeMask(i)
        continue
    end
    
    [~,fi]=findpeaks( in.block_inv(:,i) );
    fprintf('%d/%d: ( kx = %.3f; ky = %.3f; |k| = %.3f ) \n', i, length(in.ky), in.kx(i), in.ky(i), sqrt(in.kx(i)^2+in.ky(i)^2 ) );
    if length(fi) > Nbands
        output_refine.fn_bands=[ output_refine.fn_bands;  NaN(length(fi)-Nbands, length(in.ky)) ];
        output_refine.ki_bands=[ output_refine.ki_bands;  NaN(length(fi)-Nbands, length(in.ky)) ];
        output_refine.fval1    =[ output_refine.fval1;      NaN(length(fi)-Nbands, length(in.ky)) ];
        output_refine.exitflag1=[ output_refine.exitflag1;  NaN(length(fi)-Nbands, length(in.ky)) ];
        output_refine.fval2    =[ output_refine.fval2;      NaN(length(fi)-Nbands, length(in.ky)) ];
        output_refine.exitflag2=[ output_refine.exitflag2;  NaN(length(fi)-Nbands, length(in.ky)) ];
        Nbands=length(fi);
    end
    
    for f=1:length(fi)
        tic_freq = tic();
        f0  = in.fn( fi(f) );
        ki0 = -sqrt( in.kx(i)^2+in.ky(i)^2 )/50;
        if in.SeparateFmin
            opt_func           = @(x) in.FuncComsolDriver( m, x(1), in.kx(i), in.ky(i), 0 );
            [fn_min, output_refine.fval1(f,i), output_refine.exitflag1(f,i)] = fminsearch(opt_func,f0,fminsearchOptions);
            output_refine.fn_bands(f,i) = fn_min;
            opt_func           = @(x) in.FuncComsolDriver( m, fn_min, in.kx(i), in.ky(i), x(1) );
            [ki_min, output_refine.fval2(f,i), output_refine.exitflag2(f,i)] = fminsearch(opt_func,ki0,fminsearchOptions);
            output_refine.ki_bands(f,i) = ki_min;
            fprintf('   #%d ( f = %.6f; ki = %.6f; kr/ki = %.2f; fval = %d/%d; time = %d; flag = %d/%d )\n', f, output_refine.fn_bands(f,i), output_refine.ki_bands(f,i), -sqrt( in.kx(i)^2+in.ky(i)^2 )/output_refine.ki_bands(f,i), output_refine.fval1(f,i), output_refine.fval2(f,i), toc(tic_freq), output_refine.exitflag1(f,i), output_refine.exitflag2(f,i));

        else
            opt_func           = @(x) in.FuncComsolDriver( m, x(1), in.kx(i), in.ky(i), x(2) );
            [fn_ki__min, output_refine.fval1(f,i), output_refine.exitflag1(f,i)] = fminsearch(opt_func,[f0 ki0],fminsearchOptions);
            
            output_refine.fn_bands(f,i) = fn_ki__min(1);
            output_refine.ki_bands(f,i) = fn_ki__min(2);
            
            fprintf('   #%d ( f = %.6f; ki = %.6f; kr/ki = %.2f; fval = %d/%d; time = %d; flag = %d/%d )\n', f, output_refine.fn_bands(f,i), output_refine.ki_bands(f,i), -sqrt( in.kx(i)^2+in.ky(i)^2 )/output_refine.ki_bands(f,i), output_refine.fval1(f,i), toc(tic_freq), output_refine.exitflag1(f,i));
        end
    end

output_refine.in=in;
output_refine.Nbands=Nbands;
output_refine.a=a;
output_refine.c_const=c_const;
end