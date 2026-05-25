# VencordLogonUpdater.ps1 - A script to install Vencord across Discord updates.

$DebugPreference = "SilentlyContinue" # Switch between "Continue" and "SilentlyContinue" for debug output.
$ErrorActionPreference = "Stop"

try {
    # Check if Discord is installed
    if (-Not (Test-Path "$env:LOCALAPPDATA\Discord\app-*")) {
        Write-Debug "Discord is not installed. Please install it from https://discord.com"
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            "VencordLogonUpdater attempted to run but Discord doesn't seem to be installed. Please install it from https://discord.com",
            "Discord Not Found",
            "OK",
            "Error"
        ) | Out-Null
        exit 1
    }

    # Close Discord if it's running
    Write-Debug "Closing Discord if it's running..."
    Get-Process -Name "Discord" -ErrorAction SilentlyContinue | Stop-Process -Force

    # Attempt to update Discord
    Write-Debug "Attempting to update Discord..."
    Start-Process -FilePath "$env:LocalAppData\Discord\Update.exe" -Wait # Not sure if this even works.
    Start-Sleep -Seconds 1

    # Read the current installed Discord version
    $CurrentDiscordVersion = (Get-Item "$env:LOCALAPPDATA\Discord\app-*\Discord.exe" | Select-Object -Last 1).VersionInfo.ProductVersion
    Write-Debug "Current Discord version: $CurrentDiscordVersion"

    # Check if VencordLogonUpdater regkey exists (first run)
    if (-Not (Test-Path "HKCU:\Software\VencordLogonUpdater")) {
        Write-Debug "VencordLogonUpdater registry key not found. Creating it and saving the current Discord version..."
        New-Item -Path "HKCU:\Software\VencordLogonUpdater" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\VencordLogonUpdater" -Name "LastDiscordVersion" -Value $CurrentDiscordVersion
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            "This seems to be your first time running VencordLogonUpdater. The current Discord version has been saved to the registry. Set up this script to run as a scheduled task on user logon and it will automatically reinstall Vencord for you whenever Discord gets updated.",
            "First Time Setup",
            "OK",
            "Information"
        ) | Out-Null
        # Launch Discord and exit — no Vencord install needed on first run
        Start-Process -FilePath "$env:LocalAppData\Discord\Update.exe" -ArgumentList "--processStart", "Discord.exe"
        exit 0
    }

    # Compare the current Discord version with the version stored in the registry
    $LastDiscordVersion = (Get-ItemProperty -Path "HKCU:\Software\VencordLogonUpdater" -ErrorAction SilentlyContinue).LastDiscordVersion
    Write-Debug "Last recorded Discord version: $LastDiscordVersion"

    if ($CurrentDiscordVersion -ne $LastDiscordVersion) {
        Write-Debug "Discord was updated ($LastDiscordVersion -> $CurrentDiscordVersion). Reinstalling Vencord..."

        # Download the latest Vencord Installer CLI
        Write-Debug "Downloading the latest Vencord Installer CLI..."
        $VencordInstallerPath = "$env:TEMP\VencordInstallerCli.exe"
        $VencordInstallerUrl = "https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe"
        Invoke-WebRequest -Uri $VencordInstallerUrl -OutFile $VencordInstallerPath

        # Run the Vencord Installer CLI and wait for it to finish
        Write-Debug "Running the Vencord Installer CLI..."
        # Create a file containing just a newline to feed to the installer
        $newlineFile = "$env:TEMP\VencordLogonUpdater_newline.txt"
        "`n" | Out-File -FilePath $newlineFile -Encoding ascii -NoNewline:$false

        Start-Process -FilePath $VencordInstallerPath `
            -ArgumentList "-branch", "auto", "-install" `
            -RedirectStandardInput $newlineFile `
            -NoNewWindow -Wait

        Remove-Item $newlineFile -Force

        # Only update the registry after a successful install
        Write-Debug "Vencord installed successfully. Updating registry..."
        Set-ItemProperty -Path "HKCU:\Software\VencordLogonUpdater" -Name "LastDiscordVersion" -Value $CurrentDiscordVersion

        # Cleanup
        Write-Debug "Cleaning up temporary files..."
        Remove-Item $VencordInstallerPath -Force
    }
    else {
        Write-Debug "Discord version unchanged ($CurrentDiscordVersion). No Vencord reinstall needed."
    }

    # Launch Discord
    Write-Debug "Launching Discord..."
    Start-Process -FilePath "$env:LocalAppData\Discord\Update.exe" -ArgumentList "--processStart", "Discord.exe"
    exit 0
}
catch {
    try {
        $_ | Out-File "$env:TEMP\VencordLogonUpdater_error.txt"
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            "An error occurred while running VencordLogonUpdater. Please check the log file at $env:TEMP\VencordLogonUpdater_error.txt for more details.",
            "Error",
            "OK",
            "Error"
        ) | Out-Null
    }
    catch {
    }
    exit 1
}
