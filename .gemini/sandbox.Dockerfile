FROM ubuntu:24.04

# Install basic dependencies and tools for Godot, including Python for gdtoolkit
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    ca-certificates \
    libfontconfig1 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    libxi6 \
    libasound2 \
    libxkbcommon0 \
    libvulkan1 \
    mesa-utils \
    git \
    bash \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install gdtoolkit for GDScript linting (gdlint) and formatting (gdformat)
RUN pip3 install --break-system-packages gdtoolkit

# Assuming 4.3 as a stable fallback for Godot headless tools if 4.6 isn't strictly available in direct links
# The container will run Godot validations inside the sandbox.
RUN wget -q https://github.com/godotengine/godot-builds/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip -O godot.zip \
    && unzip godot.zip \
    && mv Godot_v4.3-stable_linux.x86_64 /usr/local/bin/godot \
    && rm godot.zip

# Set alias or env for validation scripts
ENV PATH="/usr/local/bin:${PATH}"
ENV GODOT_EXEC="godot --headless"

# Setup non-root user (assuming 'node' or 'gemini' based on typical sandbox setups)
RUN useradd -m -s /bin/bash gemini
USER gemini
WORKDIR /workspace
