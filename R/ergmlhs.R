#' @name ergmlhs
#' @title An API for specifying aspects of an [`ergm`] model in the
#'   LHS/basis network.
#'
#' @description `%ergmlhs%` extracts the setting, while assigning to
#'   it sets or updates it.
#'
#' @param lhs a [`network`] intended to serve as LHS of a [`ergm`]
#'   call.
#' @param setting a character string holding a setting's name.
#'
#' @details The settings are stored in a named list in an `"ergm"`
#'   network attribute attached to the LHS network. Currently
#'   understood settings include: \describe{
#'
#'   \item{`response`}{Edge attribute to be used as the response
#'   variable, constructed from the `response=` argument of [ergm()].}
#'
#'   \item{`constraints`}{Structural constraints of the network:
#'   inherited by the `constraints=` argument of [ergm()],
#'   [simulate.formula()], etc..}
#'
#'   \item{`obs.constraints`}{Structural constraints of the
#'   observation process: inherited by the `obs.constraints=` argument
#'   of [ergm()], [simulate.formula()], etc..}
#'
#' }
#'
#' @keywords internal
#' @export
`%ergmlhs%` <- function(lhs, setting){
  UseMethod("%ergmlhs%")
}

#' @rdname ergmlhs
#' @export
`%ergmlhs%.network` <- function(lhs, setting){
  out <- (lhs %n% "ergm")[[setting]]
  if(!is.null(out)) return(out)

  out <- lhs %n% setting
  if(!is.null(out)) warn(paste(sQuote(deparse(substitute(lhs))), "setting", dQuote(setting),
                               "is stored the old way. Convert the object with",sQuote("convert_ergmlhs"),"."))

  out
}

#' @rdname ergmlhs
#'
#' @usage lhs %ergmlhs% setting <- value
#'
#' @param value value with which to overwrite the setting.
#' @export
`%ergmlhs%<-` <- function(lhs, setting, value){
  UseMethod("%ergmlhs%<-")
}

#' @rdname ergmlhs
#' @export
`%ergmlhs%<-.network` <- function(lhs, setting, value){
  settings <- NVL(lhs %n% "ergm", list())
  settings[[setting]] <- value
  lhs %n% "ergm" <- settings
  lhs
}

#' @describeIn ergmlhs `convert_ergmlhs` converts old-style settings to new-style settings.
#' @export
convert_ergmlhs <- function(lhs){
  for(attr in c("response","constraints","obs.constraints")){
    NVL(lhs%ergmlhs%attr) <- lhs %n% attr
    lhs %n% attr <- NULL
  }
  lhs
}
