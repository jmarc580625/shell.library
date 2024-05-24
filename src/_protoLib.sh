#-------------------------------------------------------------------------------
# library prototype
[[ -z ${_protoLib} ]] || \
  (echo 'warning _protoLib.sh sourced multiple times, protect import with [[ -z ${_protoLib+x} ]]' >&2)
readonly _protoLib=1

#-------------------------------------------------------------------------------
# import
readonly _PROTOLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${traceLib+x} ]] && source ${_PROTOLIB_LIB_PATH}/traceLib.sh
unset _PROTOLIB_LIB_PATH

#-------------------------------------------------------------------------------
# public sections
_proto() { echo $@ ; }
