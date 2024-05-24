#-------------------------------------------------------------------------------
# timer control utilities
[[ -z ${timerLib} ]] || \
  (echo 'warning timerLib sourced multiple times, protect import with [[ -z ${timerLib+x} ]]' >&2)
readonly timerLib=1

#-------------------------------------------------------------------------------
# import
declare _TIMERLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${traceLib+x} ]] && source ${_TIMERLIB_LIB_PATH}/traceLib
unset _TIMERLIB_LIB_PATH

[[ "${timerLib_WithTrace}" != "true" ]]   && disableTrace # disabling traceLib functions

#-------------------------------------------------------------------------------
# private variables
declare -A _timerStart
declare -A _timerTop
readonly _datePattern="+%s.%N"
readonly _durationPatternWithoutNanoseconds="+%X"
readonly _durationPatternWithNanoseconds="${_durationPatternWithoutNanoseconds}.%N"
readonly _timePatternWithoutNanoseconds="+%x-%X"
readonly _timePatternWithNanoseconds="${_timePatternWithoutNanoseconds}.%N"

#-------------------------------------------------------------------------------
# public functions
function timerReset         {
  timerName=${1:-"DEFAULT"} ; traceVar timerName
  _timerStart[${timerName}]=$(date "${_datePattern}") ; traceVar _timerStart
  _timerTop[${timerName}]=0 ; traceVar _timerTop
}
function timerTop           {
  timerName=${1:-"DEFAULT"} ; traceVar timerName
  if [[ "${_timerStart[${timerName}]}" != "" ]] ; then
    local stop=$(date "${_datePattern}") ; traceVar stop
    duration=$(echo "${stop} - ${_timerStart[${timerName}]}" | bc -l )
    [[ "${duration::1}" == "." ]] && duration="0${duration}" ; traceVar duration
    _timerTop[${timerName}]=${duration} ; traceVar _timerTop
  fi
}
function timerStop          {
  timerName=${1:-"DEFAULT"} ; traceVar timerName
  unset _timerTop[${timerName}]   ;   traceVar _timerTop
  unset _timerStart[${timerName}] ;   traceVar _timerStart
  traceVar
}
function timerGet           {
  timerName=${1:-"DEFAULT"} ; traceVar timerName
  echo "${_timerTop[${timerName}]}"
}
function timerIsStarted     {
  timerName=${1:-"DEFAULT"} ; traceVar timerName
  if [[ "$(timerGet ${timerName})" == "" ]]  ; then
    echo ko
  else
    echo ok
  fi
}
function isTimerStarted     {
  timerName=${1:-"DEFAULT"} ; traceVar timerName
  [[ "$(timerGet ${timerName})" == "" ]] && return 1 || return 0 ;
}
function timerGetStartTime  {
  local timerName=${1:-"DEFAULT"} ; traceVar timerName
  local withNanoSeconds=$2        ; traceVar withNanoSeconds
  local timePattern=${_timePatternWithoutNanoseconds}
  [[ "${withNanoSeconds}" != "" ]] && timePattern=${_timePatternWithNanoseconds}
  traceVar timePattern
  if [[ "$(timerGet ${timerName})" == "" ]] ; then
    echo ""
  else
    traceVar _timerStart
    local timeStamp=${_timerStart[${timerName}]} ; traceVar timeStamp
    date -d  @${timeStamp} "${timePattern}"
  fi
}
function timerGetDuration   {
  local timerName=${1:-"DEFAULT"} ; traceVar timerName
  local withNanoSeconds=$2        ; traceVar withNanoSeconds
  local durationPattern=${_durationPatternWithoutNanoseconds}
  [[ "${withNanoSeconds}" != "" ]] && durationPattern=${_durationPatternWithNanoseconds}
  traceVar durationPattern
  if [[ "$(timerGet ${timerName})" == "" ]] ; then
    echo ""
  else
    traceVar _timerStart
    local timerDuration=${_timerTop[${timerName}]} ; traceVar timerDuration
    date -u -d  @${timerDuration} "${durationPattern}"
  fi
}

[[ "${timerLib_WithTrace}" != "true" ]]   && enableTrace # disabling traceLib functions
