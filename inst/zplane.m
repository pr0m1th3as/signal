## Copyright (C) 1999, 2001 Paul Kienzle <pkienzle@users.sf.net>
## Copyright (C) 2004 Stefan van der Walt <stefan@sun.ac.za>
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
## @deftypefn  {Function File} {} zplane (@var{z}, @var{p})
## @deftypefnx {Function File} {} zplane (@var{b}, @var{a})
##
## Plot the poles and zeros.  If the arguments are row vectors then they
## represent filter coefficients (numerator polynomial b and denominator
## polynomial a), but if they are column vectors or matrices then they
## represent poles and zeros.
##
## This is a horrid interface, but I didn't choose it; better would be
## to accept b,a or z,p,g like other functions.  The saving grace is
## that poly(x) always returns a row vector and roots(x) always returns
## a column vector, so it is usually right.  You must only be careful
## when you are creating filters by hand.
##
## Note that due to the nature of the roots() function, poles and zeros
## may be displayed as occurring around a circle rather than at a single
## point.
##
## The transfer function is
##
## @example
## @group
##        B(z)   b0 + b1 z^(-1) + b2 z^(-2) + ... + bM z^(-M)
## H(z) = ---- = --------------------------------------------
##        A(z)   a0 + a1 z^(-1) + a2 z^(-2) + ... + aN z^(-N)
##
##               b0          (z - z1) (z - z2) ... (z - zM)
##             = -- z^(-M+N) ------------------------------
##               a0          (z - p1) (z - p2) ... (z - pN)
## @end group
## @end example
##
## The denominator a defaults to 1, and the poles p defaults to [].
## @end deftypefn

## FIXME: Consider a plot-like interface:
##           zplane(x1,y1,fmt1,x2,y2,fmt2,...)
##        with y_i or fmt_i optional as usual.  This would allow
##        legends and control over point color and filters of
##        different orders.

function zplane(z, p = [])

  if (nargin < 1 || nargin > 2)
    print_usage;
  endif
  if columns(z)>1 || columns(p)>1
    if rows(z)>1 || rows(p)>1
      ## matrix form: columns are already zeros/poles
    else
      ## z -> b
      ## p -> a
      if isempty(z), z=1; endif
      if isempty(p), p=1; endif

      M = length(z) - 1;
      N = length(p) - 1;
      z = [ roots(z); zeros(N - M, 1) ];
      p = [ roots(p); zeros(M - N, 1) ];
    endif
  endif


  xmin = min([-1; real(z(:)); real(p(:))]);
  xmax = max([ 1; real(z(:)); real(p(:))]);
  ymin = min([-1; imag(z(:)); imag(p(:))]);
  ymax = max([ 1; imag(z(:)); imag(p(:))]);
  xfluff = max([0.05*(xmax-xmin), (1.05*(ymax-ymin)-(xmax-xmin))/10]);
  yfluff = max([0.05*(ymax-ymin), (1.05*(xmax-xmin)-(ymax-ymin))/10]);
  xmin = xmin - xfluff;
  xmax = xmax + xfluff;
  ymin = ymin - yfluff;
  ymax = ymax + yfluff;

  r = exp (2i * pi * [0:100] / 100);
  plot (real (r), imag (r), "k");
  axis equal;
  grid on;
  axis (1.05 * [xmin, xmax, ymin, ymax]);

  hold on;
  plot_with_labels (z, "o");
  plot_with_labels (p, "x");
  hold off;

endfunction

function plot_with_labels (x, symbol)

  if (! isempty(x))
    colors = get (gca (), "colororder");
    for c = 1:columns (x)
      color = colors(mod (c, rows (colors)), :);
      plot (real (x(:,c)), imag (x(:,c)), "color", color, ...
            "linestyle", "none", "marker", symbol);

      x_u = unique (x(:,c));
      for i = 1:length (x_u)
        n = sum (x_u(i) == x(:,c));
        if (n > 1)
          label = sprintf (" ^%d", n);
          text (real (x_u(i)), imag (x_u(i)), label, "color", color);
        endif
      endfor
    endfor
  endif

endfunction

%!demo
%! ## construct target system:
%! ##   symmetric zero-pole pairs at r*exp(iw),r*exp(-iw)
%! ##   zero-pole singletons at s
%! pw=[0.2, 0.4, 0.45, 0.95];   #pw = [0.4];
%! pr=[0.98, 0.98, 0.98, 0.96]; #pr = [0.85];
%! ps=[];
%! zw=[0.3];  # zw=[];
%! zr=[0.95]; # zr=[];
%! zs=[];
%!
%! ## system function for target system
%! p=[[pr, pr].*exp(1i*pi*[pw, -pw]), ps]';
%! z=[[zr, zr].*exp(1i*pi*[zw, -zw]), zs]';
%! M = length(z); N = length(p);
%! sys_a = [ zeros(1, M-N), real(poly(p)) ];
%! sys_b = [ zeros(1, N-M), real(poly(z)) ];
%! disp("The first two graphs should be identical, with poles at (r,w)=");
%! disp(sprintf(" (%.2f,%.2f)", [pr ; pw]));
%! disp("and zeros at (r,w)=");
%! disp(sprintf(" (%.2f,%.2f)", [zr ; zw]));
%! disp("with reflection across the horizontal plane");
%! subplot(231);
%! zplane(sys_b, sys_a);
%! title("transfer function form");
%! subplot(232);
%! zplane(z,p);
%! title("pole-zero form");
%! subplot(233);
%! zplane(z);
%! title("empty p");
%! subplot(234);
%! zplane(sys_b);
%! title("empty a");
%! disp("The matrix plot has 2 sets of points, one inside the other");
%! subplot(235);
%! zplane([z, 0.7*z], [p, 0.7*p]);
%! title("matrix");
