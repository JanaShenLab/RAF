PMEMDCUDA=pmemd.cuda
export CUDA_VISIBLE_DEVICES=0
PRMTOP='6p7g_cpH.prmtop'
PHPARM='ff14sb_pme.parm'

#Equilibration 2.1
INPCRD="equil_1.2.rst7"
rep=0
for ph in {6.5,7.0,7.5,8.0,8.5} 
do
	sed 's/PH/'${ph}'/g' template_equil_2.1.mdin > temp.mdin
	OUTPRE="rep${rep}"
	$PMEMDCUDA -O -i temp.mdin -c $INPCRD -p $PRMTOP -ref $INPCRD -phmdin phmdin_start -phmdparm $PHPARM -phmdout equil_2.1/${OUTPRE}.lambda -o equil_2.1/${OUTPRE}.mdout -r equil_2.1/${OUTPRE}.rst7 -x equil_2.1/${OUTPRE}.nc -phmdrestrt equil_2.1/${OUTPRE}.phmdrst
	rep=$((rep+2))
done

#Equilibration 2.2
rep=0
for ph in {6.5,7.0,7.5,8.0,8.5}
do
	sed 's/PH/'${ph}'/g' template_equil_2.1.mdin > temp.mdin
        OUTPRE="rep${rep}"
	INPCRD="equil_2.1/${OUTPRE}.rst7"
	$PMEMDCUDA -O -i temp.mdin -c $INPCRD -p $PRMTOP -ref $INPCRD -phmdin phmdin_start -phmdparm $PHPARM -phmdout equil_2.2/${OUTPRE}.lambda -o equil_2.2/${OUTPRE}.mdout -r equil_2.2/${OUTPRE}.rst7 -x equil_2.2/${OUTPRE}.nc -phmdstrt equil_2.1/${OUTPRE}.phmdrst -phmdrestrt equil_2.2/${OUTPRE}.phmdrst
	rep=$((rep+2))
done

#Equilibration 2.3
rep=0
for ph in {6.5,7.0,7.5,8.0,8.5}
do
	sed 's/PH/'${ph}'/g' template_equil_2.1.mdin > temp.mdin
        OUTPRE="rep${rep}"
        INPCRD="equil_2.2/${OUTPRE}.rst7"
        $PMEMDCUDA -O -i temp.mdin -c $INPCRD -p $PRMTOP -ref $INPCRD -phmdin phmdin_start -phmdparm $PHPARM -phmdout equil_2.3/${OUTPRE}.lambda -o equil_2.3/${OUTPRE}.mdout -r equil_2.3/${OUTPRE}.rst7 -x equil_2.3/${OUTPRE}.nc -phmdstrt equil_2.2/${OUTPRE}.phmdrst -phmdrestrt equil_2.3/${OUTPRE}.phmdrst
        rep=$((rep+2))
done

#Equilibration 2.4
rep=0
for ph in {6.5,7.0,7.5,8.0,8.5}
do
	sed 's/PH/'${ph}'/g' template_equil_2.1.mdin > temp.mdin
        OUTPRE="rep${rep}"
        INPCRD="equil_2.3/${OUTPRE}.rst7"
        $PMEMDCUDA -O -i temp.mdin -c $INPCRD -p $PRMTOP -ref $INPCRD -phmdin phmdin_start -phmdparm $PHPARM -phmdout equil_2.4/${OUTPRE}.lambda -o equil_2.4/${OUTPRE}.mdout -r equil_2.4/${OUTPRE}.rst7 -x equil_2.4/${OUTPRE}.nc -phmdstrt equil_2.3/${OUTPRE}.phmdrst -phmdrestrt equil_2.4/${OUTPRE}.phmdrst
        rep=$((rep+2))
done
