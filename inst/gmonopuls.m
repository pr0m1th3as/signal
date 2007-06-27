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
## @deftypefn {Function File} {[@var{y}] =} gmonopuls(@var{t},@var{fc})
##	Return the gaussian monopulse.
## @end deftypefn

function [y] = gmonopuls(t,fc)
	if nargin<1, error("Usage : gmonopuls(t,fc)"); end
	if nargin<2, fc = 1e3; end
	if fc < 0 , error("fc must be positive"); end
	y = 2*sqrt(exp(1)) .* pi.*t.*fc.*exp(-2 .* (pi.*t.*fc).^2);
endfunction