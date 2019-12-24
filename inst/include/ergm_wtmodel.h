/*  File inst/include/ergm_wtmodel.h in package ergm, part of the Statnet suite
 *  of packages for network analysis, https://statnet.org .
 *
 *  This software is distributed under the GPL-3 license.  It is free,
 *  open source, and has the attribution requirements (GPL Section 7) at
 *  https://statnet.org/attribution
 *
 *  Copyright 2003-2019 Statnet Commons
 */
#ifndef _ERGM_WTMODEL_H_
#define _ERGM_WTMODEL_H_

#include "ergm_wtedgetree.h"
#include "ergm_wtchangestat.h"
#include "R_ext/Rdynload.h"
#include "ergm_wtMHproposal.h"
#include "ergm_Rutil.h"

/* A WtModel object contains information about an entire ERGM, including the
   total numbers of terms, parameters, and statistics along with a pointer
   to an array of WtModelTerm structures.  */
typedef struct WtModelstruct {
  SEXP R; /* Pointer to the R ergm_model object. */
  WtModelTerm *termarray; /* array of size n_terms; see changestat.h
                           for WtModelTerm definition */
  int n_terms;
  int n_stats;
  unsigned int n_u; /* Number of terms with updaters. */
  double *workspace; /* temporary workspace of size */
  double **dstatarray; /* array of size n_terms; the ith element in this
			  array is a pointer to an array of size
			  termarray[i].nstats                    */
  unsigned int n_aux;
  Rboolean noinit_s;
} WtModel;

#define WtFOR_EACH_TERM(m) for(WtModelTerm *mtp = (m)->termarray; mtp < (m)->termarray + (m)->n_terms; mtp++)

#define WtEXEC_THROUGH_TERMS(m, subroutine)				\
  WtFOR_EACH_TERM(m){							\
    subroutine;								\
  }

#define WtFOR_EACH_TERM_INREVERSE(m) for(WtModelTerm *mtp = (m)->termarray + (m)->n_terms - 1; mtp >= (m)->termarray; mtp--)

#define WtEXEC_THROUGH_TERMS_INREVERSE(m, subroutine)			\
  WtFOR_EACH_TERM_INREVERSE(m){						\
    subroutine;								\
  }

#define WtEXEC_THROUGH_TERMS_INTO(m, output, subroutine)		\
  WtFOR_EACH_TERM(m){							\
    double *dstats = output + mtp->statspos;				\
    subroutine;								\
  }

#define WtSIGNAL_TERMS(m, output, type, data)             \
  WtEXEC_THROUGH_TERMS(m, {                               \
      if(mtp->x_func)                                     \
        (*(mtp->x_func))(type, data, mtp, nwp);           \
    });

#define WtSIGNAL_TERMS_INTO(m, output, type, data)        \
  WtEXEC_THROUGH_TERMS_INTO(m, output, {                  \
      if(mtp->x_func){                                    \
        mtp->dstats = dstats;                             \
        (*(mtp->x_func))(type, data, mtp, nwp);           \
      }                                                   \
    });

 /* If DEBUG is set, back up mtp->dstats and set it to NULL in order
    to trigger a segfault if u_func tries to write to change
    statistics; then restore it. Otherwise, don't bother. */
#ifdef DEBUG
#define IFDEBUG_BACKUP_DSTATS double *dstats = mtp->dstats; mtp->dstats = NULL;
#define IFDEBUG_RESTORE_DSTATS mtp->dstats = dstats;
#else
#define IFDEBUG_BACKUP_DSTATS
#define IFDEBUG_RESTORE_DSTATS
#endif

#define WtUPDATE_STORAGE_COND(tail, head, weight, nwp, m, MHp, edgeweight, cond){ \
    if((MHp) && ((WtMHProposal*)(MHp))->u_func) ((WtMHProposal*)(MHp))->u_func((tail), (head), (weight), (MHp), (nwp)); \
    WtEXEC_THROUGH_TERMS((m), {						\
	IFDEBUG_BACKUP_DSTATS;						\
	if(mtp->u_func && (cond))					\
	  (*(mtp->u_func))((tail), (head), (weight), mtp, (nwp), edgeweight);  /* Call u_??? function */ \
	IFDEBUG_RESTORE_DSTATS;						\
      });								\
  }

#define WtUPDATE_STORAGE(tail, head, weight, nwp, m, MHp, edgeweight){	\
    WtUPDATE_STORAGE_COND((tail), (head), (weight), (nwp), (m), (MHp), (edgeweight), TRUE); \
  }


#define WtGET_EDGE_UPDATE_STORAGE(tail, head, weight, nwp, m, MHp){	\
    if((m)->n_u || ((MHp) && ((WtMHProposal*)(MHp))->u_func)){		\
      Rboolean edgeweight = GETWT((tail), (head), (nwp));		\
      WtUPDATE_STORAGE((tail), (head), (weight), (nwp), (m), (MHp), (edgeweight)); \
    }									\
  }

#define WtUPDATE_STORAGE_SET(tail, head, weight, nwp, m, MHp, edgeweight){ \
    if((m)->n_u || ((MHp) && ((WtMHProposal*)(MHp))->u_func)) WtUPDATE_STORAGE((tail), (head), (weight), (nwp), (m), (MHp), (edgeweight)); \
    WtSetEdge((tail), (head), (weight), (nwp));				\
  }

#define WtGET_EDGE_UPDATE_STORAGE_SET(tail, head, weight, nwp, m, MHp){ \
    WtGET_EDGE_UPDATE_STORAGE((tail), (head), (weight), (nwp), (m), (MHp)); \
    WtSetEdge((tail), (head), (weight), (nwp));				\
  }

WtModel* WtModelInitialize(SEXP mR, SEXP ext_stateR, WtNetwork *nwp, Rboolean noinit_s);

void WtModelDestroy(WtNetwork *nwp, WtModel *m);

/* A WtModel object contains information about an entire ERGM, including the
   total numbers of terms, parameters, and statistics along with a pointer
   to an array of WtModelTerm structures.  */

void WtChangeStats(unsigned int ntoggles, Vertex *tails, Vertex *heads, double *weights, WtNetwork *nwp, WtModel *m);
void WtChangeStats1(Vertex tail, Vertex head, double weight, WtNetwork *nwp, WtModel *m, double edgeweight);

#endif

