#!/bin/bash

# Definição das variáveis de conexão com o banco de dados
DB_HOST="inpi.database.windows.net"
DB_PORT="1433"
DB_NAME="PROGRAMAS"
DB_USER="inpi"
DB_PASSWORD="!@#N3w0@"

# Diretório onde estão localizados os arquivos XML
XML_DIR="/home/ubuntu/INPI/PROGRAMAS"

# Verificar se o diretório existe e pode ser acessado
if [ ! -d "$XML_DIR" ]; then
    echo "Diretório PROGRAMAS não encontrado."
    exit 1
fi

# Inicializar um array para armazenar os despachos
declare -a despachos_array

# Obter o último diretório com maior número
maior_pasta=$(ls -d "$XML_DIR"/*/ | sort -n | tail -n 1)

if [[ -n "$maior_pasta" ]]; then
    # Iterar sobre todos os arquivos XML no diretório mais recente
    for xml_file in "$maior_pasta"/*.xml; do
        if [[ -f "$xml_file" ]]; then
            # Extrair o conteúdo XML do arquivo usando xmlstarlet
            xml_content=$(xmlstarlet sel -t -c "/despacho" "$xml_file")

            # Nome do diretório (Revista) e data atual (apenas data, sem hora) para inclusão na tabela
            REVISTA=$(basename "$maior_pasta")
            DATA=$(date +'%Y-%m-%d')

            # Chamar a procedure no SQL Server para enviar cada XML individualmente
            /opt/mssql-tools/bin/sqlcmd -S "$DB_HOST,$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -P "$DB_PASSWORD" \
                -Q "EXEC SP_INSERT_XML '$REVISTA', '$DATA', '$xml_content';"

            echo "Inserção do XML $xml_file no banco de dados concluída."
        fi
    done
else
    echo "Nenhum diretório encontrado em $XML_DIR."
fi
