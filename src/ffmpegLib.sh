#-------------------------------------------------------------------------------
# ffmpeg utilities
[[ -z ${ffmpegLib} ]] || \
(echo 'warning ffmpegLib imported multiple times, protect import with [[ -z ${ffmpegLib+x} ]]' >&2)
readonly ffmpegLib=1

#-------------------------------------------------------------------------------
# get lib location
declare _FFMPEGLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${traceLib+x} ]] && source ${_FFMPEGLIB_LIB_PATH}/traceLib
unset _FFMPEGLIB_LIB_PATH

[[ "${ffmpegLib_WithTrace}" != "true" ]]   && disableTrace # disabling traceLib functions

#-------------------------------------------------------------------------------
# getting ffmpeg command path - private section
function _getFfmpegCommand () {
  local command=$(which ffmpeg 2>/dev/null)
  traceVar command
  [[ -z ${command+x} ]] && fatal "install ffmpeg"
  echo "${command} "
}

#-------------------------------------------------------------------------------
# quality options - private section

# Constant Bit Rate : -crf $level;       with level in [0-51]; 0=highest quality
# Variable Bit Rate : -qscale:v $level;  with level in [0-31]; 0=highest quality

declare _QUALITY_METRIC=CBR    ; traceVar _QUALITY_METRIC
#declare _QUALITY_METRIC="VBR"    ; traceVar _QUALITY_METRIC

declare -A _BRLow
_BRLow[CBR]=0
_BRLow[VBR]=0
readonly _BRLow
traceVar _BRLow

declare -A _BRHigh
_BRHigh[CBR]=51
_BRHigh[VBR]=31
readonly _BRHigh
traceVar _BRHigh

declare -A _BROption
_BROption[CBR]=' -crf %s '
_BROption[VBR]=' -qscale:v %s '
readonly _BROption
traceVar _BROption

declare -A _qualityLevels

function _initQualityLevel {
  local _HighQM=${_BRHigh[${_QUALITY_METRIC}]}                  ; traceVar _HighQM
  local _LowQM=${_BRLow[${_QUALITY_METRIC}]}                    ; traceVar _LowQM
  local _MediumQM=$((     (_HighQM    - _LowQM)    / 2 ))  ; traceVar _MediumQM
  local _MediumHighQM=$(( ((_HighQM   - _MediumQM) / 2 ) + _MediumQM ))  ; traceVar _MediumHighQM
  local _MediumLowQM=$((  ((_MediumQM - _LowQM)    / 2 ) + _LowQM ))     ; traceVar _MediumLowQM
  _qualityLevels["HIGH"]=${_LowQM}
  _qualityLevels["MEDIUM_HIGH"]=${_MediumLowQM}
  _qualityLevels["MEDIUM"]=${_MediumQM}
  _qualityLevels["MEDIUM_LOW"]=${_MediumHighQM}
  _qualityLevels["LOW"]=${_HighQM}
  _qualityLevels["DEFAULT"]=${_MediumQM}
  traceVar _qualityLevels
}
_initQualityLevel

# quality options - public section
function getFfmpegQualityOption  {
  local quality=$1 ; traceVar quality
  quality=${quality:=DEFAULT}
  local level=${_qualityLevels[${quality}]}     ; traceVar level
  if [[ "${level}" == "" ]] ; then
    warning "${FUNCNAME}:bad quality level"
    result=${FFMPEG_ENCODING_QUALITY_OPTION}
  else
    local option=${_BROption[${_QUALITY_METRIC}]}  ; traceVar option
    result=$(printf "${option}" ${level})
  fi
  echo ${result}
}
function setFfmpegQualityMetrics {
  local metric=$1 ; traceVar metric
  if [[ "${metric}" =~ ^(CBR|VBR)$ ]] ; then
    _QUALITY_METRIC=${metric} ; traceVar _QUALITY_METRIC
    _initQualityLevel
    FFMPEG_ENCODING_QUALITY_OPTION=$(getFfmpegQualityOption DEFAULT)
  else
    warning "${FUNCNAME}:bad quality Metric:must be CBR or VBR"
  fi
}

#-------------------------------------------------------------------------------
# duration option - public section
function getFfmpegTimeOption  {
  duration=$1 ; traceVar duration
  duration=$1 ; traceVar duration
  if [[ "${duration}" == "0" ]] ; then
    echo
  elif [[ "${duration}" =~ ^[0-9]+.[0-9]+$ ]] || \
       [[ "${duration}" =~ ^[0-9]+$ ]] || \
       [[ "${duration}" =~ ^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$ ]] || \
       [[ "${duration}" =~ ^[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9]+$ ]] ; then
    echo "-t $1"
  elif [[ "${duration}" == "" ]] ; then
    echo
  else
    echo
    warning ${FUNCNAME}:bad duration
  fi
}

#-------------------------------------------------------------------------------
# seek option - private section
declare -A _videoDuration2seekDuration
#_videoDuration2seekDuration[0]=0
_videoDuration2seekDuration[5]=0
_videoDuration2seekDuration[10]=5
_videoDuration2seekDuration[15]=10
_videoDuration2seekDuration[30]=20
_videoDuration2seekDuration[60]=35
_videoDuration2seekDuration[120]=65
readonly _videoDuration2seekDuration

# seek option - public section
function getFfmpegSeekOption            {
  duration=$1 ; traceVar duration
  if [[ "${duration}" == "0" ]] ; then
    echo
  elif [[ "${duration}" =~ ^[0-9]+.[0-9]+$ ]] || \
       [[ "${duration}" =~ ^[0-9]+$ ]] || \
       [[ "${duration}" =~ ^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$ ]] || \
       [[ "${duration}" =~ ^[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9]+$ ]] ; then
    echo "-ss $1"
  elif [[ "${duration}" == "" ]] ; then
    echo
  else
    echo
    warning ${FUNCNAME}:bad seek format
  fi
}

function getFfmpegAdaptativeSeekOption  {
  local videoDuration=$1 ; traceVar videoDuration
  traceVar _videoDuration2seekDuration
  keys=$(for V in ${!_videoDuration2seekDuration[@]} ; do echo $V ; done | sort -n)
  traceVar keys
  for V in  ${keys} ; do
    traceVar V
    if (( V <= videoDuration )) ; then
      seekDuration=${_videoDuration2seekDuration[${V}]} ; traceVar seekDuration
    else
      break
    fi
  done
  getFfmpegSeekOption ${seekDuration}
}

#-------------------------------------------------------------------------------
# cropping geometry - private section
declare _cropTemp=${1/crop=/}

# cropping geometry - public section
function cropSpec2CropWidth     { echo ${1/crop=/} | cut -d: -f1 ; }
function cropSpec2CropHeight    { echo ${1/crop=/} | cut -d: -f2 ; }
function cropSpec2CropSize      { echo ${1/crop=/} | cut -d: --output-delimiter="x" -f1,2 ; }
function cropSpec2CropPosition  { echo ${1/crop=/} | cut -d: --output-delimiter="," -f3,4 ; }

#-------------------------------------------------------------------------------
# public variables
declare FFMPEG_COMMAND=$(_getFfmpegCommand)                 ; traceVar FFMPEG_COMMAND
readonly FFMPEG_VERBOSE_OPTIONS=' -hide_banner -v warning '  ; traceVar FFMPEG_VERBOSE_OPTIONS
readonly FFMPEG_PRESERVE_METADATA_OPTION=' -map_metadata 0 ' ; traceVar FFMPEG_PRESERVE_METADATA_OPTION
declare FFMPEG_ENCODING_QUALITY_OPTION=$(getFfmpegQualityOption) ; traceVar FFMPEG_ENCODING_QUALITY_OPTION


#-------------------------------------------------------------------------------
# intro & extro detection
declare BLACK_DETECT_THREASHOLD=0.75
declare DURATION_SEARCH=10

function blackIntroDetect() {
  local fileName=$1
  local INTRO_DURATION_SEARCH=${DURATION_SEARCH} # in seconds
  ffprobe                                                                               \
    -read_intervals 0%+${INTRO_DURATION_SEARCH}                                         \
    -f lavfi _                                                                          \
    -i "movie='${fileName}',blackdetect=d=3.0:pic_th=${BLACK_DETECT_THREASHOLD}[out0]"  \
    -show_entries tags=lavfi.black_start,lavfi.black_end                                \
    -of default=nw=1                                                                    \
    -v quiet      #|
#      uniq |
#        awk -F= '
#          BEGIN               { hasIntro=0 }
#          /lavfi.black_start/ { if ($1 == 0)        { hasIntro=1 } }
#          /lavfi.black_end/   { if (hasIntro == 1)  { print $1; exit 0} }
#          END                 { print 0 }
#          '
}

function blackExtroDetect() {
  local fileName=$1
  local length=$2
  local EXTRO_DURATION_SEARCH=${DURATION_SEARCH}  # in seconds
  ffprobe                                                                               \
    -read_intervals $(bc <<< "${length}-${EXTRO_DURATION_SEARCH}")%                     \
    -f lavfi                                                                            \
    -i "movie='${fileName}',blackdetect=d=3.0:pic_th=${BLACK_DETECT_THREASHOLD}[out0]"  \
    -show_entries tags=lavfi.black_start,lavfi.black_end                                \
    -of default=nw=1                                                                    \
    -v quiet |
      uniq |
        awk -v length=${length} -F= '
          BEGIN               { start=length }
          /lavfi.black_start/ { start=$1 }
          END                 { print start }
          '
}

#-------------------------------------------------------------------------------
# get nereast next Iframe index
function getNextIFrameIndex() {
  local fileName=$1
  local sTime=$2;
  local IFRAME_DURATION_SEARCH=5  # in seconds
  ffprobe                                                           \
    -read_intervals $(bc <<< "${sTime}-${IFRAME_DURATION_SEARCH}")% \
    -v error                                                        \
    -skip_frame nokey                                               \
    -show_entries frame=pkt_pts_time-select_streams v               \
    -of csv=p=0                                                     \
    "${fileName}" |
      awk -v stime=${sTime} -F= '{ if ($1 > stime) { print $1; exit 0} }'
}

#-------------------------------------------------------------------------------
# detect black frame
function getCropSpec() {
  local fileName=$1
  local ffmpegSeekOption=$2
  ffmpeg                \
    -i ${fileName}      \
    ${ffmpegSeekOption} \
    -t 1                \
    -vf cropdetect      \
    -f null - 2>&1 |
      awk '/crop/ {print $NF}' |
        tail -n1
}

[[ "${ffmpegLib_WithTrace}" != "true" ]]   && enableTrace
