function stop = fminsearch_bands_outfun(x, optimValues, state)
fprintf( '#%d fval = %d ( x(1) = %.9f;',optimValues.iteration,optimValues.fval,x(1) );
if length(x) > 1
    fprintf( ' x(2) = %.9f )\n',x(2) );
else
    fprintf( ' )\n' );
end
stop = false;
end