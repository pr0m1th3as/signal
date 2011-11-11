## Copyright (C) 2000 Dave Cogdell <cogdelld@asme.org>
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

## C = xcorr2 (A, B)
##	Compute the 2D cross-correlation of matrices A and B.
## C = xcorr2 (A)
##      Compute two-dimensional autocorrelation of matrix A.
## C = xcorr2 (..., 'scale')
##      biased   - scales the raw cross-correlation by the maximum number
##                 of elements of A and B involved in the generation of 
##                 any element of C
##      unbiased - scales the raw correlation by dividing each element 
##                 in the cross-correlation matrix by the number of
##                 products A and B used to generate that element 
##      coeff    - normalizes the sequence so that the largest 
##                 cross-correlation element is identically 1.0.
##      none     - no scaling (this is the default).

## Author: Dave Cogdell <cogdelld@asme.org>
## 2000-05-02 Paul Kienzle <pkienzle@users.sf.net>
##    * joined R. Johnson's xcorr2f.m and Dave Cogdell's xcorr2x.m
##    * adapted for Octave
## 2001-01-15 Paul Kienzle
##    * vectorized code for 'unbiased' correction
## 2001-02-06 Paul Kienzle
##    * replaced R. Johnson's xcorr2f code with code based on conv2

function c = xcorr2(a,b,biasflag)

  if (nargin < 1 || nargin > 3)
    usage ("c = xcorr2(A [, B] [, 'scale'])");
  endif
  if nargin == 1
    b = a; 
    biasflag = 'none'; 
  elseif nargin == 2
    if ischar (b) 
      biasflag = b; 
      b = a;
    else 
      biasflag = 'none';
    endif
  endif

  ## compute correlation
  [ma,na] = size(a);
  [mb,nb] = size(b);
  c = conv2 (a, conj (b (mb:-1:1, nb:-1:1)));

  ## bias routines by Dave Cogdell (cogdelld@asme.org)
  ## optimized by Paul Kienzle (pkienzle@users.sf.net)
  if strcmp(lower(biasflag), 'biased'),
    c = c / ( min ([ma, mb]) * min ([na, nb]) );
  elseif strcmp(lower(biasflag), 'unbiased'), 
    try eleo = empty_list_elements_ok;
    catch eleo = 0;
    end
    try wele = warn_empty_list_elements;
    catch wele = 0;
    end
    unwind_protect
      empty_list_elements_ok = 1;
      warn_empty_list_elements = 0;
      lo = min ([na,nb]); hi = max ([na, nb]);
      row = [ 1:(lo-1), lo*ones(1,hi-lo+1), (lo-1):-1:1 ];
      lo = min ([ma,mb]); hi = max ([ma, mb]);
      col = [ 1:(lo-1), lo*ones(1,hi-lo+1), (lo-1):-1:1 ]';
    unwind_protect_cleanup
      empty_list_elements_ok = eleo;
      warn_empty_list_elements = wele;
    end_unwind_protect
    bias = col*row;
    c = c./bias;
  elseif strcmp(lower(biasflag),'coeff'),
    c = c/max(c(:))';
  endif
endfunction
