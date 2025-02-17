## This will always be passed with two arguments in arglist, which
## will cause an error if we actually try to evaluate them. So,
## there's no check.ErgmTerm() but rather an immediate substitute() to
## grab the actual names or calls being passed.
`InitErgmTerm.:` <- function(nw, arglist, ...){
  arglist <- substitute(arglist)
  e1 <- arglist[[2]]
  e2 <- arglist[[3]]

  e1 <- list_summands.call(e1)
  e2 <- list_summands.call(e2)

  n1 <- length(e1)
  n2 <- length(e2)
  
  f <- ~nw
  f <- append_rhs.formula(f, c(e1,e2))
  
  m <- ergm_model(f, nw,...)

  if(!is.dyad.independent(m)) message("Note that interactions might not be meaningful for dyad-dependent terms.")
  if(is.curved(m)) stop("Interactions are undefined for curved terms at this time.")

  cn1 <- unlist(lapply(m$terms[seq_len(n1)], "[[", "coef.names"))
  cn2 <- unlist(lapply(m$terms[n1+seq_len(n2)], "[[", "coef.names"))

  inputs <- c(length(cn1), length(cn2))
  
  cn <- outer(cn1,cn2,paste,sep=":")

  wm <- wrap.ergm_model(m, nw, NULL)
  if(any(wm$offsettheta) || any(wm$offsetmap)) ergm_Init_warn(paste0("The interaction operator does not propagate offset() decorators."))

  list(name="interact", coef.names = cn, inputs=inputs, submodel=m, dependence=wm$dependence)
}

## This will always be passed with two arguments in arglist, which
## will cause an error if we actually try to evaluate them. So,
## there's no check.ErgmTerm() but rather an immediate substitute() to
## grab the actual names or calls being passed.
`InitErgmTerm.*` <- function(nw, arglist, ...){
  arglist <- substitute(arglist)
  e1 <- arglist[[2]]
  e2 <- arglist[[3]]

  e1 <- list_summands.call(e1)
  e2 <- list_summands.call(e2)

  n1 <- length(e1)
  n2 <- length(e2)
  
  f <- ~nw
  f <- append_rhs.formula(f, c(e1,e2))
  
  m <- ergm_model(f, nw,...)

  if(!is.dyad.independent(m)) message("Note that interactions might not be meaningful for dyad-dependent terms.")
  if(is.curved(m)) stop("Interactions are undefined for curved terms at this time.")
  
  cn1 <- unlist(lapply(m$terms[seq_len(n1)], "[[", "coef.names"))
  cn2 <- unlist(lapply(m$terms[n1+seq_len(n2)], "[[", "coef.names"))

  inputs <- c(length(cn1), length(cn2))

  cn <- c(cn1,cn2,outer(cn1,cn2,paste,sep=":"))
  
  wm <- wrap.ergm_model(m, nw, NULL)
  if(any(wm$offsettheta) || any(wm$offsetmap)) ergm_Init_warn(paste0("The interaction operator does not propagate offset() decorators."))

  list(name="main_interact", coef.names = cn, inputs=inputs, submodel=m, dependence=wm$dependence)
}
