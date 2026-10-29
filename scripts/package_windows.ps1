$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $root
flutter pub get
flutter build windows --release
$release = Join-Path $root 'build\windows\x64\runner\Release'
if (!(Test-Path $release)) { throw 'Windows-Release-Verzeichnis fehlt.' }
$work = Join-Path $root 'build\whisper-src'
if (!(Test-Path $work)) { git clone --depth 1 https://github.com/ggml-org/whisper.cpp.git $work }
cmake -S $work -B (Join-Path $work 'build') -DCMAKE_BUILD_TYPE=Release
cmake --build (Join-Path $work 'build') --config Release --target whisper-cli
$whisper = Join-Path $release 'data\whisper'
New-Item -ItemType Directory -Force $whisper | Out-Null
Get-ChildItem (Join-Path $work 'build') -Recurse -Filter '*.dll' | Copy-Item -Destination $whisper -Force
$cli = Get-ChildItem (Join-Path $work 'build') -Recurse -Filter 'whisper-cli.exe' | Select-Object -First 1
if (!$cli) { throw 'whisper-cli.exe wurde nicht gebaut.' }
Copy-Item $cli.FullName (Join-Path $whisper 'whisper-cli.exe') -Force
$model = Join-Path $whisper 'ggml-base.bin'
if (!(Test-Path $model)) { Invoke-WebRequest -Uri 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin' -OutFile $model }
$zip = Join-Path $root 'build\Daymark-Windows.zip'
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path (Join-Path $release '*') -DestinationPath $zip
Write-Host "Fertig: $zip"
