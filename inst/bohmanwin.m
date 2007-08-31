## Copyright (C) 2007   Sissou   <sylvain.pelissier@gmail.com>
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
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

## -*- texinfo -*-
## @deftypefn {Function File} {[@var{w}] =} bohmanwin(@var{L})
##	Compute the Bohman window of lenght L.
## @seealso{rectwin,  bartlett}
## @end deftypefn

function [w] = bohmanwin(L)
	if (nargin < 1); usage('bohmanwin(x)'); end
	if(! isscalar(L))
		error("L must be a number");
	endif
	
	N = L-1;
	n = -ceil(N/2):N/2;
	
	w = (1-2.*abs(n)./N).*cos(2.*pi.*abs(n)./N) + (1./pi).*sin(2.*pi.*abs(n)./N);
	w(1) = 0;
	w(length(w))=0;
endfunction;