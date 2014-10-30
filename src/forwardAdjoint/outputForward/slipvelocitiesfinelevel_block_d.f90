   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of slipvelocitiesfinelevel_block in forward (tangent) mode (with options i4 dr8 r8):
   !   variations   of useful results: *(*bcdata.uslip)
   !   with respect to varying inputs: gammainf pinf timeref rhoinf
   !                *x veldirfreestream machgrid
   !   Plus diff mem management of: x:in bcdata:in *bcdata.uslip:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          slipVelocities.f90                              *
   !      * Author:        Edwin van der Weide                             *
   !      * Starting date: 02-12-2004                                      *
   !      * Last modified: 06-28-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE SLIPVELOCITIESFINELEVEL_BLOCK_D(useoldcoor, t, sps)
   !
   !      ******************************************************************
   !      *                                                                *
   !      * slipVelocitiesFineLevel computes the slip velocities for       *
   !      * viscous subfaces on all viscous boundaries on groundLevel for  *
   !      * the given spectral solution. If useOldCoor is .true. the       *
   !      * velocities are determined using the unsteady time integrator;  *
   !      * otherwise the analytic form is used.                           *
   !      *                                                                *
   !      ******************************************************************
   !
   USE BCTYPES
   USE INPUTTIMESPECTRAL
   USE BLOCKPOINTERS_D
   USE CGNSGRID
   USE FLOWVARREFSTATE
   USE INPUTMOTION
   USE INPUTUNSTEADY
   USE ITERATION
   USE INPUTPHYSICS
   USE INPUTTSSTABDERIV
   USE MONITOR
   USE COMMUNICATION
   USE DIFFSIZES
   !  Hint: ISIZE1OFDrfbcdata should be the size of dimension 1 of array *bcdata
   IMPLICIT NONE
   !
   !      Subroutine arguments.
   !
   INTEGER(kind=inttype), INTENT(IN) :: sps
   LOGICAL, INTENT(IN) :: useoldcoor
   REAL(kind=realtype), DIMENSION(*), INTENT(IN) :: t
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: nn, mm, i, j, level
   REAL(kind=realtype) :: oneover4dt
   REAL(kind=realtype) :: oneover4dtd
   REAL(kind=realtype) :: velxgrid, velygrid, velzgrid, ainf
   REAL(kind=realtype) :: velxgridd, velygridd, velzgridd, ainfd
   REAL(kind=realtype) :: velxgrid0, velygrid0, velzgrid0
   REAL(kind=realtype) :: velxgrid0d, velygrid0d, velzgrid0d
   REAL(kind=realtype), DIMENSION(3) :: xc, xxc
   REAL(kind=realtype), DIMENSION(3) :: xcd, xxcd
   REAL(kind=realtype), DIMENSION(3) :: rotcenter, rotrate
   REAL(kind=realtype), DIMENSION(3) :: rotrated
   REAL(kind=realtype), DIMENSION(3) :: rotationpoint
   REAL(kind=realtype), DIMENSION(3, 3) :: rotationmatrix, &
   & derivrotationmatrix
   REAL(kind=realtype), DIMENSION(3, 3) :: derivrotationmatrixd
   REAL(kind=realtype) :: tnew, told
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: uslip
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: uslipd
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: xface
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: xfaced
   REAL(kind=realtype), DIMENSION(:, :, :, :), POINTER :: xfaceold
   INTEGER(kind=inttype) :: liftindex
   REAL(kind=realtype) :: alpha, beta, intervalmach, alphats, &
   & alphaincrement, betats, betaincrement
   REAL(kind=realtype) :: alphad, betad, alphatsd, betatsd
   REAL(kind=realtype), DIMENSION(3) :: veldir
   REAL(kind=realtype), DIMENSION(3) :: veldird
   REAL(kind=realtype), DIMENSION(3) :: refdirection
   !Function Definitions
   REAL(kind=realtype) :: TSALPHA, TSBETA, TSMACH
   INTRINSIC SQRT
   REAL(kind=realtype) :: arg1
   REAL(kind=realtype) :: arg1d
   INTEGER :: ii1
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Determine the situation we are having here.
   IF (useoldcoor) THEN
   ! The velocities must be determined via a finite difference
   ! formula using the coordinates of the old levels.
   ! Set the coefficients for the time integrator and store the
   ! inverse of the physical nonDimensional time step, divided
   ! by 4, a bit easier.
   CALL SETCOEFTIMEINTEGRATOR()
   oneover4dtd = fourth*timerefd/deltat
   oneover4dt = fourth*timeref/deltat
   DO ii1=1,ISIZE1OFDrfbcdata
   bcdatad(ii1)%uslip = 0.0_8
   END DO
   xcd = 0.0_8
   ! Loop over the number of viscous subfaces.
   bocoloop1:DO mm=1,nviscbocos
   ! Set the pointer for uSlip to make the code more
   ! readable.
   uslipd => bcdatad(mm)%uslip
   uslip => bcdata(mm)%uslip
   ! Determine the grid face on which the subface is located
   ! and set some variables accordingly.
   SELECT CASE  (bcfaceid(mm)) 
   CASE (imin) 
   xfaced => xd(1, :, :, :)
   xface => x(1, :, :, :)
   xfaceold => xold(:, 1, :, :, :)
   CASE (imax) 
   xfaced => xd(il, :, :, :)
   xface => x(il, :, :, :)
   xfaceold => xold(:, il, :, :, :)
   CASE (jmin) 
   xfaced => xd(:, 1, :, :)
   xface => x(:, 1, :, :)
   xfaceold => xold(:, :, 1, :, :)
   CASE (jmax) 
   xfaced => xd(:, jl, :, :)
   xface => x(:, jl, :, :)
   xfaceold => xold(:, :, jl, :, :)
   CASE (kmin) 
   xfaced => xd(:, :, 1, :)
   xface => x(:, :, 1, :)
   xfaceold => xold(:, :, :, 1, :)
   CASE (kmax) 
   xfaced => xd(:, :, kl, :)
   xface => x(:, :, kl, :)
   xfaceold => xold(:, :, :, kl, :)
   END SELECT
   ! Some boundary faces have a different rotation speed than
   ! the corresponding block. This happens e.g. in the tip gap
   ! region of turboMachinary problems where the casing does
   ! not rotate. As the coordinate difference corresponds to
   ! the rotation rate of the block, a correction must be
   ! computed. Therefore compute the difference in rotation
   ! rate and store the rotation center a bit easier. Note that
   ! the rotation center of subface is taken, because if there
   ! is a difference in rotation rate this info for the subface
   ! must always be specified.
   j = nbkglobal
   i = cgnssubface(mm)
   rotcenter = cgnsdoms(j)%bocoinfo(i)%rotcenter
   rotrated = (cgnsdoms(j)%bocoinfo(i)%rotrate-cgnsdoms(j)%rotrate)*&
   &       timerefd
   rotrate = timeref*(cgnsdoms(j)%bocoinfo(i)%rotrate-cgnsdoms(j)%&
   &       rotrate)
   ! Loop over the quadrilateral faces of the viscous subface.
   ! Note that due to the usage of the pointers xFace and
   ! xFaceOld an offset of +1 must be used in the coordinate
   ! arrays, because x and xOld originally start at 0 for the
   ! i, j and k indices.
   DO j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
   DO i=bcdata(mm)%icbeg,bcdata(mm)%icend
   ! Determine the coordinates of the centroid of the
   ! face, multiplied by 4.
   xcd(1) = xfaced(i+1, j+1, 1) + xfaced(i+1, j, 1) + xfaced(i, j&
   &           +1, 1) + xfaced(i, j, 1)
   xc(1) = xface(i+1, j+1, 1) + xface(i+1, j, 1) + xface(i, j+1, &
   &           1) + xface(i, j, 1)
   xcd(2) = xfaced(i+1, j+1, 2) + xfaced(i+1, j, 2) + xfaced(i, j&
   &           +1, 2) + xfaced(i, j, 2)
   xc(2) = xface(i+1, j+1, 2) + xface(i+1, j, 2) + xface(i, j+1, &
   &           2) + xface(i, j, 2)
   xcd(3) = xfaced(i+1, j+1, 3) + xfaced(i+1, j, 3) + xfaced(i, j&
   &           +1, 3) + xfaced(i, j, 3)
   xc(3) = xface(i+1, j+1, 3) + xface(i+1, j, 3) + xface(i, j+1, &
   &           3) + xface(i, j, 3)
   ! Multiply the sum of the 4 vertex coordinates with
   ! coefTime(0) to obtain the contribution for the
   ! current time level. The division by 4*deltaT will
   ! take place later. This is both more efficient and
   ! more accurate for extremely small time steps.
   uslipd(i, j, 1) = coeftime(0)*xcd(1)
   uslip(i, j, 1) = coeftime(0)*xc(1)
   uslipd(i, j, 2) = coeftime(0)*xcd(2)
   uslip(i, j, 2) = coeftime(0)*xc(2)
   uslipd(i, j, 3) = coeftime(0)*xcd(3)
   uslip(i, j, 3) = coeftime(0)*xc(3)
   ! Loop over the older time levels and take their
   ! contribution into account.
   DO level=1,noldlevels
   uslip(i, j, 1) = uslip(i, j, 1) + coeftime(level)*(xfaceold(&
   &             level, i+1, j+1, 1)+xfaceold(level, i+1, j, 1)+xfaceold(&
   &             level, i, j+1, 1)+xfaceold(level, i, j, 1))
   uslip(i, j, 2) = uslip(i, j, 2) + coeftime(level)*(xfaceold(&
   &             level, i+1, j+1, 2)+xfaceold(level, i+1, j, 2)+xfaceold(&
   &             level, i, j+1, 2)+xfaceold(level, i, j, 2))
   uslip(i, j, 3) = uslip(i, j, 3) + coeftime(level)*(xfaceold(&
   &             level, i+1, j+1, 3)+xfaceold(level, i+1, j, 3)+xfaceold(&
   &             level, i, j+1, 3)+xfaceold(level, i, j, 3))
   END DO
   ! Divide by 4 times the time step to obtain the
   ! correct velocity.
   uslipd(i, j, 1) = uslipd(i, j, 1)*oneover4dt + uslip(i, j, 1)*&
   &           oneover4dtd
   uslip(i, j, 1) = uslip(i, j, 1)*oneover4dt
   uslipd(i, j, 2) = uslipd(i, j, 2)*oneover4dt + uslip(i, j, 2)*&
   &           oneover4dtd
   uslip(i, j, 2) = uslip(i, j, 2)*oneover4dt
   uslipd(i, j, 3) = uslipd(i, j, 3)*oneover4dt + uslip(i, j, 3)*&
   &           oneover4dtd
   uslip(i, j, 3) = uslip(i, j, 3)*oneover4dt
   ! Determine the correction due to the difference
   ! in rotation rate between the block and subface.
   ! First determine the coordinates relative to the
   ! rotation center. Remember that 4 times this value
   ! is currently stored in xc.
   xcd(1) = fourth*xcd(1)
   xc(1) = fourth*xc(1) - rotcenter(1)
   xcd(2) = fourth*xcd(2)
   xc(2) = fourth*xc(2) - rotcenter(2)
   xcd(3) = fourth*xcd(3)
   xc(3) = fourth*xc(3) - rotcenter(3)
   ! Compute the velocity, which is the cross product
   ! of rotRate and xc and add it to uSlip.
   uslipd(i, j, 1) = uslipd(i, j, 1) + rotrated(2)*xc(3) + &
   &           rotrate(2)*xcd(3) - rotrated(3)*xc(2) - rotrate(3)*xcd(2)
   uslip(i, j, 1) = uslip(i, j, 1) + rotrate(2)*xc(3) - rotrate(3&
   &           )*xc(2)
   uslipd(i, j, 2) = uslipd(i, j, 2) + rotrated(3)*xc(1) + &
   &           rotrate(3)*xcd(1) - rotrated(1)*xc(3) - rotrate(1)*xcd(3)
   uslip(i, j, 2) = uslip(i, j, 2) + rotrate(3)*xc(1) - rotrate(1&
   &           )*xc(3)
   uslipd(i, j, 3) = uslipd(i, j, 3) + rotrated(1)*xc(2) + &
   &           rotrate(1)*xcd(2) - rotrated(2)*xc(1) - rotrate(2)*xcd(1)
   uslip(i, j, 3) = uslip(i, j, 3) + rotrate(1)*xc(2) - rotrate(2&
   &           )*xc(1)
   END DO
   END DO
   END DO bocoloop1
   ELSE
   ! The velocities must be determined analytically.
   ! Compute the mesh velocity from the given mesh Mach number.
   !  aInf = sqrt(gammaInf*pInf/rhoInf)
   !  velxGrid = aInf*MachGrid(1)
   !  velyGrid = aInf*MachGrid(2)
   !  velzGrid = aInf*MachGrid(3)
   arg1d = ((gammainfd*pinf+gammainf*pinfd)*rhoinf-gammainf*pinf*&
   &     rhoinfd)/rhoinf**2
   arg1 = gammainf*pinf/rhoinf
   IF (arg1 .EQ. 0.0_8) THEN
   ainfd = 0.0_8
   ELSE
   ainfd = arg1d/(2.0*SQRT(arg1))
   END IF
   ainf = SQRT(arg1)
   velxgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldirfreestream(1)) &
   &     - ainf*machgrid*veldirfreestreamd(1)
   velxgrid0 = ainf*machgrid*(-veldirfreestream(1))
   velygrid0d = -((ainfd*machgrid+ainf*machgridd)*veldirfreestream(2)) &
   &     - ainf*machgrid*veldirfreestreamd(2)
   velygrid0 = ainf*machgrid*(-veldirfreestream(2))
   velzgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldirfreestream(3)) &
   &     - ainf*machgrid*veldirfreestreamd(3)
   velzgrid0 = ainf*machgrid*(-veldirfreestream(3))
   ! Compute the derivative of the rotation matrix and the rotation
   ! point; needed for velocity due to the rigid body rotation of
   ! the entire grid. It is assumed that the rigid body motion of
   ! the grid is only specified if there is only 1 section present.
   CALL DERIVATIVEROTMATRIXRIGID_D(derivrotationmatrix, &
   &                             derivrotationmatrixd, rotationpoint, t(1))
   !compute the rotation matrix to update the velocities for the time
   !spectral stability derivative case...
   IF (tsstability) THEN
   ! Determine the time values of the old and new time level.
   ! It is assumed that the rigid body rotation of the mesh is only
   ! used when only 1 section is present.
   tnew = timeunsteady + timeunsteadyrestart
   told = tnew - t(1)
   IF ((tspmode .OR. tsqmode) .OR. tsrmode) THEN
   ! Compute the rotation matrix of the rigid body rotation as
   ! well as the rotation point; the latter may vary in time due
   ! to rigid body translation.
   CALL ROTMATRIXRIGIDBODY(tnew, told, rotationmatrix, &
   &                            rotationpoint)
   velxgrid0d = rotationmatrix(1, 1)*velxgrid0d + rotationmatrix(1&
   &         , 2)*velygrid0d + rotationmatrix(1, 3)*velzgrid0d
   velxgrid0 = rotationmatrix(1, 1)*velxgrid0 + rotationmatrix(1, 2&
   &         )*velygrid0 + rotationmatrix(1, 3)*velzgrid0
   velygrid0d = rotationmatrix(2, 1)*velxgrid0d + rotationmatrix(2&
   &         , 2)*velygrid0d + rotationmatrix(2, 3)*velzgrid0d
   velygrid0 = rotationmatrix(2, 1)*velxgrid0 + rotationmatrix(2, 2&
   &         )*velygrid0 + rotationmatrix(2, 3)*velzgrid0
   velzgrid0d = rotationmatrix(3, 1)*velxgrid0d + rotationmatrix(3&
   &         , 2)*velygrid0d + rotationmatrix(3, 3)*velzgrid0d
   velzgrid0 = rotationmatrix(3, 1)*velxgrid0 + rotationmatrix(3, 2&
   &         )*velygrid0 + rotationmatrix(3, 3)*velzgrid0
   DO ii1=1,ISIZE1OFDrfbcdata
   bcdatad(ii1)%uslip = 0.0_8
   END DO
   xcd = 0.0_8
   xxcd = 0.0_8
   ELSE IF (tsalphamode) THEN
   ! get the baseline alpha and determine the liftIndex
   CALL GETDIRANGLE_D(veldirfreestream, veldirfreestreamd, &
   &                    liftdirection, liftindex, alpha, alphad, beta, &
   &                    betad)
   !Determine the alpha for this time instance
   alphaincrement = TSALPHA(degreepolalpha, coefpolalpha, &
   &         degreefouralpha, omegafouralpha, coscoeffouralpha, &
   &         sincoeffouralpha, t(1))
   alphatsd = alphad
   alphats = alpha + alphaincrement
   !Determine the grid velocity for this alpha
   refdirection(:) = zero
   refdirection(1) = one
   CALL GETDIRVECTOR_D(refdirection, alphats, alphatsd, beta, betad&
   &                     , veldir, veldird, liftindex)
   !do I need to update the lift direction and drag direction as well?
   !set the effictive grid velocity for this time interval
   velxgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(1)) - ainf&
   &         *machgrid*veldird(1)
   velxgrid0 = ainf*machgrid*(-veldir(1))
   velygrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(2)) - ainf&
   &         *machgrid*veldird(2)
   velygrid0 = ainf*machgrid*(-veldir(2))
   velzgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(3)) - ainf&
   &         *machgrid*veldird(3)
   velzgrid0 = ainf*machgrid*(-veldir(3))
   DO ii1=1,ISIZE1OFDrfbcdata
   bcdatad(ii1)%uslip = 0.0_8
   END DO
   xcd = 0.0_8
   xxcd = 0.0_8
   ELSE IF (tsbetamode) THEN
   ! get the baseline alpha and determine the liftIndex
   CALL GETDIRANGLE_D(veldirfreestream, veldirfreestreamd, &
   &                    liftdirection, liftindex, alpha, alphad, beta, &
   &                    betad)
   !Determine the alpha for this time instance
   betaincrement = TSBETA(degreepolbeta, coefpolbeta, &
   &         degreefourbeta, omegafourbeta, coscoeffourbeta, &
   &         sincoeffourbeta, t(1))
   betatsd = betad
   betats = beta + betaincrement
   !Determine the grid velocity for this alpha
   refdirection(:) = zero
   refdirection(1) = one
   CALL GETDIRVECTOR_D(refdirection, alpha, alphad, betats, betatsd&
   &                     , veldir, veldird, liftindex)
   !do I need to update the lift direction and drag direction as well?
   !set the effictive grid velocity for this time interval
   velxgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(1)) - ainf&
   &         *machgrid*veldird(1)
   velxgrid0 = ainf*machgrid*(-veldir(1))
   velygrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(2)) - ainf&
   &         *machgrid*veldird(2)
   velygrid0 = ainf*machgrid*(-veldir(2))
   velzgrid0d = -((ainfd*machgrid+ainf*machgridd)*veldir(3)) - ainf&
   &         *machgrid*veldird(3)
   velzgrid0 = ainf*machgrid*(-veldir(3))
   DO ii1=1,ISIZE1OFDrfbcdata
   bcdatad(ii1)%uslip = 0.0_8
   END DO
   xcd = 0.0_8
   xxcd = 0.0_8
   ELSE IF (tsmachmode) THEN
   !determine the mach number at this time interval
   intervalmach = TSMACH(degreepolmach, coefpolmach, &
   &         degreefourmach, omegafourmach, coscoeffourmach, &
   &         sincoeffourmach, t(1))
   !set the effective grid velocity
   velxgrid0d = -((ainfd*(intervalmach+machgrid)+ainf*machgridd)*&
   &         veldirfreestream(1)) - ainf*(intervalmach+machgrid)*&
   &         veldirfreestreamd(1)
   velxgrid0 = ainf*(intervalmach+machgrid)*(-veldirfreestream(1))
   velygrid0d = -((ainfd*(intervalmach+machgrid)+ainf*machgridd)*&
   &         veldirfreestream(2)) - ainf*(intervalmach+machgrid)*&
   &         veldirfreestreamd(2)
   velygrid0 = ainf*(intervalmach+machgrid)*(-veldirfreestream(2))
   velzgrid0d = -((ainfd*(intervalmach+machgrid)+ainf*machgridd)*&
   &         veldirfreestream(3)) - ainf*(intervalmach+machgrid)*&
   &         veldirfreestreamd(3)
   velzgrid0 = ainf*(intervalmach+machgrid)*(-veldirfreestream(3))
   DO ii1=1,ISIZE1OFDrfbcdata
   bcdatad(ii1)%uslip = 0.0_8
   END DO
   xcd = 0.0_8
   xxcd = 0.0_8
   ELSE IF (tsaltitudemode) THEN
   CALL TERMINATE('gridVelocityFineLevel', &
   &                   'altitude motion not yet implemented...')
   DO ii1=1,ISIZE1OFDrfbcdata
   bcdatad(ii1)%uslip = 0.0_8
   END DO
   xcd = 0.0_8
   xxcd = 0.0_8
   ELSE
   CALL TERMINATE('gridVelocityFineLevel', &
   &                   'Not a recognized Stability Motion')
   DO ii1=1,ISIZE1OFDrfbcdata
   bcdatad(ii1)%uslip = 0.0_8
   END DO
   xcd = 0.0_8
   xxcd = 0.0_8
   END IF
   ELSE
   DO ii1=1,ISIZE1OFDrfbcdata
   bcdatad(ii1)%uslip = 0.0_8
   END DO
   xcd = 0.0_8
   xxcd = 0.0_8
   END IF
   ! Loop over the number of viscous subfaces.
   bocoloop2:DO mm=1,nviscbocos
   ! Determine the grid face on which the subface is located
   ! and set some variables accordingly.
   SELECT CASE  (bcfaceid(mm)) 
   CASE (imin) 
   xfaced => xd(1, :, :, :)
   xface => x(1, :, :, :)
   CASE (imax) 
   xfaced => xd(il, :, :, :)
   xface => x(il, :, :, :)
   CASE (jmin) 
   xfaced => xd(:, 1, :, :)
   xface => x(:, 1, :, :)
   CASE (jmax) 
   xfaced => xd(:, jl, :, :)
   xface => x(:, jl, :, :)
   CASE (kmin) 
   xfaced => xd(:, :, 1, :)
   xface => x(:, :, 1, :)
   CASE (kmax) 
   xfaced => xd(:, :, kl, :)
   xface => x(:, :, kl, :)
   END SELECT
   ! Store the rotation center and the rotation rate
   ! for this subface.
   j = nbkglobal
   i = cgnssubface(mm)
   rotcenter = cgnsdoms(j)%bocoinfo(i)%rotcenter
   rotrated = cgnsdoms(j)%bocoinfo(i)%rotrate*timerefd
   rotrate = timeref*cgnsdoms(j)%bocoinfo(i)%rotrate
   ! useWindAxis should go back here!
   velxgridd = velxgrid0d
   velxgrid = velxgrid0
   velygridd = velygrid0d
   velygrid = velygrid0
   velzgridd = velzgrid0d
   velzgrid = velzgrid0
   ! Loop over the quadrilateral faces of the viscous
   ! subface.
   DO j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
   DO i=bcdata(mm)%icbeg,bcdata(mm)%icend
   ! Compute the coordinates of the centroid of the face.
   ! Normally this would be an average of i-1 and i, but
   ! due to the usage of the pointer xFace and the fact
   ! that x starts at index 0 this is shifted 1 index.
   xcd(1) = fourth*(xfaced(i+1, j+1, 1)+xfaced(i+1, j, 1)+xfaced(&
   &           i, j+1, 1)+xfaced(i, j, 1))
   xc(1) = fourth*(xface(i+1, j+1, 1)+xface(i+1, j, 1)+xface(i, j&
   &           +1, 1)+xface(i, j, 1))
   xcd(2) = fourth*(xfaced(i+1, j+1, 2)+xfaced(i+1, j, 2)+xfaced(&
   &           i, j+1, 2)+xfaced(i, j, 2))
   xc(2) = fourth*(xface(i+1, j+1, 2)+xface(i+1, j, 2)+xface(i, j&
   &           +1, 2)+xface(i, j, 2))
   xcd(3) = fourth*(xfaced(i+1, j+1, 3)+xfaced(i+1, j, 3)+xfaced(&
   &           i, j+1, 3)+xfaced(i, j, 3))
   xc(3) = fourth*(xface(i+1, j+1, 3)+xface(i+1, j, 3)+xface(i, j&
   &           +1, 3)+xface(i, j, 3))
   ! Determine the coordinates relative to the center
   ! of rotation.
   xxcd(1) = xcd(1)
   xxc(1) = xc(1) - rotcenter(1)
   xxcd(2) = xcd(2)
   xxc(2) = xc(2) - rotcenter(2)
   xxcd(3) = xcd(3)
   xxc(3) = xc(3) - rotcenter(3)
   ! Compute the velocity, which is the cross product
   ! of rotRate and xc.
   bcdatad(mm)%uslip(i, j, 1) = rotrated(2)*xxc(3) + rotrate(2)*&
   &           xxcd(3) - rotrated(3)*xxc(2) - rotrate(3)*xxcd(2)
   bcdata(mm)%uslip(i, j, 1) = rotrate(2)*xxc(3) - rotrate(3)*xxc&
   &           (2)
   bcdatad(mm)%uslip(i, j, 2) = rotrated(3)*xxc(1) + rotrate(3)*&
   &           xxcd(1) - rotrated(1)*xxc(3) - rotrate(1)*xxcd(3)
   bcdata(mm)%uslip(i, j, 2) = rotrate(3)*xxc(1) - rotrate(1)*xxc&
   &           (3)
   bcdatad(mm)%uslip(i, j, 3) = rotrated(1)*xxc(2) + rotrate(1)*&
   &           xxcd(2) - rotrated(2)*xxc(1) - rotrate(2)*xxcd(1)
   bcdata(mm)%uslip(i, j, 3) = rotrate(1)*xxc(2) - rotrate(2)*xxc&
   &           (1)
   ! Determine the coordinates relative to the
   ! rigid body rotation point.
   xxcd(1) = xcd(1)
   xxc(1) = xc(1) - rotationpoint(1)
   xxcd(2) = xcd(2)
   xxc(2) = xc(2) - rotationpoint(2)
   xxcd(3) = xcd(3)
   xxc(3) = xc(3) - rotationpoint(3)
   ! Determine the total velocity of the cell center.
   ! This is a combination of rotation speed of this
   ! block and the entire rigid body rotation.
   bcdatad(mm)%uslip(i, j, 1) = bcdatad(mm)%uslip(i, j, 1) + &
   &           velxgridd + derivrotationmatrixd(1, 1)*xxc(1) + &
   &           derivrotationmatrix(1, 1)*xxcd(1) + derivrotationmatrixd(1, &
   &           2)*xxc(2) + derivrotationmatrix(1, 2)*xxcd(2) + &
   &           derivrotationmatrixd(1, 3)*xxc(3) + derivrotationmatrix(1, 3&
   &           )*xxcd(3)
   bcdata(mm)%uslip(i, j, 1) = bcdata(mm)%uslip(i, j, 1) + &
   &           velxgrid + derivrotationmatrix(1, 1)*xxc(1) + &
   &           derivrotationmatrix(1, 2)*xxc(2) + derivrotationmatrix(1, 3)&
   &           *xxc(3)
   bcdatad(mm)%uslip(i, j, 2) = bcdatad(mm)%uslip(i, j, 2) + &
   &           velygridd + derivrotationmatrixd(2, 1)*xxc(1) + &
   &           derivrotationmatrix(2, 1)*xxcd(1) + derivrotationmatrixd(2, &
   &           2)*xxc(2) + derivrotationmatrix(2, 2)*xxcd(2) + &
   &           derivrotationmatrixd(2, 3)*xxc(3) + derivrotationmatrix(2, 3&
   &           )*xxcd(3)
   bcdata(mm)%uslip(i, j, 2) = bcdata(mm)%uslip(i, j, 2) + &
   &           velygrid + derivrotationmatrix(2, 1)*xxc(1) + &
   &           derivrotationmatrix(2, 2)*xxc(2) + derivrotationmatrix(2, 3)&
   &           *xxc(3)
   bcdatad(mm)%uslip(i, j, 3) = bcdatad(mm)%uslip(i, j, 3) + &
   &           velzgridd + derivrotationmatrixd(3, 1)*xxc(1) + &
   &           derivrotationmatrix(3, 1)*xxcd(1) + derivrotationmatrixd(3, &
   &           2)*xxc(2) + derivrotationmatrix(3, 2)*xxcd(2) + &
   &           derivrotationmatrixd(3, 3)*xxc(3) + derivrotationmatrix(3, 3&
   &           )*xxcd(3)
   bcdata(mm)%uslip(i, j, 3) = bcdata(mm)%uslip(i, j, 3) + &
   &           velzgrid + derivrotationmatrix(3, 1)*xxc(1) + &
   &           derivrotationmatrix(3, 2)*xxc(2) + derivrotationmatrix(3, 3)&
   &           *xxc(3)
   END DO
   END DO
   END DO bocoloop2
   END IF
   END SUBROUTINE SLIPVELOCITIESFINELEVEL_BLOCK_D
