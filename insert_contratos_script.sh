#!/bin/bash

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

# Find the latest directory inside $DIR_CONTRATOS
latestDirectory=$(ls -d "$DIR_CONTRATOS"/*/ | sort -n | tail -n 1)

if [[ -n "$latestDirectory" ]]; then
    # Find XML files in the latest directory
    xmlFiles=($(find ${latestDirectory} -maxdepth 1 -name "*.xml"))

    if [[ ${#xmlFiles[@]} -gt 0 ]]; then
        for xmlFile in "${xmlFiles[@]}"
        do
            # Process each XML file
            echo "Processing XML file: ${xmlFile}"

            # Example of extracting XML content using awk (replace with your logic)
            xmlContent=$(awk '/<despacho>/,/<\/despacho>/' "${xmlFile}")

            # Example: Escape single quotes in XML content (replace with appropriate escaping)
            xmlContentEscaped=$(echo "${xmlContent}" | sed "s/'/''/g")

            # Example: Construct SQL command to insert XML content into database
            sql_command="EXEC dbo.SP_INSERT_XML_CONTRATOS @Revista='$(basename "${latestDirectory}")', @Data=GETDATE(), @XmlContent='${xmlContentEscaped}'"

            # Example: Execute SQL command using sqlcmd (replace with your database command)
            sqlcmd -S "${DB_HOST},${DB_PORT}" -d "${DB_NAME}" -U "${DB_USER}" -P "${DB_PASSWORD}" -Q "${sql_command}"

            echo "Inserted XML ${xmlFile} into database."
        done

        echo "Script execution completed."
    else
        echo "No XML files found in $latestDirectory."
    fi
else
    echo "No directories found in $DIR_CONTRATOS."
fi
