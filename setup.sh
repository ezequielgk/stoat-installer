#!/bin/bash

# ==========================================
# Configuración
# ==========================================
APP_NAME="Stoat"
REPO="stoatchat/for-desktop"
INSTALL_DIR="$HOME/.local/share/$APP_NAME"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"
BIN_SYMLINK="$HOME/.local/bin/${APP_NAME,,}" # Minúscula: "stoat"

# Configuración del ícono
ICON_URL="https://raw.githubusercontent.com/ezequielgk/stoat-installer/main/stoat-logo.png"
ICON_DIR="$HOME/.local/share/icons"
ICON_PATH="$ICON_DIR/${APP_NAME,,}.png"

# ==========================================
# Funciones auxiliares
# ==========================================

get_latest_url() {
    curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
    grep "browser_download_url" | \
    grep "Stoat-linux-x64-.*\.zip" | \
    cut -d '"' -f 4
}

# ==========================================
# Lógica Principal
# ==========================================

function install_app() {
    echo ""
    echo "[*] Buscando la última versión de $APP_NAME en GitHub..."
    ZIP_URL=$(get_latest_url)

    if [ -z "$ZIP_URL" ]; then
        echo "[!] Error: No se pudo obtener el enlace de descarga."
        exit 1
    fi

    VERSION=$(echo "$ZIP_URL" | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    echo "[+] Última versión encontrada: v$VERSION"

    echo "[*] Preparando instalación..."
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$ICON_DIR"
    
    # Carpeta temporal para extraer el ZIP
    TMP_EXTRACT_DIR="/tmp/${APP_NAME}_extracted"
    mkdir -p "$TMP_EXTRACT_DIR"

    echo "[*] Descargando $APP_NAME v$VERSION..."
    curl -L "$ZIP_URL" -o "/tmp/${APP_NAME}.zip"

    echo "[*] Descargando ícono..."
    curl -L "$ICON_URL" -o "$ICON_PATH"

    echo "[*] Descomprimiendo..."
    unzip -q -o "/tmp/${APP_NAME}.zip" -d "$TMP_EXTRACT_DIR"
    rm "/tmp/${APP_NAME}.zip"

    echo "[*] Instalando en $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"

    # Mover la carpeta extraída a su destino final
    if [ -d "$TMP_EXTRACT_DIR/Stoat-linux-x64" ]; then
        mv "$TMP_EXTRACT_DIR/Stoat-linux-x64" "$INSTALL_DIR"
    else
        echo "[!] Advertencia: Estructura del ZIP distinta a la esperada. Moviendo el contenido general..."
        mkdir -p "$INSTALL_DIR"
        mv "$TMP_EXTRACT_DIR"/* "$INSTALL_DIR/" 2>/dev/null
    fi
    
    rm -rf "$TMP_EXTRACT_DIR"

    # Definir el binario exacto
    BINARY_PATH="$INSTALL_DIR/stoat-desktop"

    if [ ! -f "$BINARY_PATH" ]; then
        echo "[!] Error: No se encontró el binario 'stoat-desktop' en $INSTALL_DIR."
        rm -rf "$INSTALL_DIR"
        exit 1
    fi

    chmod +x "$BINARY_PATH"
    echo "[+] Binario listo en: $BINARY_PATH"

    ln -sf "$BINARY_PATH" "$BIN_SYMLINK"

    echo "[*] Creando acceso directo en el menú de aplicaciones..."
    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=$APP_NAME
Exec="$BINARY_PATH"
Icon=$ICON_PATH
Type=Application
Terminal=false
Categories=Network;Chat;Utility;
EOF

    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null
    
    # Preguntar al usuario por el acceso directo en el escritorio
    echo ""
    read -p "¿Querés crear un acceso directo también en tu escritorio? (s/N): " CREAR_ACCESO
    if [[ "$CREAR_ACCESO" =~ ^[sS]$ ]]; then
        USER_DESKTOP=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Escritorio")
        
        if [ ! -d "$USER_DESKTOP" ] && [ -d "$HOME/Desktop" ]; then
            USER_DESKTOP="$HOME/Desktop"
        fi

        if [ -d "$USER_DESKTOP" ]; then
            cp "$DESKTOP_FILE" "$USER_DESKTOP/"
            chmod +x "$USER_DESKTOP/$(basename "$DESKTOP_FILE")"
            echo "[+] Acceso directo creado en: $USER_DESKTOP"
        else
            echo "[!] Advertencia: No se encontró la carpeta del escritorio."
        fi
    fi

    echo ""
    echo "[+] $APP_NAME v$VERSION se instaló correctamente."
}

function uninstall_app() {
    echo ""
    echo "[-] Desinstalando $APP_NAME..."
    
    rm -rf "$INSTALL_DIR"
    rm -f "$DESKTOP_FILE"
    rm -f "$BIN_SYMLINK"
    rm -f "$ICON_PATH"

    USER_DESKTOP=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Escritorio")
    rm -f "$USER_DESKTOP/$(basename "$DESKTOP_FILE")"
    rm -f "$HOME/Desktop/$(basename "$DESKTOP_FILE")"
    
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null
    
    echo "[+] $APP_NAME y su ícono fueron eliminados del sistema."
}

function update_app() {
    echo ""
    echo "[*] Actualizando $APP_NAME a la última versión disponible..."
    install_app
}

# ==========================================
# Menú Interactivo
# ==========================================
function show_menu() {
    clear
    # Usamos "EOF" entre comillas para que Bash no intente interpretar las barras invertidas
    cat << "EOF"
 ________  _________  ________  ________  _________    ________  ___  ___  ________  _________   
|\   ____\|\___   ___\\   __  \|\   __  \|\___   ___\ |\   ____\|\  \|\  \|\   __  \|\___   ___\ 
\ \  \___|\|___ \  \_\ \  \|\  \ \  \|\  \|___ \  \_| \ \  \___|\ \  \\\  \ \  \|\  \|___ \  \_| 
 \ \_____  \   \ \  \ \ \  \\\  \ \   __  \   \ \  \   \ \  \    \ \   __  \ \   __  \   \ \  \  
  \|____|\  \   \ \  \ \ \  \\\  \ \  \ \  \   \ \  \ __\ \  \____\ \  \ \  \ \  \ \  \   \ \  \ 
    ____\_\  \   \ \__\ \ \_______\ \__\ \__\   \ \__\\__\ \_______\ \__\ \__\ \__\ \__\   \ \__\
   |\_________\   \|__|  \|_______|\|__|\|__|    \|__\|__|\|_______|\|__|\|__|\|__|\|__|    \|__|
   \|_________|                                                                                  
EOF
    echo ""
    echo "  1) Instalar la aplicación"
    echo "  2) Actualizar a la última versión"
    echo "  3) Desinstalar"
    echo "  4) Salir"
    echo ""
    read -p "  > Seleccioná una opción [1-4]: " OPCION

    case $OPCION in
        1)
            install_app
            ;;
        2)
            update_app
            ;;
        3)
            uninstall_app
            ;;
        4)
            echo "¡Nos vemos!"
            exit 0
            ;;
        *)
            echo "[!] Opción no válida. Por favor, ingresá un número del 1 al 4."
            sleep 2
            show_menu
            ;;
    esac
}

# Iniciar el menú
show_menu
