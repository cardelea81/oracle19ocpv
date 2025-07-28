#!/bin/bash

# Quick SSH Connectivity Fix for Oracle RAC
# This script sets up passwordless SSH between Oracle RAC nodes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
NODE1="oracle-node01.lab.dev.example.com"
NODE2="oracle-node02.lab.dev.example.com"
ORACLE_USERS=("grid" "oracle" "dbz")
ORACLE_HOMES=("/services/oracle/gridhome" "/services/oracle/orahome" "/services/oracle/dbz")

print_status "Starting SSH connectivity setup for Oracle RAC"

# Function to setup SSH for a user
setup_ssh_for_user() {
    local user=$1
    local home=$2
    
    print_status "Setting up SSH for user: $user"
    
    # Ensure .ssh directory exists
    sudo -u $user mkdir -p $home/.ssh
    sudo -u $user chmod 700 $home/.ssh
    
    # Generate SSH key if it doesn't exist
    if [ ! -f "$home/.ssh/id_rsa" ]; then
        print_status "Generating SSH key for $user"
        sudo -u $user ssh-keygen -t rsa -b 2048 -f $home/.ssh/id_rsa -N "" -C "$user@$(hostname)"
    fi
    
    # Set proper permissions
    sudo -u $user chmod 600 $home/.ssh/id_rsa
    sudo -u $user chmod 644 $home/.ssh/id_rsa.pub
    
    # Copy key to other node
    for node in $NODE1 $NODE2; do
        if [ "$node" != "$(hostname -f)" ]; then
            print_status "Copying SSH key for $user to $node"
            sudo -u $user ssh-copy-id -o StrictHostKeyChecking=no $user@$node 2>/dev/null || {
                print_warning "Failed to copy key to $node for $user using ssh-copy-id, trying manual method"
                # Manual method
                pubkey=$(sudo -u $user cat $home/.ssh/id_rsa.pub)
                ssh -o StrictHostKeyChecking=no root@$node "
                    sudo -u $user mkdir -p $home/.ssh
                    echo '$pubkey' | sudo -u $user tee -a $home/.ssh/authorized_keys
                    sudo -u $user chmod 600 $home/.ssh/authorized_keys
                    sudo -u $user chmod 700 $home/.ssh
                " || print_error "Failed to setup SSH for $user to $node"
            }
        fi
        
        # Add to known_hosts
        print_status "Adding $node to known_hosts for $user"
        sudo -u $user ssh-keyscan -H $node >> $home/.ssh/known_hosts 2>/dev/null || true
    done
    
    # Remove duplicates from known_hosts
    if [ -f "$home/.ssh/known_hosts" ]; then
        sudo -u $user sort -u $home/.ssh/known_hosts > $home/.ssh/known_hosts.tmp
        sudo -u $user mv $home/.ssh/known_hosts.tmp $home/.ssh/known_hosts
        sudo -u $user chmod 644 $home/.ssh/known_hosts
    fi
}

# Function to test SSH connectivity
test_ssh_connectivity() {
    local user=$1
    print_status "Testing SSH connectivity for $user"
    
    for node in $NODE1 $NODE2; do
        if sudo -u $user ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $user@$node 'hostname' >/dev/null 2>&1; then
            print_success "SSH connectivity working: $user@$node"
        else
            print_error "SSH connectivity failed: $user@$node"
        fi
    done
}

# Main execution
case "$1" in
    "setup")
        print_status "Setting up SSH connectivity for all Oracle users"
        for i in "${!ORACLE_USERS[@]}"; do
            setup_ssh_for_user "${ORACLE_USERS[$i]}" "${ORACLE_HOMES[$i]}"
        done
        ;;
    "test")
        print_status "Testing SSH connectivity for all Oracle users"
        for user in "${ORACLE_USERS[@]}"; do
            test_ssh_connectivity "$user"
        done
        ;;
    "fix")
        print_status "Fixing SSH connectivity issues"
        for i in "${!ORACLE_USERS[@]}"; do
            setup_ssh_for_user "${ORACLE_USERS[$i]}" "${ORACLE_HOMES[$i]}"
        done
        
        print_status "Testing connectivity after fix"
        for user in "${ORACLE_USERS[@]}"; do
            test_ssh_connectivity "$user"
        done
        ;;
    *)
        echo "Usage: $0 {setup|test|fix}"
        echo ""
        echo "Commands:"
        echo "  setup  - Set up SSH keys and connectivity"
        echo "  test   - Test SSH connectivity"
        echo "  fix    - Fix SSH connectivity issues"
        echo ""
        echo "Example:"
        echo "  $0 fix"
        exit 1
        ;;
esac

print_success "SSH connectivity setup completed!"
echo ""
echo "Next steps:"
echo "1. Run '$0 test' to verify connectivity"
echo "2. Try Oracle RAC installation again"
echo "3. If issues persist, check /var/log/messages for SSH errors" 