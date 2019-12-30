/*  File src/netstats.c in package ergm, part of the Statnet suite
 *  of packages for network analysis, https://statnet.org .
 *
 *  This software is distributed under the GPL-3 license.  It is free,
 *  open source, and has the attribution requirements (GPL Section 7) at
 *  https://statnet.org/attribution
 *
 *  Copyright 2003-2019 Statnet Commons
 */
#include "ergm_state.h"
/*****************
 void network_stats_wrapper

 Wrapper for a call from R.  Return the statistics when of the observed graph.
*****************/

SEXP network_stats_wrapper(ARGS_STATE){
  GetRNGstate();  /* R function enabling uniform RNG */
  ErgmState *s = ErgmStateInit(YES_STATE_EMPTY_NO_INIT_S);

  Model *m = s->m;

  SEXP stats = PROTECT(allocVector(REALSXP, m->n_stats));
  m->workspace = REAL(stats);

  SEXP elR = getListElement(stateR, "el");
  SummStats(length(VECTOR_ELT(elR, 0)),
            (Vertex*) INTEGER(VECTOR_ELT(elR, 0)),
            (Vertex*) INTEGER(VECTOR_ELT(elR, 1)),
            s->nwp, m);

  PutRNGstate();
  UNPROTECT(1);
  return stats;
}
