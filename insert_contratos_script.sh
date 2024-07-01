#!/bin/bash

# Check if .env file exists
if [ ! -f .env ]; then
    echo ".env not found."
    exit 1
fi

# Load environment variables from .env file
export $(cat .env | xargs)

# Check if the contracts directory exists
if [ ! -d "$DIR_CONTRATOS" ]; then
    echo "Contracts directory not found: $DIR_CONTRATOS"
    exit 1
fi

# Find the latest directory inside $DIR_CONTRATOS more efficiently
latestDirectory=$(find "$DIR_CONTRATOS" -type d -printf '%T+ %p\n' | sort -r | head -n 1 | cut -d' ' -f2-)

if [ -n "$latestDirectory" ]; then
    # Find XML files in the latest directory
    readarray -t xmlFiles < <(find "$latestDirectory" -maxdepth 1 -name "*.xml")

    if [ ${#xmlFiles[@]} -gt 0 ]; then
        for xmlFile in "${xmlFiles[@]}"; do
            echo "Processing XML file: $xmlFile"

            xmlContent=$(awk '/<despacho>/,/<\/despacho>/' "$xmlFile")
            xmlContentEscaped=$(echo "$xmlContent" | sed "s/'/''/g")

            # Improved readability for SQL command construction
            sql_command="EXEC dbo.SP_INSERT_XML_CONTRATOS @Revista='$(basename "$latestDirectory")', @XmlContent='$xmlContentEscaped'"

            if ! sqlcmd -S "${DB_HOST},${DB_PORT}" -d "${DB_NAME}" -U "${DB_USER}" -P "${DB_PASSWORD}" -Q "$sql_command"; then
                echo "Failed to insert XML $xmlFile into database."
                continue
            fi

            echo "Inserted XML $xmlFile into database."
        done

        echo "Script execution completed."
    else
        echo "No XML files found in $latestDirectory."
    fi
else
    echo "No directories found in $DIR_CONTRATOS."
fi