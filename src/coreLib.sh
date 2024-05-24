#-------------------------------------------------------------------------------
# core utility set

#-------------------------------------------------------------------------------
# import
declare  _CORELIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${helpLib+x} ]]   && source ${_CORELIB_LIB_PATH}/helpLib
[[ -z ${logLib+x} ]]    && source ${_CORELIB_LIB_PATH}/logLib
[[ -z ${traceLib+x} ]]  && source ${_CORELIB_LIB_PATH}/traceLib
[[ -z ${ensureLib+x} ]] && source ${_CORELIB_LIB_PATH}/ensureLib
unset  _CORELIB_LIB_PATH

#-------------------------------------------------------------------------------
# private variables
readonly _CORELIB_EXEC_NOPATH=${0##*/}

#-------------------------------------------------------------------------------
# public variables
declare -xr EXEC_NAME=${_CORELIB_EXEC_NOPATH%.*}
