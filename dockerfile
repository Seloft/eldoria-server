FROM eclipse-temurin:21-jre-jammy

# Build-time arguments (can be overridden at build)
ARG MC_VERSION="1.21.1"
ARG FABRIC_LOADER_VERSION="0.18.0"
ARG INSTALLER_VERSION="1.1.0"

# Runtime environment variables
ENV MC_VERSION="${MC_VERSION}" \
    FABRIC_LOADER_VERSION="${FABRIC_LOADER_VERSION}" \
    INSTALLER_VERSION="${INSTALLER_VERSION}" \
    MEMORY="-Xmx4G -Xms2G"

# Labels for metadata
LABEL version="1.3" \
      description="Minecraft Fabric Server" \
      mc.version="${MC_VERSION}" \
      fabric.version="${FABRIC_LOADER_VERSION}"

# Install tools with specific versions and clean up
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget=1.21.2-* \
        ca-certificates \
        curl=7.81.0-* \
        netcat-openbsd=1.* \
        sed \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget https://github.com/itzg/rcon-cli/releases/download/1.6.4/rcon-cli_1.6.4_linux_amd64.tar.gz \
    && tar -xzf rcon-cli_1.6.4_linux_amd64.tar.gz \
    && mv rcon-cli /usr/local/bin/ \
    && chmod +x /usr/local/bin/rcon-cli \
    && rm rcon-cli_1.6.4_linux_amd64.tar.gz

# Create directories
RUN mkdir -p /minecraft-template /minecraft

# Set working directory for downloads
WORKDIR /minecraft-template

# Download the executable server jar directly (following Fabric docs)
RUN wget -O "fabric-server-mc.${MC_VERSION}-loader.${FABRIC_LOADER_VERSION}-launcher.${INSTALLER_VERSION}.jar" \
    "https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}/${FABRIC_LOADER_VERSION}/${INSTALLER_VERSION}/server/jar" \
    && echo "Downloaded Fabric server jar:" \
    && ls -la fabric-server-mc.*.jar

# Accept EULA in template
RUN echo "eula=true" > /minecraft-template/eula.txt

# Copy scripts and convert line endings to Unix format, then set permissions
COPY scripts/run-server.sh /minecraft-template/
COPY scripts/init-server.sh /minecraft-template/

RUN sed -i 's/\r$//' /minecraft-template/run-server.sh /minecraft-template/init-server.sh \
    && chmod +x /minecraft-template/run-server.sh /minecraft-template/init-server.sh \
    && echo "Scripts permissions set."

# Set final working directory
WORKDIR /minecraft

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD nc -z localhost 25565 || exit 1

# Expose port
EXPOSE 25565

# Volume for persistence
VOLUME ["/minecraft"]

# Use init script as entrypoint
ENTRYPOINT ["/minecraft-template/init-server.sh"]