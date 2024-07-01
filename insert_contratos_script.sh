#!/bin/bash

# Function to load environment variables from .env file
load_env() {
    if [ ! -f .env ]; then
        echo ".env not found."
        exit 1
    fi
    export $(cat .env | xargs)
}

# Function to get the latest directory
get_latest_directory() {
    if [ ! -d "$DIR_CONTRATOS" ]; then
        echo "Contracts directory not found: $DIR_CONTRATOS"
        exit 1
    fi
    ls -td "$DIR_CONTRATOS"/*/ | head -n 1
}

# Function to process XML files
process_xml_files() {
    local latestDirectory="$1"
    local xmlFiles=($(ls -1 "${latestDirectory}"/*.xml 2>/dev/null))
    local Date=$(date +'%Y-%m-%d')
    local Revista=$(basename "${latestDirectory}")

    if [[ ${#xmlFiles[@]} -gt 0 ]]; then
        for xmlFile in "${xmlFiles[@]}"
        do
            echo "Processing XML file: ${xmlFile}"
            local xmlContent=$(awk '/<despacho>/,/<\/despacho>/' "${xmlFile}")
            local xmlContentEscaped=$(echo "${xmlContent}" | sed "s/'/''/g")
            local sql_command="INSERT INTO [dbo].[TB_XML_CONTRATOS] (Revista, Data, XmlContent) VALUES ('${Revista}', '${Date}', '${xmlContentEscaped}')"

            # Execute SQL command using sqlcmd
            if ! sqlcmd -S "${DB_HOST},${DB_PORT}" -d "${DB_NAME}" -U "${DB_USER}" -P "${DB_PASSWORD}" -Q "${sql_command}"; then
                echo "Failed to execute SQL command for file ${xmlFile}"
                continue
            fi

            echo "Inserted XML ${xmlFile} into database."
        done
        echo "Script execution completed."
    else
        echo "No XML files found in $latestDirectory."
    fi
}

# Main script execution
load_env
latestDirectory=$(get_latest_directory)
process_xml_files "$latestDirectory"