🔐 SFTP User Manager (Linux)

## 🚀 Características

- Crea usuarios SFTP sin acceso a shell (`/usr/sbin/nologin`)
- Configura entorno `chroot` para aislar cada usuario
- Genera claves SSH (tipo `ed25519`) para autenticación segura
- Nombra cada par de llaves según el usuario (`sftp_<usuario>`)
- Personaliza el puerto SSH/SFTP (por defecto 22)
- Modifica automáticamente el archivo `sshd_config`
- Limpia la terminal en cada paso para una mejor experiencia
- Función de desinstalación que elimina el usuario y su configuración
- Backups automáticos de `sshd_config` antes de cada cambio

## 🧰 Requisitos

- Distribución Linux basada en Debian (como Ubuntu)
- Acceso con permisos `sudo`
- `openssh-server` (se instala automáticamente si no está presente)

## 📦 Instalación y uso

1. Concede permisos al script:

chmod +x sftp_manager.sh

2. Ejecuta el script:

./sftp_manager.sh

3. Sigue el menú interactivo:

=== Menú SFTP ===
1) Instalar/Configurar usuario SFTP
2) Desinstalar usuario SFTP
3) Salir

📝 Notas importantes

Cada par de llaves SSH generado se guarda con el nombre sftp_<usuario> en el directorio donde se ejecuta el script.

Esto evita sobrescribir claves al crear múltiples usuarios. No olvides mover o respaldar tus llaves privadas después de la creación.

Si cambias el puerto SSH, asegúrate de actualizar tu firewall y reglas de acceso.

🧹 Desinstalación de usuarios

La opción de desinstalación:

Elimina al usuario y su carpeta

Limpia la configuración en sshd_config

Reinicia el servicio SSH
