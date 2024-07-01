package insert_contratos_script

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

func main() {
	// Carregar variáveis de ambiente do arquivo .env
	if err := godotenv.Load(); err != nil {
		log.Fatalf("Erro ao carregar arquivo .env: %v", err)
	}

	// Verificar se a variável de ambiente DIR_CONTRATOS está definida
	dirContratos := os.Getenv("DIR_CONTRATOS")
	if dirContratos == "" {
		log.Fatal("Variável de ambiente DIR_CONTRATOS não está definida")
	}

	// Verificar se o diretório DIR_CONTRATOS existe
	if _, err := os.Stat(dirContratos); os.IsNotExist(err) {
		log.Fatalf("Diretório %s não encontrado", dirContratos)
	}

	// Encontrar a maior pasta dentro de DIR_CONTRATOS
	maiorPasta, err := encontrarMaiorPasta(dirContratos)
	if err != nil {
		log.Fatalf("Erro ao encontrar maior pasta em %s: %v", dirContratos, err)
	}

	// Encontrar o arquivo XML dentro da maior pasta encontrada
	xmlFile, err := encontrarXML(maiorPasta)
	if err != nil {
		log.Fatalf("Erro ao encontrar arquivo XML em %s: %v", maiorPasta, err)
	}

	// Ler conteúdo do arquivo XML e extrair o despacho
	despacho, err := extrairDespacho(xmlFile)
	if err != nil {
		log.Fatalf("Erro ao extrair despacho do arquivo XML %s: %v", xmlFile, err)
	}

	// Conectar ao banco de dados e executar o procedimento armazenado
	err = inserirXMLNoBanco(maiorPasta, despacho)
	if err != nil {
		log.Fatalf("Erro ao inserir XML no banco de dados: %v", err)
	}

	fmt.Printf("Inserção do XML %s no banco de dados concluída.\n", xmlFile)
}

func encontrarMaiorPasta(dir string) (string, error) {
	var maiorPasta string
	var maiorModTime time.Time

	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() && info.ModTime().After(maiorModTime) {
			maiorPasta = path
			maiorModTime = info.ModTime()
		}
		return nil
	})

	if err != nil {
		return "", err
	}

	return maiorPasta, nil
}

func encontrarXML(dir string) (string, error) {
	var xmlFile string

	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(info.Name(), ".xml") {
			xmlFile = path
		}
		return nil
	})

	if err != nil {
		return "", err
	}

	if xmlFile == "" {
		return "", fmt.Errorf("Nenhum arquivo XML encontrado em %s", dir)
	}

	return xmlFile, nil
}

func extrairDespacho(xmlFile string) (string, error) {
	// Ler conteúdo do arquivo XML e extrair o despacho
	cmd := exec.Command("xmllint", "--format", xmlFile)
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}

	// Filtrar o despacho usando XPath
	cmd = exec.Command("xmllint", "--xpath", "//despacho/text()", "-")
	cmd.Stdin = strings.NewReader(string(output))
	despacho, err := cmd.Output()
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(string(despacho)), nil
}

func inserirXMLNoBanco(revista, despacho string) error {
	// Conectar ao banco de dados e executar o procedimento armazenado
	// Use os.Getenv para ler variáveis de ambiente do .env
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")

	cmd := exec.Command("sqlcmd",
		"-S", fmt.Sprintf("%s,%s", dbHost, dbPort),
		"-d", dbName,
		"-U", dbUser,
		"-P", dbPassword,
		"-Q", fmt.Sprintf("EXEC SP_INSERT_XML_CONTRATOS '%s', '%s', '%s';", revista, time.Now().Format("2006-01-02"), despacho),
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return err
	}

	return nil
}
