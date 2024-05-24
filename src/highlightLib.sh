#-------------------------------------------------------------------------------
# text highlighting utilities
[[ -z ${highlightLib} ]] || \
  ('warning highlightLib imported multiple times, protect import with [[ -z ${highlightLib+x} ]]' >&2)
readonly highlightLib=1

#-------------------------------------------------------------------------------
# import
declare _HIGHLIGHTLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${ensureLib+x} ]] && source ${_HIGHLIGHTLIB_LIB_PATH}/ensureLib
unset _HIGHLIGHTLIB_LIB_PATH

#-------------------------------------------------------------------------------
# public values
# reset all highlight attributes
readonly hlReset=$(tput sgr0)

# highlight code
readonly hlBold=$(tput bold)
readonly hlBlink=$(tput blink)
readonly hlUnderline=$(tput smul) ;    readonly hlUnderlineStop=$(tput rmul)

# background color code
readonly bgBlack=$(tput setab 0)
readonly bgRed=$(tput setab 1)
readonly bgGreen=$(tput setab 2)
readonly bgYellow=$(tput setab 3)
readonly bgBlue=$(tput setab 4)
readonly bgMagenta=$(tput setab 5)
readonly bgCyan=$(tput setab 6)
readonly bgLightGray=$(tput setab 7)

# foreground color code
readonly fgBlack=$(tput setaf 0) ;     readonly fgDarkGray="${hlBold}${fgBlack}"
readonly fgRed=$(tput setaf 1) ;       readonly fgLightRed="${hlBold}${fgRed}"
readonly fgGreen=$(tput setaf 2) ;     readonly fgLightGreen="${hlBold}${fgGreen}"
readonly fgYellow=$(tput setaf 3) ;    readonly fgLightYellow="${hlBold}${fgYellow}"
readonly fgBlue=$(tput setaf 4) ;      readonly fgLightBlue="${hlBold}${fgBlue}"
readonly fgMagenta=$(tput setaf 5) ;   readonly fgLightMagenta="${hlBold}${fgMagenta}"
readonly fgCyan=$(tput setaf 6) ;      readonly fgLightCyan="${hlBold}${fgCyan}"
readonly fgLightGray=$(tput setaf 7) ; readonly fgWhite="${hlBold}${fgLightGray}"

#-------------------------------------------------------------------------------
# private section
readonly _defaultColor=${fgLightMagenta}
function _defaultHighlight { echo -e "${_defaultColor}""${@}""${hlReset}" ; }

#-------------------------------------------------------------------------------
# public section
function getHighlighter  {
  declare name=$1
  ensure [[ ! -z ${name} ]]
  ensure [[ \"$(type -t ${name})\" != "function" ]]
  declare function=${2:-_defaultHighlight}
  ensure [[ "$(type -t ${function})" == "function" ]]
  declare outFD=${3:-2}
  declare forceMode=${4:-false}

  source /dev/stdin <<EOF
${name}() { { test -t ${outFD} || ${forceMode} ; } && ${function} "\$@" >&${outFD} || echo "\$@" >&${outFD} ; }
EOF
}
