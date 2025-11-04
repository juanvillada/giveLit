FROM ghcr.io/prefix-dev/pixi:0.59.0 AS build

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
    echo 'if [[ $# -eq 0 || "$1" == -* ]]; then'; \
    echo '  set -- python -m radarsci "$@"'; \
    echo 'fi'; \
    echo 'exec "$@"'; \
  } > /app/entrypoint.sh \
  && chmod 0755 /app/entrypoint.sh


FROM ubuntu:24.04 AS runtime

WORKDIR /app

# reuse the exact pixi environment built in the previous stage
COPY --from=build /app/.pixi/envs/default /app/.pixi/envs/default
COPY --from=build /app/entrypoint.sh /app/entrypoint.sh

# ship the project sources and metadata alongside the runtime
COPY src ./src
COPY pixi.toml pixi.lock README.md ./

# ensure tools in the pixi environment and module imports (radarsci) are found
ENV PATH="/app/.pixi/envs/default/bin:${PATH}" \
    PYTHONPATH="/app/src"

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["python", "-m", "radarsci"]
