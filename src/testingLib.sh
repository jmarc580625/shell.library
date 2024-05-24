#-------------------------------------------------------------------------------
# test utilities
[[ -z ${testingLib} ]] || \
  (echo 'warning testingLib imported multiple times, protect import with [[ -z ${testingLib+x} ]]' >&2)
readonly testingLib=1

#-------------------------------------------------------------------------------
# import
declare _TESTINGLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${trapLib+x} ]]   && source ${_TESTINGLIB_LIB_PATH}/trapLib
[[ -z ${traceLib+x} ]]  && source ${_TESTINGLIB_LIB_PATH}/traceLib
[[ -z ${ensureLib+x} ]] && source ${_TESTINGLIB_LIB_PATH}/ensureLib
[[ -z ${controlerLib+x} ]] && source ${_TESTINGLIB_LIB_PATH}/controlerLib
[[ -z ${highlightLib+x} ]] && source ${_TESTINGLIB_LIB_PATH}/highlightLib
[[ -z ${timerLib+x} ]]     && source ${_TESTINGLIB_LIB_PATH}/timerLib
unset _TESTINGLIB_LIB_PATH

#-------------------------------------------------------------------------------
# disable tracing, must be placed after traceLib import
[[ "${testingLib_WithTrace}" != "true" ]] && disableTrace
# disable ensure, must be placed after ensureLib import
[[ "${testingLib_WithEnsure}" != "true" ]]  && disableEnsure

trapPrepend testSuiteEnd EXIT

#-------------------------------------------------------------------------------
# public variables
readonly CONTROL_OK=ok
readonly CONTROL_KO=ko
readonly TEST_PASS=PASS
readonly TEST_FAIL=FAIL

declare TEST_STATUS

#-------------------------------------------------------------------------------
# private variables
# text coloring patterns
declare -A _PatternTestPASS
_PatternTestPASS[Json]='\("result":"\)\('${TEST_PASS}'\)\("\)'
_PatternTestPASS[Xml]='\(result="\)\('${TEST_PASS}'\)\("\)'
_PatternTestPASS[Txt]='\(RESULT=\)\('${TEST_PASS}'\)\( \)'
readonly _PatternTestPASS

declare -A _PatternTestFAIL
_PatternTestFAIL[Json]='\("result":"\)\('${TEST_FAIL}'\)\("\)'
_PatternTestFAIL[Xml]='\(result="\)\('${TEST_FAIL}'\)\("\)'
_PatternTestFAIL[Txt]='\(RESULT=\)\('${TEST_FAIL}'\)\( \)'
readonly _PatternTestFAIL

declare -A _PatternControlOK
_PatternControlOK[Json]='\("controler":".*=>\)\('${CONTROL_OK}'\)\("\)'
_PatternControlOK[Xml]='\(controler=".*=>\)\('${CONTROL_OK}'\)\("\)'
_PatternControlOK[Txt]='\(CONTROL=.*=>\)\('${CONTROL_OK}'\)\($\)'
readonly _PatternControlOK

declare -A _PatternControlKO
_PatternControlKO[Json]='\("controler":".*=>\)\('${CONTROL_KO}'\)\("\)'
_PatternControlKO[Xml]='\(controler=".*=>\)\('${CONTROL_KO}'\)\("\)'
_PatternControlKO[Txt]='\(CONTROL=.*=>\)\('${CONTROL_KO}'\)\($\)'
readonly _PatternControlKO

declare -A _PatternName
_PatternName[Json]='\("name":"\)\([^"]*\)\("\)'
_PatternName[Xml]='\(name="\)\([^"]*\)\("\)'
_PatternName[Txt]='\(name="\)\([^"]*\)\("\)'
readonly _PatternName

declare -A _PatternId
_PatternId[Json]='\(id":"\)\([^"]*\)\("\)'
_PatternId[Xml]='\(id="\)\([^"]*\)\("\)'
_PatternId[Txt]='\(id="\)\([^"]*\)\("\)'
readonly _PatternId

#-------------------------------------------------------------------------------
# text coloring function
function _testingHighlight {
  printf "$@" | \
  sed \
    -e "s/${_PatternId[${_OUT_FORMAT_CURRENT}]}/\1${fgLightYellow}\2${hlReset}\3/g" \
    -e "s/${_PatternName[${_OUT_FORMAT_CURRENT}]}/\1${fgLightCyan}\2${hlReset}\3/g" \
    -e "s/${_PatternTestPASS[${_OUT_FORMAT_CURRENT}]}/\1${fgLightGreen}\2${hlReset}\3/g" \
    -e "s/${_PatternTestFAIL[${_OUT_FORMAT_CURRENT}]}/\1${fgLightRed}\2${hlReset}\3/g" \
    -e "s/${_PatternControlOK[${_OUT_FORMAT_CURRENT}]}/\1${fgLightGreen}\2${hlReset}\3/g" \
    -e "s/${_PatternControlKO[${_OUT_FORMAT_CURRENT}]}/\1${fgLightRed}\2${hlReset}\3/g"
}
getHighlighter _highlightOn _testingHighlight

#-------------------------------------------------------------------------------
# text coloring control
declare _HIGHLIGHT

# highlight turned on when stdout is a terminal
[[ -t 1 ]] && _HIGHLIGHT=on || _HIGHLIGHT=off

declare -A _highlightFn
_highlightFn[on]=_highlightOn
_highlightFn[off]=printf
readonly _highlightFn

function _highlight { ${_highlightFn[${_HIGHLIGHT}]} "$@" ; }

if [[ "${tesingLib_WithoutHighlight}" == "true" ]] ; then
  # highlight disabled
  _highlightFn[on]=printf
fi

#-------------------------------------------------------------------------------
# message format type
readonly _OUT_FORMAT_XML=XML
readonly _OUT_FORMAT_JSON=JSON
readonly _OUT_FORMAT_TXT=TXT
readonly _OUT_FORMAT_DEFAULT=${_OUT_FORMAT_XML}

declare -A _Formats
_Formats[${_OUT_FORMAT_XML}]=Xml
_Formats[${_OUT_FORMAT_JSON}]=Json
_Formats[${_OUT_FORMAT_TXT}]=Txt
readonly _Formats

declare _OUT_FORMAT_CURRENT=${_Formats[${_OUT_FORMAT_DEFAULT}]}

#-------------------------------------------------------------------------------
# message templates
declare -A _MsgStartTestSuite
_MsgStartTestSuite[Json]="\"testsuite\":{\n\"id\":\"%s\", \n\"description\":\"%s\"\n"
_MsgStartTestSuite[Xml]="<testsuite id=\"%s\" description=\"%s\">\n"
_MsgStartTestSuite[Txt]="<TEST SUITE:%s  - %s\n"
readonly _MsgStartTestSuite

declare -A _MsgEndTestSuite
_MsgEndTestSuite[Json]="}\n"
_MsgEndTestSuite[Xml]="</testsuite>\n"
_MsgEndTestSuite[Txt]="</testsuite>\n"
readonly _MsgEndTestSuite

declare -A _MsgStartTestItem
_MsgStartTestItem[Json]="\"testitem\":{\n\"id\":\"%s\", \n\"description\":\"%s\"\n"
_MsgStartTestItem[Xml]="<testitem id=\"%s\" description=\"%s\">\n"
_MsgStartTestItem[Txt]="- ITEM:%s - %s>\n"
readonly _MsgStartTestItem

declare -A _MsgEndTestItem
_MsgEndTestItem[Json]="}\n"
_MsgEndTestItem[Xml]="</testitem>\n"
_MsgEndTestItem[Txt]="\n"
readonly _MsgEndTestItem

declare -A _MsgTestStep
_MsgTestStep[Json]="\"teststep\":{\n\"description\":\"%s\"\n}\n"
_MsgTestStep[Xml]="<teststep description=\"%s\"/>\n"
_MsgTestStep[Txt]="  - STEP:%s\n"
readonly _MsgTestStep

declare -A _MsgFunctionStart
_MsgFunctionStart[Json]="\"function\":{\n\"name\":\"%s\"\n"
_MsgFunctionStart[Xml]="<function name=\"%s\">\n"
_MsgFunctionStart[Txt]="<  - FUNCTION %s\n"
readonly _MsgFunctionStart

declare -A _MsgFunctionEnd
_MsgFunctionEnd[Json]="}\n"
_MsgFunctionEnd[Xml]="</function>\n"
_MsgFunctionEnd[Txt]=">\n"
readonly _MsgFunctionEnd

declare -A _MsgControlFunction
_MsgControlFunction[Json]="\"control\":{\n\"result\":\"%s\", \n\"value\":\"%s\"\n, \n\"controler\":\"%s\"}\n"
_MsgControlFunction[Xml]="<control result=\"%s\" value=\"%s\" controler=\"%s\"/>\n"
_MsgControlFunction[Txt]="    - RESULT=%s VALUE=%s CONTROL=%s\n"
readonly _MsgControlFunction

declare -A _MsgControlValue
_MsgControlValue[Json]="control:{\n\"result\":\"%s\", \n\"value\":\"%s\", \n\"controler\":\"%s\"\n}\n"
_MsgControlValue[Xml]="<control result=\"%s\" value=\"%s\" controler=\"%s\" />\n"
_MsgControlValue[Txt]="  - RESULT=%s VALUE=%s CONTROL=%s\n"
readonly _MsgControlValue

declare -A _MsgDisplayVariable
_MsgDisplayVariable[Json]="\"variable\":{\n\"name\":\"%s\", \n\"value\":\"%s\"\n}\n"
_MsgDisplayVariable[Xml]="<variable name=\"%s\" value=\"%s\"/>\n"
_MsgDisplayVariable[Txt]="  - %s=%s\n"
readonly _MsgDisplayVariable

declare -A _MsgDisplayValue
_MsgDisplayValue[Json]="\"value\":{\n\"content\":\"%s\"\n}\n"
_MsgDisplayValue[Xml]="<value content=\"%s\"/>\n"
_MsgDisplayValue[Txt]="  - VALUE=%s\n"
readonly _MsgDisplayValue

declare -A _MsgStartDisplayArray
_MsgStartDisplayArray[Json]="\"%s\":[\n"
_MsgStartDisplayArray[Xml]="<array name=\"%s\">\n"
_MsgStartDisplayArray[Txt]="  - ARRAY:%s\n"
readonly _MsgStartDisplayArray

declare -A _MsgDisplayArrayElement
_MsgDisplayArrayElement[Json]="{\"key\":%.0s%s \"value\":%s}\n"
_MsgDisplayArrayElement[Xml]="<element %.0s key=\"%s\" value=\"%s\"/>\n"
_MsgDisplayArrayElement[Txt]="    - %s[%s]=%s\n"
readonly _MsgDisplayArrayElement

declare -A _MsgEndDisplayArray
_MsgEndDisplayArray[Json]="]\n"
_MsgEndDisplayArray[Xml]="</array>\n"
_MsgEndDisplayArray[Txt]="\n"
readonly _MsgEndDisplayArray

declare -A _MsgAbort
_MsgAbort[Json]="\"abort\":{\n\"reason\":\"%s\"\n}\n"
_MsgAbort[Xml]="<abort reason=\"%s\"/>\n"
_MsgAbort[Txt]="<- ABORT:%s\n"
readonly _MsgAbort

declare -A _MsgStartStatistics
_MsgStartStatistics[Json]="\"statistics\":{\n\"testsuite\":\"%s\"\n}\n"
_MsgStartStatistics[Xml]="<statistics testsuite=\"%s\">\n"
_MsgStartStatistics[Txt]="- STATISTICS FOR:%s\n"
readonly _MsgStartStatistics

declare -A _MsgEndStatistics
_MsgEndStatistics[Json]="}\n"
_MsgEndStatistics[Xml]="</statistics>\n"
_MsgEndStatistics[Txt]=""
readonly _MsgEndStatistics

declare -A _MsgItemStatistics
_MsgItemStatistics[Json]="\"testitem \":{\n\"passed\":\"%s\"}\n"
_MsgItemStatistics[Xml]="<testitem passed=\"%s\">\n"
_MsgItemStatistics[Txt]="  - test item passed:%s\n"
readonly _MsgItemStatistics

declare -A _MsgFunctionControlStatistics
_MsgFunctionControlStatistics[Json]="\"functioncontrol\":{\n\"passed\":\"%s\", \n\"succeeded\":\"%s\"\n}\n"
_MsgFunctionControlStatistics[Xml]="<functioncontrol passed=\"%s\" succeeded=\"%s\"/>\n"
_MsgFunctionControlStatistics[Txt]="  - function control passed:%s succeeded:%s\n"
readonly _MsgFunctionControlStatistics

declare -A _MsgValueControlStatistics
_MsgValueControlStatistics[Json]="\"valuecontrol\":{\n\"passed\":\"%s\", \n\"succeeded\":\"%s\"\n}\n"
_MsgValueControlStatistics[Xml]="<valuecontrol passed=\"%s\" succeeded=\"%s\"/>\n"
_MsgValueControlStatistics[Txt]="  - value control passed:%s succeeded:%s\n"
readonly _MsgValueControlStatistics

declare -A _MsgTimingStastistics
_MsgTimingStastistics[Json]="\"timing\":{\n\"starttime\":\"%s\"\n\"duration\":\"%s\"\n}\n"
_MsgTimingStastistics[Xml]="<timing starttime=\"%s\" duration=\"%s\">\n"
_MsgTimingStastistics[Txt]="  - start time:%s duration:%s\n"
readonly _MsgTimingStastistics

#-------------------------------------------------------------------------------
# statistics
readonly _STAT_STOPPED=stopped
readonly _STAT_STARTED=started
readonly _STAT_OFF=off

readonly _STAT_PASSED=Passed
readonly _STAT_SUCCEEDED=Succeeded

readonly _STAT_FUNCTION_CONTROL=functionControl
readonly _STAT_VALUE_CONTROL=variableControl
readonly _STAT_TEST_ITEM=testItem
readonly _STAT_TEST_SUITE=testSuite

declare -A _Statistics
_Statistics[testSuiteName]=""
_Statistics[${_STAT_VALUE_CONTROL}${_STAT_PASSED}]=0
_Statistics[${_STAT_VALUE_CONTROL}${_STAT_SUCCEEDED}]=0
_Statistics[${_STAT_FUNCTION_CONTROL}${_STAT_PASSED}]=0
_Statistics[${_STAT_FUNCTION_CONTROL}${_STAT_SUCCEEDED}]=0
_Statistics[${_STAT_TEST_ITEM}${_STAT_PASSED}]=0
_Statistics[${_STAT_TEST_ITEM}${_STAT_SUCCEEDED}]=0
_Statistics[${_STAT_TEST_SUITE}${_STAT_PASSED}]=0
_Statistics[${_STAT_TEST_SUITE}${_STAT_SUCCEEDED}]=0
_Statistics[statisticsPublished]=0

readonly _STAT_TEST_SUITE_TIMER=testingSuiteStatistics

function _satisticsResetSuiteStatistics {
  timerReset ${_STAT_TEST_SUITE_TIMER}
  _Statistics[${_STAT_VALUE_CONTROL}${_STAT_PASSED}]=0
  _Statistics[${_STAT_VALUE_CONTROL}${_STAT_SUCCEEDED}]=0
  _Statistics[${_STAT_FUNCTION_CONTROL}${_STAT_PASSED}]=0
  _Statistics[${_STAT_FUNCTION_CONTROL}${_STAT_SUCCEEDED}]=0
  _Statistics[${_STAT_TEST_ITEM}${_STAT_PASSED}]=0
  _Statistics[${_STAT_TEST_ITEM}${_STAT_SUCCEEDED}]=0
}
function _satisticsValues          {
  if [[ "$(_satisticsSuiteStatus)" == "${_STAT_STARTED}" ]] ; then
    echo ${_Statistics[${1}${_STAT_PASSED}]} ${_Statistics[${1}${_STAT_SUCCEEDED}]}
  fi
}
function _satisticsStatus          { (( ${_Statistics[${1}${_STAT_PASSED}]} > ${_Statistics[${1}${_STAT_SUCCEEDED}]} )) && echo ${_STAT_STARTED} || echo ${_STAT_STOPPED} ; }
function _satisticsSuiteStatus     { _satisticsStatus ${_STAT_TEST_SUITE} ; }
function _satisticsItemStatus      { _satisticsStatus ${_STAT_TEST_ITEM} ; }
function _satisticsItemIncrement   { (( _Statistics[$1]++ )) ; }
function _satisticsSuiteStart      {
  local testSuiteName=$1 ; traceVar ${_STAT_TEST_SUITE}Name
  _Statistics[testSuiteName]=${testSuiteName}
  _Statistics[statisticsPublished]=0
  _satisticsResetSuiteStatistics
  _satisticsItemIncrement ${_STAT_TEST_SUITE}${_STAT_PASSED}
}
function _satisticsSuiteStop       { _satisticsItemIncrement ${_STAT_TEST_SUITE}${_STAT_SUCCEEDED} ; }
function _satisticsItemStart       { _satisticsItemIncrement ${_STAT_TEST_ITEM}${_STAT_PASSED} ; }
function _satisticsItemStop        { _satisticsItemIncrement ${_STAT_TEST_ITEM}${_STAT_SUCCEEDED} ; }
function _satisticsFunctionUpdate  { _satisticsUpdate ${_STAT_FUNCTION_CONTROL} $1 ; }
function _satisticsValueUpdate     { _satisticsUpdate ${_STAT_VALUE_CONTROL} $1 ; }
function _satisticsUpdate          {
#  setTraceOn
  if [[ "$(_satisticsSuiteStatus)" == "${_STAT_STARTED}" ]] ; then
    local passed="${1}${_STAT_PASSED}"        ; traceVar passed       ; traceVar _Statistics[${passed}]
    local succeeded="${1}${_STAT_SUCCEEDED}"  ; traceVar succeeded    ; traceVar _Statistics[${succeeded}]
    (( _Statistics[${passed}]++ ))                                    ; traceVar _Statistics[${passed}]
    [[ "$2" == "${TEST_PASS}" ]] && (( _Statistics[${succeeded}]++ )) ; traceVar _Statistics[${succeeded}]
  fi
#  setTraceOff
}
function _satisticsPublish         {
  if [[ "$(_satisticsSuiteStatus)" == "${_STAT_STARTED}" && ((${_Statistics[statisticsPublished]} == 0)) ]] ; then
    _highlight "${_MsgStartStatistics[${_OUT_FORMAT_CURRENT}]}" "${_Statistics[testSuiteName]}"
    _highlight "${_MsgItemStatistics[${_OUT_FORMAT_CURRENT}]}" "$(satisticsItemCount)"
    eval stats=("$(getSatisticsFunctionControl)")
    _highlight "${_MsgFunctionControlStatistics[${_OUT_FORMAT_CURRENT}]}" "${stats[@]}"
    eval stats=($(getSatisticsVariableControl))
    _highlight "${_MsgValueControlStatistics[${_OUT_FORMAT_CURRENT}]}" "${stats[@]}"
    timerTop ${_STAT_TEST_SUITE_TIMER}
    _highlight "${_MsgTimingStastistics[${_OUT_FORMAT_CURRENT}]}" "$(timerGetStartTime ${_STAT_TEST_SUITE_TIMER})" "$(timerGetDuration ${_STAT_TEST_SUITE_TIMER})"
    _highlight "${_MsgEndStatistics[${_OUT_FORMAT_CURRENT}]}"
    _satisticsItemIncrement statisticsPublished
  fi
}
function _getTestingSuiteStatus    {
  # test suite must be open
  fnStat=$(getSatisticsFunctionControl)      ; traceVar fnStat
  assertStat=$(getSatisticsVariableControl)    ; traceVar assertStat
  functionFailed=$(( ${fnStat/ / - } ))  ; traceVar functionFailed
  assertFailed=$(( ${assertStat/ / - } )); traceVar assertFailed
  echo $(( functionFailed + assertFailed ))
}

#-------------------------------------------------------------------------------
# misc
readonly _integerRE_2='^([+-])?0*([0-9]{1,18})$'
readonly _integerRE='^(0|[1-9][0-9]{0,17})$'

#-------------------------------------------------------------------------------
# variable content capture
function displayElement {
  local element=$1; traceVar element
  [[ "$(_satisticsItemStatus)" != "${_STAT_STARTED}" ]] && testItemStart ANONYMOUS
  if isArray "${element}" ; then
    _highlight "${_MsgStartDisplayArray[${_OUT_FORMAT_CURRENT}]}" "${element}"
    declare -n array=${element}
    for k in "${!array[@]}" ; do
        _highlight "${_MsgDisplayArrayElement[${_OUT_FORMAT_CURRENT}]}" "${element}" "$k" "${array[$k]}"
    done
    _highlight "${_MsgEndDisplayArray[${_OUT_FORMAT_CURRENT}]}"
  elif isVariable "${element}" ; then
    declare -n value=$1
    _highlight "${_MsgDisplayVariable[${_OUT_FORMAT_CURRENT}]}" "${element}" "${value}"
  else
    _highlight "${_MsgDisplayValue[${_OUT_FORMAT_CURRENT}]}" "${element}"
  fi
  set +x
}
#-------------------------------------------------------------------------------
# control function
function _ensureCAT {
  $(kill -0 ${CAT_PID} 2>/dev/null 1>&2) || coproc CAT { cat ; }
  traceVar CAT[0]
  traceVar CAT[1]
  traceVar CAT_PID
}
function _killCAT   { kill ${CAT_PID} 2>/dev/null 1>&2 ; }
function _readAnswer {
  local answer=''
  if read -t 0 <&${CAT[0]} ; then
    # if there is something to read
    read answer <&${CAT[0]}
    # flush the pipe
    while read -t 0 <&${CAT[0]} ; do read x <&${CAT[0]} ; done
  else
    trace no answer to read
  fi
  traceVar answer
  echo ${answer}
}
function _execHere   {
  local -n result=$1
  _ensureCAT
  $2 "${@:3}" >&${CAT[1]} && trace push result
  echo >&${CAT[1]}        # ensure command output is flushed in the pipe
  result=$(_readAnswer)   && trace pop  result
}
# expectedControlResult=$1 controlingFunctionVector=$2 ; controledFunctionVector=$2
function controlFunction  {
  ensure isInteger $1;  local expect=$( (( $1 == 0 )) && echo 0 || echo 1)
  ensure isArray   $2;  declare -n controler=$2 ; traceVar controler
  if isBlank $3 ; then
    toTest=""
  else
    ensure isArray   $3;  declare -n toTest=$3    ; traceVar toTest ;
  fi
  report=$(control controler toTest)
  controlCR=$( (( $? == 0 )) && echo 0 || echo 1)
  local testResult=$( (( controlCR == expect )) && echo ${TEST_PASS} || echo ${TEST_FAIL} )

  OFS=$IFS; IFS=$'\n' controlReport=($(xargs -n1 <<<${report})) ; IFS=$OFS
  local functionReport=${controlReport[1]} ; traceVar functionReport
  local controlerReport=${controlReport[0]} ;
#  read controlerReport functionReport <<< ${report}
  controlerReport=${controlerReport/=>0/=>${CONTROL_OK}} ; controlerReport=${controlerReport/=>1/=>${CONTROL_KO}} ; traceVar controlerReport
  local functionUnderTest=${toTest[0]}

  [[ "$(_satisticsItemStatus)" != "${_STAT_STARTED}" ]] && testItemStart ANONYMOUS
  _highlight  "${_MsgFunctionStart[${_OUT_FORMAT_CURRENT}]}" "${functionUnderTest}"
  _highlight  "${_MsgControlFunction[${_OUT_FORMAT_CURRENT}]}" "${testResult}" "${functionReport}" "${controlerReport}"
  _highlight  "${_MsgFunctionEnd[${_OUT_FORMAT_CURRENT}]}"
  _satisticsFunctionUpdate ${testResult}
}
# expectedControlResult=$1 controlingFunctionVector=$2 ; controledValue=$2
function controlValue     {
  trace "params=$@"
  ensure isInteger $1;  local expect=$( (( $1 == 0 )) && echo 0 || echo 1 )
  ensure isArray   $2;  declare -n controler=$2 ; traceVar controler
  local valueToTest=$3 ; traceVar valueToTest

  report=$(control controler "${valueToTest}")
  controlCR=$( (( $? == 0 )) && echo 0 || echo 1)
  local testResult=$( (( controlCR == expect )) && echo ${TEST_PASS} || echo ${TEST_FAIL} )

  OFS=$IFS; IFS=$'\n' controlReport=($(xargs -n1 <<<${report})); IFS=$OFS
  local functionReport=${controlReport[1]} ; traceVar functionReport
  local controlerReport=${controlReport[0]} ;
#  read -r controlerReport functionReport <<< ${report}
  controlerReport=${controlerReport/=>0/=>${CONTROL_OK}} ; controlerReport=${controlerReport/=>1/=>${CONTROL_KO}} ; traceVar controlR

  [[ "$(_satisticsItemStatus)" != "${_STAT_STARTED}" ]] && testItemStart ANONYMOUS
  _highlight "${_MsgControlValue[${_OUT_FORMAT_CURRENT}]}" "${testResult}" "${functionReport}" "${controlerReport}"
  _satisticsValueUpdate ${testResult}
}
#-------------------------------------------------------------------------------
# test suite control
function testSuiteStart {
  local name=$1               ; traceVar name
  local description=$2        ; traceVar description
  testSuiteEnd
  _satisticsSuiteStart ${name}
  _highlight "${_MsgStartTestSuite[${_OUT_FORMAT_CURRENT}]}" "${name}" "${description}"
  TEST_STATUS=""
}
function testSuiteEnd   {
  local returnCode=""
  if [[ "$(_satisticsSuiteStatus)" == "${_STAT_STARTED}" ]] ; then
    testItemEnd
    _highlight "${_MsgEndTestSuite[${_OUT_FORMAT_CURRENT}]}" ;
    _satisticsPublish
    TEST_STATUS=$(_getTestingSuiteStatus)
    _satisticsSuiteStop
  fi

  echo ${returnCode}
}
function testSuiteAbort {
  _highlight "${_MsgAbort[${_OUT_FORMAT_CURRENT}]}" "$@" ;
  testSuiteEnd    # silently capture return code
  kill -TERM $$
 }

 #-------------------------------------------------------------------------------
 # test item control
function testItemStart {
  local id=$1
  local description=${@:2}
  [[ "$(_satisticsSuiteStatus)" != "${_STAT_STARTED}" ]] &&  testSuiteStart ANONYMOUS
  testItemEnd
  _satisticsItemStart
  _highlight "${_MsgStartTestItem[${_OUT_FORMAT_CURRENT}]}" "${id}" "${description}"
}
function testItemEnd   {
  if [[ "$(_satisticsItemStatus)" == "${_STAT_STARTED}" ]] ; then
    _highlight "${_MsgEndTestItem[${_OUT_FORMAT_CURRENT}]}" "$@"
    _satisticsItemStop
  fi
}

#-------------------------------------------------------------------------------
# test step
function testStep {
 local description=${@}
 _highlight "${_MsgTestStep[${_OUT_FORMAT_CURRENT}]}" "${description}"
}

#-------------------------------------------------------------------------------
# text highlighting control
function setHighlightOn   { _HIGHLIGHT=on ; traceVar _HIGHLIGHT ; }
function setHighlightOff  { _HIGHLIGHT=off ; traceVar _HIGHLIGHT ; }
function getHighlight     { echo ${_HIGHLIGHT} ; }

#-------------------------------------------------------------------------------
# text output format control
function setOutFormat           {
  local outFormat=${1:=${_Formats[0}]}}
  f=${_Formats[${1^^}]}             ; traceVar f            # index key ($1) set to uppercase and get corresponding format
  _OUT_FORMAT_CURRENT=${f:=${_OUT_FORMAT_CURRENT}}  ; traceVar _OUT_FORMAT_CURRENT  # keep current format if no format is found
}
function setDefaultOutFormat    { _OUT_FORMAT_CURRENT=${_Formats[${_OUT_FORMAT_DEFAULT}]} ; }
function getOutFormat           { echo ${_OUT_FORMAT_CURRENT} ; }
function getSupportedOutFormats { echo ${_Formats[*]} ; }

#-------------------------------------------------------------------------------
# statistics queries
function satisticsItemCount          { [[ "$(_satisticsSuiteStatus)" == "${_STAT_STARTED}" ]] && echo ${_Statistics[testItem${_STAT_PASSED}]} || echo ; }
function getSatisticsFunctionControl { _satisticsValues ${_STAT_FUNCTION_CONTROL} ; }
function getSatisticsVariableControl { _satisticsValues ${_STAT_VALUE_CONTROL} ; }

#-------------------------------------------------------------------------------
# utilities
function getRandom    { local limit=$1; limit=${limit:=10} ; echo $(( RANDOM % limit )) ; }
function getRandom_9  { date +%S | grep -o .$ | sed s/0/10/  ; }
function getRandom_60 { date +%S | grep -o ..$ | sed s/0/60/  ; }

function echoDollar1   { echo $1 ; }
function echoDollarAll { echo $@ ; }
function returnDollar1   { return $1 ; }

#-------------------------------------------------------------------------------
# epilogue : enable tracing back
#-------------------------------------------------------------------------------
[[ "${testingLib_WithTrace}" != "true" ]]   && enableTrace
[[ "${testingLib_WithEnsure}" != "true" ]]  && enableEnsure
