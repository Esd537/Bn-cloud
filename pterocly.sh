#!/bin/bash
# ============================================================
#      PTERODACTYL – INSTALAR / USUÁRIO / ATUALIZAR / REMOVER
#      Feito por BN Cloud | Discord: eabn8
# ============================================================

VERDE="\033[1;32m"
VERMELHO="\033[1;31m"
AMARELO="\033[1;33m"
CIANO="\033[1;36m"
NC="\033[0m"

# ----------- Logo BN Cloud -----------
logo() {
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
    echo -e "${AMARELO}=========== Pterodactyl Panel ===========${NC}"
    echo
}

pause() {
    read -p "Pressione Enter para voltar..."
}

# ================= INSTALAR =================
install_ptero() {
    logo
    echo -e "${CIANO}┌──────────────────────────────────────────────┐"
    echo -e "│        🚀 Instalação do Pterodactyl           │"
    echo -e "└──────────────────────────────────────────────┘${NC}"
    bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/panel/pterodactyl.sh)
    echo -e "${VERDE}✔ Instalação concluída${NC}"
    pause
}

# ================= CRIAR USUÁRIO =================
create_user() {
    logo
    echo -e "${CIANO}┌──────────────────────────────────────────────┐"
    echo -e "│        👤 Criar Usuário do Painel              │"
    echo -e "└──────────────────────────────────────────────┘${NC}"

    if [ ! -d /var/www/pterodactyl ]; then
        echo -e "${VERMELHO}❌ Painel não instalado!${NC}"
        pause
        return
    fi

    cd /var/www/pterodactyl || exit
    php artisan p:user:make

    echo -e "${VERDE}✔ Usuário criado com sucesso${NC}"
    pause
}

# ================= REMOVER =================
uninstall_panel() {
    echo ">>> Parando serviço do Painel..."
    systemctl stop pteroq.service 2>/dev/null || true
    systemctl disable pteroq.service 2>/dev/null || true
    rm -f /etc/systemd/system/pteroq.service
    systemctl daemon-reload

    echo ">>> Removendo cronjob..."
    crontab -l | grep -v 'php /var/www/pterodactyl/artisan schedule:run' | crontab - || true

    echo ">>> Removendo arquivos..."
    rm -rf /var/www/pterodactyl

    echo ">>> Removendo banco de dados..."
    mysql -u root -e "DROP DATABASE IF EXISTS panel;"
    mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';"
    mysql -u root -e "FLUSH PRIVILEGES;"

    echo ">>> Limpando nginx..."
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    systemctl reload nginx || true

    echo "✅ Painel removido."
}

uninstall_ptero() {
    logo
    echo -e "${CIANO}┌──────────────────────────────────────────────┐"
    echo -e "│        🧹 Desinstalação do Pterodactyl        │"
    echo -e "└──────────────────────────────────────────────┘${NC}"
    uninstall_panel
    echo -e "${VERDE}✔ Painel desinstalado (Wings mantidos)${NC}"
    pause
}

# ================= ATUALIZAR =================
update_panel() {
    logo
    echo -e "${AMARELO}═══════════════════════════════════════════════"
    echo -e "        ⚡ ATUALIZAÇÃO DO PAINEL              "
    echo -e "═══════════════════════════════════════════════${NC}"

    cd /var/www/pterodactyl || {
        echo -e "${VERMELHO}❌ Painel não encontrado!${NC}"
        pause
        return
    }

    php artisan down
    curl -L https://github.com/pterodactyl/panel/releases/download/v1.11.11/panel.tar.gz | tar -xzv
    chmod -R 755 storage/* bootstrap/cache
    composer install --no-dev --optimize-autoloader
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force
    chown -R www-data:www-data /var/www/pterodactyl/*
    php artisan queue:restart
    php artisan up

    echo -e "${VERDE}🎉 Painel atualizado com sucesso${NC}"
    pause
}

# ================= MENU PRINCIPAL =================
while true; do
    logo
    echo -e "${AMARELO}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║        🐲 CENTRAL DE CONTROLE PTERODACTYL      ║"
    echo "╠═══════════════════════════════════════════════╣"
    echo -e "║ ${VERDE}1) Instalar Painel${NC}"
    echo -e "║ ${CIANO}2) Criar Usuário${NC}"
    echo -e "║ ${AMARELO}3) Atualizar Painel${NC}"
    echo -e "║ ${VERMELHO}4) Remover Painel${NC}"
    echo -e "║ 5) Sair"
    echo "╚═══════════════════════════════════════════════╝"
    echo -ne "${CIANO}Escolha uma opção → ${NC}"
    read choice

    case $choice in
        1) install_ptero ;;
        2) create_user ;;
        3) update_panel ;;
        4) uninstall_ptero ;;
        5) clear; exit ;;
        *) echo -e "${VERMELHO}Opção inválida...${NC}"; sleep 1 ;;
    esac
done