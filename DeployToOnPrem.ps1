Param(
    [Hashtable]$parameters
)

function New-TemporaryFolder {
    $tempPath = Join-Path -Path $PWD -ChildPath "_temp"
    New-Item -ItemType Directory -Path $tempPath | Out-Null

    return $tempPath
}

function Get-Script {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptUrl,
        [Parameter(Mandatory = $true)]
        [string]$outputPath
    )
    Write-Host "`nDownloading ${ScriptUrl}..."

    if (-not (Test-Path -Path $outputPath)) {
        throw "Output path '$outputPath' does not exist."
    }
    $filename = [System.IO.Path]::GetFileName($ScriptUrl)
    $dplScriptPath = Join-Path -Path $outputPath -ChildPath $filename
    Write-Host "::debug::Downloading $ScriptUrl..."
    Invoke-WebRequest -Uri $ScriptUrl -OutFile $dplScriptPath
    Write-Host "Downloaded ${ScriptUrl} to $dplScriptPath"

    return $dplScriptPath
}

Write-Host "Deployment Type (CD or Release): $($parameters.type)"
Write-Host "Apps to deploy: $($parameters.apps)"
Write-Host "Environment Type: $($parameters.EnvironmentType)"
Write-Host "Environment Name: $($parameters.EnvironmentName)"

$scriptUrl = "https://raw.githubusercontent.com/Harmonize-it/ALGO/refs/heads/main/Update-NavAPP.ps1"
$filename = [System.IO.Path]::GetFileName($scriptUrl)

$tempPath = New-TemporaryFolder
cd $tempPath

Get-Script -ScriptUrl $scriptUrl -outputPath $tempPath 

Copy-AppFilesToFolder -appFiles $parameters.apps -folder $tempPath | Out-Null
$appsList = @(Get-ChildItem -Path $tempPath -Filter *.app)
if (-not $appsList -or $appsList.Count -eq 0) {
    Write-Host "::error::No apps to publish found."
    exit 1
}

$appsList | ForEach-Object -Process { 
    Write-Host "Processing app file... $($_.FullName)"
    .\Update-NAVApp.ps1 -appPath $_.FullName -srvInst $parameters.EnvironmentName
}
