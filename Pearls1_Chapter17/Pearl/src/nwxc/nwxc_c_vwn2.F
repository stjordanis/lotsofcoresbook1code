#if !defined(SECOND_DERIV) && !defined(THIRD_DERIV)
C> \ingroup nwxc
C> @{
C>
C> \file nwxc_c_vwn2.F
C> The Vosko, Wilk, Nusair correlation functional #2
C>
C> @}
#endif
C> \ingroup nwxc_priv
C> @{
C>
C> \brief The homogenous electron gas correlation functional of
C> Vosko, Wilk and Nusair #2 of 1980
C>
C> The correlation functional #2 of Vosko, Wilk and Nusair parametrized
C> against Ceperley-Alder Monte Carlo data [1].
C>
C> [1] S.H. Vosko, L. Wilk, M. Nusair,
C>     <i>"Accurate spin-dependent electron liquid correlation energies
C>     for local spin density calculations: a critical analysis"</i>,
C>     Can. J. Phys. <b>58</b>, 1200-1211 (1980), DOI:
C>     <a href="http://dx.doi.org/10.1139/p80-159">10.1139/p80-159</a>.
C>
*
* $Id: nwxc_c_vwn2.F 25606 2014-05-13 21:42:13Z d3y133 $
*
#define FNL_VWN_2
#include "nwxc_c_vwn_a.fh"
c
c     Compute the function deltaEc(rs,zeta) function and its derivatives
c     wrt rs and zeta for the spin-unrestricted case - the rest has the
c     same form for all VWN functionals and is handled in the header files.
c
            dec_rsz = devwn_rsz + (dec_rs1-derpa_rs1)*fz
            d1dec_rsz(1) = d1devwn_rsz(1) + (d1dec_rs1-d1derpa_rs1)*fz
            d1dec_rsz(2) = d1devwn_rsz(2) + (dec_rs1-derpa_rs1)*d1fz
#ifdef SECOND_DERIV
            d2dec_rsz(1) = d2devwn_rsz(1) + (d2dec_rs1-d2derpa_rs1)*fz
            d2dec_rsz(2) = d2devwn_rsz(2) + (d1dec_rs1-d1derpa_rs1)*d1fz
            d2dec_rsz(3) = d2devwn_rsz(3) + (dec_rs1-derpa_rs1)*d2fz
#endif
#ifdef THIRD_DERIV
            d3dec_rsz(1) = d3devwn_rsz(1) + (d3dec_rs1-d3derpa_rs1)*fz
            d3dec_rsz(2) = d3devwn_rsz(2) 
     &                   + (d2dec_rs1-d2derpa_rs1)*d1fz
            d3dec_rsz(3) = d3devwn_rsz(3)
     &                   + (d1dec_rs1-d1derpa_rs1)*d2fz
            d3dec_rsz(4) = d3devwn_rsz(4)
     &                   + (dec_rs1-derpa_rs1)*d3fz
#endif
c
#include "nwxc_c_vwn_b.fh"
c
#ifndef SECOND_DERIV
#define SECOND_DERIV
c
c     Compile source again for the 2nd derivative case
c
#include "nwxc_c_vwn2.F"
#endif
#ifndef THIRD_DERIV
#define THIRD_DERIV
c
c     Compile source again for the 3rd derivative case
c
#include "nwxc_c_vwn2.F"
#endif
C>
C> @}
