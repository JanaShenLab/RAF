export CUDA_VISIBLE_DEVICES=0
PMEMDMPI=pmemd.MPI
PMEMDCUDA=pmemd.cuda


########################################################
#  Important information                               #
# For REX minimization, heating, and only H atom equil #
########################################################

# Standard Variables
protein="$1"    # Name
cryph=7.0       # Crystal ph for heating and restraints on heavy atom equilibration
stage=1         # stage for production; if stage =1, do all steps; if stage > 1, only restart production step 
cutoff=12.0       # Use the same value as in system building and minimization

#########################
# minimization Specific #
#########################
maxcyc=500    # total number of minmization steps (SD+GC)
ncyc=200      # SD steps
mwfrq=100     # mdout write
mwrst=$maxcyc # rst7 write
mrestraint=100.0  # restraints on heavy atoms

####################
# Heating Specific #
####################
stemp=100         # Start temp for heating 
etemp=300        # End temp for heating 
hnsteps=100000    # 100 ps
hwfrq=1000        # How often to write ene. vel. temp. and lamb.
hwrst=100000       # How often to write restart files
hts=0.001        # Time step
hrestraint=100.0   # Restrataint for heating

##########################
# Equilibration Specific #
##########################
restraints_1=(100.0 10.0)   # Restraints on heavy atoms for equilibration
first_equil_stage=${#restraints_1[@]}
restraints_2=(10.0 1.0 0.1 0.0)   # Restraints on main chain heavy atoms for equilibration
ensteps=250000    # 250 ps for each of the three-stages
ewfrq=10000
ewrst=250000
ets=0.001

#########################################################################################################
################
# Minimization #
################
echo "
Minimization in Amber
&cntrl                                         ! cntrl is a name list, it stores all conrol parameters for amber
  imin = 1, maxcyc = $maxcyc, ncyc = $ncyc     ! Do minimization, max number of steps (Run both SD and Conjugate Gradient), first 200 steps are SD
  ntx = 1,                                     !  Read only coordinates
  ntwe = 0, ntwr = $mwrst, ntpr = $mwfrq,      ! Print frq for energy and temp to mden file, write frq for restart trj, print frq for energy to mdout 
  ntc = 1, ntf = 1, ntb = 1, ntp = 0,          ! Shake (1 = No Shake), Force Eval. (1 = complete interaction is calced), Use PBC (1 = const. vol.), Use Const. Press. (0 = no press. scaling)
  cut = $cutoff, fswitch = 10.0,               ! Nonbond cutoff (Ang.)
  ntr = 1, restraintmask = '!:WAT & !@H= & !:SOD & !:CLA', ! restraint atoms (1 = yes), Which atoms are restrained 
  restraint_wt = $mrestraint,                  ! Harmonic force to be applied as the restraint
  ioutfm = 1, ntxo = 2,                        ! Fomrat of coor. and vel. trj files, write NetCDF restrt fuile for final coor., vel., and box size
/
"> min.mdin
mpirun -np 6 $PMEMDMPI -O -i min.mdin -p $protein.prmtop -c $protein.inpcrd -o min.mdout -r mini.rst7 -x min.nc -ref $protein.inpcrd
wait

###########
# Heating #
###########
echo "heating
&cntrl
  imin = 0, nstlim = $hnsteps, dt = $hts,                         ! Don't Minimize, Number of steps, time step
  irest = 0, ntx = 1, ig = -1,                                    ! Read vel. (1 = input, 0 = no restart), (1 = start from min, 2 = start from md), random number seed 
  tempi = $stemp, temp0 = $etemp,                                 ! Initial temp., Target Temp. 
  ntc = 2, ntf = 2, tol = 0.00001,                                ! Shake (2 = bonds involving hydrogen), Force Eval. 
  ntwx = $hwfrq, ntwe = $hwfrq, ntwr = $hwrst, ntpr = $hwfrq,     ! Print info 
  cut=$cutoff, fswitch=10, iwrap=0,                               ! cutoff, no wrap
  ntt = 3, gamma_ln = 1.0, ntb = 1, ntp = 0,                      ! Choose temp. control (3 = langevin), Collision Frq,
  nscm = 0,                                                       ! Remove center of mass motion every nscm steps      
  ntr = 1, restraintmask = '!:WAT  & !@H= & !:SOD & !:CLA', restraint_wt = $hrestraint, ! All restraint options                    
  iphmd = 3, solvph = $cryph,                                     ! 2 = hybrid, pH, Implicent salt concentration
  nmropt = 1,                                                     ! Change thermostat with time 
  ioutfm = 1, ntxo = 2,                                           ! Output type 
 /
 &wt
   TYPE=\"TEMP0\", istep1 = 0, istep2 = $hnsteps,                 ! This section modulates the heatup rate 
   value1=$stemp, value2=$etemp,
/
&wt
  TYPE=\"END\",
/" > heating.mdin

$PMEMDCUDA -O -i heating.mdin -c mini.rst7 -p ${protein}.prmtop -ref mini.rst7 -phmdin phmdin_start -phmdparm /home/joec/examples/proteins/Parameters/ff14sb_pme.parm -phmdout heating.lambda -phmdrestrt heating.phmdrst -o /dev/null -r heating.rst7 -x heating.nc
wait

#################
# Equilibration #
#################

## Run equilibration; restratints on heavyatoms
for restn in `seq 1 ${#restraints_1[@]}` # loop over number of restarts
do
  echo "Stage $restn equilibration of asp
    &cntrl
    imin = 0, nstlim = $ensteps, dt = $ets,
    irest = 1, ntx = 5,ig = -1,
    temp0 = $etemp,
    ntc = 2, ntf = 2, tol = 0.00001,
    ntwx = $ewfrq, ntwe = 0, ntwr = $ewrst, ntpr = $ewfrq,
    cut = $cutoff, fswitch=10, iwrap = 0, taup = 0.5,
    ntt = 3, gamma_ln = 1.0, ntb = 2, ntp = 1,              ! ntp (1 = isotropic position scaling)
    iphmd = 3, solvph = $cryph,
    nscm = 0,
    ntr = 1, restraintmask = '!:WAT  & !@H= & !:SOD & !:CLA', restraint_wt = ${restraints_1[$(($restn-1))]},
    ioutfm = 1, ntxo = 2,
  /" > equil_1.${restn}.mdin
  if [ $restn == 1 ]; then
    equilstart="heating.rst7"
    phmdstart="heating.phmdrst"
  else
    prev=$(($restn-1))
    equilstart="equil_1.${prev}.rst7"
    phmdstart="equil_1.${prev}.phmdrst"
  fi
  sed -i 's/PHMDRST/PHMDSTRT/g' $phmdstart      
  $PMEMDCUDA -O -i equil_1.${restn}.mdin -c $equilstart -p ${protein}.prmtop -ref $equilstart -phmdin phmdin_restart -phmdparm /home/joec/examples/proteins/Parameters/ff14sb_pme.parm -phmdout equil_1.${restn}.lambda -phmdstrt $phmdstart -o equil_1.${restn}.mdout -r equil_1.${restn}.rst7 -phmdrestrt equil_1.${restn}.phmdrst -x equil_1.${restn}.nc 
  wait

done

exit
