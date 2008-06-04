
// Copyright (C) 2008 Eric Chassande-Mottin, CNRS (France)

// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, see .

#include <octave/config.h>
#include <octave/defun-dld.h>
#include <octave/error.h>
#include <octave/gripes.h>
#include <octave/oct-obj.h>
#include <octave/pager.h>
#include <octave/quit.h>
#include <octave/variables.h>

DEFUN_DLD (upfirdn, args,,
  "-*- texinfo -*-\n\
@deftypefn {Loadable Function} {@var{y} =} upfirdn (@var{x},@var{h},@var{p},@var{q})\n\
Upsample, FIR filtering and downsample.@*\n\
@end deftypefn\n")
{
  octave_value_list retval;
  
  int nargin = args.length ();
  
  if (nargin < 4)
    {
      print_usage();
      return retval;
    }

  Matrix x ( args(0).matrix_value () );

  if (error_state) 
    { 
      gripe_wrong_type_arg("upfirdn",args(0));
      return retval; 
    }

  octave_idx_type rx=x.rows();
  octave_idx_type cx=x.columns();

  bool isrowvector=false;

  if ((rx==1)&&(cx>1)) // if row vector, transpose to column vector
    {
      x=x.transpose();
      rx=x.rows();
      cx=x.columns();
      isrowvector=true;      
    }

  octave_idx_type Lx=rx;

  ColumnVector h( args(1).vector_value() );

  if (error_state) 
    { 
      gripe_wrong_type_arg("upfirdn",args(1));
      return retval; 
    }

  octave_idx_type Lh=h.length();

  octave_idx_type p=args(2).idx_type_value();

  if (error_state) 
    { 
      gripe_wrong_type_arg("upfirdn",args(2));
      return retval; 
    }

  octave_idx_type q=args(3).idx_type_value();

  if (error_state) 
    { 
      gripe_wrong_type_arg("upfirdn",args(3));
      return retval; 
    }

  double r=p/(static_cast<double>(q));

  octave_idx_type Ly= ceil( static_cast<double>((Lx-1)*p + Lh) / 
			    static_cast<double>(q));

  Matrix y(Ly,cx,0.0);
  
  for (octave_idx_type c=0; c<cx; c++)
    {

      octave_idx_type m=0;
      while (m<Ly)
	{
	  octave_idx_type n=floor(m/r);
	  octave_idx_type lm=(m*q)%p;
	  octave_idx_type k=0;
	  double accum=0.0;
	  do
	    {
	      octave_idx_type ix=n-k;
	      if (ix>=Lx)
		{
		  k++;
		  continue;
		}
	      
	      octave_idx_type ih=k*p+lm;
	      if ((ih>=Lh)|(ix<0))
		break;
	      
	      accum += h(ih)*x(ix,c);
	      k++;
	    }
	  while(1);
	  
	  y(m,c)=accum;
	  m++;
	}

    }

  if (isrowvector)
    y=y.transpose();

  retval(0)=y;
 
  return retval;
}  
  
