/*  File inst/include/wtMCMC.h in package ergm, part of the Statnet suite
 *  of packages for network analysis, https://statnet.org .
 *
 *  This software is distributed under the GPL-3 license.  It is free,
 *  open source, and has the attribution requirements (GPL Section 7) at
 *  https://statnet.org/attribution
 *
 *  Copyright 2003-2019 Statnet Commons
 */

#include "ergm_constants.h"

MCMCStatus DISPATCH_MCMCSample(DISPATCH_ErgmState *s,
			   double *eta, double *networkstatistics, 
			   int samplesize, int burnin, 
			   int interval, int nmax, int verbose);
MCMCStatus DISPATCH_MetropolisHastings(DISPATCH_ErgmState *s,
				   double *eta, double *statistics, 
				   int nsteps, int *staken,
				   int verbose);
MCMCStatus DISPATCH_MCMCSamplePhase12(DISPATCH_ErgmState *s,
                               double *eta, unsigned int n_param, double gain,
                               int nphase1, int nsubphases, double *networkstatistics,
                               int samplesize, int burnin,
                               int interval, int verbose);
MCMCStatus DISPATCH_EESamplePhase12(DISPATCH_ErgmState *s,
                               double *theta, unsigned int n_param, double gain, int nphase1, int nsubphases, double *networkstatistics,
                               int samplesize, int burnin,
                               int interval, int verbose);
