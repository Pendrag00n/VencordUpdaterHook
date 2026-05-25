# VencordLogonUpdater

> A PowerShell script that automatically reinstalls [Vencord](https://github.com/Vendicated/Vencord) after every Discord update — so you never have to do it manually again.

---

## What is this?

[Vencord](https://github.com/Vendicated/Vencord) is a popular Discord client mod — but every time Discord updates itself, it wipes Vencord out. **VencordLogonUpdater** solves this by running a scheduled task to re-run the Vencord installer automatically on every logon, but only when Discord has actually been updated.

## How it works

On each user logon, the script:

1. Reads the currently installed Discord version.
2. Compares it against the last known version stored in the Windows Registry.
3. If a new version is detected, it re-downloads and re-runs the Vencord installer automatically.
4. Updates the stored version in the Registry for the next check.

No unnecessary reinstalls, no manual intervention.

---

## Installation

### Automatic *(coming soon)*

Automatic installation is planned. Check back for updates.

### Manual

**Step 1 — Download the script**

Grab [`VencordLogonUpdater.ps1`](https://github.com/Pendrag00n/VencordLogonUpdater/blob/main/VencordLogonUpdater.ps1) from the repository.

**Step 2 — Place the script**

Store it somewhere permanent, such as:

```
C:\Users\<YourUsername>\AppData\Roaming\MyScripts\VencordLogonUpdater.ps1
```

**Step 3 — Open Task Scheduler**

Press `Win + R`, type `taskschd.msc`, and hit Enter.

**Step 4 — Create a new task**

- Click **Create Basic Task** in the right-hand panel.
- Set the trigger to **When I log on**.
- Set the action to **Start a program**, with the following settings:

| Field | Value |
|---|---|
| Program | `powershell.exe` |
| Arguments | `-ExecutionPolicy Bypass -File "C:\Users\<YourUsername>\AppData\Roaming\MyScripts\VencordLogonUpdater.ps1"` |

**Step 5 — Save and test**

Finish the wizard. To verify it works, right-click the task and select **Run**.

---

## Requirements

- Windows 10 or 11
- PowerShell 5.1+
- Discord installed via the standard installer
- Internet access (to download the Vencord installer)
