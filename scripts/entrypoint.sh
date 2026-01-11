#!/bin/bash
set -e

STEAM_DIR="/home/steam/Steam"
SERVER_DIR="${STEAM_DIR}/servers/7DaysToDie"
INSTALL_MARKER="${STEAM_DIR}/.installed"
FEX_ROOTFS_DIR="/home/steam/.fex-emu/RootFS"
CUSTOM_CONFIG="/home/steam/serverconfig.xml.custom"

# Check if update is forced via environment variable
FORCE_UPDATE="${FORCE_UPDATE:-false}"

# First run or forced update: setup FEX RootFS, SteamCMD, and 7DTD
if [ ! -f "$INSTALL_MARKER" ] || [ "$FORCE_UPDATE" = "true" ]; then
    if [ "$FORCE_UPDATE" = "true" ]; then
        echo "=== Forced update requested ==="
    else
        echo "=== First run detected, installing... ==="
    fi

    # Setup FEX RootFS (only if not already present)
    if [ ! -d "$FEX_ROOTFS_DIR/Ubuntu_22_04" ] && [ ! -f "$FEX_ROOTFS_DIR/Ubuntu_22_04.sqsh" ]; then
        echo "Setting up FEX RootFS..."
        FEXRootFSFetcher --distro-name=ubuntu --distro-version=22.04 --extract -y
    else
        echo "FEX RootFS already exists, skipping..."
        # If .sqsh exists but not extracted, extract it
        if [ -f "$FEX_ROOTFS_DIR/Ubuntu_22_04.sqsh" ] && [ ! -d "$FEX_ROOTFS_DIR/Ubuntu_22_04" ]; then
            echo "Extracting RootFS..."
            cd "$FEX_ROOTFS_DIR"
            unsquashfs -d Ubuntu_22_04 Ubuntu_22_04.sqsh || true
        fi
    fi

    # Install SteamCMD
    if [ ! -f "$STEAM_DIR/steamcmd.sh" ]; then
        echo "Installing SteamCMD..."
        mkdir -p "$STEAM_DIR"
        cd "$STEAM_DIR"
        curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    else
        echo "SteamCMD already exists, skipping..."
    fi

    # Install 7 Days to Die Dedicated Server
    echo "Installing/Updating 7 Days to Die Dedicated Server..."
    cd "$STEAM_DIR"
    FEXBash -c "./steamcmd.sh +force_install_dir \"$SERVER_DIR\" +login anonymous +app_update 294420 -validate +quit"

    # Mark as installed
    touch "$INSTALL_MARKER"
    echo "=== Installation complete ==="
fi

# Copy custom config if provided
if [ -f "$CUSTOM_CONFIG" ]; then
    echo "Applying custom serverconfig.xml..."
    cp "$CUSTOM_CONFIG" "$SERVER_DIR/serverconfig.xml"
fi

# Start the server
cd "$SERVER_DIR"
echo "Starting 7 Days to Die server..."
exec FEXBash -c "./startserver.sh -configfile=serverconfig.xml"
