## Copyright (C) 2001 Paulo Neis <p_neis@yahoo.com.br>
## Copyright (C) 2003 Doug Stewart <dastew@sympatico.ca>
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {Function File} {[@var{b}, @var{a}] =} ellip (@var{n}, @var{Rp}, @var{Rs}, @var{Wp})
## @deftypefnx {Function File} {[@var{b}, @var{a}] =} ellip (@var{n}, @var{Rp}, @var{Rs}, @var{Wp}, "high")
## @deftypefnx {Function File} {[@var{b}, @var{a}] =} ellip (@var{n}, @var{Rp}, @var{Rs}, @var{[Wl}, @var{Wh}])
## @deftypefnx {Function File} {[@var{b}, @var{a}] =} ellip (@var{n}, @var{Rp}, @var{Rs}, @var{[Wl}, @var{Wh}], "stop")
## @deftypefnx {Function File} {[@var{z}, @var{p}, @var{g}] =} ellip (@dots{})
## @deftypefnx {Function File} {[@var{a}, @var{b}, @var{c}, @var{d}] =} ellip (@dots{})
## @deftypefnx {Function File} {[@dots{}] =} ellip (@dots{}, "s")
##
## Generate an Elliptic or Cauer filter (discrete and contnuious).
##
## [b,a] = ellip(n, Rp, Rs, Wp)
##  low pass filter with order n, cutoff pi*Wp radians, Rp decibels
##  of ripple in the passband and a stopband Rs decibels down.
##
## [b,a] = ellip(n, Rp, Rs, Wp, 'high')
##  high pass filter with cutoff pi*Wp...
##
## [b,a] = ellip(n, Rp, Rs, [Wl, Wh])
##  band pass filter with band pass edges pi*Wl and pi*Wh ...
##
## [b,a] = ellip(n, Rp, Rs, [Wl, Wh], 'stop')
##  band reject filter with edges pi*Wl and pi*Wh, ...
##
## [z,p,g] = ellip(...)
##  return filter as zero-pole-gain.
##
## [...] = ellip(...,'s')
##     return a Laplace space filter, W can be larger than 1.
##
## [a,b,c,d] = ellip(...)
##  return  state-space matrices
##
## References:
##
## - Oppenheim, Alan V., Discrete Time Signal Processing, Hardcover, 1999.
## - Parente Ribeiro, E., Notas de aula da disciplina TE498 -  Processamento
##   Digital de Sinais, UFPR, 2001/2002.
## - Kienzle, Paul, functions from Octave-Forge, 1999 (http://octave.sf.net).
## @end deftypefn

function [a,b,c,d] = ellip(n, Rp, Rs, W, varargin)

  if (nargin>6 || nargin<4) || (nargout>4 || nargout<2)
    print_usage;
  endif

  ## interpret the input parameters
  if (!(length(n)==1 && n == round(n) && n > 0))
    error ("ellip: filter order n must be a positive integer");
  endif


  stop = 0;
  digital = 1;
  for i=1:length(varargin)
    switch varargin{i}
      case 's', digital = 0;
      case 'z', digital = 1;
      case { 'high', 'stop' }, stop = 1;
      case { 'low',  'pass' }, stop = 0;
      otherwise,  error ("ellip: expected [high|stop] or [s|z]");
    endswitch
  endfor

  [r, c]=size(W);
  if (!(length(W)<=2 && (r==1 || c==1)))
    error ("ellip: frequency must be given as w0 or [w0, w1]");
  elseif (!(length(W)==1 || length(W) == 2))
    error ("ellip: only one filter band allowed");
  elseif (length(W)==2 && !(W(1) < W(2)))
    error ("ellip: first band edge must be smaller than second");
  endif

  if ( digital && !all(W >= 0 & W <= 1))
    error ("ellip: critical frequencies must be in (0 1)");
  elseif ( !digital && !all(W >= 0 ))
    error ("ellip: critical frequencies must be in (0 inf)");
  endif

  if (Rp < 0)
    error("ellip: passband ripple must be positive decibels");
  endif

  if (Rs < 0)
    error("ellip: stopband ripple must be positive decibels");
  endif


  ## Prewarp the digital frequencies
  if digital
    T = 2;       # sampling frequency of 2 Hz
    W = tan(pi*W/T);
  endif

  ## Generate s-plane poles, zeros and gain
  [zero, pole, gain] = ncauer(Rp, Rs, n);

  ## splane frequency transform
  [zero, pole, gain] = sftrans(zero, pole, gain, W, stop);

  ## Use bilinear transform to convert poles to the z plane
  if digital
    [zero, pole, gain] = bilinear(zero, pole, gain, T);
  endif


  ## convert to the correct output form
  if nargout==2,
    a = real(gain*poly(zero));
    b = real(poly(pole));
  elseif nargout==3,
    a = zero;
    b = pole;
    c = gain;
  else
    ## output ss results
    [a, b, c, d] = zp2ss (zero, pole, gain);
  endif

endfunction

%!demo
%! [n, Ws] = ellipord ([.1 .2], .4, 1, 90);
%! [b, a] = ellip (5, 1, 90, [.1 .2]);
%! [h, w] = freqz (b, a);
%!
%! plot (w./pi, 20*log10 (abs (h)), ";;")
%! xlabel ("Frequency");
%! ylabel ("abs(H[w])[dB]");
%! axis ([0, 1, -100, 0]);
%!
%! hold ("on");
%! x=ones (1, length (h));
%! plot (w./pi, x.*-1, ";-1 dB;")
%! plot (w./pi, x.*-90, ";-90 dB;")
%! hold ("off");
