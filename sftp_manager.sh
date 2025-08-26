#!/bin/bash

SCRIPT_DIR=$(pwd)

clear_screen() {
    clear
}

# Función de instalación/configuración SFTP
install_sftp() {
    clear_screen
    echo "=== Instalación/Configuración SFTP ==="

    # Verificar e instalar OpenSSH si no está instalado
    if ! dpkg -s openssh-server &>/dev/null; then
        echo "🔧 Instalando OpenSSH..."
        sudo apt update -qq
        sudo apt install -y openssh-server >/dev/null
        sudo systemctl enable ssh >/dev/null
        sudo systemctl start ssh
        echo "✅ OpenSSH instalado."
    else
        echo "✅ OpenSSH ya está instalado."
    fi

    # Solicitar nombre de usuario
    read -p "Nombre de usuario SFTP (minúsculas sin espacios): " SFTP_USER
    SFTP_USER=$(echo "$SFTP_USER" | tr '[:upper:]' '[:lower:]')

    # Puerto personalizado
    read -p "Puerto SSH/SFTP (default 22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}

    # Ruta raíz
    read -p "Ruta raíz del usuario (default /home/$SFTP_USER): " ROOT_DIR
    ROOT_DIR=${ROOT_DIR:-/home/$SFTP_USER}

    clear_screen
    echo "🔧 Creando usuario y carpetas..."

    # Crear usuario sin shell
    sudo adduser --disabled-password --home "$ROOT_DIR" --shell /usr/sbin/nologin "$SFTP_USER" --gecos "" >/dev/null

    # Crear carpetas necesarias
    sudo mkdir -p "$ROOT_DIR/files" "$ROOT_DIR/.ssh"
    sudo chown root:root "$ROOT_DIR"
    sudo chmod 755 "$ROOT_DIR"
    sudo chown "$SFTP_USER:$SFTP_USER" "$ROOT_DIR/files"

    # Preparar .ssh
    sudo touch "$ROOT_DIR/.ssh/authorized_keys"
    sudo chown -R "$SFTP_USER:$SFTP_USER" "$ROOT_DIR/.ssh"
    sudo chmod 700 "$ROOT_DIR/.ssh"
    sudo chmod 600 "$ROOT_DIR/.ssh/authorized_keys"

    # Generar llaves SSH con nombre único por usuario
    KEY_NAME="sftp_$SFTP_USER"
    ssh-keygen -t ed25519 -f "$SCRIPT_DIR/$KEY_NAME" -C "$SFTP_USER" -N "" >/dev/null

    echo "🔐 Llaves generadas:"
    echo "   - Privada: $SCRIPT_DIR/$KEY_NAME"
    echo "   - Pública: $SCRIPT_DIR/${KEY_NAME}.pub"

    # Copiar llave pública al usuario
    sudo cp "$SCRIPT_DIR/${KEY_NAME}.pub" "$ROOT_DIR/.ssh/authorized_keys"
    sudo chown "$SFTP_USER:$SFTP_USER" "$ROOT_DIR/.ssh/authorized_keys"
    sudo chmod 600 "$ROOT_DIR/.ssh/authorized_keys"

    # Configurar SSHD
    SSHD_CONFIG="/etc/ssh/sshd_config"
    sudo cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak"

    {
        echo -e "\n# Configuración SFTP para $SFTP_USER"
        echo "Match User $SFTP_USER"
        echo "    ChrootDirectory $ROOT_DIR"
        echo "    ForceCommand internal-sftp"
        echo "    AllowTcpForwarding no"
        echo "    X11Forwarding no"
    } | sudo tee -a "$SSHD_CONFIG" >/dev/null

    # Cambiar puerto si aplica
    if [ "$SSH_PORT" != "22" ]; then
        sudo sed -i "s/^#Port 22/Port $SSH_PORT/" "$SSHD_CONFIG"
    fi

    sudo systemctl restart ssh

    clear_screen
    echo "✅ Usuario SFTP '$SFTP_USER' creado y configurado."
    echo "📁 Directorio de trabajo: $ROOT_DIR/files"
    echo "🔐 Llaves guardadas como:"
    echo "   - $KEY_NAME"
    echo "   - ${KEY_NAME}.pub"
    echo "📌 Usa la llave privada para conectar desde un cliente SFTP compatible."
}

# Función de desinstalación
uninstall_sftp() {
    clear_screen
    echo "=== Desinstalación de usuario SFTP ==="
    read -p "Nombre del usuario a eliminar: " SFTP_USER
    SFTP_USER=$(echo "$SFTP_USER" | tr '[:upper:]' '[:lower:]')

    ROOT_DIR=$(getent passwd "$SFTP_USER" | cut -d: -f6)
    if [ -z "$ROOT_DIR" ]; then
        echo "⚠️ Usuario '$SFTP_USER' no existe."
        return
    fi

    # Eliminar configuración en sshd_config
    SSHD_CONFIG="/etc/ssh/sshd_config"
    sudo cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak_uninstall"
    sudo sed -i "/# Configuración SFTP para $SFTP_USER/,/^Match User $SFTP_USER/{N;N;N;N;d}" "$SSHD_CONFIG"

    # Eliminar usuario
    sudo deluser --remove-home "$SFTP_USER" >/dev/null
    sudo systemctl restart ssh

    echo "✅ Usuario '$SFTP_USER' eliminado correctamente."
}

# Menú principal
while true; do
    clear_screen
    echo "=== Menú SFTP ==="
    echo "1) Instalar/Configurar usuario SFTP"
    echo "2) Desinstalar usuario SFTP"
    echo "3) Salir"
    read -p "Opción: " OPTION

    case $OPTION in
        1) install_sftp ;;
        2) uninstall_sftp ;;
        3) exit 0 ;;
        *) echo "⚠️ Opción inválida" ; sleep 2 ;;
    esac
done
