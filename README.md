# Usage

# Inside your Dockerfile

## Download the script using curl

```
RUN curl \
    https://raw.githubusercontent.com/apliteni/docker-entrypoint-library/main/docker-entrypoint-library.sh \
    -o /docker-entrypoint-library.sh
```

## Download the script using wget (if curl is not installed)

```
RUN wget \
    https://raw.githubusercontent.com/apliteni/docker-entrypoint-library/main/docker-entrypoint-library.sh \
    -O /docker-entrypoint-library.sh
```

# Inside your docker entry point

Source it and use

```
source /docker-entrypoint-library.sh
...
MAX_RAM_PCTS=5
detect_total_ram_size | to_mebibytes # prints something like 16384 if you have 16G RAM
caclulate_ram_size | to_mebibytes # prints something like 819 (5% of RAM) if you have 16G RAM
... 
log_info "Some useful info message"
...
if something_wrong; then
  fail "This is fatal error"
fi
```
