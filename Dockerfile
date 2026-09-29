# syntax=docker/dockerfile:1
FROM python:3.11-slim-bookworm

# -------------------------------------------------------------
# 1. System packages & non-root user setup
# -------------------------------------------------------------
# Install minimal OS dependencies needed for compiling packages and running git/curl
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        git \
        curl \
        jq \
        build-essential \
        libpq-dev \
        sudo \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root 'vscode' user (UID 1000) with passwordless sudo
# This ensures file permissions align cleanly with Dev Containers and CI runners
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# -------------------------------------------------------------
# 2. Fast package management via uv
# -------------------------------------------------------------
# Copy standalone uv binaries directly from the official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# -------------------------------------------------------------
# 3. Pre-baked Engine & Tooling
# -------------------------------------------------------------
# Install dbt, adapters, and developer tooling into the system environment
# so downstream containers and CI can run without runtime downloads.
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --system --no-cache -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt

# -------------------------------------------------------------
# 4. Environment & Entrypoint
# -------------------------------------------------------------
USER $USERNAME
WORKDIR /workspace

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/home/vscode/.local/bin:${PATH}"

CMD ["dbt", "--version"]
