#!/bin/bash

# Script de inicialização rápida do Barbearia App
# Uso: ./start.sh [development|production]

MODE=${1:-development}

echo "🚀 Iniciando Barbearia App em modo: $MODE"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está rodando. Por favor, inicie o Docker Desktop.${NC}"
    exit 1
fi

# Criar arquivo .env se não existir
if [ ! -f backend/.env ]; then
    echo -e "${YELLOW}⚠️  Arquivo .env não encontrado. Criando a partir do .env.example...${NC}"
    cp backend/.env.example backend/.env
    echo -e "${GREEN}✓ Arquivo .env criado. Por favor, edite com suas configurações.${NC}"
fi

# Parar containers anteriores
echo -e "${YELLOW}🛑 Parando containers antigos...${NC}"
docker-compose down

# Iniciar containers
echo -e "${GREEN}🐳 Iniciando containers Docker...${NC}"
docker-compose up -d --build

# Aguardar banco de dados estar pronto
echo -e "${YELLOW}⏳ Aguardando PostgreSQL...${NC}"
sleep 10

# Executar migrations
echo -e "${GREEN}📊 Executando migrations...${NC}"
docker-compose exec -T backend python manage.py migrate

# Criar serviços padrão
echo -e "${GREEN}💈 Criando serviços padrão...${NC}"
docker-compose exec -T backend python manage.py create_default_services

# Collectstatic
echo -e "${GREEN}📦 Coletando arquivos estáticos...${NC}"
docker-compose exec -T backend python manage.py collectstatic --noinput

# Verificar status dos containers
echo ""
echo -e "${GREEN}✓ Containers iniciados com sucesso!${NC}"
echo ""
docker-compose ps

# Mostrar URLs
echo ""
echo -e "${GREEN}📍 URLs de Acesso:${NC}"
echo ""
echo "  🌐 API REST:      http://localhost:7892/api/"
echo "  🔧 Admin Django:  http://localhost:7892/admin/"
echo "  ❤️  Health Check:  http://localhost:7892/health"
echo "  🗄️  PostgreSQL:    localhost:7890"
echo "  🔴 Redis:         localhost:7893"
echo ""

# Criar superuser (opcional)
echo -e "${YELLOW}Deseja criar um superusuário agora? (s/n)${NC}"
read -r CREATE_SUPER

if [ "$CREATE_SUPER" = "s" ] || [ "$CREATE_SUPER" = "S" ]; then
    docker-compose exec backend python manage.py createsuperuser
fi

echo ""
echo -e "${GREEN}✅ Barbearia App está rodando!${NC}"
echo ""
echo -e "${YELLOW}Comandos úteis:${NC}"
echo "  • Ver logs:        docker-compose logs -f"
echo "  • Parar:           docker-compose down"
echo "  • Reiniciar:       docker-compose restart"
echo "  • Shell Django:    docker-compose exec backend python manage.py shell"
echo ""
echo -e "${GREEN}Para rodar o app Flutter:${NC}"
echo "  • flutter pub get"
echo "  • flutter run"
echo ""
