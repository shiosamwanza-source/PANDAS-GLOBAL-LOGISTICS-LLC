#!/bin/bash

# ========================================
# PANDAS GLOBAL LOGISTICS - Database Setup Script
# ========================================
# This script automates the database setup process
# Run with: bash setup_database.sh
# ========================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "========================================="
echo "  PANDAS GLOBAL LOGISTICS"
echo "  Database Setup Script"
echo "========================================="
echo -e "${NC}"

# ========================================
# Configuration
# ========================================

# Default values
DB_NAME="${DB_NAME:-pandas_db}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
ENV="${ENV:-development}"  # development, staging, or production

echo -e "${YELLOW}Configuration:${NC}"
echo "  Database Name: $DB_NAME"
echo "  Database User: $DB_USER"
echo "  Database Host: $DB_HOST"
echo "  Database Port: $DB_PORT"
echo "  Environment: $ENV"
echo ""

# ========================================
# Check Prerequisites
# ========================================

echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}ERROR: psql not found. Please install PostgreSQL first.${NC}"
    exit 1
fi

# Check if PostgreSQL is running
if ! pg_isready -h $DB_HOST -p $DB_PORT &> /dev/null; then
    echo -e "${RED}ERROR: PostgreSQL is not running on $DB_HOST:$DB_PORT${NC}"
    exit 1
fi

echo -e "${GREEN}✓ PostgreSQL is installed and running${NC}"

# ========================================
# Ask for Password
# ========================================

echo ""
read -sp "Enter password for PostgreSQL user '$DB_USER': " DB_PASSWORD
echo ""
export PGPASSWORD="$DB_PASSWORD"

# ========================================
# Test Connection
# ========================================

echo ""
echo -e "${YELLOW}Testing database connection...${NC}"

if ! psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Cannot connect to PostgreSQL. Check your password and credentials.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Database connection successful${NC}"

# ========================================
# Check if Database Exists
# ========================================

echo ""
echo -e "${YELLOW}Checking if database exists...${NC}"

DB_EXISTS=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")

if [ "$DB_EXISTS" = "1" ]; then
    echo -e "${YELLOW}⚠ Database '$DB_NAME' already exists!${NC}"
    read -p "Do you want to DROP and recreate it? (yes/no): " RECREATE
    
    if [ "$RECREATE" = "yes" ]; then
        echo -e "${YELLOW}Dropping existing database...${NC}"
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
        echo -e "${GREEN}✓ Database dropped${NC}"
    else
        echo -e "${YELLOW}Using existing database. Schema will be updated.${NC}"
    fi
fi

# ========================================
# Create Database
# ========================================

if [ "$DB_EXISTS" != "1" ] || [ "$RECREATE" = "yes" ]; then
    echo ""
    echo -e "${YELLOW}Creating database '$DB_NAME'...${NC}"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;"
    echo -e "${GREEN}✓ Database created${NC}"
fi

# ========================================
# Run Schema Creation
# ========================================

echo ""
echo -e "${YELLOW}Creating database schema...${NC}"

if [ ! -f "01_create_schema.sql" ]; then
    echo -e "${RED}ERROR: 01_create_schema.sql not found in current directory${NC}"
    exit 1
fi

psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f 01_create_schema.sql > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Schema created successfully${NC}"
else
    echo -e "${RED}ERROR: Failed to create schema${NC}"
    exit 1
fi

# ========================================
# Run Seed Data (Development/Staging Only)
# ========================================

if [ "$ENV" != "production" ]; then
    echo ""
    echo -e "${YELLOW}Loading seed data (test data)...${NC}"
    
    if [ ! -f "02_seed_data.sql" ]; then
        echo -e "${YELLOW}⚠ 02_seed_data.sql not found. Skipping seed data.${NC}"
    else
        read -p "Load test data? (yes/no): " LOAD_SEED
        
        if [ "$LOAD_SEED" = "yes" ]; then
            psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f 02_seed_data.sql > /dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Seed data loaded successfully${NC}"
            else
                echo -e "${RED}ERROR: Failed to load seed data${NC}"
                exit 1
            fi
        fi
    fi
else
    echo -e "${YELLOW}⚠ Production environment detected. Skipping seed data.${NC}"
fi

# ========================================
# Verify Installation
# ========================================

echo ""
echo -e "${YELLOW}Verifying installation...${NC}"

# Count tables
TABLE_COUNT=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'")

echo -e "${GREEN}✓ Created $TABLE_COUNT tables${NC}"

# Count users (if seed data was loaded)
if [ "$LOAD_SEED" = "yes" ]; then
    USER_COUNT=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM users")
    echo -e "${GREEN}✓ Loaded $USER_COUNT test users${NC}"
fi

# ========================================
# Create Database Backup
# ========================================

echo ""
read -p "Create initial backup? (yes/no): " CREATE_BACKUP

if [ "$CREATE_BACKUP" = "yes" ]; then
    BACKUP_FILE="backup_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
    echo -e "${YELLOW}Creating backup: $BACKUP_FILE${NC}"
    
    pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME > $BACKUP_FILE
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
    else
        echo -e "${RED}ERROR: Failed to create backup${NC}"
    fi
fi

# ========================================
# Display Connection Info
# ========================================

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}✓ Database setup complete!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Connection String (for your application):"
echo -e "${YELLOW}postgresql://$DB_USER:YOUR_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME${NC}"
echo ""
echo "Connect using psql:"
echo -e "${YELLOW}psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME${NC}"
echo ""

# ========================================
# Test Credentials (if seed data loaded)
# ========================================

if [ "$LOAD_SEED" = "yes" ]; then
    echo -e "${BLUE}Test User Credentials:${NC}"
    echo ""
    echo "Admin:"
    echo "  Email: admin@pandaslogistics.com"
    echo "  Password: ChangeMe123!"
    echo ""
    echo "Importer:"
    echo "  Email: fatma@example.com"
    echo "  Password: Test123!"
    echo ""
    echo "Agent:"
    echo "  Email: chen@example.com"
    echo "  Password: Test123!"
    echo ""
    echo "Supplier:"
    echo "  Email: wang@example.com"
    echo "  Password: Test123!"
    echo ""
    echo -e "${RED}⚠ IMPORTANT: Change these passwords in production!${NC}"
    echo ""
fi

# ========================================
# Next Steps
# ========================================

echo -e "${BLUE}Next Steps:${NC}"
echo "1. Review the database schema in 01_create_schema.sql"
echo "2. Check common queries in 03_common_queries.sql"
echo "3. Read README_DATABASE.md for full documentation"
echo "4. Configure your backend to connect to this database"
echo "5. Set up regular backups (see README_DATABASE.md)"
echo ""

# Clear password from environment
unset PGPASSWORD

echo -e "${GREEN}Setup script finished successfully!${NC}"
echo ""