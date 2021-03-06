#' @include generics.R
#' @include aaa.R
NULL

#' A class to store peptide information from an mzIdentML file
#' 
#' This class handles parsing and storage of peptide information from mzIDentML 
#' files, residing at the /x:MzIdentML/x:SequenceCollection/x:Peptide node.
#' 
#' The information is stored in a dataframe with an id, an optinal name and the 
#' amino acid sequence of the peptide. Alongside a list is stored with 
#' modification information of each peptide. Each row in the dataframe has a
#' corresponding entry en the list. If no modification of the peptide is present
#' the entry is NULL, if a modification is present the entry is a dataframe, 
#' listing the different modifications of the peptide.
#' 
#' @section Objects from the class:
#' Objects of mzIDpeptides are not meant to be created explicitly but as part of
#' the \code{\link{mzID-class}}. Still object can be created with the 
#' constructor \code{\link{mzIDpeptides}}.
#' 
#' 
#' @slot peptides A data.frame containing all peptides used in the search
#' 
#' @slot modifications A list containing possible modifications of the peptides 
#' listed in @@peptides
#' 
#' @family mzID-classes
#' @seealso \code{\link{mzIDpeptides}}
#'
setClass(
    'mzIDpeptides',
    slots=list(
        peptides = 'data.frame',
        modifications = 'list'
    ),
    validity=function(object){
        if(nrow(object@peptides) != length(object@modifications) & length(object@modifications) != 0){
            return('Dimensions must match between elements')
        }
    },
    prototype=prototype(
        peptides = data.frame(),
        modifications = list()
    )
)

#' @describeIn mzIDpeptides Short summary of the content of the object
#' 
#' @param object An mzIDpeptides object
#' 
setMethod(
    'show', 'mzIDpeptides',
    function(object){
        if(length(object) == 0){
            cat('An empty mzIDpeptides object\n')
        } else {
            cat('An mzIDpeptides object containing: ',
                length(unique(object@peptides$id)),
                ' peptides (', sum(object@peptides$modified), ' modified)\n', sep='')
        }
    }
)

#' @describeIn mzIDpeptides Report the number of peptides
#' 
#' @param x An mzIDpeptides object
#' 
setMethod(
    'length', 'mzIDpeptides',
    function(x){
        nrow(x@peptides)
    }
)

#' @describeIn flatten Merge peptides with their modifications
#' 
setMethod(
    'flatten', 'mzIDpeptides',
    function(object, safeNames=TRUE){
        ans <- peptides(object, safeNames=safeNames)
        ans$modification <- NA
        nMod <- sapply(object@modifications[object@peptides$modified], nrow)
        if(length(nMod) > 0){
            modPasted <- do.call('rbind', object@modifications)
            modPasted <- paste(modPasted$monoisotopicMassDelta, ' (', modPasted$location, ')', sep='')
            modPasted <- sapply(split(modPasted, rep(1:length(nMod), nMod)), paste, collapse=', ')
            ans$modification[ans$modified] <- modPasted 
        }
        ans
    }
)

#' @describeIn mzIDpeptides Get the peptides identified.
#' 
#' @param safeNames Should column names be lowercased to ensure compatibility
#' between v1.0 and v1.1 files?
#' 
#' @importFrom ProtGenerics peptides
#' 
setMethod(
    'peptides', 'mzIDpeptides',
    function(object, safeNames=TRUE){
        if(safeNames) {
            colNamesToLower(object@peptides)
        } else {
            object@peptides
        }
    }
)
#' @describeIn mzIDpeptides Get the modification on the identified peptides
#' 
#' @importFrom ProtGenerics modifications
#' 
setMethod(
    'modifications', 'mzIDpeptides',
    function(object){
        object@modifications
    }
)

#' A constructor for the mzIDpeptides class
#' 
#' This function handles parsing of data and construction of an mzIDpeptides 
#' object. This function is not intended to be called explicitly but as part of 
#' an mzID construction. Thus, the function is not exported.
#' 
#' @param doc an \code{XMLInternalDocument} created using 
#' \code{\link[XML]{xmlInternalTreeParse}}
#' 
#' @param ns The appropriate namespace for the doc, as a named character vector 
#' with the namespace named x
#' 
#' @param addFinalizer \code{Logical} Sets whether reference counting should be 
#' turned on
#' 
#' @param path If doc is missing the file specified here will be parsed
#' 
#' @return An \code{mzIDpeptides} object
#' 
#' @seealso \code{\link{mzIDpeptides-class}}
#' 
#' @importFrom XML xpathSApply xpathApply
#' @export
#' 
mzIDpeptides <- function(doc, ns, addFinalizer=FALSE, path) {
    if (missing(doc)) {
        if (missing(path)) {
            return(new(Class = 'mzIDpeptides'))
        } else {
            xml <- prepareXML(path)
            doc <- xml$doc
            ns <- xml$ns
        }
    }
    .path <- getPath(ns)
    pepID <- attrExtract(doc, ns,
                         path=paste0(.path, "/x:SequenceCollection/x:Peptide"),
                         addFinalizer=addFinalizer)
    if (nrow(pepID) == 0) {
        return(new('mzIDpeptides'))
    }
    pepSeq <- xpathSApply(doc,
                          path=paste0(.path, "/x:SequenceCollection/x:Peptide"),
                          namespaces=ns,
                          fun=xmlValue,
                          addFinalizer=addFinalizer)
    modDF <- attrExtract(doc, ns,
                         path=paste0(.path, "/x:SequenceCollection/x:Peptide/x:Modification"),
                         addFinalizer=addFinalizer)
    if (nrow(modDF) != 0) {
        ## not using xpathSApply, as does not always simplify
        ## -> using list and extract 'names' element 
        modName <- xpathApply(doc,
                              path=paste0(.path, "/x:SequenceCollection/x:Peptide/x:Modification/x:cvParam"),
                              namespaces=ns,
                              fun=xmlAttrs,
                              addFinalizer=addFinalizer)
        modName <- sapply(modName, "[", "name")
        nModPepID <- countChildren(doc, ns,
                                   path=paste0(.path, "/x:SequenceCollection/x:Peptide"),
                                   'Modification',
                                   addFinalizer=addFinalizer)
        pepDF <- data.frame(pepID, pepSeq, modified=nModPepID > 0, stringsAsFactors=FALSE)
        modList <- list()
        modList[nModPepID > 0] <- split(modDF, rep(1:length(nModPepID), nModPepID))
    } else {
        pepDF <- data.frame(pepID, pepSeq, modified=FALSE, stringsAsFactors=FALSE)
        modList <- list()
    }
    new(Class='mzIDpeptides',
        peptides=pepDF,
        modifications=modList)
}
