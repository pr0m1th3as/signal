## Copyright (C) 2007   Muthiah Annamalai  <muthiah.annamalai@uta.edu>
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

## -*- texinfo -*-
## @deftypefn {Function File} {[@var{w}] =} welchwin(@var{L})
##	Compute the Welch window, given by 
##      w(n) = 1 - ((n-L/2)/(L/2))^2, n=0,1, ... L-1
## @seealso{blackman,  kaiser}
## @end deftypefn

function [w] = welchwin(L)
	if (nargin < 1); usage('welchwin(L)'); end
	if(! isscalar(L))
		error("L must be a number");
	endif
	
	N = L/2;
	n= 0:L-1;
	w = 1 - ((n-N)./N).^2;
endfunction;

