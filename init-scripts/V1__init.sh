#!/bin/bash

set -e

echo "Running create user script..."

# Check if required environment variables are set
if [[ -z "$INIT_PWD" || -z "$INIT_USER" || -z "$INIT_PASSWORD" ]]; then
    echo "Error: Required environment variables not set"
    echo "Please set: INIT_PWD, INIT_USER, INIT_PASSWORD"
    exit 1
fi

echo "Creating user: ${INIT_USER}"

# Connect directly to FREEPDB1 and create user
sqlplus -s "sys/${INIT_PWD}@//localhost:1521/FREEPDB1" AS SYSDBA <<EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    
    -- Drop user if exists
    DECLARE
        user_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = '${INIT_USER^^}';
        IF user_exists > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER ${INIT_USER} CASCADE';
        END IF;
    END;
    /
    
    -- Create user
    CREATE USER ${INIT_USER} IDENTIFIED BY "${INIT_PASSWORD}";
    
    -- Grant privileges
    GRANT CONNECT, RESOURCE TO ${INIT_USER};
    ALTER USER ${INIT_USER} QUOTA UNLIMITED ON USERS;
    
    -- Verify creation
    SELECT 'User created successfully' as result FROM DUAL 
    WHERE EXISTS (SELECT 1 FROM dba_users WHERE username = '${INIT_USER^^}');
    
    COMMIT;
    EXIT;
EOF

if [ $? -eq 0 ]; then
    echo "✅ User '${INIT_USER}' created successfully"
else
    echo "❌ User creation failed"
    exit 1
fi