#!/usr/bin/env sh

LOG_LEVELS='trace debug info warn error fatal'
DEFAULT_LOG_LEVEL='info'

logs_log() {
  local level="${1}" message="${2}"
  if logs_is_loggable "${level}"; then
    if [[ "${LOG_PRINT_TIMESTAMP:-}" != '' ]]; then
      datetime="$(TZ=UTC date '+%F %H:%M:%S %z')"
      line="${datetime} [${level}] ${message}"
    else
      line="[${level}] ${message}"
    fi
    echo "[${level}] ${message}" >&2
  fi
}

logs_define_helper_fns() {
  while [[ "${1:-}" != "" ]]; do 
    logger_level="${1}"
    source /dev/stdin <<-EOF
      logs_${logger_level}() {
        logs_log "${logger_level}" "\${1}";
      };
EOF
    shift
  done
}

logs_is_loggable() {
  local level="${1}"
  local int_log_level configured_int_log_level

  int_log_level="$(arrays_index_of "${level}" ${LOG_LEVELS})"
  configured_int_log_level="$(arrays_index_of "${LOG_LEVEL:-${DEFAULT_LOG_LEVEL}}" ${LOG_LEVELS})"

  [[ ! ${int_log_level} -lt ${configured_int_log_level} ]]
}

fail() {
  local message="${1}"
  logs_fatal "${message}"
  exit 1
}

arrays_index_of() {
  local index=0; value="${1}"; shift

  while [[ "${1:-}" != "" ]]; do 
    if [[ "${1}" == "${value}" ]]; then
      echo "${index}"
      break
    fi
    index="$(( index + 1 ))"
    shift
  done
}

detect_ram_size_mb() {
  get_pcts_of_ram_mb() {
    local pcts_of_ram_size="${1}" total_ram_size_mb ram_size_mb
    total_ram_size_mb="$(free -m | awk 'NR==2 {print $2}')"
    ram_size_mb="$(( total_ram_size_mb * pcts_of_ram_size / 100 ))"
    logs_debug "Calculated ${pcts_of_ram_size}% of total RAM size (${total_ram_size_mb}MB) - ${ram_size_mb}MB"
    echo "${ram_size_mb}"
  }

  local ram_size="${1}" ram_size_mb
  local ram_size_measure="${ram_size//[0-9]/}"
  local ram_size_value="${ram_size//[^0-9]/}" 

  logs_trace "detect_ram_size_mb: value: ${ram_size_value}, measure: ${ram_size_measure}" 
  if [[ "${ram_size}" == "" ]]; then
    fail "detect_ram_size_mb: argument '${ram_size}' must not be empty"
  fi

  if [[ "${ram_size_value}" -lt 0 ]]; then
    fail "detect_ram_size_mb: '${ram_size}' must contains memory size with suffix"
  fi

  case "${ram_size_measure}" in
    '%') # RAM size as pcts of total RAM
      ram_size_mb="$(get_pcts_of_ram_mb "${ram_size_value}")"
      ;;
    [Mm][Bb]) # RAM size in MBs
      ram_size_mb="${ram_size_value}"
      logs_debug "Converted '${ram_size}' to ${ram_size_mb}MB"
      ;;
    [Gg][Bb]) # RAM size in GBs
      ram_size_mb="$((ram_size_value * 1024))"
      logs_debug "Converted '${ram_size}' to ${ram_size_mb}MB"
      ;;
    *)
      fail "detect_ram_size_mb: '${ram_size}' must contains memory size with suffix"
      ;;
  esac

  echo "${ram_size_mb}"
}

logs_define_helper_fns ${LOG_LEVELS}

