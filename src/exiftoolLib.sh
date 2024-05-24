#-------------------------------------------------------------------------------
# exiftool utilities
[[ -z ${exiftoolLib} ]] || \
  (echo 'warning exiftoolLib imported multiple times, protect import with [[ -z ${exiftoolLib+x} ]]' >&2)
readonly exiftoolLib=1

#-------------------------------------------------------------------------------
# import
declare _EXIFTOOLLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${traceLib+x} ]] && source ${_EXIFTOOLLIB_LIB_PATH}/traceLib
unset _EXIFTOOLLIB_LIB_PATH

[[ "${exiftoolLib_WithTrace}" != "true" ]]   && disableTrace # disabling traceLib functions

#-------------------------------------------------------------------------------
# private functions
function _getExiftoolCommand  {
  local command=$(which exiftool 2>/dev/null)
  traceVar command
  [[ -z ${command+x} ]] && fatal "install exiftool"
  echo "${command} "
}
function _durationInSeconds   { echo $(( ($1 * 3600 ) + ($2 * 60) + $3 )) ; }

#-------------------------------------------------------------------------------
# public variables
declare EXIFTOOL_COMMAND=$(_getExiftoolCommand)

#-------------------------------------------------------------------------------
# public functions
function getMetaData      { ${EXIFTOOL_COMMAND} -s -s -s -${@:2} $1 ; }
function getVideoSize     { ${EXIFTOOL_COMMAND} -s -s -s -ImageSize ${1} ; }
function getVideoWidth    { ${EXIFTOOL_COMMAND} -s -s -s -Imagewidth ${1} ; }
function getVideoHeight   { ${EXIFTOOL_COMMAND} -s -s -s -Imageheight ${1} ; }
function getGeoTag        { ${EXIFTOOL_COMMAND} -n -gpsposition ${1} | awk '{r = $4 + $5; if (r != 0) print "G"}' ; }
function getVideoLength   { ${EXIFTOOL_COMMAND} -s -s -s -n -Duration ${1} ; }
function getVideoDuration {
  local duration=$(${EXIFTOOL_COMMAND} -s -s -s -duration ${1} | \
    sed                                               \
      -e 's/:/ /g'                                    \
      -e 's/\([0-9][0-9]\)\(\.[0-9]*\)\( s\)/0 0 \1/' \
      -e 's/\([0-9]\)\(\.[0-9]*\)\( s\)/0 0 \1/'      \
      -e 's/[0-9] 0\([1-9] \)\([0-9]*\)/0 \1 \2/g'        \
      -e 's/\([0-9] [0-9]* \)0\([1-9]\)/\1 \2/g'
  )
  traceVar duration
  _durationInSeconds ${duration}
}

[[ "${exiftoolLib_WithTrace}" != "true" ]]   && enableTrace
