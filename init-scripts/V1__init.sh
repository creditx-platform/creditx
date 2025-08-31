#!/bin/bash

set -e

echo "Running create users script..."

# Check if required environment variables are set
if [[ -z "$INIT_PWD" || -z "$INIT_USER" || -z "$INIT_PASSWORD" ]]; then
    echo "Error: Required environment variables not set"
    echo "Please set: INIT_PWD, INIT_USER, INIT_PASSWORD"
    exit 1
fi

echo "Creating ${INIT_USER} database users with suffixes..."

# Define user suffixes for each service
MAIN_USER="${INIT_USER}_MAIN"
HOLD_USER="${INIT_USER}_HOLD"
POST_USER="${INIT_USER}_POST"

echo "Creating users: ${MAIN_USER}, ${HOLD_USER}, ${POST_USER}"

# Connect directly to FREEPDB1 and create users
sqlplus -s "sys/${INIT_PWD}@//localhost:1521/FREEPDB1" AS SYSDBA <<EOF
    WHENEVER SQLERROR EXIT SQL.SQLCODE
    
    -- Drop users if they exist
    DECLARE
        user_exists NUMBER;
    BEGIN
        -- Drop ${MAIN_USER}
        SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = '${MAIN_USER^^}';
        IF user_exists > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER ${MAIN_USER} CASCADE';
        END IF;
        
        -- Drop ${HOLD_USER}
        SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = '${HOLD_USER^^}';
        IF user_exists > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER ${HOLD_USER} CASCADE';
        END IF;
        
        -- Drop ${POST_USER}
        SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = '${POST_USER^^}';
        IF user_exists > 0 THEN
            EXECUTE IMMEDIATE 'DROP USER ${POST_USER} CASCADE';
        END IF;
    END;
    /
    
    -- Create ${MAIN_USER} user (Main Service)
    CREATE USER ${MAIN_USER} IDENTIFIED BY "${INIT_PASSWORD}";
    GRANT CONNECT, RESOURCE TO ${MAIN_USER};
    ALTER USER ${MAIN_USER} QUOTA UNLIMITED ON USERS;
    
    -- Create ${HOLD_USER} user (Hold Service)
    CREATE USER ${HOLD_USER} IDENTIFIED BY "${INIT_PASSWORD}";
    GRANT CONNECT, RESOURCE TO ${HOLD_USER};
    ALTER USER ${HOLD_USER} QUOTA UNLIMITED ON USERS;
    
    -- Create ${POST_USER} user (Posting Service)
    CREATE USER ${POST_USER} IDENTIFIED BY "${INIT_PASSWORD}";
    GRANT CONNECT, RESOURCE TO ${POST_USER};
    ALTER USER ${POST_USER} QUOTA UNLIMITED ON USERS;
    
    -- Verify creation
    SELECT '${MAIN_USER} created' as result FROM DUAL 
    WHERE EXISTS (SELECT 1 FROM dba_users WHERE username = '${MAIN_USER^^}');
    
    SELECT '${HOLD_USER} created' as result FROM DUAL 
    WHERE EXISTS (SELECT 1 FROM dba_users WHERE username = '${HOLD_USER^^}');
    
    SELECT '${POST_USER} created' as result FROM DUAL 
    WHERE EXISTS (SELECT 1 FROM dba_users WHERE username = '${POST_USER^^}');
    
    COMMIT;
    EXIT;
EOF

if [ $? -eq 0 ]; then
    echo "✅ All ${INIT_USER} users created successfully"
    echo "   - ${MAIN_USER} (Main Service)"
    echo "   - ${HOLD_USER} (Hold Service)" 
    echo "   - ${POST_USER} (Posting Service)"
else
    echo "❌ User creation failed"
    exit 1
fi