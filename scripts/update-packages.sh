#!/bin/bash

# Firebase UPM Package Updater
# Downloads packages directly from Google's registry
# Usage: ./update-packages.sh [version]
# If no version is specified, it will fetch the latest version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEMP_DIR="$ROOT_DIR/temp"
PACKAGES_DIR="$ROOT_DIR/packages"

# Firebase packages to download from Google's registry
# URL pattern: https://dl.google.com/games/registry/unity/{pkg}/{pkg}-{version}.tgz
FIREBASE_PACKAGES=(
    "com.google.firebase.app"
    "com.google.firebase.analytics"
    "com.google.firebase.crashlytics"
    "com.google.firebase.app-check"
    "com.google.firebase.auth"
    "com.google.firebase.firestore"
    "com.google.firebase.functions"
    "com.google.firebase.storage"
    "com.google.firebase.database"
    "com.google.firebase.remote-config"
    "com.google.firebase.messaging"
    "com.google.firebase.installations"
    "com.google.firebase.dynamic-links"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${CYAN}[OK]${NC} $1"
}

# Get the latest Firebase version from GitHub
get_latest_version() {
    curl -s https://api.github.com/repos/firebase/firebase-unity-sdk/releases/latest | \
        grep '"tag_name"' | \
        sed -E 's/.*"v?([^"]+)".*/\1/'
}

# Get the current version from VERSION file
get_current_version() {
    if [ -f "$ROOT_DIR/VERSION" ]; then
        cat "$ROOT_DIR/VERSION"
    else
        echo "0.0.0"
    fi
}

# Download a Firebase package from Google's registry
download_firebase_package() {
    local pkg_name=$1
    local version=$2
    local url="https://dl.google.com/games/registry/unity/${pkg_name}/${pkg_name}-${version}.tgz"
    local tgz_path="$TEMP_DIR/${pkg_name}.tgz"

    echo -n "  Downloading $pkg_name..."

    if curl -L -f -s -o "$tgz_path" "$url" 2>/dev/null; then
        echo -e " ${GREEN}OK${NC}"
        return 0
    else
        echo -e " ${YELLOW}FAILED (may not exist for this version)${NC}"
        return 1
    fi
}

# Extract a package from tgz
extract_package() {
    local pkg_name=$1
    local tgz_file="$TEMP_DIR/${pkg_name}.tgz"

    if [ ! -f "$tgz_file" ]; then
        return 1
    fi

    echo -n "  Extracting $pkg_name..."

    # Clean and recreate package directory
    rm -rf "$PACKAGES_DIR/$pkg_name"
    mkdir -p "$PACKAGES_DIR/$pkg_name"

    # Extract tgz
    if tar -xzf "$tgz_file" -C "$PACKAGES_DIR/$pkg_name" --strip-components=1 2>/dev/null; then
        echo -e " ${GREEN}OK${NC}"
        return 0
    else
        echo -e " ${RED}FAILED${NC}"
        return 1
    fi
}

# Download External Dependency Manager
download_edm4u() {
    log_info "Downloading External Dependency Manager..."

    # Get latest EDM4U version from GitHub releases
    local edm_version=$(curl -s https://api.github.com/repos/googlesamples/unity-jar-resolver/releases/latest | \
        grep '"tag_name"' | \
        sed -E 's/.*"v?([^"]+)".*/\1/')

    if [ -n "$edm_version" ]; then
        # Download from Google's registry (same pattern as Firebase packages)
        local edm_url="https://dl.google.com/games/registry/unity/com.google.external-dependency-manager/com.google.external-dependency-manager-${edm_version}.tgz"

        echo -n "  Downloading com.google.external-dependency-manager v${edm_version}..."

        if curl -L -f -s -o "$TEMP_DIR/edm4u.tgz" "$edm_url" 2>/dev/null; then
            echo -e " ${GREEN}OK${NC}"

            rm -rf "$PACKAGES_DIR/com.google.external-dependency-manager"
            mkdir -p "$PACKAGES_DIR/com.google.external-dependency-manager"

            echo -n "  Extracting com.google.external-dependency-manager..."
            tar -xzf "$TEMP_DIR/edm4u.tgz" -C "$PACKAGES_DIR/com.google.external-dependency-manager" --strip-components=1
            echo -e " ${GREEN}OK${NC}"
            return 0
        else
            echo -e " ${YELLOW}FAILED${NC}"
        fi
    fi

    log_warn "Could not download EDM4U"
    return 1
}

# Cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Main function
main() {
    local version=${1:-$(get_latest_version)}
    local current_version=$(get_current_version)

    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Firebase UPM Package Updater${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    echo -e "  Latest version:  ${YELLOW}$version${NC}"
    echo -e "  Current version: ${YELLOW}$current_version${NC}"
    echo ""

    if [ "$version" == "$current_version" ] && [ -z "$FORCE_UPDATE" ]; then
        log_success "Already up to date!"
        exit 0
    fi

    # Create directories
    mkdir -p "$TEMP_DIR"
    mkdir -p "$PACKAGES_DIR"

    # Download Firebase packages
    log_info "Downloading Firebase packages from Google Registry..."
    local downloaded_count=0
    for pkg in "${FIREBASE_PACKAGES[@]}"; do
        if download_firebase_package "$pkg" "$version"; then
            ((downloaded_count++)) || true
        fi
    done

    # Download EDM4U
    download_edm4u

    # Extract packages
    echo ""
    log_info "Extracting packages..."
    local extracted_count=0
    for pkg in "${FIREBASE_PACKAGES[@]}"; do
        if extract_package "$pkg"; then
            ((extracted_count++)) || true
        fi
    done

    # Update VERSION file
    echo "$version" > "$ROOT_DIR/VERSION"

    # Cleanup
    cleanup

    # Summary
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Update Complete!${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    log_success "Updated to Firebase SDK v${version}"
    echo ""
    echo "  Packages extracted: $extracted_count / ${#FIREBASE_PACKAGES[@]}"
    echo ""
    echo "  Packages:"
    for pkg in "${FIREBASE_PACKAGES[@]}"; do
        if [ -d "$PACKAGES_DIR/$pkg" ] && [ -f "$PACKAGES_DIR/$pkg/package.json" ]; then
            local pkg_version=$(grep '"version"' "$PACKAGES_DIR/$pkg/package.json" | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
            echo "    - $pkg @ $pkg_version"
        fi
    done
    if [ -d "$PACKAGES_DIR/com.google.external-dependency-manager" ]; then
        local edm_version=$(grep '"version"' "$PACKAGES_DIR/com.google.external-dependency-manager/package.json" | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
        echo "    - com.google.external-dependency-manager @ $edm_version"
    fi
    echo ""
}

# Run main function
main "$@"
