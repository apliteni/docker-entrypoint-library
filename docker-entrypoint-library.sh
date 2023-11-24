#!/bin/bash

LOGGER_LEVELS=(trace debug info warn error fatal)
LOGGER_DEFAULT_LEVEL='info'

logs.set_log_level() {
  local level="${1}"
  LOGGER_LEVEL="${level}"
}

logs.init() {
  if [[ "${LOGGER_LEVEL}" == '' ]]; then
    logs.set_log_level "${LOGGER_DEFAULT_LEVEL}"
  fi
}

logs.log() {
  local level="${1}" message="${2}"
  logs.init
  if logs.is_loggable "${level}"; then
    TZ=UTC printf "%(%Y-%m-%d %H:%M:%S %z)T [%s] %s\n" -1 "${level}" "${message}" >&2
  fi
}

# Define logs.* helper fuctions - logs.trace, logs.debug, logs.info, logs.warn logs.error logs.fatal
for logger_level in "${LOGGER_LEVELS[@]}"; do source /dev/stdin <<-EOF
  logs.${logger_level}() {
    logs.log "${logger_level}" "\${1}";
  };
EOF
done

logs.is_loggable() {
  local level="${1}"
  local int_log_level configured_int_log_level

  int_log_level="$(arrays.index_of "${level}" "${LOGGER_LEVELS[@]}")"
  configured_int_log_level="$(arrays.index_of "${LOGGER_LEVEL}" "${LOGGER_LEVELS[@]}")"

  (( int_log_level >= configured_int_log_level ))
}

fail() {
  local message="${1}"
  logs.fatal "${message}"
  exit 1
}

arrays.index_of() {
  local value="${1}"; shift
  local array=("${@}")

  for ((index=0; index<${#array[@]}; index++)); do
    if [[ "${array[$index]}" == "${value}" ]]; then
      echo "${index}"
      break
    fi
  done
}

detect_ram_size_mb() {
  get_pcts_of_ram_mb() {
    local pcts_of_ram_size="${1}" total_ram_size_mb ram_size_mb
    total_ram_size_mb="$(free -m | awk 'NR==2 {print $2}')"
    ram_size_mb="$(( total_ram_size_mb * pcts_of_ram_size / 100 ))"
    logs.info "Calculated ${pcts_of_ram_size}% of total RAM size (${total_ram_size_mb}MB) - ${ram_size_mb}MB"
    echo "${ram_size_mb}"
  }

  local ram_size="${1}" ram_size_mb
  local ram_size_measure="${ram_size//[0-9]/}"
  local ram_size_value="${ram_size//[^0-9]/}" 
 
  if [[ "${ram_size}" == "" ]]; then
    fail "detect_ram_size_mb: argument '${ram_size}' must not be empty"
  fi

  if [[ "${ram_size_value}" -lt 0 ]]; then
    fail "detect_ram_size_mb: '${ram_size}' must contains memory size with suffix"
  fi

  case "${ram_size_measure,,}" in
    '%') # RAM size as pcts of total RAM
      ram_size_mb="$(get_pcts_of_ram_mb "${ram_size_value}")"
      ;;
    'mb') # RAM size in MBs
      ram_size_mb="${ram_size_value}"
      logs.info "Converted '${ram_size}' to ${ram_size_mb}MB"
      ;;
    'gb') # RAM size in GBs
      ram_size_mb="$((ram_size_value * 1024))"
      logs.info "Converted '${ram_size}' to ${ram_size_mb}MB"
      ;;
    *)
      fail "detect_ram_size_mb: '${ram_size}' must contains memory size with suffix"
      ;;
  esac

  echo "${ram_size_mb}"
}
