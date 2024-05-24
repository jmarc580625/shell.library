#-------------------------------------------------------------------------------
#  file renaming utilities
[[ -z ${renameFileLib} ]] || \
  echo 'warning renameFileLib sourced multiple times, protect import with [[ -z ${renameFileLib+x} ]]' >&2
readonly renameFileLib=1

#-------------------------------------------------------------------------------
# import
declare _RENAMEFILELIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${traceLib+x} ]] && source ${_RENAMEFILELIB_LIB_PATH}/traceLib
unset _RENAMEFILELIB_LIB_PATH

[[ "${renameFileLib_WithTrace}" != "true" ]]   && disableTrace # disabling traceLib functions

#-------------------------------------------------------------------------------
# public functions
function getNewFileName       {
  [[ -z "${1//[[:space:]]}" ]] && echo && return
  [[ "$1" == "." || $1 == ".." ]] && echo $1 && return
  local currentFileName=$1  ; traceVar currentFileName
  local suffix=$2           ; traceVar suffix
  local forcedExtention=$3  ; traceVar forcedExtention
  local fileNameWithoutExtention=${currentFileName%.*}  ; traceVar fileNameWithoutExtention
  local fileNameExtention=$(getFileNameExtention ${currentFileName}) ; traceVar fileNameExtention

  [[ "${forcedExtention}" != "" ]] && fileNameExtention=${forcedExtention}
  if [[ ! -z "${fileNameExtention//[:space:]}" ]] ; then
     extention=".${fileNameExtention}"
   else
     [[ "${currentFileName}" =~ \.$ ]] && extention="."
   fi

  local newFileName=${fileNameWithoutExtention}${suffix}${extention} ; traceVar newFileName

  local counter=0
  while [[ -f ${newFileName} ]] ; do
    (( counter++ ))
    newFileName=${fileNameWithoutExtention}${suffix}"-"${counter}${extention} ; traceVar newFileName
  done
  echo ${newFileName}
}
function getFileNameExtention { t=$(getBaseName $1) ; [[ $t = *.* ]] && echo ${t##*.} || echo ; }
function getDirectoryName     { dirname "$1" ; }
function getFileName          { [[ "$1" == ".." ]] && echo $1 && return ; t=$(getBaseName $1) ; echo ${t%.*} ; }
function getBaseName          { echo ${1##*/} ; }

[[ "${renameFileLib_WithTrace}" != "true" ]]   && enableTrace
