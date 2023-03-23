New-Service -Name "windows_exporter" -DisplayName "Windows Exporter" -Description "Exposition des metrics pour Prometheus" -StartupType AutomaticDelayedStart -BinaryPathName '"C:\Program Files\windows_exporter\windows_exporter-0.21.0-amd64.exe" --config.file="C:\Program Files\windows_exporter\config.yml" --web.config.file="C:\Program Files\windows_exporter\web-config.yml"'
Start-Service -Name "windows_exporter"