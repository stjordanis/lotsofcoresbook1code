#ifndef SECOND_DERIV
C> \ingroup nwxc
C> @{
C>
C> \file nwxc_xc_kt1.F
C> The KT1, KT2 and SSB-D functional
C>
C> @}
#endif
C>
C> \ingroup nwxc_priv
C> @{
C>
C> \brief Evaluate the KT1, KT2, and part of the SSB-D functional
C>
C> This is the gradient correction term by Keal and Tozer [1],
C> which can be used on its own (as in the KT1 or KT2 functional),
C> or forms part of the SSB-D functional [2].
C>
C> Note that even though the energy takes the form of an exchange
C> functional, this gradient correction is strictly speaking
C> NOT an exchange functional!
C>
C> ### References ###
C>
C> [1] T.W. Keal, D.J. Tozer,
C>     "The exchange-correlation potential in Kohn-Sham nuclear
C>     magnetic resonance shielding calculations", J. Chem. Phys.
C>     <b>119</b>, 3015-3024 (2006), DOI:
C>     <a href="http://dx.doi.org/10.1063/1.1590634">
C>     10.1063/1.1590634</a>.
C>
C> [2] M. Swart, M. Sola, F.M. Bickelhaupt,
C>     "A new all-round density functional based on spin states and
C>     SN2 barriers",
C>     J. Chem. Phys. <b>131</b>, 094103 (2009), DOI:
C>     <a href="http://dx.doi.org/10.1063/1.3213193">
C>     10.1063/1.3213193</a>.
C>
#ifndef SECOND_DERIV
      Subroutine nwxc_xc_kt1(tol_rho, ipol, nq, wght, rho, rgamma, 
     &                       func, Amat, Cmat)
#else
      Subroutine nwxc_xc_kt1_d2(tol_rho, ipol, nq, wght, rho, rgamma, 
     &                          func, Amat, Amat2, Cmat, Cmat2)
#endif
c
C$Id: nwxc_xc_kt1.F 25011 2013-12-19 17:45:25Z d3y133 $
c
      implicit none
c      
#include "nwxc_param.fh"
c
c     Input and other parameters
c
      double precision tol_rho !< [Input] The lower limit on the density
      integer ipol             !< [Input] The number of spin channels
      integer nq               !< [Input] The number of points
      double precision wght    !< [Input] The weight of the functional
c
c     Charge Density 
c
      double precision rho(nq,*)    !< [Input] The density
c
c     Charge Density Gradient
c
      double precision rgamma(nq,*) !< [Input] The norm of the density gradients
c
c     Sampling Matrices for the XC Potential
c
      double precision func(nq)     !< [Output] The value of the functional
      double precision Amat(nq,*)   !< [Output] The derivative wrt rho
      double precision Cmat(nq,*)   !< [Output] The derivative wrt rgamma

#ifdef SECOND_DERIV
c
c     Second Derivatives of the Exchange Energy Functional
c
      double precision Amat2(nq,*)  !< [Output] The 2nd derivative wrt rho
      double precision Cmat2(nq,*)  !< [Output] The 2nd derivative wrt rgamma
                                    !< and possibly rho
#endif
c
      double precision DELTA, GAMKT
      Parameter (DELTA = 0.1D0, GAMKT= -0.006d0)
c
c References:
c
c    Keal, Tozer, JCP 119, 3015 (2003), JCP 121, 5654 (2004)
c    Swart, Sola, Bickelhaupt, JCP 131, XXXX (2009)
c    Johnson, Gill & Pople, J. Chem. Phys. 98, 5612 (1993)
c
c***************************************************************************
c
      integer n
      double precision hrho
      double precision rho13, rho43, gamma, g, gdenom, gdenom2
#ifdef SECOND_DERIV
      double precision rho23, rhom23, gdenom3
#endif
c
c     NOTE: the gamma from the KT1 formulation is here called
c           gamkt, gamma is in NWChem reserved for grad**2
c
      if (ipol.eq.1) then
c
c        ======> SPIN-RESTRICTED <======
c
         do 10 n = 1, nq
            if (rho(n,R_T).lt.tol_rho) goto 10
c
c           Spin alpha:
c
            hrho  = 0.5d0*rho(n,R_T)
            rho13 = hrho**(1.d0/3.d0)
            rho43 = rho13*hrho
            gamma = rgamma(n,G_TT)
c           gamma = delrho(n,1,1)*delrho(n,1,1) +
c    &              delrho(n,2,1)*delrho(n,2,1) +
c    &              delrho(n,3,1)*delrho(n,3,1)
            if (dsqrt(gamma).gt.tol_rho) then
               gamma = 0.25d0 * gamma
            else
               goto 10
            endif
c
            gdenom = 1.d0 / (rho43 + DELTA)
            gdenom2 = gdenom*gdenom
            g = GAMKT * gamma * gdenom
c
            func(n) = func(n) + 2.d0*g*wght
            Amat(n,D1_RA) = Amat(n,D1_RA) - (4d0/3d0)*GAMKT*gamma*rho13*
     &                  wght*gdenom2
            Cmat(n,D1_GAA) = Cmat(n,D1_GAA) + GAMKT*gdenom*wght
c
#ifdef SECOND_DERIV
            rho23 = rho13*rho13
            rhom23 = rho13 / (0.5d0*rho(n,R_T))
            gdenom3 = gdenom2*gdenom
c
            Amat2(n,D2_RA_RA) = Amat2(n,D2_RA_RA) + (4d0/3d0)*GAMKT*
     &          gamma*(rho23*7d0/3d0 - DELTA*rhom23/3d0)*gdenom3*wght
            Cmat2(n,D2_RA_GAA) = Cmat2(n,D2_RA_GAA)
     &           - (4d0/3d0)*GAMKT*rho13*gdenom2*wght
c
c      second derivative w.r.t. gamma is zero !
c      (by construction)
c      therefore, nothing added to Cmat2(n,D2_GAA_GAA)
c
#endif
c
 10      continue
c
      else
c
c        ======> SPIN-UNRESTRICTED <======
c
         do 20 n = 1, nq
            if (rho(n,R_A)+rho(n,R_B).lt.tol_rho) goto 20
            if (rho(n,R_A).lt.tol_rho) goto 25
c
c           Spin alpha:
c
            rho13 = rho(n,R_A)**(1.d0/3.d0)
            rho43 = rho13*rho(n,R_A)
            gamma = rgamma(n,G_AA)
c           gamma = delrho(n,1,1)*delrho(n,1,1) +
c    &              delrho(n,2,1)*delrho(n,2,1) +
c    &              delrho(n,3,1)*delrho(n,3,1)
            if (dsqrt(gamma).lt.tol_rho) then
               goto 25
            endif
c
            gdenom = 1d0 / (rho43 + DELTA)
            gdenom2 = gdenom*gdenom
            g = GAMKT * gamma * gdenom
c
            func(n) = func(n) + g*wght
            Amat(n,D1_RA) = Amat(n,D1_RA) - (4d0/3d0)*GAMKT*gamma*rho13*
     &                 gdenom2*wght
            Cmat(n,D1_GAA) = Cmat(n,D1_GAA) + GAMKT*gdenom*wght
c
#ifdef SECOND_DERIV
            rho23 = rho13*rho13
            rhom23 = rho13 / rho(n,R_A)
            gdenom3 = gdenom2*gdenom
c
            Amat2(n,D2_RA_RA) = Amat2(n,D2_RA_RA) + (4d0/3d0)*GAMKT*
     &          gamma*(rho23*7d0/3d0 - DELTA*rhom23/3d0)*gdenom3*wght
            Cmat2(n,D2_RA_GAA) = Cmat2(n,D2_RA_GAA)
     &           - (4d0/3d0)*GAMKT*rho13*gdenom2*wght
c
c      second derivative w.r.t. gamma is zero !
c      (by construction)
c      therefore, nothing added to Cmat2(n,D2_GAA_GAA)
#endif
c
 25         continue
c
c           Spin beta:
c
            if (rho(n,R_B).lt.tol_rho) goto 20
c
            rho13 = rho(n,R_B)**(1.d0/3.d0)
            rho43 = rho13*rho(n,R_B)
            gamma = rgamma(n,G_BB)
c           gamma = delrho(n,1,2)*delrho(n,1,2) +
c    &              delrho(n,2,2)*delrho(n,2,2) +
c    &              delrho(n,3,2)*delrho(n,3,2)
            if (dsqrt(gamma).lt.tol_rho) then
               goto 20
            endif
c           
            gdenom = 1d0 / (rho43 + DELTA)
            gdenom2 = gdenom*gdenom 
            g = GAMKT * gamma * gdenom
c           
            func(n) = func(n) + g*wght
            Amat(n,D1_RB) = Amat(n,D1_RB) - (4d0/3d0)*GAMKT*gamma*rho13*
     &            wght*gdenom2
            Cmat(n,D1_GBB) = Cmat(n,D1_GBB) + GAMKT*gdenom*wght
c           
#ifdef SECOND_DERIV
            rho23 = rho13*rho13
            rhom23 = rho13 / rho(n,R_B)
            gdenom3 = gdenom2*gdenom
c
            Amat2(n,D2_RB_RB) = Amat2(n,D2_RB_RB) + (4d0/3d0)*GAMKT*
     &          gamma*(rho23*7d0/3d0 - DELTA*rhom23/3d0)*gdenom3*wght
            Cmat2(n,D2_RB_GBB) = Cmat2(n,D2_RB_GBB)
     &           - (4d0/3d0)*GAMKT*rho13*gdenom2*wght
c
c      second derivative w.r.t. gamma is zero !
c      (by construction)
c      therefore, nothing added to Cmat2(n,D2_GAA_GAA)
c
#endif
c
 20      continue
c
      endif
c
      return
      end
#ifndef SECOND_DERIV
#define SECOND_DERIV
c
c     Compile source again for the 2nd derivative case
c
#include "nwxc_xc_kt1.F"
#endif
C>
C> @}
