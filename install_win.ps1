# RX8 Cloud - Windows Auto-Installer

$ErrorActionPreference = "Stop"

Clear-Host
Host.UI.RawUI.ForegroundColor = "Cyan"
Write-Host "================================================"
Write-Host "[+] Instalando RX8 Cloud en Windows..." -ForegroundColor Green
Write-Host "================================================"
Write-Host ""


if (-not (Get-Command syncthing -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Syncthing no está instalado. Instalando vía Winget..." -ForegroundColor Yellow
    try {
        winget install --id Syncthing.Syncthing --exact --accept-source-agreements --accept-package-agreements --silent
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } catch {
        Write-Host "[!] No se pudo instalar Syncthing automáticamente con winget." -ForegroundColor Red
        Write-Host "[i] Por favor instala Syncthing desde https://syncthing.net/downloads/ e inténtalo de nuevo." -ForegroundColor Yellow
        exit
    }
}


$syncthingConfig = Join-Path $env:LOCALAPPDATA "Syncthing"
$certFile = Join-Path $syncthingConfig "cert.pem"

if (-not (Test-Path $certFile)) {
    Write-Host "[!] Generando claves de seguridad iniciales RX8..." -ForegroundColor Yellow
    $process = Start-Process -FilePath "syncthing" -ArgumentList "--no-browser" -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 4
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
}


$userScriptsPath = Join-Path $env:USERPROFILE "RX8Cloud"
if (-not (Test-Path $userScriptsPath)) {
    New-Item -ItemType Directory -Path $userScriptsPath -Force | Out-Null
}

$nubeScriptPath = Join-Path $userScriptsPath "nube.ps1"

$nubeScriptContent = @'
function Show-Logo {
    Clear-Host
    Write-Host "  ██████╗ ██╗  ██╗ █████╗ " -ForegroundColor Red
    Write-Host "  ██╔══██╗██║  ██║██╔══██╗" -ForegroundColor Red
    Write-Host "  ██████╔╝███████║╚█████╔╝" -ForegroundColor Red
    Write-Host "  ██╔══██╗╚════██║██╔══██╗" -ForegroundColor Red
    Write-Host "  ██║  ██║     ██║╚█████╔╝" -ForegroundColor Red
    Write-Host "  ╚═╝  ╚═╝     ╚═╝ ╚════╝ " -ForegroundColor Red
    Write-Host "   [ RX8 CLOUD - AUTOMATIC SYSTEM ]" -ForegroundColor Cyan
    Write-Host "------------------------------------------------"
}

function Get-MyId {
    Show-Logo
    Write-Host "[+] Tu Token / ID de Dispositivo RX8:" -ForegroundColor Green
    Write-Host ""
    
    $deviceId = & syncthing device-id 2>$null
    if (-not $deviceId) {
        $deviceId = & syncthing --device-id 2>$null
    }
    
    if ($deviceId) {
        Write-Host $deviceId -ForegroundColor Yellow
    } else {
        Write-Host "[!] Generando configuración inicial... por favor ejecuta primero la Opción 4 para iniciar el servicio." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Read-Host "Presiona ENTER para volver al menú..."
}

function Connect-Device {
    Show-Logo
    Write-Host "[+] Vincular dispositivo remoto (Termux / PC)" -ForegroundColor Green
    Write-Host ""
    $remoteId = Read-Host "Introduce el Token ID remoto"
    $devName = Read-Host "Nombre para el dispositivo"
    if ($remoteId) {
        & syncthing cli config devices add --device-id "$remoteId" --name "$DEV_NAME"
        Write-Host "[✓] Dispositivo guardado exitosamente." -ForegroundColor Green
    }
    Read-Host "Presiona ENTER para volver al menú..."
}

function Start-Sync {
    Show-Logo
    $syncthingProc = Get-Process -Name "syncthing" -ErrorAction SilentlyContinue
    if ($syncthingProc) {
        Write-Host "[!] El servicio ya está activo." -ForegroundColor Yellow
    } else {
        Write-Host "[+] Iniciando servicio Nube RX8..." -ForegroundColor Green
        Start-Process -FilePath "syncthing" -ArgumentList '--gui-address="127.0.0.1:8384"', '--no-browser' -WindowStyle Hidden
        Write-Host "[i] Esperando a que el servidor web responda (3 seg)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        Write-Host "[✓] Servicio iniciado con éxito." -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "[i] Abre esta dirección en tu navegador si deseas gestionar archivos:" -ForegroundColor Cyan
    Write-Host "    http://127.0.0.1:8384" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona ENTER para volver al menú..."
}

function Stop-Sync {
    Show-Logo
    Stop-Process -Name "syncthing" -Force -ErrorAction SilentlyContinue
    Write-Host "[✓] Servicio Nube RX8 detenido." -ForegroundColor Red
    Write-Host ""
    Read-Host "Presiona ENTER para volver al menú..."
}

while ($true) {
    Show-Logo
    Write-Host "1. Ver fecha y hora actual de la terminal"
    Write-Host "2. Ver mi Token / ID de dispositivo RX8"
    Write-Host "3. Vincular con otro dispositivo (Termux / PC)"
    Write-Host "4. Iniciar servicio de Nube"
    Write-Host "5. Detener servicio de Nube"
    Write-Host "6. Salir"
    Write-Host "------------------------------------------------"
    $option = Read-Host "Selecciona una opción [1-6]"
    
    switch ($option) {
        "1" { Show-Logo; Get-Date; Read-Host "Presiona ENTER para volver..." }
        "2" { Get-MyId }
        "3" { Connect-Device }
        "4" { Start-Sync }
        "5" { Stop-Sync }
        "6" { exit }
        Default { Start-Sleep -Seconds 1 }
    }
}
'@

Set-Content -Path $nubeScriptPath -Value $nubeScriptContent -Encoding UTF8


$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$userScriptsPath*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$userScriptsPath", "User")
    $env:Path += ";$userScriptsPath"
}


$cmdLauncherPath = Join-Path $userScriptsPath "nube.cmd"
$cmdLauncherContent = "@echo off`r`npowershell -ExecutionPolicy Bypass -NoProfile -File `"%USERPROFILE%\RX8Cloud\nube.ps1`""
Set-Content -Path $cmdLauncherPath -Value $cmdLauncherContent

Write-Host ""
Write-Host "[✓] ¡INSTALACIÓN COMPLETADA EXITOSAMENTE EN WINDOWS!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Escribe el comando: " -NoNewline -ForegroundColor Yellow
Write-Host "nube" -NoNewline -ForegroundColor White
Write-Host " para iniciar el menú." -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
