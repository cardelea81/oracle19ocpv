#!/bin/bash

# Example Oracle RAC Installation Script
# This script demonstrates a step-by-step installation approach

echo "==============================================="
echo "Oracle RAC 19c Installation Example"
echo "==============================================="

# Step 1: Prerequisites
echo ""
echo "Step 1: Installing Prerequisites..."
./run_installation.sh prerequisites

# Step 2: Users and Groups
echo ""
echo "Step 2: Creating Oracle Users and Groups..."
./run_installation.sh users

# Step 3: Storage Configuration
echo ""
echo "Step 3: Configuring Storage..."
./run_installation.sh storage

# Step 4: Node Configuration
echo ""
echo "Step 4: Configuring Nodes..."
./run_installation.sh node-config

# Step 5: Grid Infrastructure
echo ""
echo "Step 5: Installing Grid Infrastructure..."
echo "Note: This step may take 30-60 minutes"
./run_installation.sh grid

# Step 6: Database Software
echo ""
echo "Step 6: Installing Database Software..."
echo "Note: This step may take 20-30 minutes"
./run_installation.sh database

# Step 7: Post Installation
echo ""
echo "Step 7: Post Installation Configuration..."
./run_installation.sh post-install

# Step 8: Verification
echo ""
echo "Step 8: Verifying Installation..."
./run_installation.sh check

echo ""
echo "==============================================="
echo "Oracle RAC Installation Completed!"
echo "==============================================="
echo ""
echo "Next steps:"
echo "1. Create ASM diskgroups for DATA and FRA"
echo "2. Create Oracle RAC database using DBCA"
echo "3. Configure services and listeners"
echo ""
echo "Summary file: /root/oracle_rac_installation_summary.txt" 