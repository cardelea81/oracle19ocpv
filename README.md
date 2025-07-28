# Oracle RAC 19c Installation on Red Hat Linux - Ansible Playbook

This Ansible playbook automates the installation and configuration of Oracle Real Application Clusters (RAC) 19c on Red Hat Enterprise Linux.

## Overview

This playbook performs a complete Oracle RAC installation including:
- System prerequisites and package installation
- Oracle users and groups creation
- iSCSI storage configuration
- Oracle ASM setup
- Grid Infrastructure installation
- Oracle Database software installation
- Post-installation configuration

## Prerequisites

### Infrastructure Requirements
- 2 Red Hat Linux servers (RHEL 8/9 or compatible)
- Shared storage (iSCSI/SAN) with at least 3 disks:
  - 20GB+ for OCR/Voting disks
  - 50GB+ for DATA diskgroup
  - 30GB+ for FRA (Fast Recovery Area)
- Network configuration:
  - Public network for client connections
  - Private network for interconnect
  - Virtual IPs configured in DNS/hosts

### Software Requirements
- Ansible 2.9+
- Oracle Grid Infrastructure 19c software
- Oracle Database 19c software
- Required RPM packages (automatically installed)

### Network Configuration
The playbook assumes the following network layout:
- **Public Network**: `192.168.2.0/24`
- **Private Network**: `172.25.250.0/24`
- **ASM Network**: `192.168.100.0/24`
- **Storage Network**: `192.168.2.137` (iSCSI target)

## Installation

### 1. Clone or Download the Playbook

```bash
git clone <repository-url>
cd oracle-rac-ansible
```

### 2. Configure Inventory

Edit `inventory/hosts.yml` to match your environment:

```yaml
oracle_rac_node1:
  hosts:
    your-node1-fqdn:
      ansible_host: your-node1-ip
      node_id: 1
      public_ip: your-node1-public-ip
      private_ip: your-node1-private-ip
      vip_ip: your-node1-vip-ip
      vip_hostname: your-node1-vip-hostname
```

### 3. Update Variables

Modify `vars/oracle_rac_vars.yml` according to your environment:
- Network configurations
- Storage paths
- Oracle software URLs
- Passwords (use Ansible Vault for production)

### 4. Prepare Oracle Software

Ensure Oracle installation files are available via HTTP server:
- `LINUX.X64_193000_grid_home.zip`
- `LINUX.X64_193000_db_home.zip`
- Required RPM packages

### 5. Run the Playbook

```bash
# Run complete installation
ansible-playbook -i inventory/hosts.yml oracle-rac-playbook.yml

# Run specific phases
ansible-playbook -i inventory/hosts.yml oracle-rac-playbook.yml --tags "prerequisites"
ansible-playbook -i inventory/hosts.yml oracle-rac-playbook.yml --tags "users,storage"
ansible-playbook -i inventory/hosts.yml oracle-rac-playbook.yml --tags "grid_install"
ansible-playbook -i inventory/hosts.yml oracle-rac-playbook.yml --tags "db_install"
```

## Playbook Structure

```
oracle-rac-ansible/
├── oracle-rac-playbook.yml    # Main playbook
├── inventory/
│   └── hosts.yml              # Inventory file
├── vars/
│   └── oracle_rac_vars.yml    # Configuration variables
├── tasks/
│   ├── prerequisites.yml      # System preparation
│   ├── users_groups.yml       # Oracle users/groups
│   ├── storage_setup.yml      # iSCSI and ASM
│   ├── node1_specific.yml     # Node 1 configuration
│   ├── node2_specific.yml     # Node 2 configuration
│   ├── grid_installation.yml  # Grid Infrastructure
│   ├── database_installation.yml # Database software
│   └── post_installation.yml  # Final configuration
├── templates/
│   ├── hosts.j2               # /etc/hosts template
│   ├── grid.rsp.j2           # Grid response file
│   ├── db.rsp.j2             # Database response file
│   ├── *_bashrc_*.j2         # User profiles
│   └── *.j2                  # Other templates
└── README.md                  # This file
```

## Configuration Tags

Use tags to run specific parts of the installation:

- `prerequisites` - System packages and configuration
- `users` - Oracle users and groups
- `storage` - iSCSI and ASM setup
- `node1` - Node 1 specific tasks
- `node2` - Node 2 specific tasks
- `grid_install` - Grid Infrastructure installation
- `db_install` - Database software installation
- `post_install` - Final configuration

## Post-Installation Steps

After successful completion:

1. **Verify Cluster Status**:
   ```bash
   su - grid
   crsctl stat res -t
   ```

2. **Create Additional ASM Diskgroups**:
   ```bash
   su - grid
   asmca  # Use GUI or silent mode
   ```

3. **Create Oracle RAC Database**:
   ```bash
   su - oracle
   dbca  # Use GUI or silent mode
   ```

4. **Configure Services and Listeners**:
   ```bash
   su - oracle
   srvctl add service -d ORCL -s ORCLSRV -r ORCL1,ORCL2
   ```

## Troubleshooting

### Common Issues

1. **SSH Connectivity**: Ensure passwordless SSH is configured
2. **Storage Access**: Verify iSCSI targets are accessible
3. **Network Configuration**: Check VIP and SCAN resolution
4. **Permissions**: Ensure Oracle users have proper permissions

### Log Locations

- Grid Infrastructure: `$ORACLE_INVENTORY/logs/`
- Database Installation: `$ORACLE_BASE/diag/`
- System logs: `/var/log/messages`

### Useful Commands

```bash
# Check cluster status
su - grid -c "crsctl stat res -t"

# Check ASM status
su - grid -c "srvctl status asm"

# Check database status
su - oracle -c "srvctl status database -d ORCL"

# View cluster configuration
su - grid -c "olsnodes -v"
```

## Security Considerations

- Use Ansible Vault for sensitive data
- Implement proper firewall rules
- Configure SSL/TLS for database connections
- Regular security patches and updates
- Monitor audit logs

## Customization

### Network Configuration
Modify `oracle_rac_nodes` and `network_interfaces` in variables file.

### Storage Configuration
Update `asm_disks` configuration for different storage layout.

### Oracle Versions
Adjust `oracle_version` and software URLs for different Oracle versions.

## Support

For issues and questions:
- Review Oracle documentation
- Check Ansible logs and task output
- Verify system requirements
- Consult Oracle support for licensing questions

## License

This playbook is provided as-is for educational and testing purposes. Oracle software licensing is governed by Oracle Corporation's terms and conditions. 