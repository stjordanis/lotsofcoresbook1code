#if !defined(SECOND_DERIV) && !defined(THIRD_DERIV)
C> \ingroup nwxc
C> @{
C>
C> \file nwxc_x_b88.F
C> The B88 exchange functional
C>
C> @}
#endif
C> \ingroup nwxc_priv
C> @{
C>
C> \brief Evaluate the B88 exchange functional
C>
C> Evaluate the non-local part of B88 hybrid-GGA [1]. 
C>
C> ### References ###
C>
C> [1] A.D. Becke,
C> "Density-functional exchange-energy approximation with correct
C> asymptotic behavior",
C> Phys. Rev. A <b>38</b>, 3098-3100 (1998), DOI:
C> <a href="http://dx.doi.org/10.1103/PhysRevA.38.3098">
C> 10.1103/PhysRevA.38.3098</a>.
C>
#if defined(FUJITSU_VPP)
!ocl scalar
#endif
#if !defined(SECOND_DERIV) && !defined(THIRD_DERIV)
      Subroutine nwxc_x_b88(tol_rho, ipol, nq, wght, rho, rgamma,
     &                      func, Amat, Cmat)
#elif defined(SECOND_DERIV) && !defined(THIRD_DERIV)
      Subroutine nwxc_x_b88_d2(tol_rho, ipol, nq, wght, rho,
     &                         rgamma, func, Amat, Amat2, Cmat, Cmat2)
#else
      Subroutine nwxc_x_b88_d3(tol_rho, ipol, nq, wght, rho, rgamma,
     &                         func, Amat, Amat2, Amat3,
     &                         Cmat, Cmat2, Cmat3)
#endif
c
C$Id: nwxc_x_b88.F 25513 2014-04-24 01:32:15Z d3y133 $
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
      double precision func(nq)    !< [Output] The value of the functional
      double precision Amat(nq,*)   !< [Output] The derivative wrt rho
      double precision Cmat(nq,*)   !< [Output] The derivative wrt rgamma
#if defined(SECOND_DERIV) || defined(THIRD_DERIV)
c
c     Sampling Matrices for the XC Kernel
c
      double precision Amat2(nq,*)  !< [Output] The 2nd derivative wrt rho
      double precision Cmat2(nq,*)  !< [Output] The 2nd derivative wrt rgamma
                                    !< and possibly rho
#endif
#if defined(THIRD_DERIV)
c
c     Sampling Matrices for the XC Kernel
c
      double precision Amat3(nq,*)  !< [Output] The 3rd derivative wrt rho
      double precision Cmat3(nq,*)  !< [Output] The 3rd derivative wrt rgamma
                                    !< and possibly rho
#endif
c
      double precision BETA
      Parameter (BETA = 0.0042D0)
c
c References:
c
c    Becke, Phys. Rev. A 38, 3098 (1988)
c    Johnson, Gill & Pople, J. Chem. Phys. 98, 5612 (1993)
c
c***************************************************************************
c
      integer n
      double precision arcsinh, darcsinh, d2arcsinh
      double precision C, rho13, rho43, gamma, x, g, gdenom, dg,
     &     dgdenom, t, gdenom2
#if defined(SECOND_DERIV) || defined(THIRD_DERIV)
      double precision rhom23, d2g, d2gdenom, gdenom3
#endif
#if defined(THIRD_DERIV)
      double precision rhom53, d3g, d3gdenom
      double precision gdenom4
#endif
c
      arcsinh(x)=log(x+dsqrt(1d0+x*x))
      darcsinh(x)=1d0/dsqrt(1d0+x*x)
      d2arcsinh(x) = -x/dsqrt(1d0+x*x)**3
c
c     Uniform electron gas constant
c
      C = -(1.5d0)*(0.75d0/acos(-1d0))**(1d0/3d0)
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
            rho13 = (0.5d0*rho(n,R_T))**(1.d0/3.d0)
            rho43 = rho13**4 
            gamma = rgamma(n,G_TT)
            if (dsqrt(gamma).gt.tol_rho)then
               gamma = 0.25d0 * gamma
               x = dsqrt(gamma) / rho43
            else
               x = 0d0
            endif
c
            gdenom = 1d0 + 6d0*BETA*x*arcsinh(x)
            gdenom2 = gdenom*gdenom
            g = -BETA*x*x / gdenom
            dgdenom = 6d0*BETA*(arcsinh(x) + x*darcsinh(x))
            dg = BETA*x*(x*dgdenom - 2d0*gdenom) / gdenom2
c
c           if (lfac) then
c              Ex = Ex + 2d0*rho43*C*qwght(n)*fac
c              if(ldew)func(n) = func(n) + 2.d0*rho43*C*fac
c              Amat(n,1) = Amat(n,1) + (4d0/3d0)*rho13*C*fac
c           endif
c
c           if (nlfac) then
c              Ex = Ex + 2d0*rho43*g*qwght(n)*fac
               func(n) = func(n) + 2.d0*rho43*g*wght
               Amat(n,D1_RA) = Amat(n,D1_RA)
     &                       + (4d0/3d0)*rho13*(g-x*dg)*wght
c           endif
c
            if (x.gt.tol_rho) then
               t = 0.5d0 * dg / sqrt(gamma) * wght
               Cmat(n,D1_GAA) = Cmat(n,D1_GAA) + t
            endif
c
#if defined(SECOND_DERIV) || defined(THIRD_DERIV)
c           if(lfac) g = g + C           ! Add local contribution back to g
            rhom23 = rho13 / (0.5d0*rho(n,R_T))
            d2gdenom = 6d0*BETA*darcsinh(x)*(2d0 - x*x/(x*x+1d0))
            gdenom3 = gdenom2*gdenom
            d2g = -2d0*BETA/gdenom + 4d0*BETA*x*dgdenom/gdenom2
     &           + BETA*x*x*d2gdenom/gdenom2
     &           - 2d0*BETA*x*x*(dgdenom)**2/gdenom**3
c
            Amat2(n,D2_RA_RA) = Amat2(n,D2_RA_RA)
     &           + (4d0/9d0)*rhom23*(g-x*dg+4d0*x*x*d2g)*wght
            Cmat2(n,D2_RA_GAA) = Cmat2(n,D2_RA_GAA)
     &           - (4d0/3d0)*(rhom23**2/rho(n,R_T))*d2g*wght
            if (x.gt.tol_rho) then
               Cmat2(n,D2_GAA_GAA) = Cmat2(n,D2_GAA_GAA)
     &              - 0.25d0*gamma**(-1.5d0)*(dg-x*d2g)*wght
            endif
#endif
#if defined(THIRD_DERIV)
            rhom53 = rhom23 / (0.5d0*rho(n,R_T))
c
            d3gdenom = 6.0d0*BETA*
     1          d2arcsinh(x)*( 3.0d0
     2                       - (2.0d0*x*x - 1.0d0)/(1.0d0 + x*x))
c
            gdenom4 = gdenom3*gdenom
c
            d3g = 6.0d0*BETA*dgdenom/gdenom2
     1          - 12.0d0*BETA*x*dgdenom*dgdenom/gdenom3
     2          + 6.0d0*BETA*x*d2gdenom/gdenom2
     3          + 6.0d0*BETA*x*x*dgdenom*dgdenom*dgdenom/gdenom4
     4          - 6.0d0*BETA*x*x*dgdenom*d2gdenom/gdenom3
     5          + BETA*x*x*d3gdenom/gdenom2
c
            Amat3(n,D3_RA_RA_RA) = Amat3(n,D3_RA_RA_RA)
     1           + (8.0d0/27.0d0)*rhom53*(-g + x*dg
     2                                   - 18.0d0*x*x*d2g
     3                                   - 8.0d0*x*x*x*d3g)*wght
c
            Cmat3(n,D3_RA_RA_GAA) = Cmat3(n,D3_RA_RA_GAA)
     1           + (2.0d0/9.0d0)*(rhom23/gamma)*( 7.0d0*x*x*d2g
     2                                          + 4.0d0*x*x*x*d3g)*wght
c
            Cmat3(n,D3_RA_GAA_GAA) = Cmat3(n,D3_RA_GAA_GAA)
     1           - (8.0d0/3.0d0)*(rhom23/rho(n,1)**3)/dsqrt(gamma)
     2             *d3g*wght
c
            if (x.gt.tol_rho) then
              Cmat3(n,D3_GAA_GAA_GAA) = Cmat3(n,D3_GAA_GAA_GAA)
     1             + (1.0d0/8.0d0)*gamma**(-2.5d0)*( 3.0d0*dg
     2                                             - 3.0d0*x*d2g
     3                                             + x*x*d3g)*wght
            endif
#endif
c
 10      continue
c
      else
c
c        ======> SPIN-UNRESTRICTED <======
c
         do 20 n = 1, nq
c           if (rho(n,1).lt.tol_rho) goto 20
            if (rho(n,R_A).lt.0.5d0*tol_rho) goto 25
c
c           Spin alpha:
c
            rho13 = rho(n,R_A)**(1.d0/3.d0)
            rho43 = rho13*rho(n,R_A)
            gamma = rgamma(n,G_AA)
            if (dsqrt(gamma).gt.tol_rho)then
               x = dsqrt(gamma) / rho43
            else
               x = 0d0
            endif
c
            gdenom = 1d0 + 6d0*BETA*x*arcsinh(x)
            g = -BETA*x*x / gdenom
            dgdenom = 6d0*BETA*(arcsinh(x) + x*darcsinh(x))
            gdenom2 = gdenom*gdenom
            dg = BETA*x*(x*dgdenom - 2d0*gdenom) / gdenom**2
c
c           if (lfac) then
c              Ex = Ex + rho43*C*qwght(n)*fac
c              if (ldew)func(n) = func(n) + rho43*C*fac
c              Amat(n,1) = Amat(n,1) + (4d0/3d0)*rho13*C*fac
c           endif
c
c           if (nlfac) then
c              Ex = Ex + rho43*g*qwght(n)*fac
               func(n) = func(n) + rho43*g*wght
               Amat(n,D1_RA) = Amat(n,D1_RA) 
     &                       + (4d0/3d0)*rho13*(g-x*dg)*wght
c           endif
c
            if (x.gt.tol_rho) then
               t = dg / sqrt(gamma) * wght
               Cmat(n,D1_GAA) = Cmat(n,D1_GAA) + t * 0.5d0
c               Cmat(n,1,1) = Cmat(n,1,1) + t*delrho(n,1,1)
c               Cmat(n,2,1) = Cmat(n,2,1) + t*delrho(n,2,1)
c               Cmat(n,3,1) = Cmat(n,3,1) + t*delrho(n,3,1)
            endif
c
#if defined(SECOND_DERIV) || defined(THIRD_DERIV)
c           if (lfac) g = g + C           ! Add local contribution back to g
            rhom23 = rho13 / rho(n,R_A)
            d2gdenom = 6d0*BETA*darcsinh(x)*(2d0 - x*x/(x*x+1d0))
            gdenom3 = gdenom2*gdenom
            d2g = -2d0*BETA/gdenom + 4d0*BETA*x*dgdenom/gdenom2
     &           + BETA*x*x*d2gdenom/gdenom2
     &           - 2d0*BETA*x*x*(dgdenom)**2/gdenom**3
c
            Amat2(n,D2_RA_RA) = Amat2(n,D2_RA_RA)
     &           + (4d0/9d0)*rhom23*(g-x*dg+4d0*x*x*d2g)*wght
            Cmat2(n,D2_RA_GAA) = Cmat2(n,D2_RA_GAA)
     &           - (2d0/3d0)*(rhom23**2/rho(n,R_A))*d2g*wght
            if (x.gt.tol_rho) then
               Cmat2(n,D2_GAA_GAA) = Cmat2(n,D2_GAA_GAA)
     &              - 0.25d0*gamma**(-1.5d0)*(dg-x*d2g)*wght
            endif
#endif
#ifdef THIRD_DERIV
            rhom53 = rhom23 / rho(n,R_A)
            d3gdenom = 6.0d0*BETA*
     1          d2arcsinh(x)*( 3.0d0
     2                       - (2.0d0*x*x - 1.0d0)/(1.0d0 + x*x))
            gdenom4 = gdenom3*gdenom
            d3g = 6.0d0*BETA*dgdenom/gdenom2
     1          - 12.0d0*BETA*x*dgdenom*dgdenom/gdenom3
     2          + 6.0d0*BETA*x*d2gdenom/gdenom2
     3          + 6.0d0*BETA*x*x*dgdenom*dgdenom*dgdenom/gdenom4
     4          - 6.0d0*BETA*x*x*dgdenom*d2gdenom/gdenom3
     5          + BETA*x*x*d3gdenom/gdenom2
c
            Amat3(n,D3_RA_RA_RA) = Amat3(n,D3_RA_RA_RA)
     1           + (8.0d0/27.0d0)*rhom53*(-g + x*dg
     2                                   - 18.0d0*x*x*d2g
     3                                   - 8.0d0*x*x*x*d3g)*wght
c
            Cmat3(n,D3_RA_RA_GAA) = Cmat3(n,D3_RA_RA_GAA)
     1           + (2.0d0/9.0d0)*(rhom23/gamma)*( 7.0d0*x*x*d2g
     2                                          + 4.0d0*x*x*x*d3g)*wght
c
            Cmat3(n,D3_RA_GAA_GAA) = Cmat3(n,D3_RA_GAA_GAA)
     1           - (1.0d0/3.0d0)*(rhom23/rho(n,2)**3)/dsqrt(gamma)
     2             *d3g*wght
c
            if (x.gt.tol_rho) then
              Cmat3(n,D3_GAA_GAA_GAA) = Cmat3(n,D3_GAA_GAA_GAA)
     1             + (1.0d0/8.0d0)*gamma**(-2.5d0)*( 3.0d0*dg
     2                                             - 3.0d0*x*d2g
     3                                             + x*x*d3g)*wght
            endif
#endif
c
 25         continue
c
c           Spin beta:
c
            if (rho(n,R_B).lt.0.5d0*tol_rho) goto 20
c
            rho13 = rho(n,R_B)**(1.d0/3.d0)
            rho43 = rho13*rho(n,R_B)
            gamma = rgamma(n,G_BB)
            if (dsqrt(gamma).gt.tol_rho)then
               x = dsqrt(gamma) / rho43
            else
               x = 0d0
            endif
c
            gdenom = 1d0 + 6d0*BETA*x*arcsinh(x)
            g = -BETA*x*x / gdenom
            dgdenom = 6d0*BETA*(arcsinh(x) + x*darcsinh(x))
            gdenom2 = gdenom*gdenom
            dg = BETA*x*(x*dgdenom - 2d0*gdenom) / gdenom2
c
c           if (lfac) then
c              Ex = Ex + rho43*C*qwght(n)*fac
c              if (ldew)func(n) = func(n) + rho43*C*fac
c              Amat(n,2) = Amat(n,2) + (4d0/3d0)*rho13*C*fac
c           endif
c
c           if (nlfac) then
c              Ex = Ex + rho43*g*qwght(n)*fac
               func(n) = func(n) +rho43*g*wght
               Amat(n,D1_RB) = Amat(n,D1_RB)
     &                       + (4d0/3d0)*rho13*(g-x*dg)*wght
c           endif
c
            if (x.gt.tol_rho) then
               t = dg / sqrt(gamma) * wght
               Cmat(n,D1_GBB) = Cmat(n,D1_GBB) + t * 0.5d0
c               Cmat(n,1,2) = Cmat(n,1,2) + t*delrho(n,1,2)
c               Cmat(n,2,2) = Cmat(n,2,2) + t*delrho(n,2,2)
c               Cmat(n,3,2) = Cmat(n,3,2) + t*delrho(n,3,2)
            endif
c
#if defined(SECOND_DERIV) || defined(THIRD_DERIV)
c           if(lfac) g = g + C           ! Add local contribution back to g
            rhom23 = rho13 / rho(n,R_B)
            d2gdenom = 6d0*BETA*darcsinh(x)*(2d0 - x*x/(x*x+1d0))
            gdenom3 = gdenom2*gdenom
            d2g = -2d0*BETA/gdenom + 4d0*BETA*x*dgdenom/gdenom2
     &           + BETA*x*x*d2gdenom/gdenom2
     &           - 2d0*BETA*x*x*(dgdenom)**2/gdenom**3
c
            Amat2(n,D2_RB_RB) = Amat2(n,D2_RB_RB)
     &           + (4d0/9d0)*rhom23*(g-x*dg+4d0*x*x*d2g)*wght
            Cmat2(n,D2_RB_GBB) = Cmat2(n,D2_RB_GBB)
     &           - (2d0/3d0)*(rhom23**2/rho(n,R_B))*d2g*wght
            if (x.gt.tol_rho) then
               Cmat2(n,D2_GBB_GBB) = Cmat2(n,D2_GBB_GBB)
     &              - 0.25d0*gamma**(-1.5d0)*(dg-x*d2g)*wght
            endif
#endif
#if defined(THIRD_DERIV)
            rhom53 = rhom23 / rho(n,R_B)
c
            d3gdenom = 6.0d0*BETA*
     1          d2arcsinh(x)*( 3.0d0
     2                       - (2.0d0*x*x - 1.0d0)/(1.0d0 + x*x))
c
            gdenom4 = gdenom3*gdenom
c
            d3g = 6.0d0*BETA*dgdenom/gdenom2
     1          - 12.0d0*BETA*x*dgdenom*dgdenom/gdenom3
     2          + 6.0d0*BETA*x*d2gdenom/gdenom2
     3          + 6.0d0*BETA*x*x*dgdenom*dgdenom*dgdenom/gdenom4
     4          - 6.0d0*BETA*x*x*dgdenom*d2gdenom/gdenom3
     5          + BETA*x*x*d3gdenom/gdenom2
c
            Amat3(n,D3_RB_RB_RB) = Amat3(n,D3_RB_RB_RB)
     1           + (8.0d0/27.0d0)*rhom53*(-g + x*dg
     2                                   - 18.0d0*x*x*d2g
     3                                   - 8.0d0*x*x*x*d3g)*wght
c
            Cmat3(n,D3_RB_RB_GBB) = Cmat3(n,D3_RB_RB_GBB)
     1           + (2.0d0/9.0d0)*(rhom23/gamma)*( 7.0d0*x*x*d2g
     2                                          + 4.0d0*x*x*x*d3g)*wght
c
            Cmat3(n,D3_RB_GBB_GBB) = Cmat3(n,D3_RB_GBB_GBB)
     1           - (1.0d0/3.0d0)*(rhom23/rho(n,3)**3)/dsqrt(gamma)
     2             *d3g*wght
c
            if (x.gt.tol_rho) then
              Cmat3(n,D3_GBB_GBB_GBB) = Cmat3(n,D3_GBB_GBB_GBB)
     1             + (1.0d0/8.0d0)*gamma**(-2.5d0)*( 3.0d0*dg
     2                                             - 3.0d0*x*d2g
     3                                             + x*x*d3g)*wght
            endif
#endif
c
 20      continue
c
      endif
c
      return
      end
#if !defined(SECOND_DERIV) 
#define SECOND_DERIV
c
c     Compile source again for the 2nd derivative case
c
#include "nwxc_x_b88.F"
#endif
#if !defined(THIRD_DERIV) 
#define THIRD_DERIV
c
c     Compile source again for the 3rd derivative case
c
#include "nwxc_x_b88.F"
#endif
C>
C> @}
