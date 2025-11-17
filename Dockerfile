FROM ubuntu:24.04 AS build

ARG DEBIAN_FRONTEND=noninteractive
ENV PIXI_HOME=/opt/pixi \
    PATH="/opt/pixi/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://pixi.sh/install.sh | sh

WORKDIR /app

# copy project metadata and sources required to resolve the environment
COPY pixi.toml pixi.lock ./
COPY src ./src

# create the locked environment inside the container
RUN pixi install --locked

# capture the shell hook to bootstrap the environment for arbitrary commands
RUN pixi shell-hook -s bash > /tmp/shell-hook

# assemble an entrypoint that enables the pixi environment before running the requested command
RUN { \
    echo "#!/bin/bash"; \
    echo "set -euo pipefail"; \
    cat /tmp/shell-hook; \
    echo 'DEFAULT_CAFILE="/etc/ssl/certs/ca-certificates.crt"'; \
    echo 'if [[ -n "${SSL_CERT_FILE:-}" && ! -f "$SSL_CERT_FILE" ]]; then'; \
    echo '  export SSL_CERT_FILE="${DEFAULT_CAFILE}"'; \
    echo 'elif [[ -z "${SSL_CERT_FILE:-}" ]]; then'; \
    echo '  export SSL_CERT_FILE="${DEFAULT_CAFILE}"'; \
    echo 'fi'; \
    echo 'if [[ -n "${SSL_CERT_DIR:-}" && ! -d "$SSL_CERT_DIR" ]]; then'; \
    echo '  unset SSL_CERT_DIR'; \
    echo 'fi'; \
    echo 'if [[ $# -eq 0 || "$1" == -* ]]; then'; \
    echo '  set -- python -m givelit "$@"'; \
    echo 'fi'; \
    echo 'exec "$@"'; \
  } > /app/entrypoint.sh \
  && chmod 0755 /app/entrypoint.sh


FROM ubuntu:24.04 AS runtime

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# reuse the exact pixi environment built in the previous stage
COPY --from=build /app/.pixi/envs/default /app/.pixi/envs/default
COPY --from=build /app/entrypoint.sh /app/entrypoint.sh

# ship the project sources and metadata alongside the runtime
COPY src ./src
COPY pixi.toml pixi.lock README.md ./

# ensure tools in the pixi environment and module imports (givelit) are found
ENV PATH="/app/.pixi/envs/default/bin:${PATH}" \
    PYTHONPATH="/app/src"

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["python", "-m", "givelit"]
