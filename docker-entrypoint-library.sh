#!/bin/sh

LOG_LEVELS='trace debug info warn error fatal'
DEFAULT_LOG_LEVEL='info'

print_full_var_name() {
  local var_name="${1}"
  local upcased_container_name="$(echo ${COMPONENT_NAME} | tr '[a-z]' '[A-Z]')"
  local prefix="${upcased_container_name//-/_}"

  if [[ "${prefix}" == "" ]]; then
    echo "${var_name}"
  else
    echo "${prefix}_${var_name}"
  fi
}

print_env_var() {
  local var_name="${1}"
  local full_var_name; full_var_name="$(print_full_var_name "${var_name}")"
  if [[ "${full_var_name}" != "" ]]; then
    eval 'echo "${'"$full_var_name"':-}"'
  fi
}

log() {
  local level="${1}" message="${2}"
  if is_log_level_visible "${level}"; then
    line="[${level}] ${message}"
    echo "[${level}] ${message}" >&2
  fi
}

define_log_helper_fns() {
  while [[ "${1:-}" != "" ]]; do 
    logger_level="${1}"
    source /dev/stdin <<-EOF
      log_${logger_level}() {
        log "${logger_level}" "\${1}";
      };
EOF
    shift
  done
}

print_current_log_level() {
  local log_level; log_level="$(print_env_var "LOG_LEVEL")"
  echo "${log_level:-${DEFAULT_LOG_LEVEL}}"
}

is_log_level_visible() {
  local level="${1}"
  local int_log_level configured_int_log_level

  int_log_level="$(arrays_index_of "${level}" ${LOG_LEVELS})"
  configured_int_log_level="$(arrays_index_of "$(print_current_log_level)" ${LOG_LEVELS})"

  [[ ! ${int_log_level} -lt ${configured_int_log_level} ]]
}

fail() {
  local message="${1}"
  log_fatal "${message}"
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

detect_total_ram_size() {
  free -b | awk 'NR==2 {print $2}'
}

calculate_max_ram_size() {
  local max_memory_pcts; max_memory_pcts="$(print_env_var MAX_RAM_PCTS)"

  if [[ "${max_memory_pcts}" == "" ]]; then
    local max_ram_pcts_var_name; max_ram_pcts_var_name="$(print_full_var_name MAX_RAM_PCTS)"
    fail "${max_ram_pcts_var_name} must be nonempty"
  fi

  local total_ram_size; total_ram_size="$(detect_total_ram_size)"
  local max_ram_size; max_ram_size="$(( total_ram_size * max_memory_pcts / 100 ))"

  echo "${max_ram_size}"
}

get_arg_or_read_stdin() {
  if [[ -n "${1:-}" ]]; then
    echo "${1}"
  elif [[ ! -t 0 ]]; then
    cat
  fi
}

to_kibibytes() {
  local bytes; bytes="$(get_arg_or_read_stdin "${@}")"
  echo "$(( bytes / 1024 ))"
}

to_mebibytes() {
  local bytes; bytes="$(get_arg_or_read_stdin "${@}")"
  echo "$(( bytes / 1024 / 1024 ))"
}

to_gibibytes() {
  local bytes; bytes="$(get_arg_or_read_stdin "${@}")"
  echo "$(( bytes / 1024 / 1024 / 1024 ))"
}

define_log_helper_fns ${LOG_LEVELS}
