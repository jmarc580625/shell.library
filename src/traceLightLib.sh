#-------------------------------------------------------------------------------
# lightweight trace & debug utilities
[[ -z ${traceLightLib} ]] || \
  (echo 'warning traceLightLib sourced multiple times, protect import with [[ -z ${traceLightLib+x} ]]' >&2)
readonly traceLightLib=1

#-------------------------------------------------------------------------------
# import
declare _TRACELIGHTLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${traceLib+x} ]] && source ${_TRACELIGHTLIB_LIB_PATH}/traceLib
unset _TRACELIGHTLIB_LIB_PATH

# override function
function _logStack  { :; }
function _TRACE_OUT { :; }
