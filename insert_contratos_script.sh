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

# Find the latest directory inside $DIR_CONTRATOS using ls and sort
latestDirectory=$(ls -td "$DIR_CONTRATOS"/*/ | head -n 1)

if [[ -n "$latestDirectory" ]]; then
    # Find XML files in the latest directory
    xmlFiles=($(ls -1 "${latestDirectory}"/*.xml 2>/dev/null))

    Date=$(date +'%Y-%m-%d')
    Revista=$(basename "${latestDirectory}")

    if [[ ${#xmlFiles[@]} -gt 0 ]]; then
        for xmlFile in "${xmlFiles[@]}"; do
            # Process each XML file
            echo "Processing XML file: ${xmlFile}"

            # Example of extracting XML content using awk (replace with your logic)
            xmlContent=$(awk '/<despacho>/,/<\/despacho>/' "${xmlFile}")

            # Example: Escape single quotes in XML content for SQL compatibility
            xmlContentEscaped=$(echo "${xmlContent}" | sed "s/'/''/g")

            # Example: Construct SQL command to insert XML content into a table
            sql_command="INSERT INTO dbo.TB_XML_CONTRATOS (Revista, Data, XmlContent) VALUES ('${Revista}', '${Date}', '${xmlContentEscaped}')"

            # Construct SQL connection string and execute SQL command using sqlcmd
            sqlcmd -S "${DB_HOST},${DB_PORT}" -d "${DB_NAME}" -U "${DB_USER}" -P "${DB_PASSWORD}" -Q "${sql_command}"

            if [ $? -eq 0 ]; then
                echo "Inserted XML ${xmlFile} into database."
            else
                echo "Failed to insert XML ${xmlFile} into database."
            fi
        done

        echo "Script execution completed."
    else
        echo "No XML files found in $latestDirectory."
    fi
else
    echo "No directories found in $DIR_CONTRATOS."
fi
