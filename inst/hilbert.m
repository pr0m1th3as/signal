## Copyright (C) 2000 Paul Kienzle
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

## usage: y = hilbert(x)
##
## real(y) contains the original signal x (x must be a real-valued)
## imag(y) contains the hilbert transform of x, which is the same
## signal with a phase shift of 90 degrees.
##
## If x is a matrix, computes the hilbert transform on each row.
function y = hilbert(x)
  if nargin != 1, usage("y = hilbert(x)"); endif
  if !isreal(x), error("hilbert: requires real input vector"); endif
  transpose = rows(x)==1;
  if transpose, x=x.'; endif
  [r, c] = size(x);
  n=2^nextpow2(r);
  if r < n, x = [ x ; zeros(n-r, c) ]; endif
  y = fft(x);
  y = ifft([y(1,:) ; 2*y(2:n/2,:) ; y(n/2+1,:) ; zeros(n/2-1,columns(y))]);
  if r < n, y(r+1:n,:) = []; endif
  if transpose, y = y.'; endif
endfunction

%!demo
%! % notice that the imaginary signal is phase-shifted 90 degrees
%! t=linspace(0,10,256);
%! z = hilbert(sin(2*pi*0.5*t));
%! grid on; plot(t,real(z),';real;',t,imag(z),';imag;');

%!demo
%! % the magnitude of the hilbert transform eliminates the carrier
%! t=linspace(0,10,1024);
%! x=5*cos(0.2*t).*sin(100*t);
%! grid on; plot(t,x,'g;z;',t,abs(hilbert(x)),'b;|hilbert(z)|;');