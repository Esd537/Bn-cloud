#!/usr/bin/env bash

# ============================================================
#   AIRLINK PANEL PRO - INSTALADOR
#   Feito por BN Cloud | Discord: eabn8
# ============================================================

# ----------- UI / Cores -----------
VERMELHO=$(tput setaf 1 2>/dev/null || true)
VERDE=$(tput setaf 2 2>/dev/null || true)
AMARELO="$(tput bold 2>/dev/null || true)$(tput setaf 3 2>/dev/null || true)"
AZUL=$(tput setaf 4 2>/dev/null || true)
CIANO=$(tput setaf 6 2>/dev/null || true)
NC=$(tput sgr0 2>/dev/null || true)

LOG_FILE="${LOG_FILE:-$HOME/airlink-installer.log}"

# ----------- Logo BN Cloud -----------
logo() {
  clear
  printf "%s" "$AZUL"
  cat <<'EOF'
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|

        FEITO POR BN CLOUD | DISCORD: eabn8
EOF
  printf "%s\n" "${NC}${AMARELO}=========== Airlink Panel PRO ===========${NC}"
  printf "%s\n\n" "${AZUL}Arquivo de log:${NC} $LOG_FILE"
}

pause() {
  printf "\n%sPressione Enter para continuar...%s" "$AZUL" "$NC"
  read -r _
}

# ----------- Barra de progresso + pontos -----------
BAR_WIDTH=28
TOTAL_STEPS=1
DONE_STEPS=0

progress_init() {
  TOTAL_STEPS="$1"
  DONE_STEPS=0
}

_progress_line() {
  local msg="$1"
  local dots="$2"

  local percent=$(( DONE_STEPS * 100 / TOTAL_STEPS ))
  local filled=$(( percent * BAR_WIDTH / 100 ))
  local empty=$(( BAR_WIDTH - filled ))

  local fillstr emptstr
  fillstr=$(printf "%${filled}s" | tr ' ' '#')
  emptstr=$(printf "%${empty}s"  | tr ' ' '-')

  printf "\r%s[%s%s] %3d%%%s %s%s%s" \
    "$CIANO" "$fillstr" "$emptstr" "$percent" "$NC" \
    "$AMARELO" "$msg" "$dots"
}

step_ok() {
  DONE_STEPS=$((DONE_STEPS + 1))
  _progress_line "$1" ""
  printf " %s✓%s\n" "$VERDE" "$NC"
}

step_fail() {
  printf "\n%sFalhou:%s %s\n" "$VERMELHO" "$NC" "$1"
  printf "%sVerifique o log:%s %s\n" "$AMARELO" "$NC" "$LOG_FILE"
  return 1
}

step_skip() {
  DONE_STEPS=$((DONE_STEPS + 1))
  _progress_line "$1" " (pular)"
  printf " %s✓%s\n" "$VERDE" "$NC"
}

task() {
  local msg="$1"
  local cmd="$2"

  # Executa o comando em background, registra tudo no log
  bash -c "set -o pipefail; $cmd" >>"$LOG_FILE" 2>&1 &
  local pid=$!

  local i=0 dots=""
  while kill -0 "$pid" 2>/dev/null; do
    case $i in
      0) dots="   " ;;
      1) dots=".  " ;;
      2) dots=".. " ;;
      3) dots="..." ;;
    esac
    _progress_line "$msg" " $dots"
    i=$(( (i + 1) % 4 ))
    sleep 0.35
  done

  wait "$pid"
  local rc=$?
  if [ $rc -ne 0 ]; then
    step_fail "$msg"
    return $rc
  fi

  step_ok "$msg"
  return 0
}

# ----------- Auxiliares -----------
need_sudo() {
  if [ "$(id -u)" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
      printf "%sErro:%s sudo não encontrado. Execute como root.\n" "$VERMELHO" "$NC"
      exit 1
    fi
  fi
}

confirm_reinstall_dir() {
  local dir="$1"
  local label="$2"

  if [ -d "$dir" ]; then
    printf "%s%s já instalado.%s\n" "$AMARELO" "$label" "$NC"
    printf "%sRemover %s e instalar do zero? (s/N): %s" "$CIANO" "$dir" "$NC"
    read -r ans
    if [[ ! "$ans" =~ ^[Ss]$ ]]; then
      printf "%sCancelado.%s\n" "$VERMELHO" "$NC"
      return 1
    fi
    rm -rf "$dir"
  fi
  return 0
}

ensure_node_and_npm_latest() {
  # Node.js (apenas se ausente)
  if command -v node >/dev/null 2>&1; then
    step_skip "Node.js já instalado"
  else
    task "Instalar Node.js (NodeSource LTS)" "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs"
  fi

  # npm mais recente
  if command -v npm >/dev/null 2>&1; then
    task "Atualizar npm para a versão mais recente" "sudo npm i -g npm@latest"
  else
    task "Instalar npm" "sudo apt-get install -y npm"
    task "Atualizar npm para a versão mais recente" "sudo npm i -g npm@latest"
  fi
}

ensure_pm2() {
  if command -v pm2 >/dev/null 2>&1; then
    step_skip "PM2 já instalado"
  else
    task "Instalar PM2" "sudo npm i -g pm2"
  fi
}

clone_to_dir() {
  local repo="$1"
  local finaldir="$2"

  confirm_reinstall_dir "$finaldir" "$finaldir" || return 1

  local tmpbase
  tmpbase="$(mktemp -d -t airlink.XXXXXX)"
  task "Clonar repositório $finaldir" "git clone --quiet $repo $tmpbase/src"
  task "Mover para $finaldir" "mv $tmpbase/src $finaldir && rm -rf $tmpbase"
}

# ----------- Ações -----------
install_panel() {
  logo
  printf "%sInstalação do Painel selecionada.%s\n\n" "$VERDE" "$NC"

  progress_init 12
  task "Atualizar APT" "sudo apt-get update -qq"
  task "Instalar dependências" "sudo apt-get install -y curl git gnupg ca-certificates"
  ensure_node_and_npm_latest
  clone_to_dir "https://github.com/JishnuTheGamer/Air-link-panel.git" "panel" || return 0

  task "npm i (painel)" "cd panel && npm i"
  task "Criar .env (sem sobrescrever)" "cd panel && cp -n example.env .env"
  task "Migrar Prisma" "cd panel && npm run migrate:dev"
  task "Compilar" "cd panel && npm run build"
  task "Semear banco" "cd panel && npm run seed"
  ensure_pm2
  task "Iniciar painel com PM2" "cd panel && pm2 start dist/app.js --name panel"
  task "Salvar PM2" "pm2 save"
  printf "\n%sPainel em execução:%s pm2 logs panel\n" "$VERDE" "$NC"
}

install_daemon() {
  logo
  printf "%sInstalação do Daemon selecionada.%s\n\n" "$VERDE" "$NC"

  progress_init 13
  task "Atualizar APT" "sudo apt-get update -qq"
  task "Instalar dependências" "sudo apt-get install -y curl git ca-certificates"
  ensure_node_and_npm_latest
  clone_to_dir "https://github.com/AirlinkLabs/daemon.git" "daemon" || return 0

  task "Instalar TypeScript (global)" "sudo npm i -g typescript --silent"
  task "npm i (daemon)" "cd daemon && npm i --silent"
  task "npm i (daemon/libs)" "cd daemon/libs && npm i --silent"
  task "Criar .env (sem sobrescrever)" "cd daemon && [ -f .env ] || cp example.env .env"
  task "Compilar daemon" "cd daemon && npm run --silent build"

  # Configurar (interativo, ainda logado)
  DONE_STEPS=$((DONE_STEPS + 1))
  _progress_line "Configurar daemon (cole o comando)" ""
  printf "\n%sExemplo:%s npm run configure -- --panel \"http://localhost:3000\" --key \"**********\"\n" "$AZUL" "$NC"
  while true; do
    printf "%sCole o configure → %s" "$CIANO" "$NC"
    read -r nodecmd
    if [[ $nodecmd =~ ^[[:space:]]*npm[[:space:]]+run[[:space:]]+configure ]] \
       && [[ $nodecmd == *"--panel"* ]] \
       && [[ $nodecmd == *"--key"* ]]; then
      bash -c "cd daemon && $nodecmd" >>"$LOG_FILE" 2>&1 || { step_fail "Configurar daemon"; return 1; }
      step_ok "Configurar daemon"
      break
    else
      printf "%sFormato incorreto. Necessário --panel e --key.%s\n" "$VERMELHO" "$NC"
    fi
  done

  ensure_pm2
  task "Iniciar daemon com PM2" "cd daemon && pm2 start npm --name daemon -- start"
  task "Salvar PM2" "pm2 save"
  printf "\n%sDaemon em execução:%s pm2 logs daemon\n" "$VERDE" "$NC"
}

start_all() {
  logo
  printf "%sIniciando painel + daemon com PM2...%s\n\n" "$VERDE" "$NC"

  progress_init 3
  ensure_pm2
  task "Reiniciar painel com PM2" "pm2 restart panel || pm2 start panel/dist/app.js --name panel"
  task "Reiniciar daemon com PM2" "pm2 restart daemon || (cd daemon && pm2 start npm --name daemon -- start)"
  task "Salvar PM2" "pm2 save"
  printf "\n%sConcluído.%s\n" "$VERDE" "$NC"
}

install_cloudflared() {
  logo
  printf "%sInstalação do Cloudflared selecionada.%s\n\n" "$VERDE" "$NC"

  progress_init 5
  task "Atualizar APT" "sudo apt-get update -qq"
  task "Instalar curl + gnupg" "sudo apt-get install -y curl gnupg ca-certificates"
  task "Adicionar chave Cloudflare" "sudo mkdir -p /usr/share/keyrings && curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null"
  task "Adicionar repositório Cloudflared" "echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list >/dev/null"
  task "Instalar cloudflared" "sudo apt-get update -qq && sudo apt-get install -y cloudflared"
  printf "\n%sCloudflared instalado.%s\n" "$VERDE" "$NC"
}

install_playit() {
  logo
  printf "%sInstalação do túnel Playit selecionada.%s\n\n" "$VERDE" "$NC"

  # Executa diretamente (sem barra de progresso), para mostrar prompts/saída normalmente.
  bash <(curl -fsSL https://raw.githubusercontent.com/JishnuTheGamer/Vps/refs/heads/main/playit-2)

  pause
}

# ----------- Menu Principal -----------
main_menu() {
  need_sudo

  while true; do
    logo
    printf "%s1%s) %sInstalar Painel Airlink%s\n" "$VERDE" "$NC" "$AMARELO" "$NC"
    printf "%s2%s) %sInstalar Node (Daemon)%s\n" "$VERDE" "$NC" "$AMARELO" "$NC"
    printf "%s3%s) %sIniciar Painel + Node%s\n" "$VERDE" "$NC" "$AMARELO" "$NC"
    printf "%s4%s) %sInstalar Cloudflared%s\n" "$VERDE" "$NC" "$AMARELO" "$NC"
    printf "%s5%s) %sTúnel Playit%s\n" "$VERDE" "$NC" "$AMARELO" "$NC"
    printf "%s6%s) %sSair%s\n" "$VERMELHO" "$NC" "$VERMELHO" "$NC"

    printf "\n%sEscolha [1-6]: %s" "$CIANO" "$NC"
    read -r opt

    case "$opt" in
      1) install_panel; pause ;;
      2) install_daemon; pause ;;
      3) start_all; pause ;;
      4) install_cloudflared; pause ;;
      5) install_playit; pause ;;
      6) exit 0 ;;
      *) printf "%sOpção inválida.%s\n" "$VERMELHO" "$NC"; sleep 1 ;;
    esac
  done
}

main_menu