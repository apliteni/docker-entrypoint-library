#!/bin/sh

LOG_LEVELS='trace debug info warn error fatal'
DEFAULT_LOG_LEVEL='info'

env_print_full_var_name() {
  local var_name="${1}"
  local prefix="${ENV_VARS_PREFIX:-}"
  if [[ "${prefix}" == "" ]]; then
    echo "${var_name}"
  else
    echo "${prefix}_${var_name}"
  fi
}

env_print_var_value() {
  local var_name="${1}"
  local full_var_name; full_var_name="$(env_print_full_var_name "${var_name}")"
  if [[ "${full_var_name}" != "" ]]; then
    eval 'echo "${'"$full_var_name"':-}"'
  fi
}

logs_log() {
  local level="${1}" message="${2}"
  if logs_is_loggable "${level}"; then
    line="[${level}] ${message}"
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

logs_configured_log_level() {
  local log_level; log_level="$(env_print_var_value "LOG_LEVEL")"
  echo "${log_level:-${DEFAULT_LOG_LEVEL}}"
}

logs_is_loggable() {
  local level="${1}"
  local int_log_level configured_int_log_level

  int_log_level="$(arrays_index_of "${level}" ${LOG_LEVELS})"
  configured_int_log_level="$(arrays_index_of "$(logs_configured_log_level)" ${LOG_LEVELS})"

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

detect_allowed_ram_size_mb() {
  local ram_size_in_pcts_var="${1:-RAM_SIZE_IN_PCTS}"
  local ram_size_in_pcts; ram_size_in_pcts="$(env_print_var_value "${ram_size_in_pcts_var}")"

  logs_trace "detect_ram_size: env_var: ${ram_size_var_in_pcts}, value: ${ram_size_in_pcts}" 
  if [[ "${ram_size_in_pcts}" == "" ]]; then
    fail "detect_ram_size: ${ram_size_in_pcts_var} must be nonempty"
  fi

  local total_ram_size_mb; total_ram_size_mb="$(free -m | awk 'NR==2 {print $2}')"
  local ram_size_mb; ram_size_mb="$(( total_ram_size_mb * ram_size_in_pcts / 100 ))"

  logs_info "Allowed to use ${ram_size_in_pcts}% of total RAM size (${total_ram_size_mb}MB) - ${ram_size_mb}MB"
  echo "${ram_size_mb}"
}

logs_define_helper_fns ${LOG_LEVELS}
