#!/bin/bash

# Oracle RAC 19c Installation Script
# This script provides a convenient way to run the Oracle RAC installation

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    # Check if inventory file exists
    if [ ! -f "inventory/hosts.yml" ]; then
        print_error "Inventory file not found. Please create inventory/hosts.yml"
        exit 1
    fi
    
    # Check if variables file exists
    if [ ! -f "vars/oracle_rac_vars.yml" ]; then
        print_error "Variables file not found. Please create vars/oracle_rac_vars.yml"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  full              Run complete Oracle RAC installation"
    echo "  prerequisites     Install prerequisites and prepare system"
    echo "  users             Create Oracle users and groups"
    echo "  storage           Configure iSCSI and ASM storage"
    echo "  node-config       Configure node-specific settings"
    echo "  grid              Install Grid Infrastructure"
    echo "  database          Install Database software"
    echo "  post-install      Run post-installation tasks"
    echo "  check             Check cluster status"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 full                    # Complete installation"
    echo "  $0 prerequisites           # Install prerequisites only"
    echo "  $0 grid                    # Install Grid Infrastructure only"
}

# Function to run ansible playbook with specific tags
run_playbook() {
    local tags="$1"
    local description="$2"
    
    print_status "Running: $description"
    
    if [ -n "$tags" ]; then
        ansible-playbook -i inventory/hosts.yml oracle-rac-playbook.yml --tags "$tags"
    else
        ansible-playbook -i inventory/hosts.yml oracle-rac-playbook.yml
    fi
    
    if [ $? -eq 0 ]; then
        print_success "$description completed successfully"
    else
        print_error "$description failed"
        exit 1
    fi
}

# Function to check cluster status
check_cluster() {
    print_status "Checking cluster status..."
    ansible oracle_rac_node1 -i inventory/hosts.yml -m shell -a "su - grid -c 'crsctl stat res -t'" -b
}

# Main script logic
main() {
    case "$1" in
        "full")
            check_prerequisites
            print_status "Starting complete Oracle RAC installation..."
            run_playbook "" "Complete Oracle RAC Installation"
            print_success "Oracle RAC installation completed!"
            print_status "Check the installation summary at /root/oracle_rac_installation_summary.txt"
            ;;
        "prerequisites")
            check_prerequisites
            run_playbook "prerequisites" "Prerequisites Installation"
            ;;
        "users")
            check_prerequisites
            run_playbook "users" "Oracle Users and Groups Creation"
            ;;
        "storage")
            check_prerequisites
            run_playbook "storage" "Storage Configuration"
            ;;
        "node-config")
            check_prerequisites
            run_playbook "node1,node2" "Node Configuration"
            ;;
        "grid")
            check_prerequisites
            run_playbook "grid_install" "Grid Infrastructure Installation"
            ;;
        "database")
            check_prerequisites
            run_playbook "db_install" "Database Software Installation"
            ;;
        "post-install")
            check_prerequisites
            run_playbook "post_install" "Post-Installation Configuration"
            ;;
        "check")
            check_cluster
            ;;
        "--help"|"-h"|"help")
            show_usage
            ;;
        "")
            print_error "No option specified"
            show_usage
            exit 1
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 