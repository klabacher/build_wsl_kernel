FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential flex bison libssl-dev libelf-dev libncurses-dev python3 \
    autoconf libudev-dev libtool bc git ca-certificates curl jq gosu pkg-config \
    dwarves rsync kmod cpio \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash builder
RUN mkdir -p /workspace /out

WORKDIR /workspace

RUN echo '#!/bin/bash\n\
set -euo pipefail\n\
\n\
if [ "$(id -u)" = "0" ]; then\n\
    echo "Ajustando permissoes dos volumes /out e /workspace..."\n\
    chown -R builder:builder /out /workspace\n\
    exec gosu builder "$0" "$@"\n\
fi\n\
\n\
KERNEL_REPO="https://github.com/microsoft/WSL2-Linux-Kernel.git"\n\
RELEASE="latest"\n\
RUN_MENUCONFIG=0\n\
MAKE_ARGS=""\n\
\n\
while [[ $# -gt 0 ]]; do\n\
  case $1 in\n\
    --release)\n\
      RELEASE="$2"\n\
      shift 2\n\
      ;;\n\
    --menuconfig)\n\
      RUN_MENUCONFIG=1\n\
      shift\n\
      ;;\n\
    --make-args)\n\
      MAKE_ARGS="$2"\n\
      shift 2\n\
      ;;\n\
    *)\n\
      echo "Erro de execucao: Parametro nao reconhecido -> $1"\n\
      exit 1\n\
      ;;\n\
  esac\n\
done\n\
\n\
if [ ! -d "/out" ] || [ ! -w "/out" ]; then\n\
    echo "Falha de I/O: O diretorio /out precisa ser montado com permissoes de escrita."\n\
    exit 1\n\
fi\n\
\n\
echo "Sincronizando codigo fonte..."\n\
if [ ! -d "/workspace/.git" ]; then\n\
    git clone --depth 2 $KERNEL_REPO .\n\
else\n\
    git fetch --all --tags\n\
    git clean -fdx\n\
fi\n\
\n\
if [ "$RELEASE" = "latest" ]; then\n\
    DEFAULT_BRANCH=$(git remote show origin | awk "/HEAD branch/ {print \$3}")\n\
    git checkout "$DEFAULT_BRANCH"\n\
    git pull origin "$DEFAULT_BRANCH"\n\
else\n\
    git checkout "$RELEASE"\n\
fi\n\
\n\
if [ -f "/out/custom.config" ]; then\n\
    cp /out/custom.config .config\n\
else\n\
    cp Microsoft/config-wsl .config\n\
fi\n\
\n\
if [ "$RUN_MENUCONFIG" -eq 1 ]; then\n\
    make menuconfig\n\
    cp .config /out/custom.config\n\
fi\n\
\n\
# make -j$(nproc) $MAKE_ARGS\n\
if ! make -j$(nproc) $MAKE_ARGS; then\n\
    echo "Falha detectada. Executando make V=1 para capturar logs detalhados do erro..."\n\
    make V=1 $MAKE_ARGS > /out/error_trace.log 2>&1\n\
    echo "Log de erro exportado para /out/error_trace.log"\n\
    exit 1\n\
fi\n\
\n\
cp arch/x86/boot/bzImage /out/bzImage\n\
echo "Construcao finalizada com sucesso."\n\
echo "Compilando e empacotando modulos carregaveis..."\n\
make modules -j$(nproc) $MAKE_ARGS\n\
make INSTALL_MOD_PATH=/tmp/modules_install modules_install\n\
cd /tmp/modules_install\n\
tar -czvf /out/kernel_modules.tar.gz lib/modules/\n\
echo "Modulos empacotados em /out/kernel_modules.tar.gz"\n\
' > /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
