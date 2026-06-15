FROM rocker/tidyverse:latest
WORKDIR /workdir
COPY . /workdir
RUN wget https://github.com/tree-sitter/tree-sitter/releases/download/v0.26.8/tree-sitter-cli-linux-x64.zip && \
    unzip tree-sitter-cli-linux-x64.zip && \
    chmod +x tree-sitter && \
    mv tree-sitter /usr/local/bin/ && \
    tree-sitter --version
RUN apt update && apt install --yes \
    lua5.4 \
    luarocks \
    nodejs \
    npm \
    python3-jsonschema
RUN git clone https://github.com/r-lib/tree-sitter-r /opt/tree-sitter-r && \
    cd /opt/tree-sitter-r && \
    tree-sitter generate && \
    tree-sitter build
RUN git clone https://github.com/tree-sitter/tree-sitter-python /opt/tree-sitter-python && \
    cd /opt/tree-sitter-python && \
    tree-sitter generate && \
    tree-sitter build
RUN luarocks install busted && \
    luarocks install luacheck
