# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11
FROM python:${PYTHON_VERSION}-slim-bookworm

# -------------------------------------------------------------
# 1. System packages & non-root user setup
# -------------------------------------------------------------
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
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# -------------------------------------------------------------
# 3. Pre-baked Engine & Tooling (Parameterized via ARGs)
# -------------------------------------------------------------
ARG DBT_PACKAGES="dbt-core==1.12.5 dbt-duckdb duckdb"
ARG SQLFLUFF_VERSION=">=3.0.0"

RUN uv pip install --system --no-cache \
    ${DBT_PACKAGES} \
    "sqlfluff${SQLFLUFF_VERSION}"

# -------------------------------------------------------------
# 4. Auto-Discovery & Entrypoint (Versioned via TOOLS_VERSION)
# -------------------------------------------------------------
ARG TOOLS_VERSION=v1
COPY scripts/${TOOLS_VERSION}/init_duckdb.py /usr/local/bin/init_duckdb.py
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/init_duckdb.py /usr/local/bin/entrypoint.sh

# -------------------------------------------------------------
# 5. Pre-baked 12-Factor dbt Profile
# -------------------------------------------------------------
RUN mkdir -p /home/${USERNAME}/.dbt /root/.dbt
COPY config/profiles.yml /home/${USERNAME}/.dbt/profiles.yml
COPY config/profiles.yml /root/.dbt/profiles.yml
RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.dbt

USER $USERNAME
WORKDIR /workspace

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DBT_PROFILES_DIR="/home/vscode/.dbt" \
    PATH="/home/vscode/.local/bin:${PATH}"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["dbt", "--version"]
