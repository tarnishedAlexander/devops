FROM ubuntu:20.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Actualizar sistema e instalar herramientas necesarias
RUN apt-get update && apt-get install -y \
    bash \
    cron \
    git \
    curl \
    wget \
    vim \
    nano \
    systemctl \
    nginx \
    apache2 \
    mailutils \
    sysstat \
    tar \
    gzip \
    net-tools \
    procps \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configurar zona horaria
ENV TZ=America/La_Paz
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Crear directorios auxiliares
RUN mkdir -p /backup/logs

# Establecer directorio de trabajo
WORKDIR /workspace

# Mantener el contenedor corriendo
CMD ["/bin/bash"]