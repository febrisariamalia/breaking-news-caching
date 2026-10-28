$OutputDir = ".\results\C\mira\resource"
$OutputFile = Join-Path $OutputDir "container_stats.csv"
New-Item -ItemType Directory -Force $OutputDir | Out-Null
"timestamp,container,cpu_percent,memory_usage,memory_percent" | Set-Content $OutputFile
Write-Host "Pencatatan resource berjalan. Tekan Ctrl+C untuk berhenti."
while ($true) {
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $stats = docker stats --no-stream --format "{{.Name}};{{.CPUPerc}};{{.MemUsage}};{{.MemPerc}}"
    foreach ($line in $stats) {
        $parts = $line -split ";", 4
        if ($parts.Count -eq 4 -and $parts[0] -like "news-c-*") {
            [PSCustomObject]@{ timestamp = $timestamp; container = $parts[0]; cpu_percent = $parts[1].TrimEnd("%"); memory_usage = $parts[2]; memory_percent = $parts[3].TrimEnd("%") } | Export-Csv -Path $OutputFile -NoTypeInformation -Append
        }
    }
    Start-Sleep -Seconds 2
}
