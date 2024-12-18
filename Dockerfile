# Base image con SO Linux (Ubuntu)
FROM ubuntu:22.04

# Configurar zona horaria no interactiva e instalar tzdata
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y tzdata

# Configurar la zona horaria y demás paquetes
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Actualizar sistema y configurar pre-requisitos
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    gnupg \
    software-properties-common \
    openjdk-11-jre \
    maven \
    postgresql \
    net-tools \
    apache2 \
    unzip

# Instalar .NET Core SDK
RUN wget https://dot.net/v1/dotnet-install.sh && \
    chmod +x dotnet-install.sh && \
    ./dotnet-install.sh --version latest && \
    ln -s /root/.dotnet/dotnet /usr/bin/dotnet

# Instalar Visual Studio Code Server (código remoto)
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/ && \
    sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list' && \
    apt-get install -y apt-transport-https && \
    apt-get update && apt-get install -y code

# Configurar página "Hola Mundo" en Apache
RUN echo "<html><body><h1>Hola Mundo desde Docker</h1></body></html>" > /var/www/html/index.html

# Exponer el puerto 80
EXPOSE 80

# Comando para ejecutar Apache
CMD ["apachectl", "-D", "FOREGROUND"]
