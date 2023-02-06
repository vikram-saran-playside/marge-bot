FROM python:3.9-slim AS builder

ARG POETRY_VERSION=1.3.2
RUN pip install poetry==$POETRY_VERSION

WORKDIR /src

COPY pyproject.toml poetry.lock README.md pylintrc ./
COPY marge/ ./marge/
RUN poetry export -o requirements.txt && \
  poetry build

FROM python:3.9-slim

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
  git-core \
  && \
  rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/requirements.txt /src/dist/marge-*.tar.gz /tmp/

RUN pip install -r /tmp/requirements.txt && \
  pip install /tmp/marge-*.tar.gz


WORKDIR /app
COPY . /app

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-python-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# During debugging, this entry point will be overridden. For more information, please refer to https://aka.ms/vscode-docker-python-debug
CMD ["python", "-m", "marge"]
# ENTRYPOINT ["marge"]