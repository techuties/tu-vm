#!/bin/bash

# Disk Extension Script for Ubuntu VM
# This script extends the LVM logical volume to use all available space

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔧${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Check if running as root or with sudo
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        SUDO_CMD=""
    elif sudo -n true 2>/dev/null; then
        SUDO_CMD="sudo"
    else
        print_error "This script requires sudo privileges. Please run with sudo or ensure passwordless sudo is configured."
        echo "Usage: sudo $0"
        exit 1
    fi
}

# Main function
main() {
    print_status "Extending disk space for Ubuntu VM..."
    
    # Check current disk usage
    echo ""
    print_status "Current disk usage:"
    df -h /
    
    echo ""
    print_status "Current partition layout:"
    lsblk
    
    echo ""
    print_status "Checking LVM status:"
    $SUDO_CMD pvs
    $SUDO_CMD vgs
    $SUDO_CMD lvs
    
    echo ""
    print_status "Extending physical volume..."
    $SUDO_CMD pvresize /dev/sda3
    
    echo ""
    print_status "Extending logical volume to use all available space..."
    $SUDO_CMD lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    
    echo ""
    print_status "Resizing filesystem..."
    $SUDO_CMD resize2fs /dev/ubuntu-vg/ubuntu-lv
    
    echo ""
    print_success "Disk extension complete!"
    echo ""
    print_status "New disk usage:"
    df -h /
    
    echo ""
    print_status "New partition layout:"
    lsblk
    
    echo ""
    print_success "Disk space successfully extended!"
    echo ""
    print_warning "You may want to restart your services to ensure they recognize the new space:"
    echo "  ./tu-vm.sh restart"
}

# Check sudo and run main function
check_sudo
main
