# Script de Backup Automático para Base de Datos MultiSIBControl

Un script de **Batch (.bat) para Windows** diseñado para automatizar el proceso de respaldo de las bases de datos de la aplicación **MultiSIBControl**. Realiza una copia de seguridad local, la comprime, la sube a la nube (Google Drive vía `rclone`) y envía notificaciones del estado del proceso a través de **Pushsafer**.

## 🎯 Funcionalidades

- **Copia Inteligente**: Busca y copia solo los archivos de base de datos (`.db3`) desde el directorio de origen.
- **Compresión**: Utiliza **7-Zip** para crear un archivo comprimido `.7z` optimizado, ahorrando espacio en la nube.
- **Subida a la Nube**: Sube el backup a una carpeta específica en **Google Drive** usando `rclone`.
- **Limpieza Automática**: Mantiene solo los **2 backups más recientes** en la nube, eliminando los más antiguos para no consumir espacio infinitamente.
- **Notificaciones en Tiempo Real**: Envía una notificación a tu dispositivo móvil (via Pushsafer) si el backup se completó con éxito o si falló en algún paso.
- **Logging Detallado**: Genera un archivo de log por cada ejecución con fecha y hora, permitiendo un fácil diagnóstico de problemas.

## ⚙️ Requisitos Previos

Antes de ejecutar el script, asegúrate de tener instalado y configurado lo siguiente en el sistema Windows:

1.  **7-Zip**: Debe estar instalado en la ruta por defecto `C:\Program Files\7-Zip\7z.exe`. Si lo tienes en otro lugar, ajusta la ruta en el script.
2.  **rclone**: La herramienta de sincronización con la nube. El ejecutable (`rclone.exe`) debe estar en la ruta especificada en la variable `RCLONE_PATH`. Además, `rclone` debe estar **configurado previamente** con el remoto `backupdb` apuntando a tu Google Drive.
3.  **curl**: Generalmente incluido en Windows 10/11. Si no, necesitarás instalarlo o tener el ejecutable en el PATH.
4.  **Cuenta de Pushsafer**: Necesitas una cuenta y una clave de API (`PUSHKEY`) para recibir notificaciones.

---

### 🔧 Configuración de Rclone (Paso Clave)

Este script depende de una configuración previa de `rclone` para conectar con tu cuenta de Google Drive. Si no lo has hecho, sigue estos pasos:

1.  **Descarga rclone**: Descarga `rclone.exe` para Windows desde [la web oficial de rclone](https://rclone.org/downloads/) y colócalo en una carpeta de tu elección (ej: `C:\utils\rclone`).

2.  **Abre una terminal (CMD o PowerShell)** y navega a la carpeta donde guardaste `rclone.exe`.

3.  **Inicia la configuración** con el comando:
    ```bash
    rclone config
    ```

4.  **Sigue el asistente**:
    -   Te preguntará si quieres crear un nuevo remoto. Escribe `n` y dale Enter.
    -   **Nombre**: Dale un nombre al remoto. **Para este script, debe ser `backupdb`**.
    -   **Tipo de almacenamiento**: Elige `Google Drive` (generalmente es la opción `16`).
    -   **OAuth Client ID**: Deja en blanco y presiona Enter para usar el cliente de rclone.
    -   **Scope**: Elige `1` para "Full access all files, except Application Data Folder".
    -   El resto de opciones (service_account_file, advanced config) déjalas en blanco.
    -   **Use auto config?**: Escribe `y` (sí).

5.  **Autenticación en el navegador**:
    -   Se abrirá una ventana de tu navegador pidiéndote que inicies sesión con tu cuenta de Google y autorices a rclone.
    -   Una vez autorizado, vuelve a la terminal. Verás un mensaje confirmando que el remoto `backupdb` se configuró correctamente.

6.  **Verifica la conexión** (opcional pero recomendado):
    ```bash
    rclone lsd backupdb:
    ```
    Este comando debería listar las carpetas en la raíz de tu Google Drive.

¡Con esto, el script podrá usar el nombre `backupdb` para saber a qué cuenta de Google Drive debe conectarse!

---

## 📋 Configuración del Script

La sección superior del script contiene todas las variables que necesitas ajustar. Modifícalas según tu entorno:

```batch
REM ===== CONFIG =====
set SOURCE=C:\Program Files (x86)\MultiSIBControl
set TEMP=C:\backup_msib_temp
set REMOTE=backupdb:backup_msibc_auto
set RCLONE_PATH=C:\Users\Gea-minipc\Desktop\rclone\rclone.exe
set PUSHKEY=WHVXql3PFwAO9PQt6B1l
set PUSHDEVICE=101626
set LOGDIR=C:\backup_logs