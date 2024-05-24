#-------------------------------------------------------------------------------
# testing driver helper
[[ ! -z ${testingHelper} ]] && \
  echo 'warning testingHelper.sh imported multiple times, protect import with [[ -z ${testingHelper+x} ]]' >&2
readonly testingHelper=1

#-------------------------------------------------------------------------------
# Initialization
# get script location
readonly SCRIPT_HOME=${0%/*}
# get lib location: assumes script is run from a lib sibling directory
LIB_PATH=$(realpath ${SCRIPT_HOME}/../lib)
# control import placement
if [[ ! -z ${testingLib+x} ]] ; then
  echo FATAL ERROR:testingHelper must be placed before any other import >&2
  exit 1
fi
#import core libraries
source ${LIB_PATH}/coreLib
# trace & ensure activation option must be placed before testingLib import
#testingLib_WithTrace=true
#testingLib_WithEnsure=true
[ -z ${testingLib+x} ]  && source ${LIB_PATH}/testingLib
[[ "${testingHelper_WithTrace}" != "true" ]] && disableTrace
trapAppend "echo terminate on TERM signal; exit 1" TERM

#-------------------------------------------------------------------------------
# private section
readonly _ITEM_ALL=all
readonly _ITEM_NONE=""
readonly _ITEM_LIST=list

declare _passMode=""
declare _traceMode=false
declare _listMode=false
declare _itemName=""
declare _itemCount=0

function _passTest {
  if [[ "${_passMode}" == "${_ITEM_NONE}" ]] ; then
    echo ignore $1
    return 1
  elif [[ "${_passMode}" == "${_ITEM_ALL}" ]] ; then
    return 0
  elif [[ "${_passMode}" == "${_ITEM_LIST}" ]] ; then
    if inArray _itemList2Test $1 ; then
      return 0
    else
      echo ignore $1
      return 1
    fi
  fi
}

#-------------------------------------------------------------------------------
# public section
readonly EXPECT_PASS=0
readonly EXPECT_FAIL=1

declare forceTest=false   ; traceVar forceTest
declare function2Test=""  ; traceVar function2Test


function itemStart    {
  function2Test=$1 ; traceVar function2Test
  _itemName="${function2Test}${2}" ; traceVar _itemName
  if ${_listMode} ; then
    echo "item: '${_itemName}'"
    return 1
  fi
  if ${forceTest} || (_passTest ${_itemName}) ; then
    (( _itemCount++ ))
    testItemStart "${_itemName}"
    return 0
  else
    return 1
  fi
}
function itemEnd      {
  testItemEnd
  forceTest=false
  ${_traceMode} || setTraceOff
}
function suiteStart   {
  if ${_listMode} ; then
    echo "suite: '$1'"
    return 1
  fi
  testSuiteStart $1 "$2"
}
function suiteEnd     {
  if ${_listMode} ; then
    echo "suite contains ${_itemCount} items"
    exit 0
  else
    testSuiteEnd
    echo "failled test steps: ${TEST_STATUS}"
    exit ${TEST_STATUS}
  fi
}
function itemCountGet { echo ${_itemCount} ; }
function chekFiles    {
  # check file name presence
  if (( $# < 1 )) ; then
    fatal "${USAGE} <videoFile>"
  fi
  local fileName=$1
  # check if the file is a regular file
  if [[ ! -f ${fileName} ]] ; then
    fatal "file '${fileName}' do not exist or not a regular file"
  fi
  # check if the file can be read
  if [[ ! -r ${fileName} ]] ; then
    fatal  "unable to read '${fileName}'"
  fi
  # check if the file is empty
  if [[ ! -s ${fileName} ]] ; then
    fatal "empty file '${fileName}'"
  fi
  echo ${fileName}
}
function inListMode   { ${_listMode} ; }

#-------------------------------------------------------------------------------
# usage & help
readonly USAGE='usage: %s [-h] [-v] [-i "<item id list>"] [-a]'
readonly HELP="
Execute test suite
  -h: display this help
      ignore any other options and parameters
  -v: verbose mode, display traces
  -a: execute all test items
  -i: execute test items in the list
      items id are anclosed between double quote and separated by space
  -l: display testing information
      test suite id
      list of test items
"
#-------------------------------------------------------------------------------
# parse options
[[ "${testingHelper_WithTrace}" != "true" ]] && enableTrace

while getopts ":h :v :a :l :i:" opt; do
  case ${opt} in
    h)
      help
      exit 0
      ;;
    v)
      setTraceOn
      _traceMode=true                   ; traceVar _traceMode
      trace "verbose mode"
      ;;
    i)
      _itemList2Test=($echo ${OPTARG})  ; traceVar _itemList2Test
      _passMode=${_ITEM_LIST}           ; traceVar _passMode
      ;;
    a)
      _passMode=${_ITEM_ALL}            ; traceVar _passMode
      ;;
    l)
      _listMode=true                    ; traceVar _listMode
      ;;
    \?)
      error "Invalid option: -$OPTARG"
      usage
      exit 1
      ;;
    :)
      error "Option -$OPTARG requires an argument."
      usage
      exit 1
      ;;
  esac
done
shift $(( OPTIND-1 ))
