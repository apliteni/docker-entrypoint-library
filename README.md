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
RAM_SIZE_MB=$(detect_ram_size_mb '20%')
... 
logs.info "Some useful info message" 
...
if something_wrong; then
  fail "This is fatal error"
fi
```
