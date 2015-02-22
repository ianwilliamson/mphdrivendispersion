function output_meshgrid = MPH_Driven_Dispersion_Mesh_Grid( varargin )
% output = MPH_Driven_Dispersion_Mesh_Grid( model_filename, kx, ky, ki, fn )
% 

import com.comsol.model.*
import com.comsol.model.util.*
ModelUtil.showProgress(true);

inparser=inputParser;   
addRequired(inparser,'model_filename');
addRequired(inparser,'kx',@isnumeric);
addRequired(inparser,'ky',@isnumeric);
addRequired(inparser,'ki',@isnumeric);
addRequired(inparser,'fn',@isnumeric);
parse(inparser,varargin{:});
in=inparser.Results;

if ischar(in.model_filename)
    m       = mphload_enhanced(in.model_filename);
    [~,name_mph,~]=fileparts(in.model_filename);
else
    m=in.model_filename;
    name_mph='mph';
end

a       = mphglobal(m,{'a'},'Dataset','dset1','Outersolnum',1,'Solnum',1);
c_const = mphglobal(m,{'c_const'},'Dataset','dset1','Outersolnum',1,'Solnum',1);

m.study('std3').feature('param').set('pname', {'kxn' 'kyn' 'kin'});
m.study('std3').feature('param').set('plistarr', {num2str(in.kx) num2str(in.ky) num2str(in.ki)});
m.study('std3').feature('freq').set('plist', in.fn*c_const/a);
fprintf('# Running sweep... \n');

m.batch('p1').run;

fprintf('# Extracting results... \n');
block            = mphglobal(m,{'Eav_ratio'},'Dataset','dset2','Outersolnum','all','Solnum','all');
output_meshgrid.block_inv = block.^-1;

output_meshgrid.in=in;
output_meshgrid.a=a;
output_meshgrid.c_const=c_const;

end