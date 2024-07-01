#!/bin/bash

# Definição das variáveis de conexão com o banco de dados
if [ ! -f .env ]; then
  echo ".env file not found!"
  exit 1
else
  export $(cat .env | xargs)
fi

# Verificar se o diretório existe e pode ser acessado
if [ ! -d "$DIR_CONTRATOS" ]; then
    echo "Diretório não encontrado."
    exit 1
fi

# Obter o último diretório com maior número
maior_pasta=$(ls -d "$DIR_CONTRATOS"/*/ | sort -n | tail -n 1)

if [[ -n "$maior_pasta" ]]; then
    # Encontrar o arquivo XML
    xml_file=$(find "$maior_pasta" -type f -name "*.xml")

    if [[ -f "$xml_file" ]]; then
        # Nome do diretório (Revista) e data atual (apenas data, sem hora) para inclusão na tabela
        REVISTA=$(basename "$maior_pasta")
        DATA=$(date +'%Y-%m-%d')

        # Extrair o conteúdo XML do arquivo usando xmllint
        xmllint --xpath '//despacho' "$xml_file" | while IFS= read -r despacho; do
            # Chamar a procedure no SQL Server para enviar cada XML individualmente
            sqlcmd -S "$DB_HOST,$DB_PORT" -d "CONTRATOS" -U "$DB_USER" -P "$DB_PASSWORD" \
                -Q "EXEC SP_INSERT_XML_CONTRATOS '$REVISTA', '$DATA', '$despacho';"

            echo "Inserção do XML $xml_file no banco de dados concluída."
        done
    else
        echo "Nenhum arquivo XML encontrado em $maior_pasta."
    fi
else
    echo "Nenhum diretório encontrado em $DIR_CONTRATOS."
fi
