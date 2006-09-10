## Copyright (C) 1999 Paul Kienzle
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

## usage: [y, xm] = rceps(x)
##   Produce the cepstrum of the signal x, and if desired, the minimum
##   phase reconstruction of the signal x.  If x is a matrix, do so
##   for each column of the matrix.
##
## Example
##   f0=70; Fs=10000;           # 100 Hz fundamental, 10kHz sampling rate
##   a=poly(0.985*exp(1i*pi*[0.1, -0.1, 0.3, -0.3])); # two formants
##   s=0.005*randn(1024,1);      # Noise excitation signal
##   s(1:Fs/f0:length(s)) = 1;   # Impulse glottal wave
##   x=filter(1,a,s);            # Speech signal in x
##   [y, xm] = rceps(x.*hanning(1024)); # cepstrum and min phase reconstruction
##
## Reference
##    Programs for digital signal processing. IEEE Press.
##    New York: John Wiley & Sons. 1979.

function [y, ym] = rceps(x)
  if (nargin != 1)
    usage("y = rceps(x)");
  end
  y = real(ifft(log(abs(fft(x)))));
  if nargout == 2
    n=length(x);
    if rows(x)==1
      if rem(n,2)==1
      	ym = [y(1), 2*y(2:n/2), zeros(1,n/2-1)];
      else
	ym = [y(1), 2*y(2:n/2), y(n/2+1), zeros(1,n/2-1)];
      endif
    else
      if rem(n,2)==1
	ym = [y(1,:); 2*y(2:n/2,:); zeros(n/2-1,columns(y))];
      else
	ym = [y(1,:); 2*y(2:n/2,:); y(n/2+1,:); zeros(n/2-1,columns(y))];
      endif
    endif
    ym = real(ifft(exp(fft(ym))));
  endif
endfunction

%!error rceps
%!error rceps(1,2)  # too many arguments

%!test
%! ## accepts matrices
%! x=randn(32,3);
%! [y, xm] = rceps(x);
%! ## check the mag-phase response of the reproduction
%! hx = fft(x);
%! hxm = fft(xm);
%! assert(abs(hx), abs(hxm), 200*eps); # good magnitude response match
%! #XXX FIXME XXX test for minimum phase?  Stop using random datasets!
%! #assert(arg(hx) != arg(hxm));        # phase mismatch

%!test
%! ## accepts column and row vectors
%! x=randn(256,1);
%! [y, xm] = rceps(x);
%! [yt, xmt] = rceps(x.');
%! assert(yt.', y); 
%! assert(xmt.', xm);

%!demo
%! f0=70; Fs=10000;           # 100 Hz fundamental, 10kHz sampling rate
%! a=real(poly(0.985*exp(1i*pi*[0.1, -0.1, 0.3, -0.3]))); # two formants
%! s=0.05*randn(1024,1);      # Noise excitation signal
%! s(1:Fs/f0:length(s)) = 1;  # Impulse glottal wave
%! x=filter(1,a,s);           # Speech signal in x
%! isreal(x)
%! [y, xm] = rceps(x);        # cepstrum and minimum phase x
%! [hx, w] = freqz(x,1,[],Fs); hxm = freqz(xm);
%! figure(1);
%! subplot(311);
%!    __gnuplot_set__ tmargin 3;
%!    __gnuplot_set__ lmargin 10;
%!    auplot(x,Fs,'b',';signal;');
%!    hold on; auplot(xm,Fs,'g',';reconstruction;'); 
%!    hold off;
%! subplot(312);
%!    __gnuplot_set__ lmargin 10;
%!    __gnuplot_set__ bmargin 0;
%!    axis("ticy");
%!    plot(w,log(abs(hx)), ";magnitude;", ...
%!         w,log(abs(hxm)),";reconstruction;");
%! subplot(313);
%!    __gnuplot_set__ lmargin 10;
%!    __gnuplot_set__ tmargin 0;
%!    __gnuplot_set__ bmargin 3;
%!    axis("on");
%!    plot(w,unwrap(arg(hx))/(2*pi), ";phase;",...
%!	   w,unwrap(arg(hxm))/(2*pi),";reconstruction;");
%!    __gnuplot_set__ tmargin;
%!    __gnuplot_set__ bmargin;
%!    __gnuplot_set__ lmargin;
%! oneplot();
%! figure(2); auplot(y,Fs,';cepstrum;');
%! %-------------------------------------------------------------
%! % confirm the magnitude spectrum is identical in the signal
%! % and the reconstruction and that there are peaks in the
%! % cepstrum at 14 ms intervals corresponding to an F0 of 70 Hz.