# Copy minion keys & config to correct location
New-Item c:\salt\conf\pki\minion\ -ItemType directory | out-null

# Check if minion keys have been uploaded
if (Test-Path C:\tmp\minion.pem) {
  cp C:\tmp\minion.pem C:\salt\conf\pki\minion\
  cp C:\tmp\minion.pub C:\salt\conf\pki\minion\
}

# Check if minion config has been uploaded
if (Test-Path C:\tmp\minion) {
  cp C:\tmp\minion C:\salt\conf\
}

# Detect architecture
if ([IntPtr]::Size -eq 4) {
  $arch = "win32"
} else {
  $arch = "AMD64"
}

# Download minion setup file
Write-Host "Downloading Salt minion installer ($arch)..."
$webclient = New-Object System.Net.WebClient
$url = "https://docs.saltstack.com/downloads/Salt-Minion-2014.1.3-1-$arch-Setup.exe"
$file = "C:\tmp\salt.exe"
$webclient.DownloadFile($url, $file)

# Install minion silently
Write-Host "Installing Salt minion..."
C:\tmp\salt.exe /S

# Wait for salt-minion service to be registered before trying to start it
$service = Get-Service salt-minion -ErrorAction SilentlyContinue
While (!$service) {
  Start-Sleep -s 2
  $service = Get-Service salt-minion -ErrorAction SilentlyContinue
}

# Start service
Start-Service -Name "salt-minion" -ErrorAction SilentlyContinue

# Check if service is started, otherwise retry starting the 
# service 4 times.
$try = 0
While (($service.Status -ne "Running") -and ($try -ne 4)) {
  Start-Service -Name "salt-minion" -ErrorAction SilentlyContinue
  $service = Get-Service salt-minion -ErrorAction SilentlyContinue
  Start-Sleep -s 2
  $try += 1
}

# If the salt-minion service is still not running, something probably
# went wrong and user intervention is required - report failure.
if ($service.Status -eq "Stopped") {
  Write-Host "Failed to start Salt minion"
  exit 1
}

Write-Host "Salt minion successfully installed"
