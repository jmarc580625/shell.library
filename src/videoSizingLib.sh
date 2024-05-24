#-------------------------------------------------------------------------------
# video sizing utilities
[[ -z ${videoSizingLib} ]] || \
  echo 'warning videoSizingLib imported multiple times, protect import with [[ -z ${videoSizingLib+x} ]]' >&2
readonly videoSizingLib=1

#-------------------------------------------------------------------------------
# import
declare _VIDEOSIZINGLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${traceLib+x} ]]      && source ${_VIDEOSIZINGLIB_LIB_PATH}/traceLib
[[ -z ${controlerLib+x} ]]  && source ${_VIDEOSIZINGLIB_LIB_PATH}/controlerLib
[[ -z ${exiftoolLib+x} ]]   && source ${_VIDEOSIZINGLIB_LIB_PATH}/exiftoolLib
unset _VIDEOSIZINGLIB_LIB_PATH

[[ "${videoSizingLib_WithTrace}" != "true" ]] && disableTrace # disabling traceLib functions

#-------------------------------------------------------------------------------
# public variables
declare STEP=16
readonly TARGET_UPPER="Upper"
readonly TARGET_LOWER="Lower"
readonly TARGET_CLOSER="Closer"
readonly TARGET_DEFAULT=${TARGET_CLOSER}

#-------------------------------------------------------------------------------
# private functions
function _resizeCalculation {
  initialWidth=$1
  traceVar initialWidth
  widthRatio=$2
  traceVar widthRatio
  heightRatio=$3
  traceVar heightRatio
  oversize=$4
  traceVar oversize
  target=$5
  traceVar target
  traceIsOn=$([[ "${TRACE}" != "on" ]])$?
  traceVar traceIsOn
  awk --lint \
  -v traceIsOn=${traceIsOn} \
  -v initialWidth=${initialWidth} -v widthRatio=${widthRatio} -v heightRatio=${heightRatio} \
  -v step=${STEP}\
    -v oversize=${oversize} -v target=${target} \
    'function _trace(str) {
      if (traceIsOn) {
        print str > "/dev/stderr"
      }
    }
    BEGIN{
      _trace("step="step)
      if (oversize=="no") oversize=""
      _trace("oversize="oversize)

      upperWidth=initialWidth
      _trace("initialWidth="initialWidth)

      lowerWidth=upperWidth
      rest=initialWidth % step
      if (rest != 0) {
        upperWidth+=(step-rest)
        lowerWidth-=rest
      }
      _trace("lowerWidth="lowerWidth)
      _trace("upperWidth="upperWidth)
      over=oversize
      while (1) {
        upperHeight = upperWidth * heightRatio / widthRatio
        if ((upperHeight == int(upperHeight)) && ((upperHeight % 2) == 0)) {
          _trace("upperHeight="upperHeight)
          _trace("over="over)
          if (over == "") break
          over = ""
        }
        upperWidth+=step
      }
      _trace("upperSize="upperWidth"x"upperHeight)
      over=oversize
      while (1) {
        lowerHeight = lowerWidth * heightRatio / widthRatio
        if ((lowerHeight == int(lowerHeight)) && ((lowerHeight % 2) == 0)) {
          _trace("lowerHeight="lowerHeight)
          _trace("over="over)
          if (over == "") break
          over = ""
        }
        lowerWidth-=step
      }
      _trace("lowerSize="lowerWidth"x"lowerHeight)

      targetWidth=upperWidth
      targetHeight=upperHeight
      if ((initialWidth - lowerWidth) < (upperWidth - initialWidth)) {
        targetWidth = lowerWidth
        targetHeight = lowerHeight
      }
      if (target == "Upper") {
        print upperWidth"x"upperHeight
      } else if (target == "Lower") {
        print lowerWidth"x"lowerHeight
      } else {
        print targetWidth"x"targetHeight
      }
    }'
}

#-------------------------------------------------------------------------------
readonly _sizePattern='^[1-9][0-9]*x[1-9][0-9]*$'
readonly _integerPattern='^[1-9][0-9]*$'

function _getWidthHeight  {
  trace "params=$@"
  ensure "(( $# >= 1 ))"
  if (( $# == 1 )) ; then
    local width=${1%x*}
    local height=${1#*x}
  else
    local width=$1
    local height=$2
  fi
  ensure "isInteger \"${width}\" && isInteger \"${height}\""
  traceVar width ; traceVar height
  echo "${width} ${height}"
}
function _getSurfaces     {
  trace "params=$@"
  ensure "(( $# >= 2 ))"
  if [[ "$1" =~ ${_sizePattern} ]] ; then
    s1=$(getVideoSurface $1)
    if [[ "$2" =~ ${_sizePattern} ]] ; then
      s2=$(getVideoSurface $2)
    else
      ensure "isInteger \"$2\" && isInteger \"$3\""
      s2=$(getVideoSurface $2 $3)
    fi
  else
    ensure "isInteger \"$2\""
    s1=$(getVideoSurface $1 $2)
    ensure "(( $# > 2 ))"
    if [[ "$3" =~ ${_sizePattern} ]] ; then
       s2=$(getVideoSurface $3)
     else
       ensure "(( $# > 3 ))"
       ensure "isInteger \"$3\" && isInteger \"$4\""
       s2=$(getVideoSurface $3 $4)
     fi
  fi
  traceVar s1
  traceVar s2
  echo $s1 $s2
}

#-------------------------------------------------------------------------------
declare -A _aspectRatio
_aspectRatio[1x1]=$(awk "BEGIN{print 1/1}")
_aspectRatio[5x4]=$(awk "BEGIN{print 5/4}")
_aspectRatio[4x3]=$(awk "BEGIN{print 4/3}")
_aspectRatio[16x10]=$(awk "BEGIN{print 16/10}")
_aspectRatio[16x9]=$(awk "BEGIN{print 16/9}")
readonly _aspectRatio

readonly ORIENTATION_LANDSCAPE="Landscape"
readonly ORIENTATION_PORTRAIT="Portrait"
readonly ORIENTATION_SQUARE="Square"

function getAspectRatio       {
  local videoRatio=$(getVideoRatio "$@") ;  traceVar videoRatio
  for V in  ${!_aspectRatio[@]} ; do echo ${_aspectRatio[${V}]} " " ${V}; done | \
    awk -v VAL=${videoRatio} '{
      D=(VAL - $1) * (VAL - $1)
      if((!SET) || (D < DIFF)) {
        DIFF=D
        X=$1
        R=$2
        SET=1
      }
    } END {
      printf(R);
    }'
}
function getNewVideoSize      {
  if [[ $1 =~ ${_sizePattern} ]] ; then
    read -r videoWidth videoHeight <<< $(_getWidthHeight $1)
    overSize=$2; overSize=${overSize:=no}
    target=$3; target=${target:=${TARGET_DEFAULT}}
  else
    videoHeight=$2
    videoWidth=$1
    overSize=$3; overSize=${overSize:=no}
    target=$4; target=${target:=${TARGET_DEFAULT}}
  fi
  traceVar videoWidth
  traceVar videoHeight
  traceVar overSize
  traceVar target

  videoOrientation=$(getVideoOrientation ${videoWidth} ${videoHeight})
  traceVar videoOrientation

  if [[ "${videoOrientation}" = "${ORIENTATION_LANDSCAPE}"   ]] ; then
    highest=${videoWidth}
    lowest=${videoHeight}
  else
    highest=${videoHeight}
    lowest=${videoWidth}
  fi
  local aspectRatio=$(getAspectRatio ${videoWidth} ${videoHeight}) ; traceVar aspectRatio
  read -r widthRatio heightRatio <<< $(_getWidthHeight ${aspectRatio}) ; traceVar widthRatio ; traceVar heightRatio

  local newVideoSize=$(_resizeCalculation ${highest} ${widthRatio} ${heightRatio} ${overSize} ${target})

  if [[ "${videoOrientation}" = "${ORIENTATION_PORTRAIT}"   ]] ; then
    newVideoSize=$(echo ${newVideoSize} | sed -r "s/([0-9]*)(x)([0-9]*)/\3\2\1/")
  fi

  echo ${newVideoSize}
}
function getVideoOrientation  {
  read -r videoWidth videoHeight <<< $(_getWidthHeight "$@") ; traceVar videoWidth ; traceVar videoHeight
  #determine video orientation
  awk -v videoWidth=${videoWidth} \
      -v videoHeight=${videoHeight} \
      -v square=${ORIENTATION_SQUARE} \
      -v portrait=${ORIENTATION_PORTRAIT} \
      -v landscape=${ORIENTATION_LANDSCAPE} \
    "BEGIN {
      print videoWidth >= videoHeight ? (videoWidth == videoHeight ? square : landscape) :   portrait
    }"
}
function getVideoRatio        {
  read -r videoWidth videoHeight <<< $(_getWidthHeight "$@") ; traceVar videoWidth ; traceVar videoHeight
  awk -v videoWidth=${videoWidth} -v videoHeight=${videoHeight} \
    "BEGIN {
      r1=videoWidth / videoHeight
      r2=1 / r1
      print (r1>r2?r1:r2)
    }"
}
function getVideoSurface      {
  read -r videoWidth videoHeight <<< $(_getWidthHeight "$@") ; traceVar videoWidth ; traceVar videoHeight
  echo $(( videoWidth * videoHeight )) ;
}
function getVideoSurfaceDiff  {
  read -r s1 s2 <<< $(_getSurfaces "$@") ; traceVar s1 ; traceVar s2
  echo $(( s1 - s2 ))
}
function getVideoSurfaceRatio {
  read -r s1 s2 <<< $(_getSurfaces "$@") ; traceVar s1 ; traceVar s2
  echo $(( 100 - (( s2 * 100 ) / s1) ))
}

[[ "${videoSizingLib_WithTrace}" != "true" ]] && enableTrace
