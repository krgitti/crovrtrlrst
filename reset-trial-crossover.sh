#!/usr/bin/env bash

# ============================================
# CrossOver Trial Reset - Linux (v3.1)
# Versão Avançada com Detecção Completa
# ============================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# FUNÇÕES DE UTILITÁRIO
# ============================================

print_header() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   CrossOver Trial Reset - Linux v3.1 (Avançado)      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# ============================================
# FUNÇÃO PARA GERAR DATA
# ============================================

generate_date() {
    # Tentar diferentes métodos para gerar data passada
    local new_date=""
    
    # Método 1: GNU date (Linux)
    new_date=$(date -u -d "30 days ago" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null) || true
    
    # Método 2: BSD date (macOS/BSD)
    if [ -z "${new_date}" ]; then
        new_date=$(date -u -v-30d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null) || true
    fi
    
    # Método 3: Data atual menos 30 dias manualmente
    if [ -z "${new_date}" ]; then
        local current_epoch=$(date +%s)
        local thirty_days_ago=$((current_epoch - 2592000)) # 30 dias em segundos
        new_date=$(date -u -d "@${thirty_days_ago}" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null) || true
    fi
    
    # Método 4: Apenas usar data atual (fallback)
    if [ -z "${new_date}" ]; then
        new_date=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    fi
    
    echo "${new_date}"
}

# ============================================
# DETECÇÃO DE INSTALAÇÃO
# ============================================

find_crossover_installation() {
    print_info "Buscando instalação do CrossOver..."
    
    # Locais possíveis
    local search_paths=(
        "/opt/cxoffice"
        "$HOME/.cxoffice"
        "$HOME/cxoffice"
        "$HOME/.local/share/crossover"
        "/usr/local/cxoffice"
    )
    
    for path in "${search_paths[@]}"; do
        if [ -d "${path}" ]; then
            if [ -f "${path}/bin/crossover" ] || [ -f "${path}/bin/cxoffice" ]; then
                print_success "CrossOver encontrado: ${path}"
                echo "${path}"
                return 0
            fi
        fi
    done
    
    # Buscar via which
    local which_result=$(which crossover 2>/dev/null || which cxoffice 2>/dev/null)
    if [ -n "${which_result}" ]; then
        local install_dir=$(dirname $(dirname "${which_result}"))
        print_success "CrossOver encontrado: ${install_dir}"
        echo "${install_dir}"
        return 0
    fi
    
    print_error "CrossOver não encontrado automaticamente"
    return 1
}

# ============================================
# MATAR PROCESSOS
# ============================================

kill_all_crossover() {
    print_info "Finalizando todos os processos do CrossOver..."
    
    # Lista de processos relacionados
    local processes=("crossover" "cxoffice" "CXMenuAgent" "wineserver" "wine")
    local killed=0
    
    for proc in "${processes[@]}"; do
        local pids=$(pgrep -i "${proc}" 2>/dev/null || true)
        if [ -n "${pids}" ]; then
            print_warning "Matando processo: ${proc} (PIDs: ${pids})"
            kill -9 ${pids} 2>/dev/null || true
            ((killed++))
        fi
    done
    
    if [ ${killed} -gt 0 ]; then
        sleep 3
        print_success "Processos finalizados: ${killed}"
    else
        print_success "Nenhum processo em execução"
    fi
}

# ============================================
# LIMPEZA DE ARQUIVOS DE CONFIGURAÇÃO
# ============================================

clean_config_files() {
    local install_dir="$1"
    print_info "Limpando arquivos de configuração..."
    
    local config_locations=(
        "$HOME/.cxoffice/CrossOver.conf"
        "$HOME/.config/crossover/CrossOver.conf"
        "$HOME/.local/share/crossover/CrossOver.conf"
        "${install_dir}/etc/CrossOver.conf"
        "/opt/cxoffice/etc/CrossOver.conf"
    )
    
    local new_date=$(generate_date)
    print_info "Data a ser configurada: ${new_date}"
    
    local cleaned=0
    for config in "${config_locations[@]}"; do
        if [ -f "${config}" ]; then
            print_info "Processando: ${config}"
            
            # Backup
            cp "${config}" "${config}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
            
            # Remover chaves de trial
            sed -i '/^FirstRunDate=/d' "${config}" 2>/dev/null || true
            sed -i '/^TrialEndDate=/d' "${config}" 2>/dev/null || true
            sed -i '/^SULastCheckTime=/d' "${config}" 2>/dev/null || true
            sed -i '/^TrialStart=/d' "${config}" 2>/dev/null || true
            sed -i '/^TrialDaysRemaining=/d' "${config}" 2>/dev/null || true
            sed -i '/^ProductRegistered=/d' "${config}" 2>/dev/null || true
            
            # Adicionar nova data
            echo "FirstRunDate=${new_date}" >> "${config}"
            echo "SULastCheckTime=${new_date}" >> "${config}"
            
            print_success "Configuração limpa: $(basename ${config})"
            ((cleaned++))
        fi
    done
    
    if [ ${cleaned} -eq 0 ]; then
        print_warning "Nenhum arquivo de configuração encontrado - criando novo"
        mkdir -p "$HOME/.cxoffice" 2>/dev/null || true
        cat > "$HOME/.cxoffice/CrossOver.conf" << EOF
[General]
FirstRunDate=${new_date}
SULastCheckTime=${new_date}
EOF
        print_success "Nova configuração criada"
    fi
}

# ============================================
# LIMPEZA DE BOTTLES
# ============================================

clean_bottles() {
    local install_dir="$1"
    print_info "Buscando e limpando bottles..."
    
    local bottle_dirs=(
        "$HOME/.cxoffice/Bottles"
        "$HOME/.cxoffice"
        "$HOME/.local/share/crossover/Bottles"
        "${install_dir}/Bottles"
    )
    
    local bottles_found=0
    
    for bottle_dir in "${bottle_dirs[@]}"; do
        if [ ! -d "${bottle_dir}" ]; then
            continue
        fi
        
        # Encontrar bottles válidos
        while IFS= read -r bottle; do
            if [ -d "${bottle}/drive_c" ] && [ -f "${bottle}/system.reg" ]; then
                local bottle_name=$(basename "${bottle}")
                print_info "Limpando bottle: ${bottle_name}"
                
                # Backup
                [ -f "${bottle}/system.reg" ] && cp "${bottle}/system.reg" "${bottle}/system.reg.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
                [ -f "${bottle}/user.reg" ] && cp "${bottle}/user.reg" "${bottle}/user.reg.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
                
                # Limpar system.reg - MÉTODO MAIS AGRESSIVO
                if [ -f "${bottle}/system.reg" ]; then
                    sed -i '/CodeWeavers/d' "${bottle}/system.reg" 2>/dev/null || true
                    sed -i '/CrossOver/d' "${bottle}/system.reg" 2>/dev/null || true
                    sed -i '/cxoffice/d' "${bottle}/system.reg" 2>/dev/null || true
                    print_success "  system.reg limpo"
                fi
                
                # Limpar user.reg
                if [ -f "${bottle}/user.reg" ]; then
                    sed -i '/CodeWeavers/d' "${bottle}/user.reg" 2>/dev/null || true
                    sed -i '/CrossOver/d' "${bottle}/user.reg" 2>/dev/null || true
                    sed -i '/cxoffice/d' "${bottle}/user.reg" 2>/dev/null || true
                    print_success "  user.reg limpo"
                fi
                
                # Remover arquivos de tracking
                local tracking_files=(
                    ".update-timestamp"
                    ".timestamp"
                    ".tie"
                    ".version"
                    ".cxoffice.installed"
                    ".cxoffice.timestamp"
                )
                
                for tf in "${tracking_files[@]}"; do
                    if [ -f "${bottle}/${tf}" ]; then
                        rm -f "${bottle}/${tf}" 2>/dev/null || true
                        print_success "  Removido: ${tf}"
                    fi
                done
                
                ((bottles_found++))
            fi
        done < <(find "${bottle_dir}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
    done
    
    if [ ${bottles_found} -eq 0 ]; then
        print_warning "Nenhum bottle encontrado"
    else
        print_success "Total de bottles processados: ${bottles_found}"
    fi
}

# ============================================
# LIMPEZA PROFUNDA DE CACHES
# ============================================

clean_caches() {
    print_info "Limpando caches e dados temporários..."
    
    local cache_dirs=(
        "$HOME/.cache/crossover"
        "$HOME/.cache/cxoffice"
        "$HOME/.cache/wine"
        "$HOME/.local/share/crossover/HTTPStorages"
        "$HOME/.local/share/crossover/WebKit"
        "$HOME/.local/share/cxoffice"
    )
    
    local cleaned=0
    for cache_dir in "${cache_dirs[@]}"; do
        if [ -d "${cache_dir}" ] || [ -f "${cache_dir}" ]; then
            rm -rf "${cache_dir}" 2>/dev/null && ((cleaned++)) || true
            print_success "Cache removido: ${cache_dir}"
        fi
    done
    
    # Limpar /tmp com pattern matching
    for pattern in "crossover" "cxoffice"; do
        # Usar nullglob para evitar erro quando não há correspondências
        shopt -s nullglob
        for dir in /tmp/${pattern}* /var/tmp/${pattern}*; do
            if [ -e "${dir}" ]; then
                rm -rf "${dir}" 2>/dev/null || true
                print_success "Temp removido: ${dir}"
                ((cleaned++))
            fi
        done
        shopt -u nullglob
    done
    
    # Limpar logs
    if [ -d "$HOME/.cxoffice/logs" ]; then
        rm -rf "$HOME/.cxoffice/logs"/* 2>/dev/null || true
        print_success "Logs limpos"
        ((cleaned++))
    fi
    
    print_success "Total de caches removidos: ${cleaned}"
}

# ============================================
# LIMPEZA DE DADOS DO SISTEMA
# ============================================

clean_system_data() {
    print_info "Limpando dados do sistema..."
    
    # Limpar locks específicos de forma segura
    local locks_to_remove=(
        "$HOME/.cxoffice/.lock"
        "/tmp/.X0-lock"
        "/tmp/.X1-lock" 
    )
    
    for lock in "${locks_to_remove[@]}"; do
        if [ -e "$lock" ]; then
            rm -f "$lock" 2>/dev/null || true
            print_success "Lock removido: $lock"
        fi
    done
    
    # Limpar locks do cxoffice no /var/lock - VERSÃO SEGURA
    if [ -d "/var/lock" ]; then
        # Método seguro usando find
        find /var/lock -maxdepth 1 -name "cxoffice*" -type f 2>/dev/null | while read -r lock; do
            if [ -e "$lock" ]; then
                sudo rm -f "$lock" 2>/dev/null || rm -f "$lock" 2>/dev/null || true
                print_success "Lock removido: $lock"
            fi
        done
    fi
    
    # Buscar outros locks relacionados no /tmp
    find /tmp -maxdepth 1 -name "*crossover*" -o -name "*cxoffice*" -type f 2>/dev/null | while read -r file; do
        if [ -e "$file" ]; then
            rm -f "$file" 2>/dev/null || true
            print_success "Arquivo temporário removido: $file"
        fi
    done
}

# ============================================
# VERIFICAÇÃO PÓS-LIMPEZA
# ============================================

verify_cleanup() {
    print_info "Verificando limpeza..."
    
    local issues=0
    
    # Verificar se ainda existem referências ao trial
    local config_file="$HOME/.cxoffice/CrossOver.conf"
    if [ -f "${config_file}" ]; then
        if grep -q "TrialEndDate" "${config_file}" 2>/dev/null; then
            print_warning "Ainda existe TrialEndDate no config"
            ((issues++))
        fi
        
        if grep -q "ProductRegistered=1" "${config_file}" 2>/dev/null; then
            print_warning "ProductRegistered ainda está definido"
            ((issues++))
        fi
    fi
    
    # Verificar processos ainda rodando
    if pgrep -x "crossover" > /dev/null 2>&1; then
        print_warning "CrossOver ainda está em execução"
        ((issues++))
    fi
    
    if [ ${issues} -eq 0 ]; then
        print_success "Verificação OK - nenhum problema encontrado"
        return 0
    else
        print_warning "Encontrados ${issues} possíveis problemas"
        return 1
    fi
}

# ============================================
# BLOQUEAR SERVIDOR DE VALIDAÇÃO (OPCIONAL)
# ============================================

block_validation_servers() {
    echo ""
    print_info "Deseja bloquear servidores de validação? (Requer sudo)"
    read -p "Isso impedirá verificações online [s/N]: " block_choice
    
    if [ "${block_choice}" = "s" ] || [ "${block_choice}" = "S" ]; then
        local hosts_file="/etc/hosts"
        local servers=(
            "www.codeweavers.com"
            "codeweavers.com"
            "store.codeweavers.com"
            "api.codeweavers.com"
        )
        
        print_info "Adicionando entradas ao ${hosts_file}..."
        
        for server in "${servers[@]}"; do
            if ! grep -q "${server}" "${hosts_file}" 2>/dev/null; then
                echo "127.0.0.1 ${server}" | sudo tee -a "${hosts_file}" > /dev/null 2>&1 || true
                if [ $? -eq 0 ]; then
                    print_success "Bloqueado: ${server}"
                else
                    print_warning "Falha ao bloquear: ${server} (sem permissão sudo?)"
                fi
            else
                print_info "Já bloqueado: ${server}"
            fi
        done
        
        print_warning "ATENÇÃO: Isso bloqueará atualizações e registro legítimo!"
        print_info "Para reverter, edite ${hosts_file} e remova as linhas adicionadas"
    fi
}

# ============================================
# SCRIPT PRINCIPAL
# ============================================

main() {
    print_header
    
    # Verificar se não é root
    if [ "$EUID" -eq 0 ]; then 
        print_error "NÃO execute este script como root!"
        print_info "Execute como usuário normal: ./script.sh"
        exit 1
    fi
    
    # 1. Encontrar instalação
    INSTALL_DIR=$(find_crossover_installation)
    if [ -z "${INSTALL_DIR}" ]; then
        print_error "CrossOver não encontrado"
        read -p "Digite o caminho de instalação manualmente: " manual_path
        if [ -z "${manual_path}" ] || [ ! -d "${manual_path}" ]; then
            print_error "Caminho inválido!"
            exit 1
        fi
        INSTALL_DIR="${manual_path}"
    fi
    
    echo ""
    print_info "Diretório de instalação: ${INSTALL_DIR}"
    echo ""
    
    # Confirmação
    print_warning "Este script irá:"
    echo "  1. Finalizar todos os processos do CrossOver"
    echo "  2. Limpar arquivos de configuração"
    echo "  3. Limpar todos os bottles"
    echo "  4. Remover caches e dados temporários"
    echo "  5. Redefinir data de primeiro uso"
    echo ""
    read -p "Deseja continuar? [S/n]: " confirm
    
    if [ "${confirm}" = "n" ] || [ "${confirm}" = "N" ]; then
        print_info "Operação cancelada"
        exit 0
    fi
    
    echo ""
    print_info "═══════════════════════════════════════════════"
    print_info "INICIANDO LIMPEZA COMPLETA"
    print_info "═══════════════════════════════════════════════"
    echo ""
    
    # 2. Matar processos
    kill_all_crossover
    echo ""
    
    # 3. Limpar configurações
    clean_config_files "${INSTALL_DIR}"
    echo ""
    
    # 4. Limpar bottles
    clean_bottles "${INSTALL_DIR}"
    echo ""
    
    # 5. Limpar caches
    clean_caches
    echo ""
    
    # 6. Limpar dados do sistema
    clean_system_data
    echo ""
    
    # 7. Verificar limpeza
    verify_cleanup
    echo ""
    
    # 8. Opcional: bloquear servidores
    block_validation_servers
    echo ""
    
    # Resultado final
    print_info "═══════════════════════════════════════════════"
    print_success "LIMPEZA CONCLUÍDA COM SUCESSO!"
    print_info "═══════════════════════════════════════════════"
    echo ""
    
    print_warning "PRÓXIMOS PASSOS IMPORTANTES:"
    echo "  1. REINICIE o computador (CRÍTICO!)"
    echo "  2. Após reiniciar, inicie o CrossOver"
    echo "  3. Se ainda mostrar trial expirado:"
    echo "     - Desinstale completamente o CrossOver"
    echo "     - Execute: sudo rm -rf /opt/cxoffice ~/.cxoffice"
    echo "     - Reinstale o CrossOver"
    echo ""
    
    print_info "Backups criados com timestamp no nome"
    print_info "Para restaurar: encontre arquivos .bak.YYYYMMDD_HHMMSS"
    echo ""
    
    # Opção de reiniciar
    read -p "Deseja reiniciar o computador AGORA? [s/N]: " reboot_choice
    
    if [ "${reboot_choice}" = "s" ] || [ "${reboot_choice}" = "S" ]; then
        print_info "Reiniciando em 5 segundos..."
        sleep 5
        systemctl reboot 2>/dev/null || sudo reboot 2>/dev/null || true
    else
        print_warning "Lembre-se de REINICIAR antes de usar o CrossOver!"
    fi
}

# Executar script principal
main "$@"
