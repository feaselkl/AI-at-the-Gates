<#
.SYNOPSIS
    Sets up a local Ollama embedding endpoint for the SQL Server 2025 vector demo.

.DESCRIPTION
    1. Installs Ollama (if not already installed) -- via winget, falling back to
       the official installer download.
    2. Pulls the Harrier embedding model GGUF from Hugging Face.
    3. Renames it to the short name "harrier".
    4. Persists OLLAMA_HOST=0.0.0.0:11434 (user environment variable) so the TLS
       proxy container can reach Ollama on the host -- no stage-day step to forget.

    Harrier (microsoft/harrier-oss-v1-0.6b) is a multilingual *embedding* model
    (feature-extraction, sentence-transformers, SOTA on MTEB v2 at release). The
    0.6B variant returns 1024-dimensional vectors -- so use VECTOR(1024) on the
    SQL Server side. The GGUF build used here is mradermacher's quantization.

.NOTES
    Run from PowerShell. If Ollama was just installed, you may need to open a new
    PowerShell window so 'ollama' is on PATH (this script adds the default install
    path for the current session).
#>

$ErrorActionPreference = 'Stop'

# --- Configuration (change $ModelRepo to use a different model) ---------------
$ModelRepo  = 'hf.co/mradermacher/harrier-oss-v1-0.6b-GGUF'   # Ollama pulls GGUF straight from Hugging Face
$TargetName = 'harrier'
$OllamaHost = if ($env:OLLAMA_HOST) { $env:OLLAMA_HOST } else { 'http://127.0.0.1:11434' }

# --- 1. Install Ollama if missing --------------------------------------------
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Write-Host "==> Ollama already installed: $(ollama --version 2>$null | Select-Object -First 1)"
}
else {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "==> Installing Ollama with winget..."
        winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements
    }
    else {
        Write-Host "==> winget not found; downloading the Ollama installer..."
        $installer = Join-Path $env:TEMP 'OllamaSetup.exe'
        Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile $installer
        Start-Process -FilePath $installer -ArgumentList '/SILENT' -Wait
    }
    # Add the default install location to PATH for this session.
    $ollamaDir = Join-Path $env:LOCALAPPDATA 'Programs\Ollama'
    if (Test-Path $ollamaDir) { $env:PATH = "$ollamaDir;$env:PATH" }
}

# --- 2. Make sure the Ollama server is running -------------------------------
function Test-OllamaUp {
    try { Invoke-RestMethod -Uri "$OllamaHost/api/version" -TimeoutSec 2 | Out-Null; return $true }
    catch { return $false }
}
if (-not (Test-OllamaUp)) {
    Write-Host "==> Starting Ollama server..."
    Start-Process -FilePath 'ollama' -ArgumentList 'serve' -WindowStyle Hidden
    $ready = $false
    for ($i = 0; $i -lt 30; $i++) {
        if (Test-OllamaUp) { $ready = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw "Ollama server did not become ready at $OllamaHost" }
}
Write-Host "==> Ollama server is up at $OllamaHost"

# --- 3. Pull the model (no tag => Ollama picks the default quant, tagged :latest)
Write-Host "==> Pulling $ModelRepo (downloads the GGUF from Hugging Face)..."
ollama pull $ModelRepo

# --- 4. Rename to "harrier" (Ollama has no rename: copy, then remove original)
$src = ollama list |
    Select-String -Pattern 'harrier-oss-v1-0.6b-GGUF' |
    ForEach-Object { ($_.ToString() -split '\s+')[0] } |
    Select-Object -First 1
if (-not $src) { throw "Could not find the pulled model in 'ollama list'." }
Write-Host "==> Renaming '$src' -> '$TargetName'"
ollama cp $src $TargetName
ollama rm $src

# --- 5. Verify it embeds, and report the dimension ---------------------------
Write-Host "==> Model details:"
ollama show $TargetName
try {
    $body = @{ model = $TargetName; input = 'cold holding temperature violation' } | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri "$OllamaHost/api/embed" -Method Post -Body $body -ContentType 'application/json'
    $dim  = $resp.embeddings[0].Count
    Write-Host "==> Embedding smoke test: OK (dimension $dim)"
}
catch {
    Write-Host "==> WARNING: embedding smoke test failed; check 'ollama show $TargetName'." -ForegroundColor Yellow
    $dim = 1024
}
# --- 6. Make Ollama listen on all interfaces (0.0.0.0) so the TLS proxy can
#        reach it from its container. Persisted as a user environment variable.
$bindAddr = '0.0.0.0:11434'
Write-Host "==> Persisting user environment variable OLLAMA_HOST=$bindAddr ..."
[System.Environment]::SetEnvironmentVariable('OLLAMA_HOST', $bindAddr, 'User')
# Restart Ollama so it rebinds. (The CLI calls above used the default 127.0.0.1.)
Write-Host "==> Restarting Ollama to apply the new bind address..."
Get-Process -Name 'ollama*' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$env:OLLAMA_HOST = $bindAddr
Start-Process -FilePath 'ollama' -ArgumentList 'serve' -WindowStyle Hidden

Write-Host "==> Done. '$TargetName' is ready (dimension $dim); Ollama listening on $bindAddr."
Write-Host "    Use VECTOR($dim) in SQL Server to match this model."
Write-Host "    Note: $bindAddr is a bind address. If a future 'ollama' CLI call can't connect," -ForegroundColor DarkGray
Write-Host "    set OLLAMA_HOST=127.0.0.1:11434 for that shell." -ForegroundColor DarkGray
