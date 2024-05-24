#-------------------------------------------------------------------------------
# trace & debug utilities
[[ -z ${traceLib} ]] || \
  (echo 'warning traceLib sourced multiple times, protect import with [[ -z ${traceLib+x} ]]' >&2)
readonly traceLib=1

#-------------------------------------------------------------------------------
# import
declare _TRACELIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${highlightLib+x} ]] && source ${_TRACELIB_LIB_PATH}/highlightLib
[[ -z ${trapLib+x} ]] && source ${_TRACELIB_LIB_PATH}/trapLib
unset  _TRACELIB_LIB_PATH

#-- -----------------------------------------------------------------------------
# initialize
trapPrepend "setTraceOn; traceStack; setTraceOff" SIGTERM

#-------------------------------------------------------------------------------
# public variable
readonly TRACE_ON=on
readonly TRACE_OFF=off

#-------------------------------------------------------------------------------
# private variables
declare _TRACE=${_TRACE:=${TRACE_OFF}}
declare -a _LAST_STACK=()
declare _SCRIPT_NAME=${0##*/}
        _SCRIPT_NAME=${_SCRIPT_NAME%.*}
declare _DISPLAYED_SCRIPT_NAME=false

# trace function routing table
declare _functioNoOp=":"

declare -A _traceFn
_traceFn[on]=_trace
_traceFn[off]=${_functioNoOp}
readonly _traceFn

declare -A _traceVarFn
_traceVarFn[on]=_traceVar
_traceVarFn[off]=${_functioNoOp}
readonly _traceVarFn

declare -A _traceStackFn
_traceStackFn[on]=_traceStack
_traceStackFn[off]=${_functioNoOp}
readonly _traceStackFn

#-------------------------------------------------------------------------------
# colorize trace output when displayed on terminal
function _traceHighlight { echo -e "${fgCyan}""${@}""${hlReset}" ; }
getHighlighter _TRACE_OUT _traceHighlight

#-------------------------------------------------------------------------------
# call stack representation
function _getTrail    { printf '.%.0s' $(seq $1) ; }
function _getLogTrail { _getTrail $(( traceStackOffset=3, ${#FUNCNAME[@]} - traceStackOffset )) ; }
function _logStack    {
  # call stack depth
  local traceStackOffset=3
  local currentStack=(${FUNCNAME[@]:${traceStackOffset}})
  #declare -p currentStack
  # Display scrip name only once: first time stack is displayed
  if [[ "${_DISPLAYED_SCRIPT_NAME}" != true ]] ; then
    _TRACE_OUT ">${_SCRIPT_NAME}"
    _DISPLAYED_SCRIPT_NAME=true
  fi

  stackDepth=${#currentStack[@]}
  lastStackDepth=${#_LAST_STACK[@]}

  if [[ (( stackDepth != lastStackDepth )) || "${currentStack[0]}" != "${_LAST_STACK[0]}" ]] ;  then
    local last=""
    # find first common in in the stack
    for (( i=0 ; i<stackDepth ; i++ )) ; do
      [[ "${last}" != "" ]] && break
      #printf "\n%s->" ${currentStack[i]} >&2
      for (( j=0 ; j<lastStackDepth ; j++ )) ; do
        #printf "%s, " ${_LAST_STACK[j]} >&2
        if [[ ${currentStack[i]} == ${_LAST_STACK[j]} ]] ; then
          last=$(( i-1 ))
          break
        fi
      done
    done
    #echo >&2
    last=${last:=${stackDepth}}
    for (( j=last ; j>=0 ; j-- )) ; do
      depth=$(( stackDepth - j ))
      if (( depth != 0 )) ; then
        trail=$(_getTrail ${depth})
        _TRACE_OUT "${trail}>${currentStack[$j]}"
      fi
    done
  fi
  _LAST_STACK=(${currentStack[@]})
}

#-------------------------------------------------------------------------------
# regular expression to identify simple variable from array variable
readonly _arrayRE='^declare[[:space:]]-[aA]'
readonly _variableRE='^declare[[:space:]]-[-r]'
readonly _referenceRE='^declare[[:space:]]-n'
readonly _arrayElemRE='^[^[]*\[[^][]*\]$'

#-------------------------------------------------------------------------------
function _trace       { _logStack ; _TRACE_OUT "$(_getLogTrail)""$@" ; }
function _getArrayVal {
  declare -n array=$1
  if (( ${#array[@]} == 0 )) ; then
    echo "()"
  else
    local out=$(declare -p $1 2>&-)
    echo ${out#*=}
  fi
}
function _getVal      {
  if varSpec=$(declare -p "$1" 2>&-) ; then
    if [[ "${varSpec}" =~ ${_referenceRE} ]] ; then
      local q1=${varSpec/#*=/}
      local varName=$(echo ${q1//\"/})
      _getVal "${varName}"
      return
    elif [[ "${varSpec}" =~ ${_arrayRE} ]] ; then
      _getArrayVal $1
    else
      echo \"$(eval echo \${$1})\"
    fi
  elif [[ "$1" =~ ${_arrayElemRE} ]] ; then
    echo \"$(eval echo \${$1})\"
  else
    echo UNDEFINED
  fi
}
function _traceVar    { _logStack ; _TRACE_OUT "$(_getLogTrail)\${$1}=$(_getVal "$1")" ; }
function _traceStack  {
  local traceStackOffset=1
  local stackDepth=$(( ${#FUNCNAME[@]} - 1 )) # remove main from stack trace
  _TRACE_OUT "... Call stack at file:${BASH_SOURCE[${traceStackOffset}]} line:${BASH_LINENO[${traceStackOffset}]}"
  for (( i=traceStackOffset ; i < stackDepth; i++ )) ; do
    _TRACE_OUT "file:${BASH_SOURCE[$i]} line:${BASH_LINENO[$i]} call:${FUNCNAME[$i]}"
  done
}

#-------------------------------------------------------------------------------
# public functions
function getTrace     { echo ${_TRACE} ; }
function setTraceOn   { _TRACE=${TRACE_ON} ; }
function setTraceOff  { _TRACE=${TRACE_OFF} ; }
function trace        { ${_traceFn[${_TRACE}]} "$@" ; }
function traceVar     { ${_traceVarFn[${_TRACE}]} "$@" ; }
function traceStack   { ${_traceStackFn[${_TRACE}]} "$@" ; }

# scoped trace disabling enforcement
function disableTrace {
  shopt -s expand_aliases
  alias getTrace="echo ${TRACE_OFF}"
  alias setTraceOn=":"
  alias setTraceOff=":"
  alias trace=":"
  alias traceVar=":"
  alias traceStack=":"
}
function enableTrace  {
  unalias getTrace
  unalias setTraceOn
  unalias setTraceOff
  unalias trace
  unalias traceVar
  unalias traceStack
  shopt -u expand_aliases
}
