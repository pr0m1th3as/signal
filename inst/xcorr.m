## Copyright (C) 1999-2001 Paul Kienzle
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; If not, see <http://www.gnu.org/licenses/>.

## usage: [R, lag] = xcorr (X [, Y] [, maxlag] [, scale])
##
## Compute correlation R_xy of X and Y for various lags k:  
##
##    R_xy(k) = sum_{i=1}^{N-k}{x_i y_{i-k}}/(N-k),  for k >= 0
##    R_xy(k) = R_yx(-k),  for k <= 0
##
## Returns R(k+maxlag+1)=Rxy(k) for lag k=[-maxlag:maxlag].
## Scale is one of:
##    'biased'   for correlation=raw/N, 
##    'unbiased' for correlation=raw/(N-|lag|), 
##    'coeff'    for correlation=raw/(rms(x).rms(y)),
##    'none'     for correlation=raw
##
## If Y is omitted, compute autocorrelation.  
## If maxlag is omitted, use N-1 where N=max(length(X),length(Y)).
## If scale is omitted, use 'none'.
##
## If X is a matrix, computes the cross correlation of each column
## against every other column for every lag.  The resulting matrix has
## 2*maxlag+1 rows and P^2 columns where P is columns(X). That is,
##    R(k+maxlag+1,P*(i-1)+j) == Rij(k) for lag k=[-maxlag:maxlag],
## so
##    R(:,P*(i-1)+j) == xcorr(X(:,i),X(:,j))
## and
##    reshape(R(k,:),P,P) is the cross-correlation matrix for X(k,:).
##
## xcorr computes the cross correlation using an FFT, so the cost is
## dependent on the length N of the vectors and independent of the
## number of lags k that you need.  If you only need lags 0:k-1 for 
## vectors x and y, then the direct sum may be faster:
##
## Ref: Stearns, SD and David, RA (1988). Signal Processing Algorithms.
##      New Jersey: Prentice-Hall.

## unbiased:
##  ( hankel(x(1:k),[x(k:N); zeros(k-1,1)]) * y ) ./ [N:-1:N-k+1](:)
## biased:
##  ( hankel(x(1:k),[x(k:N); zeros(k-1,1)]) * y ) ./ N
##
## If length(x) == length(y) + k, then you can use the simpler
##    ( hankel(x(1:k),x(k:N-k)) * y ) ./ N
##

## 2008-11-12  Peter Lanspeary, <pvl@mecheng.adelaide.edu.au>
##       1) fix incorrectly shifted return value (when X and Y vectors have
##          unequal length) - bug reported by <stephane.brunner@gmail.com>.
##       2) scale='coeff' should give R=raw/(rms(x).rms(y)); fixed.
##       3) restore use of autocorrelation code when isempty(Y).
##       4) imaginary part of cross correlation had wrong sign; fixed.
##       5) use R.' rather than R' to correct the shape of the result
## 2004-05 asbjorn dot sabo at broadpark dot no
##     - Changed definition of cross correlation from 
##       sum{x(i)y(y+k)} to sum(x(i)y(i-k)}  (Note sign change.)
##       Results are now returned in reverse order of before.
##       The function is now compatible with Matlab (and with f.i.
##       "Digital Signal Processing" by Proakis and Manolakis).
## 2000-03 pkienzle@kienzle.powernet.co.uk
##     - use fft instead of brute force to compute correlations
##     - allow row or column vectors as input, returning same
##     - compute cross-correlations on columns of matrix X
##     - compute complex correlations consitently with matlab
## 2000-04 pkienzle@kienzle.powernet.co.uk
##     - fix test for real return value
## 2001-02-24 Paul Kienzle
##     - remove all but one loop
## 2001-10-30 Paul Kienzle <pkienzle@users.sf.net>
##     - fix arg parsing for 3 args
## 2001-12-05 Paul Kienzle <pkienzle@users.sf.net>
##     - return lags as vector rather than range

function [R, lags] = xcorr (X, Y, maxlag, scale)
  
  if (nargin < 1 || nargin > 4)
    usage ("[c, lags] = xcorr(x [, y] [, h] [, scale])");
  endif

  ## assign arguments from list
  if nargin==1
    Y=[]; maxlag=[]; scale=[];
  elseif nargin==2
    maxlag=[]; scale=[];
    if ischar(Y), scale=Y; Y=[];
    elseif isscalar(Y), maxlag=Y; Y=[];
    endif
  elseif nargin==3
    scale=[];
    if ischar(maxlag), scale=maxlag; maxlag=[]; endif
    if isscalar(Y), maxlag=Y; Y=[]; endif
  endif

  ## assign defaults to arguments which were not passed in
  if isvector(X) 
    ## if isempty(Y), Y=X; endif  ## this line disables code for autocorr'n
    N = max(length(X),length(Y));
  else
    N = rows(X);
  endif
  if isempty(maxlag), maxlag=N-1; endif
  if isempty(scale), scale='none'; endif

  ## check argument values
  if isscalar(X) || ischar(X) || isempty(X)
    error("xcorr: X must be a vector or matrix"); 
  endif
  if isscalar(Y) || ischar(Y) || (!isempty(Y) && !isvector(Y))
    error("xcorr: Y must be a vector");
  endif
  if !isvector(X) && !isempty(Y)
    error("xcorr: X must be a vector if Y is specified");
  endif
  if !isscalar(maxlag) && !isempty(maxlag) 
    error("xcorr: maxlag must be a scalar"); 
  endif
  if maxlag>N-1, 
    error("xcorr: maxlag must be less than length(X)"); 
  endif
  if isvector(X) && isvector(Y) && length(X) != length(Y) && \
	!strcmp(scale,'none')
    error("xcorr: scale must be 'none' if length(X) != length(Y)")
  endif
    
  P = columns(X);
  M = 2^nextpow2(N + maxlag);
  if !isvector(X) 
    ## For matrix X, compute cross-correlation of all columns
    R = zeros(2*maxlag+1,P^2);

    ## Precompute the padded and transformed `X' vectors
    pre = fft (postpad (prepad (X, N+maxlag), M) ); 
    post = conj (fft (postpad (X, M)));

    ## For diagonal (i==j)
    cor = ifft (post .* pre);
    R(:, 1:P+1:P^2) = cor (1:2*maxlag+1,:);

    ## For remaining i,j generate xcorr(i,j) and by symmetry xcorr(j,i).
    for i=1:P-1
      j = i+1:P;
      cor = ifft( pre(:,i*ones(length(j),1)) .* post(:,j) );
      R(:,(i-1)*P+j) = cor(1:2*maxlag+1,:);
      R(:,(j-1)*P+i) = conj( flipud( cor(1:2*maxlag+1,:) ) );
    endfor
  elseif isempty(Y)
    ## compute autocorrelation of a single vector
    post = fft( postpad(X(:),M) );
    cor = ifft( post .* conj(post) );
    R = [ conj(cor(maxlag+1:-1:2)) ; cor(1:maxlag+1) ];
  else 
    ## compute cross-correlation of X and Y
    ##  If one of X & Y is a row vector, the other can be a column vector.
    pre  = fft( postpad( prepad( X(:), length(X)+maxlag ), M) );
    post = fft( postpad( Y(:), M ) );
    cor = ifft( pre .* conj(post) );
    R = cor(1:2*maxlag+1);
  endif

  ## if inputs are real, outputs should be real, so ignore the
  ## insignificant complex portion left over from the FFT
  if isreal(X) && (isempty(Y) || isreal(Y))
    R=real(R); 
  endif

  ## correct for bias
  if strcmp(scale, 'biased')
    R = R ./ N;
  elseif strcmp(scale, 'unbiased')
    R = R ./ ( [ N-maxlag:N-1, N, N-1:-1:N-maxlag ]' * ones(1,columns(R)) );
  elseif strcmp(scale, 'coeff')
    ## R = R ./ R(maxlag+1) works only for autocorrelation
    ## For cross correlation coeff, divide by rms(X)*rms(Y).
    if !isvector(X)
      ## for matrix (more than 1 column) X
      rms = sqrt( sumsq(X) );
      R = R ./ ( ones(rows(R),1) * reshape(rms.'*rms,1,[]) );
    elseif isempty(Y)
      ##  for autocorrelation, R(zero-lag) is the mean square.
      R = R / R(maxlag+1);
    else
      ##  for vectors X and Y
      R = R / sqrt( sumsq(X)*sumsq(Y) );
    endif
  elseif !strcmp(scale, 'none')
    error("xcorr: scale must be 'biased', 'unbiased', 'coeff' or 'none'");
  endif
    
  ## correct the shape so that it is the same as the first input vector
  if isvector(X) && P > 1
    R = R.'; 
  endif
  
  ## return the lag indices if desired
  if nargout == 2
    lags = [-maxlag:maxlag];
  endif

endfunction

##------------ Use brute force to compute the correlation -------
##if !isvector(X) 
##  ## For matrix X, compute cross-correlation of all columns
##  R = zeros(2*maxlag+1,P^2);
##  for i=1:P
##    for j=i:P
##      idx = (i-1)*P+j;
##      R(maxlag+1,idx) = X(i)*X(j)';
##      for k = 1:maxlag
##  	    R(maxlag+1-k,idx) = X(k+1:N,i) * X(1:N-k,j)';
##  	    R(maxlag+1+k,idx) = X(k:N-k,i) * X(k+1:N,j)';
##      endfor
##	if (i!=j), R(:,(j-1)*P+i) = conj(flipud(R(:,idx))); endif
##    endfor
##  endfor
##elseif isempty(Y)
##  ## reshape X so that dot product comes out right
##  X = reshape(X, 1, N);
##    
##  ## compute autocorrelation for 0:maxlag
##  R = zeros (2*maxlag + 1, 1);
##  for k=0:maxlag
##  	R(maxlag+1+k) = X(1:N-k) * X(k+1:N)';
##  endfor
##
##  ## use symmetry for -maxlag:-1
##  R(1:maxlag) = conj(R(2*maxlag+1:-1:maxlag+2));
##else
##  ## reshape and pad so X and Y are the same length
##  X = reshape(postpad(X,N), 1, N);
##  Y = reshape(postpad(Y,N), 1, N)';
##  
##  ## compute cross-correlation
##  R = zeros (2*maxlag + 1, 1);
##  R(maxlag+1) = X*Y;
##  for k=1:maxlag
##  	R(maxlag+1-k) = X(k+1:N) * Y(1:N-k);
##  	R(maxlag+1+k) = X(k:N-k) * Y(k+1:N);
##  endfor
##endif
##--------------------------------------------------------------
