#!/bin/bash


clear
echo -e "\e[36m================================================\e[0m"
echo -e "\e[32m[+] Instalando RX8 Cloud en el dispositivo...\e[0m"
echo -e "\e[36m================================================\e[0m"
echo ""


if ! command -v syncthing &> /dev/null; then
    echo -e "\e[33m[!] Instalando Syncthing y dependencias...\e[0m"
    pkg update -y && pkg install syncthing -y
fi


if [ ! -f "$HOME/.config/syncthing/cert.pem" ] && [ ! -f "$HOME/.local/state/syncthing/cert.pem" ]; then
    echo -e "\e[33m[!] Generando claves de seguridad iniciales RX8...\e[0m"
    syncthing --no-browser > /dev/null 2>&1 &
    SYN_PID=$!
    sleep 4
    kill $SYN_PID > /dev/null 2>&1
fi


cat << 'SCRIPT_EOF' > $PREFIX/bin/nube
#!/bin/bash

show_logo() {
    clear
    echo -e "\e[31m"
    echo "  ██████╗ ██╗  ██╗ █████╗ "
    echo "  ██╔══██╗██║  ██║██╔══██╗"
    echo "  ██████╔╝███████║╚█████╔╝"
    echo "  ██╔══██╗╚════██║██╔══██╗"
    echo "  ██║  ██║     ██║╚█████╔╝"
    echo "  ╚═╝  ╚═╝     ╚═╝ ╚════╝ "
    echo -e "\e[0m"
    echo -e "\e[36m   [ RX8 CLOUD - AUTOMATIC SYSTEM ]\e[0m"
    echo "------------------------------------------------"
}

get_my_id() {
    show_logo
    echo -e "\e[32m[+] Tu Token / ID de Dispositivo RX8:\e[0m"
    echo ""
    
    # Intentar obtener el ID sin arrojar errores de consola
    DEVICE_ID=$(syncthing device-id 2>/dev/null || syncthing --device-id 2>/dev/null)
    
    if [ -n "$DEVICE_ID" ]; then
        echo -e "\e[1;33m$DEVICE_ID\e[0m"
    else
        echo -e "\e[33m[!] Generando configuración inicial... por favor ejecuta primero la Opción 4 para iniciar el servicio.\e[0m"
    fi
    
    echo ""
    read -p "Presiona ENTER para volver al menú..."
}

connect_device() {
    show_logo
    echo -e "\e[32m[+] Vincular dispositivo remoto (Termux / PC)\e[0m"
    echo ""
    read -p "Introduce el Token ID remoto: " REMOTE_ID
    read -p "Nombre para el dispositivo: " DEV_NAME
    if [ -n "$REMOTE_ID" ]; then
        syncthing cli config devices add --device-id "$REMOTE_ID" --name "$DEV_NAME"
        echo -e "\e[32m[✓] Dispositivo guardado exitosamente.\e[0m"
    fi
    read -p "Presiona ENTER para volver al menú..."
}

start_sync() {
    show_logo
    if pgrep -x "syncthing" > /dev/null; then
        echo -e "\e[33m[!] El servicio ya está activo.\e[0m"
    else
        echo -e "\e[32m[+] Iniciando servicio Nube RX8...\e[0m"
        syncthing --gui-address="127.0.0.1:8384" --no-browser > /dev/null 2>&1 &
        echo -e "\e[33m[i] Esperando a que el servidor web responda (3 seg)...\e[0m"
        sleep 3
        echo -e "\e[32m[✓] Servicio iniciado con éxito.\e[0m"
    fi
    echo ""
    echo -e "\e[36m[i] Abre esta dirección en tu navegador si deseas gestionar archivos:\e[0m"
    echo -e "\e[33m    http://127.0.0.1:8384\e[0m"
    echo ""
    read -p "Presiona ENTER para volver al menú..."
}

stop_sync() {
    show_logo
    pkill syncthing
    echo -e "\e[31m[✓] Servicio Nube RX8 detenido.\e[0m"
    echo ""
    read -p "Presiona ENTER para volver al menú..."
}

while true; do
    show_logo
    echo "1. Ver fecha y hora actual de la terminal"
    echo "2. Ver mi Token / ID de dispositivo RX8"
    echo "3. Vincular con otro dispositivo (Termux / PC)"
    echo "4. Iniciar servicio de Nube"
    echo "5. Detener servicio de Nube"
    echo "6. Salir"
    echo "------------------------------------------------"
    read -p "Selecciona una opción [1-6]: " OPTION
    case $OPTION in
        1) show_logo; date; read -p "Presiona ENTER para volver..." ;;
        2) get_my_id ;;
        3) connect_device ;;
        4) start_sync ;;
        5) stop_sync ;;
        6) exit 0 ;;
        *) sleep 1 ;;
    esac
done
SCRIPT_EOF


chmod +x $PREFIX/bin/nube
chmod 755 $PREFIX/bin/nube
hash -r 2>/dev/null

echo ""
echo -e "\e[32m[✓] ¡INSTALACIÓN COMPLETADA EXITOSAMENTE!\e[0m"
echo -e "\e[36m================================================\e[0m"
echo -e "\e[33m Escribe el comando: \e[1;37mnube\e[0m\e[33m para iniciar el menú.\e[0m"
echo -e "\e[36m================================================\e[0m"
echo ""
