import sys
sys.path.append('/home/joec/Applications/async_ph_replica_exchange/')
import replica_exchange as re
import numpy as np

#pH to run
minpH = 6.5
maxpH = 8.5
steppH= .5
#MD parameters
numSwap = 5000  #Each round is 2ps, do 10ns     
mdInFile= '2ps.mdin'
parmFile= '6p7g_cpH.prmtop'
phParmFile='ff14sb_pme.parm'
phInFile= '../run.phmdin'
outDir  = 'output_5nsFinish'
inRestart='prep/relax6.rst7' #Used for initial
inDir = 'output_10ns'      #Used for restart

phs_array = np.arange(minpH,maxpH+steppH,steppH)
phs_list = ['{:.1f}'.format(ph) for ph in phs_array]

#Initial
#re.do_replica_exchange(phs_list,numSwap,mdInFile,parmFile,phParmFile,phInFile,outDir,initial_restart_file=inRestart)
#Restart
re.do_replica_exchange(phs_list,numSwap,mdInFile,parmFile,phParmFile,phInFile,outDir,restart_directory=inDir,restart=True)
