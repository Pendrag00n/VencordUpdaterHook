# VencordUpdaterHook.ps1 - A script to install Vencord across Discord updates.

# Check if Discord is installed
if (-Not (Test-Path "$env:LOCALAPPDATA\Discord\app-*")) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "VencordUpdaterHook attempted to run but Discord doesn't seem to be installed. Please install it from https://discord.com",
        "Discord Not Found",
        "OK",
        "Error"
    ) | Out-Null
    exit 1
}
else {
    # Update Discord
    Start-Process -FilePath "$env:LocalAppData\Discord\Update.exe" -Wait # Not sure if this even works.
    $CurrentDiscordVersion = (Get-Item "$env:LOCALAPPDATA\Discord\app-*\Discord.exe" | Select-Object -Last 1).VersionInfo.ProductVersion
}

# Check if VencordHook regkey exists
if (-Not (Test-Path "HKCU:\Software\VencordHook")) {
    # Create VencordHook regkey
    New-Item -Path "HKCU:\Software\VencordHook" -Force | Out-Null
    # Write the current Discord version to the registry
    Set-ItemProperty -Path "HKCU:\Software\VencordHook" -Name "LastDiscordVersion" -Value $CurrentDiscordVersion
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "This seems to be your first time running VencordUpdaterHook. The current Discord version has been saved to the registry. Set up this script to run as a scheduled task on user logon and it will automatically reinstall Vencord for you whenever Discord gets updated.",
        "First Time Setup",
        "OK",
        "Information"
    ) | Out-Null
    exit 0
}
else {
    # Compare the current Discord version with the version stored in the registry
    $LastDiscordVersion = (Get-ItemProperty -Path "HKCU:\Software\VencordHook" -ErrorAction SilentlyContinue).LastDiscordVersion
    if ($CurrentDiscordVersion -ne $LastDiscordVersion) {
        # Close Discord if it's running
        Get-Process -Name "Discord" -ErrorAction SilentlyContinue | Stop-Process -Force
        # Update the registry with the current Discord version
        Set-ItemProperty -Path "HKCU:\Software\VencordHook" -Name "LastDiscordVersion" -Value $CurrentDiscordVersion
        # Download the latest Vencord Installer CLI
        $VencordInstallerUrl = "https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe"
        Invoke-WebRequest -Uri $VencordInstallerUrl -OutFile "$env:TEMP\VencordInstallerCli.exe"
        # Run the Vencord Installer CLI
        Start-Process -FilePath "$env:TEMP\VencordInstallerCli.exe" -ArgumentList "-branch", "auto", "-install" -Wait
        # Launch Discord
        Start-Process -FilePath "$env:LocalAppData\Discord\Update.exe" -ArgumentList "--processStart", "Discord.exe"
        # Cleanup
        Remove-Item "$env:TEMP\VencordInstallerCli.exe" -Force
        exit 0
    }
    else {
        exit 0
    }
}
