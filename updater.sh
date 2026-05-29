#!/usr/bin/env bash
set -e

# ============================================================
#   PTERODACTYL PANEL UPDATER
#   Feito por BN Cloud | Discord: eabn8
# ============================================================

# Cores
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
CIANO='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # Sem cor

# Cabeçalhos das seções
print_header() {
    echo -e "\n${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CIANO} $1 ${NC}"
    echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Mensagens de status
print_status() {
    echo -e "${AMARELO}⏳ $1...${NC}"
}

print_success() {
    echo -e "${VERDE}✅ $1${NC}"
}

print_error() {
    echo -e "${VERMELHO}❌ $1${NC}"
}

print_warning() {
    echo -e "${MAGENTA}⚠️  $1${NC}"
}

# Verifica sucesso do último comando
check_success() {
    if [ $? -eq 0 ]; then
        print_success "$1"
        return 0
    else
        print_error "$2"
        return 1
    fi
}

# Barra de progresso animada
animate_progress() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='|/-\'
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Limpa a tela e mostra a logo BN Cloud
clear
echo -e "${VERDE}"
cat <<'EOF'
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|

        FEITO POR BN CLOUD | DISCORD: eabn8
EOF
echo -e "${NC}"
echo -e "${AMARELO}=========== Atualizador do Pterodactyl Panel ===========${NC}\n"

# Verifica se é root
if [ "$EUID" -ne 0 ]; then
    print_error "Execute este script como root ou com sudo"
    exit 1
fi

print_header "INICIANDO PROCESSO DE ATUALIZAÇÃO"

# Acessa o diretório do painel
print_status "Indo para o diretório do painel"
cd /var/www/pterodactyl || { print_error "Diretório do painel não encontrado!"; exit 1; }
print_success "Diretório do painel acessado"

# Modo de manutenção
print_header "MODO DE MANUTENÇÃO"
print_status "Ativando modo de manutenção"
php artisan down > /dev/null 2>&1 &
animate_progress $! "Colocando painel em modo de manutenção"
print_success "Modo de manutenção ativado"

# Download da versão mais recente
print_header "BAIXANDO ATUALIZAÇÃO"
print_status "Baixando a versão mais recente do painel"
curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv > /dev/null 2>&1 &
animate_progress $! "Baixando e extraindo atualização"
print_success "Versão mais recente baixada e extraída"

# Permissões
print_header "CONFIGURANDO PERMISSÕES"
print_status "Ajustando permissões"
chmod -R 755 storage/* bootstrap/cache > /dev/null 2>&1 &
animate_progress $! "Ajustando permissões"
print_success "Permissões ajustadas"

# Dependências PHP (composer)
print_header "INSTALANDO DEPENDÊNCIAS"
print_status "Executando composer install"
composer install --no-dev --optimize-autoloader > /dev/null 2>&1 &
animate_progress $! "Instalando dependências PHP"
print_success "Dependências PHP instaladas"

# Limpar caches
print_header "LIMPANDO CACHE"
print_status "Limpando cache de visualização"
php artisan view:clear > /dev/null 2>&1 &
animate_progress $! "Limpando cache de views"
print_success "Cache de views limpo"

print_status "Limpando cache de configuração"
php artisan config:clear > /dev/null 2>&1 &
animate_progress $! "Limpando cache de configuração"
print_success "Cache de configuração limpo"

# Migrações do banco
print_header "MIGRAÇÃO DO BANCO DE DADOS"
print_status "Executando migrações"
php artisan migrate --seed --force > /dev/null 2>&1 &
animate_progress $! "Executando migrações"
print_success "Migrações concluídas"

# Ajustar proprietário
print_header "PROPRIETÁRIO DOS ARQUIVOS"
print_status "Definindo proprietário como www-data"
chown -R www-data:www-data /var/www/pterodactyl/* > /dev/null 2>&1 &
animate_progress $! "Definindo proprietário"
print_success "Proprietário definido como www-data"

# Reiniciar workers da fila
print_header "GERENCIAMENTO DE FILAS"
print_status "Reiniciando queue workers"
php artisan queue:restart > /dev/null 2>&1 &
animate_progress $! "Reiniciando queue workers"
print_success "Queue workers reiniciados"

# Tirar do modo de manutenção
print_header "FINALIZANDO ATUALIZAÇÃO"
print_status "Colocando painel online novamente"
php artisan up > /dev/null 2>&1 &
animate_progress $! "Trazendo painel de volta"
print_success "Painel online novamente"

# Resumo final
clear
echo -e "${VERDE}"
cat <<'EOF'
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|
EOF
echo -e "${NC}"
echo -e "${AMARELO}=========== Atualização concluída com sucesso! ===========${NC}\n"
echo -e "${VERDE}🎉 O Pterodactyl Panel foi atualizado com sucesso!${NC}\n"
echo -e "${AMARELO}📋 RESUMO DA ATUALIZAÇÃO:${NC}"
echo -e "  ${CIANO}•${NC} ${VERDE}Modo de manutenção ativado e desativado${NC}"
echo -e "  ${CIANO}•${NC} ${VERDE}Versão mais recente do painel baixada${NC}"
echo -e "  ${CIANO}•${NC} ${VERDE}Permissões de arquivos atualizadas${NC}"
echo -e "  ${CIANO}•${NC} ${VERDE}Dependências PHP instaladas${NC}"
echo -e "  ${CIANO}•${NC} ${VERDE}Cache limpo${NC}"
echo -e "  ${CIANO}•${NC} ${VERDE}Banco de dados migrado${NC}"
echo -e "  ${CIANO}•${NC} ${VERDE}Propriedade dos arquivos corrigida${NC}"
echo -e "  ${CIANO}•${NC} ${VERDE}Queue workers reiniciados${NC}\n"
echo -e "${AMARELO}🔧 PRÓXIMOS PASSOS:${NC}"
echo -e "  ${CIANO}•${NC} Acesse seu painel em ${VERDE}https://seu-dominio.com${NC}"
echo -e "  ${CIANO}•${NC} Verifique se todas as funcionalidades estão normais"
echo -e "  ${CIANO}•${NC} Confira o status dos servidores no painel\n"
echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CIANO}     Obrigado por usar BN Cloud! | Discord: eabn8   ${NC}"
echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e ""
read -p "$(echo -e "${AMARELO}Pressione Enter para sair...${NC}")" -n 1