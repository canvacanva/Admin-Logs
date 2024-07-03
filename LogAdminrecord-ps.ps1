# Impostazioni
$password = "scegli_la_tua_psw"
$savePath = "E:\LogStorage" # Puoi parametrizzare il percorso di salvataggio qui
$logFilePath = "E:\LogStorage\logEventi.txt" # Percorso del file di log
$compressionLevel = "Optimal" # Imposta il livello di compressione ("Fastest", "NoCompression", "Low", "Normal", "High", "Ultra", "Optimal")

# Definizione della funzione per la registrazione degli eventi
function Log-Event {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[ $timestamp ] $Message"
    $logEntry | Out-File -Append -FilePath $logFilePath
}

# Controllo se la cartella di salvataggio esiste, altrimenti la crea
if (-not (Test-Path -Path $savePath)) {
    New-Item -ItemType Directory -Path $savePath | Out-Null
}

# Registra l'inizio del processo nel log
Log-Event "Inizio processo di scaricamento e compressione dei log degli amministratori."

# Ottieni tutti i server di dominio
$servers = Get-ADComputer -Filter {OperatingSystem -like "*Server*"} | Select-Object -ExpandProperty Name

# Ciclo sui server per scaricare i log degli amministratori
foreach ($server in $servers) {
    $logPath = "\\$server\c$\Windows\System32\winevt\Logs\Security.evtx"
    $tempFolderPath = Join-Path -Path $savePath -ChildPath "$server"
    $saveFileName = "$(Get-Date -Format 'yyyyMMdd')_$server.zip"
    $saveFilePath = Join-Path -Path $savePath -ChildPath $saveFileName
    
    # Controllo se il file di log esiste e lo copio nella cartella temporanea
    if (Test-Path $logPath) {
        # Creo una cartella temporanea per i log del server
        New-Item -ItemType Directory -Path $tempFolderPath -Force | Out-Null
        Copy-Item -Path $logPath -Destination $tempFolderPath -Force
        # Comprimi il file di log utilizzando la libreria .NET
#        Add-Type -AssemblyName System.IO.Compression.FileSystem
#        [System.IO.Compression.ZipFile]::CreateFromDirectory($tempFolderPath, $saveFilePath, $compressionLevel, $true)
        # Applica la password al file zip utilizzando 7-Zip
#       $7zip = "C:\Program Files\7-Zip\7z.exe"
        $7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"
        Set-Alias Start-SevenZip $7zipPath
        if (Test-Path $7zipPath) {
#           $arguments = "a -p$password `"$saveFilePath`""
#           $arguments = "-p$password `"$saveFilePath`" `"$tempFolderPath`""
           & Start-SevenZip a -p"$password" $saveFilePath $tempFolderPath
#          echo a -p"$password" $saveFilePath $tempFolderPath
            # Rimuovi la cartella temporanea
            Remove-Item -Path $tempFolderPath -Recurse -Force
            # Registra l'avvenuta compressione nel log
            Log-Event "Il log degli amministratori su $server è stato compresso e salvato in $saveFilePath."
        } else {
            Log-Event "Errore: 7-Zip non trovato."
        }
    } else {
        # Registra un errore nel log se il file di log non è stato trovato
        Log-Event "Errore: Il file di log degli amministratori non è stato trovato su $server."
    }
}

# Registra la fine del processo nel log
Log-Event "Fine processo di scaricamento e compressione dei log degli amministratori."
