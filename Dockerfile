FROM rocker/tidyverse:latest
WORKDIR /workdir

# Install system dependencies
RUN apt update && apt install --yes \
    curl \
    git \
    lua5.4 \
    luarocks \
    nodejs \
    npm \
    python3-jsonschema

# Install elan (Lean version manager)
RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y

# Install the Lean toolchain used by qed
RUN . "$HOME/.elan/env" && elan toolchain install leanprover/lean4:v4.28.0

# Clone and build qed
RUN git clone https://github.com/tskovlund/qed.git /opt/qed
RUN . "$HOME/.elan/env" && cd /opt/qed && lake build

# Add qed to PATH
RUN ln -sf /opt/qed/.lake/build/bin/qed /usr/local/bin/qed

# Copy source code
COPY . /workdir

# Install tree-sitter CLI
RUN wget https://github.com/tree-sitter/tree-sitter/releases/download/v0.26.8/tree-sitter-cli-linux-x64.zip && \
    unzip tree-sitter-cli-linux-x64.zip && \
    chmod +x tree-sitter && \
    mv tree-sitter /usr/local/bin/ && \
    tree-sitter --version

# Build tree-sitter grammars
RUN git clone https://github.com/r-lib/tree-sitter-r /opt/tree-sitter-r && \
    cd /opt/tree-sitter-r && \
    tree-sitter generate && \
    tree-sitter build
RUN git clone https://github.com/tree-sitter/tree-sitter-python /opt/tree-sitter-python && \
    cd /opt/tree-sitter-python && \
    tree-sitter generate && \
    tree-sitter build

# Install Lua test/lint tools
RUN luarocks install busted && \
    luarocks install luacheck
