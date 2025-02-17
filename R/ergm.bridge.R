#  File R/ergm.bridge.R in package ergm, part of the Statnet suite
#  of packages for network analysis, https://statnet.org .
#
#  This software is distributed under the GPL-3 license.  It is free,
#  open source, and has the attribution requirements (GPL Section 7) at
#  https://statnet.org/attribution
#
#  Copyright 2003-2020 Statnet Commons
#######################################################################

#' Bridge sampling to evaluate ERGM log-likelihoods and log-likelihood ratios
#' 
#' \code{ergm.bridge.llr} uses bridge sampling with geometric spacing to
#' estimate the difference between the log-likelihoods of two parameter vectors
#' for an ERGM via repeated calls to \code{\link{simulate.formula.ergm}}.
#' 
#' 
#' 
#' @param object A model formula. See \code{\link{ergm}} for details.
#' @template response
#' @param constraints,obs.constraints One-sided formulas specifying
#'   one or more constraints on the support of the distribution of the
#'   networks being simulated and on the observation process
#'   respectively. See the documentation for a similar argument for
#'   \code{\link{ergm}} for more information.
#' @param reference {A one-sided formula specifying the reference
#'   measure (\eqn{h(y)}) to be used.  (Defaults to
#'   \code{~Bernoulli}.)}
#' @param target.stats {A vector of sufficient statistics to be used
#'   in place of those of the network in the formula.}
#' @param from,to The initial and final parameter vectors.
#' @param basis An optional \code{\link[network]{network}} object to
#'   start the Markov chain.  If omitted, the default is the
#'   left-hand-side of the \code{object}.
#' @param verbose Logical: If TRUE, print detailed information.
#' @param \dots Further arguments to \code{ergm.bridge.llr} and
#'   \code{\link{simulate.formula.ergm}}.
#' @param llronly Logical: If TRUE, only the estiamted log-ratio will
#'   be returned by `ergm.bridge.llr`.
#'
#' @templateVar mycontrol control.ergm.bridge
#' @template control
#'
#' @param coef A vector of coefficients for the configuration of
#'   interest.
#' @param llkonly Whether only the estiamted log-likelihood should be
#'   returned by the `ergm.bridge.0.llk` and
#'   `ergm.bridge.dindstart.llk`.  (Defaults to TRUE.)
#' @return If `llronly=TRUE` or `llkonly=TRUE`, these functions return
#'   the scalar log-likelihood-ratio or the log-likelihood.
#'   Otherwise, they return a list with the following components:
#'   \item{llr}{The estimated log-ratio.}  \item{llrs}{The estimated
#'   log-ratios for each of the \code{nsteps} bridges.}  \item{path}{A
#'   numeric matrix with nsteps rows, with each row being the
#'   respective bridge's parameter configuration.}  \item{stats}{A
#'   numeric matrix with nsteps rows, with each row being the
#'   respective bridge's vector of simulated statistics.}
#'   \item{Dtheta.Du}{The gradient vector of the parameter values with
#'   respect to position of the bridge.}
#' @seealso \code{\link{simulate.formula.ergm}}
#' @references Hunter, D. R. and Handcock, M. S. (2006)
#'   \emph{Inference in curved exponential family models for
#'   networks}, Journal of Computational and Graphical Statistics.
#' @keywords model
#' @export
ergm.bridge.llr<-function(object, response=NULL, reference=~Bernoulli, constraints=~., from, to, obs.constraints=~.-observed, target.stats=NULL, basis=eval_lhs.formula(object), verbose=FALSE, ..., llronly=FALSE, control=control.ergm.bridge()){
  check.control.class("ergm.bridge", "ergm.bridge.llr")
  handle.control.toplevel("ergm.bridge", ...)

  if(!is.null(control$seed)) {set.seed(as.integer(control$seed))}
  
  ergm_preprocess_response(basis, response)

  ## Generate the path.
  path<-t(rbind(sapply(seq(from=0+1/2/(control$nsteps+1),to=1-1/2/(control$nsteps+1),length.out=control$nsteps),function(u) cbind(to*u + from*(1-u)))))

  ## Control list constructor.
  gen_control <- function(obs, burnin){
    control.simulate.formula(
      MCMC.burnin = if(burnin=="first"){
                      if(obs) control$obs.MCMC.burnin
                      else control$MCMC.burnin
                    }else if(burnin=="between"){
                      if(obs) control$obs.MCMC.burnin.between
                      else control$MCMC.burnin.between
                    }else{
                      0
                    },
      term.options = control$term.options,
      MCMC.interval = if(burnin!="no"){
                       1
                     }else{
                       if(obs) control$obs.MCMC.interval
                       else control$MCMC.interval
                     },
      MCMC.packagenames=control$MCMC.packagenames,
      parallel=control$parallel,
      parallel.type=control$parallel.type,
      parallel.version.check=control$parallel.version.check
    )
  }
  
  ## Obtain simulation setting arguments in terms of ergm_state.
  sim_settings <- do.call(stats::simulate, c(simulate(object, coef=from, nsim=1, constraints=constraints, output="ergm_state", verbose=max(verbose-1,0), basis = basis, control=gen_control(FALSE, "first"), ..., do.sim=FALSE), do.sim=FALSE))
  nw.state <- sim_settings$object
  stats <- matrix(NA, control$nsteps, nparam(nw.state,canonical=TRUE))

  obs <- !is.null(.handle.auto.constraints(basis, constraints, obs.constraints, target.stats)$constraints.obs)
  if(obs){
    sim_settings.obs <- do.call(stats::simulate, c(simulate(object, coef=from, nsim=1, constraints=obs.constraints, output="ergm_state", verbose=max(verbose-1,0), basis = basis, control=gen_control(TRUE, "first"), ..., do.sim=FALSE), do.sim=FALSE))
    nw.state.obs <- sim_settings.obs$object
    stats.obs <- matrix(NA, control$nsteps, nparam(nw.state.obs,canonical=TRUE))
  }else
    stats.obs <- matrix(NVL(target.stats, summary(nw.state)), control$nsteps, nparam(nw.state,canonical=TRUE), byrow=TRUE)

  message("Using ", control$nsteps, " bridges: ", appendLF=FALSE)
  
  for(i in seq_len(control$nsteps)){
    theta<-path[i,]
    if(verbose==0) message(i," ",appendLF=FALSE)
    if(verbose>0) message("Running theta=[",paste(format(theta),collapse=","),"].")
    if(verbose>1) message("Burning in...")

    ## First burn-in has to be longer, but those thereafter should be shorter if the bridges are closer together.
    sim_settings[c("nsim", "coef", "object", "output", "control")] <-
      list(
        nsim = 1,
        coef = theta,
        object = nw.state,
        output = "ergm_state",
        control = gen_control(FALSE, if(i==1)"first"else"between")
      )
    nw.state <- do.call(stats::simulate, sim_settings)

    if(obs){
      sim_settings.obs[c("nsim", "coef", "object", "output", "control")] <-
        list(
          nsim = 1,
          coef = theta,
          object = nw.state.obs,
          output = "ergm_state",
          control = gen_control(TRUE, if(i==1)"first"else"between")
        )
      nw.state.obs <- do.call(stats::simulate, sim_settings.obs)
    }

    if(verbose>1) message("Simulating...")
    sim_settings[c("nsim", "object", "output", "control")] <-
      list(
        nsim = ceiling(control$MCMC.samplesize/control$nsteps),
        object = nw.state,
        output = "stats",
        control = gen_control(FALSE,"no")
      )
    stats[i,] <- colMeans(as.matrix(do.call(stats::simulate, sim_settings)))

    if(obs){
      sim_settings.obs[c("nsim", "object", "output", "control")] <-
        list(
          nsim = ceiling(control$obs.MCMC.samplesize/control$nsteps),
          object = nw.state.obs,
          output = "stats",
          control = gen_control(TRUE,"no")
        )
      stats.obs[i,] <- colMeans(as.matrix(do.call(stats::simulate, sim_settings.obs)))
    }
  }
  message(".")
    
  Dtheta.Du<-(to-from)/control$nsteps

  esteq  <- rbind(sapply(seq_len(control$nsteps), function(i) ergm.etagradmult(path[i,],stats[i,]-stats.obs[i,],nw.state$model$etamap)))
  nochg <- Dtheta.Du==0 | apply(esteq==0, 1, all)
  llrs <- -as.vector(crossprod(Dtheta.Du[!nochg],esteq[!nochg,,drop=FALSE]))
  llr <- sum(llrs)
  if(llronly) llr
  else list(llr=llr,from=from,to=to,llrs=llrs,path=path,stats=stats,stats.obs=stats.obs,Dtheta.Du=Dtheta.Du)
}

#' @rdname ergm.bridge.llr
#'
#' @description \code{ergm.bridge.0.llk} is a convenience wrapper that
#'   returns the log-likelihood of configuration \eqn{\theta}
#'   \emph{relative to the reference measure}. That is, the
#'   configuration with \eqn{\theta=0} is defined as having log-likelihood of
#'   0.
#'
#' @return \code{ergm.bridge.0.llk} result list also includes an `llk`
#'   element, with the log-likelihood itself (with the reference
#'   distribution assumed to have likelihood 0).
#' 
#' 
#' @export
ergm.bridge.0.llk<-function(object, response=NULL, reference=~Bernoulli, coef, ..., llkonly=TRUE, control=control.ergm.bridge(), basis=eval_lhs.formula(object)){
  check.control.class("ergm.bridge", "ergm.bridge.0.llk")
  handle.control.toplevel("ergm.bridge", ...)
  ergm_preprocess_response(basis, response)
  br<-ergm.bridge.llr(object, from=rep(0,length(coef)), to=coef, reference=reference, control=control, ..., basis=basis)
  if(llkonly) br$llr
  else c(br,llk=br$llr)
}

#' @rdname ergm.bridge.llr
#'
#' @description `ergm.bridge.dindstart.llk` is a wrapper that uses a
#'   dyad-independent ERGM as a starting point for bridge sampling to
#'   estimate the log-likelihood for a given dyad-dependent model and
#'   parameter configuration.  Note that it only handles binary ERGMs
#'   (`response=NULL`) and with constraints (`constraints=`) that that
#'   do not induce dyadic dependence.
#'
#' @param dind A one-sided formula with the dyad-independent model to use as a
#' starting point. Defaults to the dyad-independent terms found in the formula
#' \code{object} with an overal density term (\code{edges}) added if not
#' redundant.
#' @param coef.dind Parameter configuration for the dyad-independent starting
#' point. Defaults to the MLE of \code{dind}.
#'
#' @return \code{ergm.bridge.dindstart.llk} result list also includes
#'   an `llk` element, with the log-likelihood itself and an
#'   `llk.dind` element, with the log-likelihood of the nearest
#'   dyad-independent model.
#' 
#' @export
ergm.bridge.dindstart.llk<-function(object, response=NULL, constraints=~., coef, obs.constraints=~.-observed, target.stats=NULL, dind=NULL, coef.dind=NULL,  basis=eval_lhs.formula(object), ..., llkonly=TRUE, control=control.ergm.bridge()){
  check.control.class("ergm.bridge", "ergm.bridge.dindstart.llk")
  handle.control.toplevel("ergm.bridge", ...)

  ## Here, we need to get the model object to get the list of
  ## dyad-independent terms.
  nw <- basis
  ergm_preprocess_response(nw, response)

  if(is.valued(nw)) stop("Only binary ERGMs are supported at this time.")
  if(!is.null(dind)) stop("Custom dind scaffolding has been disabled. It may be reenabled in the future.")

  m<-ergm_model(object, nw, term.options=control$term.options)
  
  q.pos.full <- c(0,cumsum(nparam(m, canonical=FALSE, byterm=TRUE, offset=TRUE)))
  p.pos.full <- c(0,cumsum(nparam(m, canonical=TRUE, byterm=TRUE, offset=FALSE)))
  rng <- function(x, from, to) if(to>=from) x[from:to]
  
  tmp <- .handle.auto.constraints(nw, constraints, obs.constraints, target.stats); nw <- tmp$nw; constraints <- tmp$constraints; constraints.obs <- tmp$constraints.obs

  if(!is.dyad.independent(ergm_conlist(constraints,nw), ergm_conlist(constraints.obs,nw))) stop("Bridge sampling with dyad-independent start does not work with dyad-dependent constraints.")

  # If target.stats are given, then we need between passed network and
  # target stats, if any. It also means that the dyad-independent
  # submodel cannot contain any statistics that target.stats does not,
  # so edges are not added on.
  if(!is.null(target.stats) && !is.null(dind)) stop("Non-default dyad-independent model is not supported when target.stats is passed and passed network's statistics do not match it.")

  ## By default, take dyad-independent terms in the formula, fit a
  ## model with these terms and "edges". Terms that are redundant (NA)
  ## get their coefficients zeroed out below.
  ## FIXME: What to do about dyad-independent curved terms?
  offset.dind <- c()
  if(!is.null(target.stats)) ts.dind <- c()
  dindmap <- logical(0)
  if(is.null(dind)){
    terms.full<-list_rhs.formula(object)[!m$term.skipped] # Ensure that terms to be added to the dyad-independent formula are aligned with terms that had actually made it into the model.
    for(i in seq_along(terms.full))
      if(NVL(m$terms[[i]]$dependence, TRUE)){ # Dyad-dependent: drop.
        terms.full[i] <- list(NULL)
        dindmap <- c(dindmap, rep(FALSE, length(m$terms[[i]]$offset)))
      }else{
        dindmap <- c(dindmap, rep(TRUE, length(m$terms[[i]]$offset)))
        if(!is.null(target.stats)) ts.dind <- c(ts.dind, rng(target.stats, p.pos.full[i]+1, p.pos.full[i+1]))
        offset.dind <- c(offset.dind, coef[(q.pos.full[i]+1):q.pos.full[i+1]][m$terms[[i]]$offset]) # Add offset coefficient where applicable.
      }

    if(is.null(target.stats)){
      terms.full <- c(terms.full, list(as.name("edges")))
      dindmap <- c(dindmap, TRUE)
    }

    # Copy environment and LHS if present.
    dind <- append_rhs.formula(object[-length(object)], compact(terms.full))

    if(length(object)==3) dind[[2]] <- object[[2]] else dind <- dind[-2]
  }

  ergm.dind<-suppressMessages(suppressWarnings(ergm(dind,estimate="MPLE",constraints=constraints,eval.loglik=FALSE,control=control.ergm(drop=FALSE, term.options=control$term.options, MPLE.max.dyad.types=control$MPLE.max.dyad.types), offset.coef = offset.dind)))
  
  if(is.null(coef.dind)){
    coef.dind <- coef(ergm.dind)[!ergm.dind$etamap$offsettheta]
    coef.dind <- ifelse(is.na(coef.dind),0,coef.dind)
    llk.dind<--ergm.dind$glm$deviance/2 - -ergm.dind$glm.null$deviance/2
  }else{
    lin.pred <- model.matrix(ergm.dind$glm) %*% coef.dind
    llk.dind <- 
      crossprod(lin.pred,ergm.dind$glm$y*ergm.dind$glm$prior.weights)-sum(log1p(exp(lin.pred))*ergm.dind$glm$prior.weights) -
        (network.dyadcount(ergm.dind$network,FALSE) - network.edgecount(NVL(as.rlebdm(ergm.dind$constrained, ergm.dind$constrained.obs,which="missing"),network.initialize(1))))*log(1/2)
  }
  
  # If there are target.stats we need to adjust the log-likelihood in
  # case they are different from those to which the dyad-independent
  # submodel was actually fit:
  # l(theta,ts)-l(theta,ns)=sum(theta*(ts-ns)).
  if(!is.null(target.stats)) llk.dind <- llk.dind + c(crossprod(coef.dind, NVL(c(ts.dind), ergm.dind$nw.stats[!ergm.dind$etamap$offsetmap]) - ergm.dind$nw.stats[!ergm.dind$etamap$offsetmap]))

  from <- numeric(length(dindmap))
  from[dindmap] <- replace(coef(ergm.dind), is.na(coef(ergm.dind)), 0)
  to <- c(coef, if(is.null(target.stats)) 0)

  form.aug <- if(is.null(target.stats)) append_rhs.formula(object, list(as.name("edges"))) else object

  ## From this point on, target.stats has NAs corresponding to offset
  ## terms.
  if(!is.null(target.stats)) target.stats <- .align.target.stats.offset(m, target.stats)

  if(!is.null(target.stats) && any(is.na(target.stats))){
    warning("Using target.stats for a model with offset terms may produce an inaccurate estimate of the log-likelihood and derived quantities (deviance, AIC, BIC, etc.), because some of the target stats must be imputed.")
    target.stats[m$etamap$offsetmap] <- summary(m, nw)[m$etamap$offsetmap]
  }

  br<-ergm.bridge.llr(form.aug, constraints=constraints, from=from, to=to, basis=basis, target.stats=target.stats, control=control)
  
  if(llkonly) llk.dind + br$llr
  else c(br,llk.dind=llk.dind, llk=llk.dind + br$llr)
}
