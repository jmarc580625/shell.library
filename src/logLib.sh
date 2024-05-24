#-------------------------------------------------------------------------------
# log message utilities
[[ -z ${logLib} ]] || \
  (echo 'WARNING: logLib multiple import , use [[ -z ${logLib+x} ]] && source ${EXEC_HOME}/lib/logLib' >&2)
readonly logLib=1

#-------------------------------------------------------------------------------
# import
declare _LOGLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${trapLib+x} ]] && source ${_LOGLIB_LIB_PATH}/trapLib
[[ -z ${highlightLib+x} ]] && source ${_LOGLIB_LIB_PATH}/highlightLib
unset _LOGLIB_LIB_PATH

#-------------------------------------------------------------------------------
# private variables
readonly _LOG_MESSAGE_INFO="INFO"
readonly _LOG_MESSAGE_WARNING="WARNING"
readonly _LOG_MESSAGE_ERROR="ERROR"
readonly _LOG_MESSAGE_FATAL="FATAL"

readonly _textColor=${fgMagenta}
function _logHighlight {
  echo -e "${_textColor}""${@}""${hlReset}" | \
  sed \
    -e "s/\(${_LOG_MESSAGE_INFO}\)/${fgLightGreen}\1${hlReset}${_textColor}/g" \
    -e "s/\(${_LOG_MESSAGE_WARNING}\)/${fgLightBlue}\1${hlReset}${_textColor}/g" \
    -e "s/\(${_LOG_MESSAGE_ERROR}\)/${fgLightYellow}\1${hlReset}${_textColor}/g" \
    -e "s/\(${_LOG_MESSAGE_FATAL}\)/${fgLightRed}\1${hlReset}${_textColor}/g"
}
getHighlighter _LOG_HIGHLIGHTER _logHighlight

#-------------------------------------------------------------------------------
# public functions
function out     { _LOG_HIGHLIGHTER "${EXEC_NAME}:$@" ; }
function info    { _LOG_HIGHLIGHTER "${EXEC_NAME}:${_LOG_MESSAGE_INFO}:$@" ; }
function warning { _LOG_HIGHLIGHTER "${EXEC_NAME}:${_LOG_MESSAGE_WARNING}:$@" ; }
function error   { _LOG_HIGHLIGHTER "${EXEC_NAME}:${_LOG_MESSAGE_ERROR}:$@" ; }
function fatal   { _LOG_HIGHLIGHTER "${EXEC_NAME}:${_LOG_MESSAGE_FATAL}:$@" ; kill -s TERM $$ ; }
