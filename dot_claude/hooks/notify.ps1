# Claude Code Notification hook -> Windows toast.
# Fires when Claude needs the operator (permission_prompt / idle_prompt).
# Reads the hook JSON payload from stdin.

$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
$payload = $null
if ($raw) { try { $payload = $raw | ConvertFrom-Json } catch { } }

$type = if ($payload) { $payload.notification_type } else { $null }
# Only notify on the cases that actually want the operator's attention.
if ($type -and @('permission_prompt', 'idle_prompt') -notcontains $type) { return }

$message = $null
if ($payload) { $message = $payload.message }
if (-not $message) {
    $message = switch ($type) {
        'permission_prompt' { 'Claude needs permission to continue.' }
        'idle_prompt'       { 'Claude is waiting for your input.' }
        default             { 'Claude Code needs your attention.' }
    }
}
$cwd = if ($payload -and $payload.cwd) { Split-Path -Leaf $payload.cwd } else { '' }
$title = if ($cwd) { "Claude Code - $cwd" } else { 'Claude Code' }

function Show-Toast([string]$Title, [string]$Body) {
    # Dependency-free WinRT toast (Windows 10/11). Falls back to a tray balloon.
    try {
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        # Build a ToastGeneric toast from scratch. Appending an <image> to a legacy
        # template's binding (ToastText02) is silently ignored, so the logo never shows.
        $logo = Join-Path $PSScriptRoot 'claude-logo.png'
        $logoXml = ''
        if (Test-Path $logo) {
            # Toast images need a file:// URI; a bare C:\ path silently fails to load.
            $logoUri = ([System.Uri]$logo).AbsoluteUri
            $logoXml = "<image placement=""appLogoOverride"" src=""$logoUri""/>"
        }
        $escTitle = [System.Security.SecurityElement]::Escape($Title)
        $escBody = [System.Security.SecurityElement]::Escape($Body)
        $xmlText = "<toast><visual><binding template=""ToastGeneric""><text>$escTitle</text><text>$escBody</text>$logoXml</binding></visual></toast>"
        $xml = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]::new()
        $xml.LoadXml($xmlText)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        # A registered AppUserModelID is required; PowerShell's is present on Win10/11.
        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
        return $true
    } catch { return $false }
}

if (-not (Show-Toast -Title $title -Body $message)) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $ni = New-Object System.Windows.Forms.NotifyIcon
        $ni.Icon = [System.Drawing.SystemIcons]::Information
        $ni.Visible = $true
        $ni.ShowBalloonTip(5000, $title, $message, [System.Windows.Forms.ToolTipIcon]::Info)
        Start-Sleep -Milliseconds 200
    } catch { }
}
