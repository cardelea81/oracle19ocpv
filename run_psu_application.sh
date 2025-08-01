#!/bin/bash

# Oracle Grid Infrastructure PSU Application Script
# This script applies PSU patches to Oracle Grid Infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    
    # Check if patch files exist
    if [ ! -f "patch/p6880880_121010_Linux-x86-64.zip" ]; then
        print_error "OPatch file not found: patch/p6880880_121010_Linux-x86-64.zip"
        exit 1
    fi
    
    if [ ! -f "patch/p34762026_190000_Linux-x86-64.zip" ]; then
        print_error "PSU patch file not found: patch/p34762026_190000_Linux-x86-64.zip"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  simple            Run simple PSU application (single node)"
    echo "  full              Run full PSU application (all nodes)"
    echo "  dry-run           Check what would be done without applying"
    echo "  verify            Verify current patch status"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 simple                  # Apply PSU on first node only"
    echo "  $0 full                    # Apply PSU on all RAC nodes"
    echo "  $0 verify                  # Check current patch status"
}

# Function to run playbook
run_playbook() {
    local playbook="$1"
    local description="$2"
    
    print_status "Running: $description"
    
    ansible-playbook -i inventory/hosts.yml "$playbook"
    
    if [ $? -eq 0 ]; then
        print_success "$description completed successfully"
    else
        print_error "$description failed"
        exit 1
    fi
}

# Function to verify patch status
verify_patches() {
    print_status "Checking current patch status..."
    ansible oracle_rac_node1 -i inventory/hosts.yml -m shell -a "
        export ORACLE_HOME=/services/oracle/grid/19.3/grid_home; 
        \$ORACLE_HOME/OPatch/opatch lspatches
    " -b --become-user=grid
}

# Function to perform dry-run
dry_run_check() {
    print_status "Performing dry-run check..."
    ansible-playbook -i inventory/hosts.yml apply_grid_psu_simple.yml --check --diff
}

# Main script logic
main() {
    case "$1" in
        "simple")
            check_prerequisites
            print_status "Starting simple PSU application (single node)..."
            run_playbook "apply_grid_psu_simple.yml" "Simple PSU Application"
            print_success "PSU application completed!"
            ;;
        "full")
            check_prerequisites
            print_status "Starting full PSU application (all nodes)..."
            run_playbook "apply_grid_psu.yml" "Full PSU Application"
            print_success "PSU application completed!"
            ;;
        "dry-run")
            check_prerequisites
            dry_run_check
            ;;
        "verify")
            verify_patches
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

# Display banner
echo "================================================"
echo "Oracle Grid Infrastructure PSU Application"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Make sure SSH keys are set up for Oracle users."
fi

# Run main function with all arguments
main "$@"

echo ""
print_status "For more information, check:"
print_status "- Grid alert logs: \$ORACLE_BASE/diag/asm/+asm/+ASM*/trace/"
print_status "- CRS logs: \$ORACLE_HOME/log/\$(hostname)/client/"
print_status "- Cluster status: su - grid -c 'crsctl stat res -t'" 