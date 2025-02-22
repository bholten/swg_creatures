FROM rocker/r-ver:4.2.3

RUN apt-get update && apt-get install -y \
    libz-dev git \
    lua5.3 liblua5.3-dev luarocks pandoc \
    && rm -rf /var/lib/apt/lists/*

RUN luarocks install luafilesystem

COPY install_packages.R /install_packages.R
RUN Rscript install_packages.R

RUN git config --global --add safe.directory /workspace/submodules/Core3

WORKDIR /workspace

CMD ["/bin/bash"]
