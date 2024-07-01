#!/bin/bash

if [ ! -f .env ]; then
  echo ".ENV não encontrado"
  exit 1
else
  export $(cat .env | xargs)
fi

if [ ! -d "$DIR_CONTRATOS" ]; then
    echo "Diretório não encontrado."
    exit 1
fi

maior_pasta=$(ls -d "$DIR_CONTRATOS"/*/ | sort -n | tail -n 1)

if [[ -n "$maior_pasta" ]]; then
    xml_file=$(find "$maior_pasta" -type f -name "*.xml")

    if [[ -f "$xml_file" ]]; then
        xmllint --format "$xml_file" | xmllint --xpath '//despacho' - | while IFS= read -r despacho; do
            despacho=$(echo "$despacho" | tr -d '\n' | tr -d '\r')

            sqlcmd -S "$DB_HOST,$DB_PORT" -d "CONTRATOS" -U "$DB_USER" -P "$DB_PASSWORD" \
                -Q "EXEC SP_INSERT_XML_CONTRATOS '$(basename "$maior_pasta")', '$(date +'%Y-%m-%d')', '$despacho';"

            echo "Inserção do XML $xml_file no banco de dados concluída."
        done
    else
        echo "Nenhum arquivo XML encontrado em $maior_pasta."
    fi
else
    echo "Nenhum diretório encontrado em $DIR_CONTRATOS."
fi
