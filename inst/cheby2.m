## Copyright (C) 1999 Paul Kienzle <pkienzle@users.sf.net>
## Copyright (C) 2003 Doug Stewart <dastew@sympatico.ca>
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING. If not, see
## <https://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {Function File} {[@var{b}, @var{a}] =} cheby2 (@var{n}, @var{rs}, @var{wc})
## @deftypefnx {Function File} {[@var{b}, @var{a}] =} cheby2 (@var{n}, @var{rs}, @var{wc}, "high")
## @deftypefnx {Function File} {[@var{b}, @var{a}] =} cheby2 (@var{n}, @var{rs}, [@var{wl}, @var{wh}])
## @deftypefnx {Function File} {[@var{b}, @var{a}] =} cheby2 (@var{n}, @var{rs}, [@var{wl}, @var{wh}], "stop")
## @deftypefnx {Function File} {[@var{z}, @var{p}, @var{g}] =} cheby2 (@dots{})
## @deftypefnx {Function File} {[@var{a}, @var{b}, @var{c}, @var{d}] =} cheby2 (@dots{})
## @deftypefnx {Function File} {[@dots{}] =} cheby2 (@dots{}, "s")
## Generate a Chebyshev type II filter with @var{rs} dB of stopband attenuation.
##
## [b, a] = cheby2(n, Rs, Wc)
##    low pass filter with cutoff pi*Wc radians
##
## [b, a] = cheby2(n, Rs, Wc, 'high')
##    high pass filter with cutoff pi*Wc radians
##
## [b, a] = cheby2(n, Rs, [Wl, Wh])
##    band pass filter with edges pi*Wl and pi*Wh radians
##
## [b, a] = cheby2(n, Rs, [Wl, Wh], 'stop')
##    band reject filter with edges pi*Wl and pi*Wh radians
##
## [z, p, g] = cheby2(...)
##    return filter as zero-pole-gain rather than coefficients of the
##    numerator and denominator polynomials.
##
## [...] = cheby2(...,'s')
##     return a Laplace space filter, W can be larger than 1.
##
## [a,b,c,d] = cheby2(...)
##  return  state-space matrices
##
## References:
##
## Parks & Burrus (1987). Digital Filter Design. New York:
## John Wiley & Sons, Inc.
## @end deftypefn

function [a, b, c, d] = cheby2 (n, rs, w, varargin)

  if (nargin > 5 || nargin < 3 || nargout > 4 || nargout < 2)
    print_usage ();
  endif

  ## interpret the input parameters
  if (! (isscalar (n) && (n == fix (n)) && (n > 0)))
    error ("cheby2: filter order N must be a positive integer");
  endif

  stop = false;
  digital = true;
  for i = 1:numel (varargin)
    switch (varargin{i})
      case "s"
        digital = false;
      case "z"
        digital = true;
      case {"high", "stop"}
        stop = true;
      case {"low", "pass"}
        stop = false;
      otherwise
        error ("cheby2: expected [high|stop] or [s|z]");
    endswitch
  endfor

  if (! ((numel (w) <= 2) && (rows (w) == 1 || columns (w) == 1)))
    error ("cheby2: frequency must be given as WC or [WL, WH]");
  elseif ((numel (w) == 2) && (w(2) <= w(1)))
    error ("cheby2: W(1) must be less than W(2)");
  endif

  if (digital && ! all ((w >= 0) & (w <= 1)))
    error ("cheby2: all elements of W must be in the range [0,1]");
  elseif (! digital && ! all (w >= 0))
    error ("cheby2: all elements of W must be in the range [0,inf]");
  endif

  if (! (isscalar (rs) && isnumeric (rs) && (rs >= 0)))
    error ("cheby2: stopband attenuation RS must be a non-negative scalar");
  endif

  ## Prewarp to the band edges to s plane
  if (digital)
    T = 2;       # sampling frequency of 2 Hz
    w = 2 / T * tan (pi * w / T);
  endif

  ## Generate splane poles and zeros for the Chebyshev type 2 filter
  ## From: Stearns, SD; David, RA; (1988). Signal Processing Algorithms.
  ##       New Jersey: Prentice-Hall.
  C = 1;  ## default cutoff frequency
  lambda = 10^(rs / 20);
  phi = log (lambda + sqrt (lambda^2 - 1)) / n;
  theta = pi * ([1:n] - 0.5) / n;
  alpha = -sinh (phi) * sin (theta);
  beta = cosh (phi) * cos (theta);
  if (rem (n, 2))
    ## drop theta==pi/2 since it results in a zero at infinity
    zero = 1i * C ./ cos (theta([1:(n - 1) / 2, (n + 3) / 2:n]));
  else
    zero = 1i * C ./ cos (theta);
  endif
  pole = C ./ (alpha.^2 + beta.^2) .* (alpha - 1i * beta);

  ## Compensate for amplitude at s=0
  ## Because of the vagaries of floating point computations, the
  ## prod(pole)/prod(zero) sometimes comes out as negative and
  ## with a small imaginary component even though analytically
  ## the gain will always be positive, hence the abs(real(...))
  gain = abs (real (prod (pole) / prod (zero)));

  ## splane frequency transform
  [zero, pole, gain] = sftrans (zero, pole, gain, w, stop);

  ## Use bilinear transform to convert poles to the z plane
  if (digital)
    [zero, pole, gain] = bilinear (zero, pole, gain, T);
  endif

  ## convert to the correct output form
  if (nargout == 2)
    a = real (gain * poly (zero));
    b = real (poly (pole));
  elseif (nargout == 3)
    a = zero;
    b = pole;
    c = gain;
  else
    ## output ss results
    [a, b, c, d] = zp2ss (zero, pole, gain);
  endif

endfunction

%% Test input validation
%!error [a, b] = cheby2 ()
%!error [a, b] = cheby2 (1)
%!error [a, b] = cheby2 (1, 2)
%!error [a, b] = cheby2 (1, 2, 3, 4, 5, 6)
%!error [a, b] = cheby2 (.5, 40, .2)
%!error [a, b] = cheby2 (3, 40, .2, "invalid")

