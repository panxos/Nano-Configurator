#!/bin/bash
#=====================================================================
# NanoConfigurator - Advanced Configuration Tool for Nano Editor
# Author: P4nx0z
# GitHub: https://github.com/panxos
# Repository: https://github.com/panxos/Nano-Configurator
# Location: Chile
# License: MIT
# Version: 1.1
#=====================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'
RESET='\033[0m'

# Configuration paths
GLOBAL_CONFIG="/etc/nanorc"
BACKUP_CONFIG="/etc/nanorc.original"
CONFIG_DIR="/etc/nano.d"
MODULES_DIR="/etc/nano.d/modules"

# Language selection (default: English)
LANGUAGE="en"

# String translations
get_string() {
    local key="$1"
    
    if [ "$LANGUAGE" == "es" ]; then
        case "$key" in
            "welcome") echo "Bienvenido a Nano Configurator";;
            "subtitle") echo "Herramienta de configuración avanzada para el editor Nano";;
            "created_by") echo "Creado por";;
            "help_opt") echo "Use --help para ver las opciones";;
            *) echo "$key";;
        esac
    else
        case "$key" in
            "welcome") echo "Welcome to Nano Configurator";;
            "subtitle") echo "Advanced configuration tool for Nano editor";;
            "created_by") echo "Created by";;
            "help_opt") echo "Use --help to see options";;
            *) echo "$key";;
        esac
    fi
}

# Display banner
display_banner() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo ' ███╗   ██╗ █████╗ ███╗   ██╗ ██████╗  ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ '
    echo ' ████╗  ██║██╔══██╗████╗  ██║██╔═══██╗██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ '
    echo ' ██╔██╗ ██║███████║██╔██╗ ██║██║   ██║██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗'
    echo ' ██║╚██╗██║██╔══██║██║╚██╗██║██║   ██║██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║'
    echo ' ██║ ╚████║██║  ██║██║ ╚████║╚██████╔╝╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝'
    echo ' ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ '
    echo -e "${RESET}"
    
    if [ "$LANGUAGE" == "es" ]; then
        echo -e "${GREEN}${BOLD} $(get_string "welcome") ${RESET}"
        echo -e "${CYAN} $(get_string "subtitle") ${RESET}"
        echo -e "${YELLOW} $(get_string "created_by") ${BOLD}P4nx0z${RESET}${YELLOW} | GitHub: ${BOLD}https://github.com/panxos/Nano-Configurator${RESET}"
        echo -e "${CYAN} $(get_string "help_opt") ${RESET}"
    else
        echo -e "${GREEN}${BOLD} $(get_string "welcome") ${RESET}"
        echo -e "${CYAN} $(get_string "subtitle") ${RESET}"
        echo -e "${YELLOW} $(get_string "created_by") ${BOLD}P4nx0z${RESET}${YELLOW} | GitHub: ${BOLD}https://github.com/panxos/Nano-Configurator${RESET}"
        echo -e "${CYAN} $(get_string "help_opt") ${RESET}"
    fi
    echo ""
}

# Check if user is root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        if [ "$LANGUAGE" == "es" ]; then
            echo -e "${RED}Error: Este script debe ejecutarse como root o con sudo.${NC}"
        else
            echo -e "${RED}Error: This script must be run as root or with sudo.${NC}"
        fi
        exit 1
    fi
}

# Check nano version to use appropriate commands
check_nano_version() {
    local nano_version=$(nano --version | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n 1)
    
    # If we can't parse the version, assume it's an old version
    if [ -z "$nano_version" ]; then
        return 1
    fi
    
    local major=$(echo "$nano_version" | cut -d. -f1)
    local minor=$(echo "$nano_version" | cut -d. -f2)
    
    # Verify that major and minor are integers
    if [[ ! "$major" =~ ^[0-9]+$ ]] || [[ ! "$minor" =~ ^[0-9]+$ ]]; then
        # If not valid integers, assume old version
        return 1
    fi
    
    # Full version check
    if [ "$major" -gt 2 ] || ([ "$major" -eq 2 ] && [ "$minor" -ge 9 ]); then
        # Version 2.9.0 or higher (full features)
        return 0
    elif [ "$major" -eq 2 ] && [ "$minor" -ge 7 ]; then
        # Version 2.7.0-2.8.x (line numbers but no toggle function)
        return 2
    else
        # Version below 2.7.0 (no line numbers)
        return 1
    fi
}

# Create backup of original configuration if it doesn't exist
create_backup() {
    if [ ! -f "$BACKUP_CONFIG" ]; then
        if [ -f "$GLOBAL_CONFIG" ]; then
            cp "$GLOBAL_CONFIG" "$BACKUP_CONFIG"
            if [ "$LANGUAGE" == "es" ]; then
                echo -e "${GREEN}✓ Copia de seguridad creada en $BACKUP_CONFIG${NC}"
            else
                echo -e "${GREEN}✓ Backup created at $BACKUP_CONFIG${NC}"
            fi
        else
            touch "$BACKUP_CONFIG"
            if [ "$LANGUAGE" == "es" ]; then
                echo -e "${YELLOW}⚠ Archivo de configuración original no encontrado. Creando uno vacío.${NC}"
            else
                echo -e "${YELLOW}⚠ Original configuration file not found. Creating an empty one.${NC}"
            fi
        fi
    fi
}

# Update main nanorc file to include modular configurations
update_main_config() {
    # Create a temporary file for the new config
    local temp_file=$(mktemp)
    
    # Start with the original backup if it exists
    if [ -f "$BACKUP_CONFIG" ]; then
        cp "$BACKUP_CONFIG" "$temp_file"
    else
        touch "$temp_file"
    fi
    
    # Add a header
    echo "" >> "$temp_file"
    echo "# ===== CONFIGURATION ADDED BY NANOCONFIGURATOR =====" >> "$temp_file"
    echo "# https://github.com/panxos/Nano-Configurator" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Check if we have syntax files in the standard location
    SYNTAX_DIR="/usr/share/nano"
    if [ -d "$SYNTAX_DIR" ]; then
        echo "# Syntax highlighting" >> "$temp_file"
        echo "include \"$SYNTAX_DIR/*.nanorc\"" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Check nano version for feature compatibility
    check_nano_version
    NANO_VERSION=$?
    
    # Add line numbers if supported (version 2.7.0+)
    if [ $NANO_VERSION -eq 0 ] || [ $NANO_VERSION -eq 2 ]; then
        echo "# Line numbers" >> "$temp_file"
        echo "set linenumbers" >> "$temp_file"
        echo "" >> "$temp_file"
        
        # Add number color for better visibility
        echo "# Customize line number appearance" >> "$temp_file"
        echo "set numbercolor brightblack,black" >> "$temp_file"
        echo "" >> "$temp_file"
        
        # Add key bindings for toggling line numbers (version 2.9.0+)
        if [ $NANO_VERSION -eq 0 ]; then
            echo "# Key bindings to toggle line numbers" >> "$temp_file"
            echo "# Alt+# (Alt+Shift+3) toggles line numbers" >> "$temp_file"
            echo "bind M-# toggle_linenumbers main" >> "$temp_file"
            echo "" >> "$temp_file"
        fi
    fi
    
    # Test if nano supports autoindent (safe option)
    if nano --help | grep -q "autoindent"; then
        echo "# Programming features" >> "$temp_file"
        echo "set autoindent" >> "$temp_file"
        echo "set tabsize 4" >> "$temp_file"
        echo "set tabstospaces" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Add editor behavior settings - check each option individually
    echo "# Editor behavior" >> "$temp_file"
    
    # Check for various features and add only supported ones
    if nano --help | grep -q "constantshow"; then
        echo "set constantshow" >> "$temp_file"
    fi
    
    if nano --help | grep -q "showcursor"; then
        echo "set showcursor" >> "$temp_file"
    fi
    
    # These are more version-dependent
    if [ $NANO_VERSION -eq 0 ]; then
        if nano --help | grep -q "regexp"; then
            echo "set regexp" >> "$temp_file"
        fi
        
        if nano --help | grep -q "smooth"; then
            echo "set smooth" >> "$temp_file"
        fi
        
        if nano --help | grep -q "undo"; then
            echo "set undo" >> "$temp_file"
        fi
    fi
    echo "" >> "$temp_file"
    
    # Advanced features - check each one
    echo "# Advanced features" >> "$temp_file"
    if nano --help | grep -q "multibuffer"; then
        echo "set multibuffer" >> "$temp_file"
    fi
    
    #if nano --help | grep -q "mouse"; then
        #Secho "set mouse" >> "$temp_file"
    #fi
    
    if nano --help | grep -q "historylog"; then
        echo "set historylog" >> "$temp_file"
    fi
    
    # Move the temp file to the global config
    mv "$temp_file" "$GLOBAL_CONFIG"
    chmod 644 "$GLOBAL_CONFIG"
    
    if [ "$LANGUAGE" == "es" ]; then
        echo -e "${GREEN}✓ Configuración global actualizada${NC}"
        if [ $NANO_VERSION -eq 0 ]; then
            echo -e "${YELLOW}ℹ Usa Alt+# (Alt+Shift+3) para activar/desactivar números de línea${NC}"
            echo -e "${YELLOW}ℹ Este atajo también es útil para comentar/descomentar líneas en código${NC}"
        elif [ $NANO_VERSION -eq 2 ]; then
            echo -e "${YELLOW}ℹ Tu versión de nano tiene números de línea pero no soporta alternarlos con atajos${NC}"
        fi
    else
        echo -e "${GREEN}✓ Global configuration updated${NC}"
        if [ $NANO_VERSION -eq 0 ]; then
            echo -e "${YELLOW}ℹ Use Alt+# (Alt+Shift+3) to toggle line numbers${NC}"
            echo -e "${YELLOW}ℹ This shortcut is also useful for commenting/uncommenting lines in code${NC}"
        elif [ $NANO_VERSION -eq 2 ]; then
            echo -e "${YELLOW}ℹ Your nano version has line numbers but doesn't support toggling them with shortcuts${NC}"
        fi
    fi
}

# Install the default configuration
install_configuration() {
    create_backup
    update_main_config
    
    if [ "$LANGUAGE" == "es" ]; then
        echo -e "\n${GREEN}✓ Configuración de nano instalada exitosamente para todos los usuarios${NC}"
        echo -e "${YELLOW}ℹ Ejecute 'sudo $0 --reset' para restaurar la configuración original si es necesario${NC}"
        echo -e "${YELLOW}ℹ Reinicie su sesión para ver los cambios${NC}"
    else
        echo -e "\n${GREEN}✓ Nano configuration successfully installed for all users${NC}"
        echo -e "${YELLOW}ℹ Run 'sudo $0 --reset' to restore the original configuration if needed${NC}"
        echo -e "${YELLOW}ℹ Restart your shell session to see the changes${NC}"
    fi
}

# Reset to original configuration
reset_configuration() {
    if [ -f "$BACKUP_CONFIG" ]; then
        cp "$BACKUP_CONFIG" "$GLOBAL_CONFIG"
        chmod 644 "$GLOBAL_CONFIG"
        
        # Also remove all module files
        if [ -d "$CONFIG_DIR" ]; then
            rm -rf "$CONFIG_DIR"
            mkdir -p "$CONFIG_DIR"
        fi
        
        if [ "$LANGUAGE" == "es" ]; then
            echo -e "${GREEN}✓ Configuración original restaurada${NC}"
            echo -e "${YELLOW}ℹ Reinicie su sesión para ver los cambios${NC}"
        else
            echo -e "${GREEN}✓ Original configuration restored${NC}"
            echo -e "${YELLOW}ℹ Restart your shell session to see the changes${NC}"
        fi
    else
        if [ "$LANGUAGE" == "es" ]; then
            echo -e "${RED}✗ No se encontró el archivo de respaldo original${NC}"
        else
            echo -e "${RED}✗ Original backup file not found${NC}"
        fi
    fi
}

# List available modules
list_modules() {
    if [ "$LANGUAGE" == "es" ]; then
        echo -e "${CYAN}Configuración activa:${NC}"
    else
        echo -e "${CYAN}Active configuration:${NC}"
    fi
    
    if [ -f "$GLOBAL_CONFIG" ]; then
        echo -e "${YELLOW}=== $GLOBAL_CONFIG ===${NC}"
        
        # Display active settings
        grep "^set " "$GLOBAL_CONFIG" | while read -r line; do
            setting=$(echo "$line" | cut -d' ' -f2)
            echo -e "${GREEN}[✓]${NC} $setting"
        done
        
        # Display if syntax highlighting is enabled
        if grep -q "include \".*\*.nanorc\"" "$GLOBAL_CONFIG"; then
            if [ "$LANGUAGE" == "es" ]; then
                echo -e "${GREEN}[✓]${NC} Resaltado de sintaxis"
            else
                echo -e "${GREEN}[✓]${NC} Syntax highlighting"
            fi
        else
            if [ "$LANGUAGE" == "es" ]; then
                echo -e "${RED}[✗]${NC} Resaltado de sintaxis"
            else
                echo -e "${RED}[✗]${NC} Syntax highlighting"
            fi
        fi
    else
        if [ "$LANGUAGE" == "es" ]; then
            echo -e "${RED}✗ No se encontró el archivo de configuración${NC}"
        else
            echo -e "${RED}✗ Configuration file not found${NC}"
        fi
    fi
}

# Toggle a specific module
toggle_module() {
    local id="$1"
    local found=0
    
    # Create a temporary file for the new config
    local temp_file=$(mktemp)
    
    # Start with the original backup if it exists
    if [ -f "$BACKUP_CONFIG" ]; then
        cp "$BACKUP_CONFIG" "$temp_file"
    else
        touch "$temp_file"
    fi
    
    # Add the header
    echo "" >> "$temp_file"
    echo "# ===== CONFIGURATION ADDED BY NANOCONFIGURATOR =====" >> "$temp_file"
    echo "# https://github.com/panxos/Nano-Configurator" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Check nano version for feature compatibility
    check_nano_version
    MODERN_NANO=$?
    
    # Add syntax highlighting (this always stays)
    SYNTAX_DIR="/usr/share/nano"
    if [ -d "$SYNTAX_DIR" ]; then
        echo "# Syntax highlighting" >> "$temp_file"
        echo "include \"$SYNTAX_DIR/*.nanorc\"" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Check which feature to toggle
    case "$id" in
        "01"|"1"|"line"|"linenumbers")
            if [ $MODERN_NANO -eq 0 ]; then
                # Check if line numbers are currently enabled
                if grep -q "set linenumbers" "$GLOBAL_CONFIG"; then
                    found=1
                    if [ "$LANGUAGE" == "es" ]; then
                        echo -e "${YELLOW}✓ Números de línea desactivados${NC}"
                    else
                        echo -e "${YELLOW}✓ Line numbers disabled${NC}"
                    fi
                else
                    found=1
                    echo "# Line numbers" >> "$temp_file"
                    echo "set linenumbers" >> "$temp_file"
                    echo "" >> "$temp_file"
                    # Add key bindings for toggling line numbers
                    echo "# Key bindings to toggle line numbers" >> "$temp_file"
                    echo "# Alt+# (Alt+Shift+3) toggles line numbers" >> "$temp_file"
                    echo "bind M-# toggle_linenumbers main" >> "$temp_file"
                    echo "" >> "$temp_file"
                    
                    # Add number color for better visibility
                    echo "# Customize line number appearance" >> "$temp_file"
                    echo "set numbercolor brightblack,black" >> "$temp_file"
                    echo "" >> "$temp_file"
                    if [ "$LANGUAGE" == "es" ]; then
                        echo -e "${GREEN}✓ Números de línea activados${NC}"
                        echo -e "${YELLOW}ℹ Usa Alt+L, F12 o Alt+# para activar/desactivar números de línea${NC}"
                        echo -e "${YELLOW}ℹ También puedes usar Ctrl+G y luego escribir 'toggle_linenumbers'${NC}"
                    else
                        echo -e "${GREEN}✓ Line numbers enabled${NC}"
                        echo -e "${YELLOW}ℹ Use Alt+L, F12 or Alt+# to toggle line numbers${NC}"
                        echo -e "${YELLOW}ℹ You can also use Ctrl+R and then type 'toggle_linenumbers'${NC}"
                    fi
                fi
            else
                if [ "$LANGUAGE" == "es" ]; then
                    echo -e "${RED}✗ Tu versión de nano no soporta números de línea${NC}"
                else
                    echo -e "${RED}✗ Your nano version doesn't support line numbers${NC}"
                fi
                found=1
            fi
            ;;
            
        "02"|"2"|"syntax"|"highlighting")
            # Syntax highlighting is always added above, so just inform the user
            if [ "$LANGUAGE" == "es" ]; then
                echo -e "${GREEN}✓ Resaltado de sintaxis siempre activado${NC}"
            else
                echo -e "${GREEN}✓ Syntax highlighting always enabled${NC}"
            fi
            found=1
            ;;
            
        "03"|"3"|"prog"|"programming")
            # Check if programming features are currently enabled
            if grep -q "set autoindent" "$GLOBAL_CONFIG" && \
               grep -q "set tabsize" "$GLOBAL_CONFIG" && \
               grep -q "set tabstospaces" "$GLOBAL_CONFIG"; then
                found=1
                if [ "$LANGUAGE" == "es" ]; then
                    echo -e "${YELLOW}✓ Características de programación desactivadas${NC}"
                else
                    echo -e "${YELLOW}✓ Programming features disabled${NC}"
                fi
            else
                found=1
                echo "# Programming features" >> "$temp_file"
                echo "set autoindent" >> "$temp_file"
                echo "set tabsize 4" >> "$temp_file"
                echo "set tabstospaces" >> "$temp_file"
                echo "" >> "$temp_file"
                if [ "$LANGUAGE" == "es" ]; then
                    echo -e "${GREEN}✓ Características de programación activadas${NC}"
                else
                    echo -e "${GREEN}✓ Programming features enabled${NC}"
                fi
            fi
            ;;
            
        "04"|"4"|"behavior"|"editor")
            # Check if editor behavior settings are currently enabled
            if grep -q "set smooth" "$GLOBAL_CONFIG" && \
               grep -q "set undo" "$GLOBAL_CONFIG" && \
               grep -q "set constantshow" "$GLOBAL_CONFIG"; then
                found=1
                if [ "$LANGUAGE" == "es" ]; then
                    echo -e "${YELLOW}✓ Comportamiento del editor desactivado${NC}"
                else
                    echo -e "${YELLOW}✓ Editor behavior disabled${NC}"
                fi
            else
                found=1
                echo "# Editor behavior" >> "$temp_file"
                echo "set smooth" >> "$temp_file"
                if [ $MODERN_NANO -eq 0 ]; then
                    echo "set regexp" >> "$temp_file"
                fi
                echo "set undo" >> "$temp_file"
                echo "set constantshow" >> "$temp_file"
                echo "set showcursor" >> "$temp_file"
                echo "" >> "$temp_file"
                if [ "$LANGUAGE" == "es" ]; then
                    echo -e "${GREEN}✓ Comportamiento del editor activado${NC}"
                else
                    echo -e "${GREEN}✓ Editor behavior enabled${NC}"
                fi
            fi
            ;;
            
        "05"|"5"|"advanced"|"features")
            # Check if advanced features are currently enabled
            if grep -q "set multibuffer" "$GLOBAL_CONFIG" && \
               grep -q "set mouse" "$GLOBAL_CONFIG" && \
               grep -q "set historylog" "$GLOBAL_CONFIG"; then
                found=1
                if [ "$LANGUAGE" == "es" ]; then
                    echo -e "${YELLOW}✓ Características avanzadas desactivadas${NC}"
                else
                    echo -e "${YELLOW}✓ Advanced features disabled${NC}"
                fi
            else
                found=1
                echo "# Advanced features" >> "$temp_file"
                echo "set multibuffer" >> "$temp_file"
               # echo "set mouse" >> "$temp_file"
                echo "set historylog" >> "$temp_file"
                echo "" >> "$temp_file"
                if [ "$LANGUAGE" == "es" ]; then
                    echo -e "${GREEN}✓ Características avanzadas activadas${NC}"
                else
                    echo -e "${GREEN}✓ Advanced features enabled${NC}"
                fi
            fi
            ;;
            
        "all"|"everything")
            # Enable all features
            found=1
            
            # Line numbers if supported
            if [ $MODERN_NANO -eq 0 ]; then
                echo "# Line numbers" >> "$temp_file"
                echo "set linenumbers" >> "$temp_file"
                echo "" >> "$temp_file"
                # Add key binding for toggling line numbers
                echo "# Key binding to toggle line numbers using Alt+L" >> "$temp_file"
                echo "bind M-l toggle_linenumbers main" >> "$temp_file"
                echo "" >> "$temp_file"
            fi
            
            # Programming features
            echo "# Programming features" >> "$temp_file"
            echo "set autoindent" >> "$temp_file"
            echo "set tabsize 4" >> "$temp_file"
            echo "set tabstospaces" >> "$temp_file"
            echo "" >> "$temp_file"
            
            # Editor behavior
            echo "# Editor behavior" >> "$temp_file"
            echo "set smooth" >> "$temp_file"
            if [ $MODERN_NANO -eq 0 ]; then
                echo "set regexp" >> "$temp_file"
            fi
            echo "set undo" >> "$temp_file"
            echo "set constantshow" >> "$temp_file"
            echo "set showcursor" >> "$temp_file"
            echo "" >> "$temp_file"
            
            # Advanced features
            echo "# Advanced features" >> "$temp_file"
            echo "set multibuffer" >> "$temp_file"
            echo "set mouse" >> "$temp_file"
            echo "set historylog" >> "$temp_file"
            
            if [ "$LANGUAGE" == "es" ]; then
                echo -e "${GREEN}✓ Todas las características activadas${NC}"
                if [ $MODERN_NANO -eq 0 ]; then
                    echo -e "${YELLOW}ℹ Usa Alt+L, F12 o Alt+# para activar/desactivar números de línea${NC}"
                    echo -e "${YELLOW}ℹ También puedes usar Ctrl+R y luego escribir 'toggle_linenumbers'${NC}"
                fi
            else
                echo -e "${GREEN}✓ All features enabled${NC}"
                if [ $MODERN_NANO -eq 0 ]; then
                    echo -e "${YELLOW}ℹ Use Alt+L, F12 or Alt+# to toggle line numbers${NC}"
                    echo -e "${YELLOW}ℹ You can also use Ctrl+R and then type 'toggle_linenumbers'${NC}"
                fi
            fi
            ;;
            
        "none"|"reset")
            # Disable all features (except syntax highlighting)
            found=1
            if [ "$LANGUAGE" == "es" ]; then
                echo -e "${YELLOW}✓ Todas las características desactivadas excepto resaltado de sintaxis${NC}"
            else
                echo -e "${YELLOW}✓ All features disabled except syntax highlighting${NC}"
            fi
            ;;
            
        *)
            if [ "$LANGUAGE" == "es" ]; then
                echo -e "${RED}✗ Módulo desconocido: '$id'${NC}"
                echo -e "${YELLOW}ℹ Opciones disponibles: 1 o line - números de línea, 2 o syntax - sintaxis, 3 o programming - programación,${NC}"
                echo -e "${YELLOW}  4 o behavior - comportamiento, 5 o advanced - avanzadas, all - todo, none - nada${NC}"
            else
                echo -e "${RED}✗ Unknown module: '$id'${NC}"
                echo -e "${YELLOW}ℹ Available options: 1 or line - line numbers, 2 or syntax - syntax, 3 or programming - programming,${NC}"
                echo -e "${YELLOW}  4 or behavior - behavior, 5 or advanced - advanced, all - everything, none - nothing${NC}"
            fi
            ;;
    esac
    
    if [ "$found" -eq 1 ]; then
        # Copy the temporary config to the real one
        mv "$temp_file" "$GLOBAL_CONFIG"
        chmod 644 "$GLOBAL_CONFIG"
        
        # Tell the user to restart
        if [ "$LANGUAGE" == "es" ]; then
            echo -e "${YELLOW}ℹ Reinicie su sesión para ver los cambios${NC}"
        else
            echo -e "${YELLOW}ℹ Restart your shell session to see the changes${NC}"
        fi
    else
        # Remove the temporary file
        rm -f "$temp_file"
    fi
}

# Display help in the selected language
display_help() {
    if [ "$LANGUAGE" == "es" ]; then
        echo -e "${YELLOW}Uso: $0 [opciones]${NC}"
        echo ""
        echo "Opciones:"
        echo "  -h, --help          Muestra esta ayuda"
        echo "  -e, --english       Establece el idioma a inglés"
        echo "  -s, --spanish       Establece el idioma a español"
        echo "  -i, --install       Instala la configuración para todos los usuarios"
        echo "  -r, --reset         Restaura la configuración original"
        echo "  -l, --list          Lista la configuración activa"
        echo "  -t, --toggle ID     Activa/desactiva una funcionalidad específica"
        echo ""
        echo "Funcionalidades disponibles para --toggle:"
        echo "  1, line            - Números de línea [Alt+# (Alt+Shift+3) para activar/desactivar]"
        echo "  2, syntax          - Resaltado de sintaxis"
        echo "  3, programming     - Características para programación"
        echo "  4, behavior        - Comportamiento mejorado del editor"
        echo "  5, advanced        - Características avanzadas"
        echo "  all                - Activa todas las características"
        echo "  none               - Desactiva todas excepto resaltado de sintaxis"
        echo ""
        echo "Ejemplo:"
        echo "  sudo $0 --install   # Instala nano-configurator"
        echo "  sudo $0 --toggle 1  # Activa/desactiva números de línea"
        echo "  sudo $0 --reset     # Restaura la configuración original"
    else
        echo -e "${YELLOW}Usage: $0 [options]${NC}"
        echo ""
        echo "Options:"
        echo "  -h, --help          Display this help"
        echo "  -e, --english       Set language to English"
        echo "  -s, --spanish       Set language to Spanish"
        echo "  -i, --install       Install configuration for all users"
        echo "  -r, --reset         Reset to original configuration"
        echo "  -l, --list          List active configuration"
        echo "  -t, --toggle ID     Toggle a specific feature"
        echo ""
        echo "Available features for --toggle:"
        echo "  1, line            - Line numbers [Alt+# (Alt+Shift+3) to toggle]"
        echo "  2, syntax          - Syntax highlighting"
        echo "  3, programming     - Programming features"
        echo "  4, behavior        - Improved editor behavior"
        echo "  5, advanced        - Advanced features"
        echo "  all                - Enable all features"
        echo "  none               - Disable all except syntax highlighting"
        echo ""
        echo "Example:"
        echo "  sudo $0 --install   # Install nano-configurator"
        echo "  sudo $0 --toggle 1  # Toggle line numbers"
        echo "  sudo $0 --reset     # Reset to original configuration"
    fi
}

# Display interactive menu
interactive_menu() {
    while true; do
        display_banner
        
        if [ "$LANGUAGE" == "es" ]; then
            echo -e "${CYAN}MENÚ PRINCIPAL${NC}"
            echo -e "${YELLOW}1.${NC} Instalar nano-configurator"
            echo -e "${YELLOW}2.${NC} Restaurar configuración original"
            echo -e "${YELLOW}3.${NC} Listar configuración activa"
            echo -e "${YELLOW}4.${NC} Activar/desactivar funcionalidad"
            echo -e "${YELLOW}5.${NC} Cambiar a inglés"
            echo -e "${YELLOW}0.${NC} Salir"
            echo ""
            echo -n -e "${CYAN}Seleccione una opción:${NC} "
        else
            echo -e "${CYAN}MAIN MENU${NC}"
            echo -e "${YELLOW}1.${NC} Install nano-configurator"
            echo -e "${YELLOW}2.${NC} Reset to original configuration"
            echo -e "${YELLOW}3.${NC} List active configuration"
            echo -e "${YELLOW}4.${NC} Toggle feature"
            echo -e "${YELLOW}5.${NC} Switch to Spanish"
            echo -e "${YELLOW}0.${NC} Exit"
            echo ""
            echo -n -e "${CYAN}Select an option:${NC} "
        fi
        
        read choice
        
        case $choice in
            1)
                install_configuration
                read -p "Press Enter to continue..."
                ;;
            2)
                reset_configuration
                read -p "Press Enter to continue..."
                ;;
            3)
                list_modules
                read -p "Press Enter to continue..."
                ;;
            4)
                if [ "$LANGUAGE" == "es" ]; then
                    echo -n -e "${CYAN}Ingrese la funcionalidad para activar/desactivar [1-5, all, none]:${NC} "
                else
                    echo -n -e "${CYAN}Enter feature to toggle [1-5, all, none]:${NC} "
                fi
                read module_id
                toggle_module "$module_id"
                read -p "Press Enter to continue..."
                ;;
            5)
                if [ "$LANGUAGE" == "es" ]; then
                    LANGUAGE="en"
                else
                    LANGUAGE="es"
                fi
                ;;
            0)
                if [ "$LANGUAGE" == "es" ]; then
                    echo -e "${GREEN}¡Gracias por usar NanoConfigurator!${NC}"
                else
                    echo -e "${GREEN}Thank you for using NanoConfigurator!${NC}"
                fi
                exit 0
                ;;
            *)
                if [ "$LANGUAGE" == "es" ]; then
                    echo -e "${RED}Opción inválida${NC}"
                else
                    echo -e "${RED}Invalid option${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Main function
main() {
    check_root
    
    # Process command line arguments
    if [ $# -eq 0 ]; then
        interactive_menu
    else
        case "$1" in
            -h|--help)
                display_banner
                display_help
                ;;
            -e|--english)
                LANGUAGE="en"
                shift
                if [ $# -eq 0 ]; then
                    interactive_menu
                else
                    main "$@"
                fi
                ;;
            -s|--spanish)
                LANGUAGE="es"
                shift
                if [ $# -eq 0 ]; then
                    interactive_menu
                else
                    main "$@"
                fi
                ;;
            -i|--install)
                display_banner
                install_configuration
                ;;
            -r|--reset)
                display_banner
                reset_configuration
                ;;
            -l|--list)
                display_banner
                list_modules
                ;;
            -t|--toggle)
                display_banner
                if [ -n "$2" ]; then
                    toggle_module "$2"
                else
                    if [ "$LANGUAGE" == "es" ]; then
                        echo -e "${RED}Error: Se requiere un ID de módulo${NC}"
                    else
                        echo -e "${RED}Error: Module ID required${NC}"
                    fi
                    display_help
                fi
                ;;
            *)
                display_banner
                if [ "$LANGUAGE" == "es" ]; then
                    echo -e "${RED}Opción desconocida: $1${NC}"
                else
                    echo -e "${RED}Unknown option: $1${NC}"
                fi
                display_help
                ;;
        esac
    fi
}

# Start the program
main "$@"
