$ErrorActionPreference = "Stop"
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$script:LauncherDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ConfigPath = Join-Path $script:LauncherDir "config.json"
$script:DefaultClientPath = "C:\mangos\client-2.4.3"
$script:LauncherVersion = "0.6.0"
$script:UpdateSourcePath = Join-Path $script:LauncherDir "update-source.json"
$script:UpdateStagingRoot = Join-Path $script:LauncherDir "ika-update-staging"
$script:UpdateBackupRoot = Join-Path $script:LauncherDir "ika-update-backups"
$script:UpdaterWorkerPath = Join-Path $script:LauncherDir "IKA-UpdaterWorker.ps1"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

function Get-LauncherConfig {
    $defaults = [ordered]@{
        ClientPath = $script:DefaultClientPath
        RealmAddress = "127.0.0.1"
        RealmPort = 3724
    }

    if (-not (Test-Path -LiteralPath $script:ConfigPath -PathType Leaf)) {
        return [pscustomobject]$defaults
    }

    try {
        $saved = Get-Content -LiteralPath $script:ConfigPath -Raw | ConvertFrom-Json
        if ($saved.ClientPath) { $defaults.ClientPath = [string]$saved.ClientPath }
        if ($saved.RealmAddress) { $defaults.RealmAddress = [string]$saved.RealmAddress }
        if ($saved.RealmPort) { $defaults.RealmPort = [int]$saved.RealmPort }
    } catch {
        [System.Windows.MessageBox]::Show(
            "O arquivo config.json estava invalido e sera recriado.",
            "IKA Gaming Launcher",
            "OK",
            "Warning") | Out-Null
    }

    return [pscustomobject]$defaults
}

function Save-LauncherConfig([string]$ClientPath, [string]$RealmAddress, [int]$RealmPort) {
    $cfg = [ordered]@{
        ClientPath = $ClientPath.Trim().TrimEnd("\")
        RealmAddress = $RealmAddress.Trim()
        RealmPort = $RealmPort
    }
    $cfg | ConvertTo-Json | Set-Content -LiteralPath $script:ConfigPath -Encoding UTF8
    $script:Config = [pscustomobject]$cfg
}

function Get-WowExecutable {
    $ikaExecutable = Join-Path $script:Config.ClientPath "Wow-IKA-LoadScreens.exe"
    if (Test-Path -LiteralPath $ikaExecutable -PathType Leaf) {
        return $ikaExecutable
    }
    $testedExecutable = Join-Path $script:Config.ClientPath "Wow-IKA-LoadScreens-TESTE.exe"
    if (Test-Path -LiteralPath $testedExecutable -PathType Leaf) {
        return $testedExecutable
    }
    return Join-Path $script:Config.ClientPath "Wow.exe"
}

function Get-RealmlistTargets {
    $candidates = @(
        (Join-Path $script:Config.ClientPath "realmlist.wtf"),
        (Join-Path $script:Config.ClientPath "Data\enUS\realmlist.wtf"),
        (Join-Path $script:Config.ClientPath "Data\enGB\realmlist.wtf")
    )

    $existing = @($candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
    if ($existing.Count -gt 0) { return $existing }
    return @($candidates[0])
}

function Set-GameRealmlist {
    if ([string]::IsNullOrWhiteSpace($script:Config.RealmAddress)) {
        throw "Configure o endereco do servidor antes de jogar."
    }

    $line = "set realmlist $($script:Config.RealmAddress)"
    foreach ($target in @(Get-RealmlistTargets)) {
        $parent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Set-Content -LiteralPath $target -Value $line -Encoding ASCII
    }
}

function Test-RealmConnection([string]$Address, [int]$Port, [int]$TimeoutMs = 1200) {
    if ([string]::IsNullOrWhiteSpace($Address)) { return $false }
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $result = $client.BeginConnect($Address, $Port, $null, $null)
        if (-not $result.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
        $client.EndConnect($result)
        return $true
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function Get-UpdateSource {
    $disabled = New-Object PSObject -Property @{
        Enabled = $false
        ManifestUrl = ""
        Channel = "stable"
    }
    if (-not (Test-Path -LiteralPath $script:UpdateSourcePath -PathType Leaf)) {
        return $disabled
    }

    try {
        $source = Get-Content -LiteralPath $script:UpdateSourcePath -Raw | ConvertFrom-Json
        $enabled = $false
        if ($null -ne $source.Enabled) { $enabled = [bool]$source.Enabled }
        $manifestUrl = [string]$source.ManifestUrl
        if (-not $enabled -or [string]::IsNullOrWhiteSpace($manifestUrl)) {
            return $disabled
        }
        return New-Object PSObject -Property @{
            Enabled = $true
            ManifestUrl = $manifestUrl.Trim()
            Channel = $(if ($source.Channel) { [string]$source.Channel } else { "stable" })
        }
    } catch {
        throw "O arquivo update-source.json esta invalido: $($_.Exception.Message)"
    }
}

function Resolve-UpdateLocation([string]$Location, [string]$BaseLocation = "") {
    if ([string]::IsNullOrWhiteSpace($Location)) {
        throw "O manifesto possui um endereco de arquivo vazio."
    }

    $absoluteUri = $null
    if ([System.Uri]::TryCreate($Location, [System.UriKind]::Absolute, [ref]$absoluteUri)) {
        if ($absoluteUri.Scheme -in @("https", "http", "file")) {
            return $absoluteUri.AbsoluteUri
        }
        throw "Protocolo de atualizacao nao permitido: $($absoluteUri.Scheme)"
    }

    if (-not [string]::IsNullOrWhiteSpace($BaseLocation)) {
        $baseUri = $null
        if ([System.Uri]::TryCreate($BaseLocation, [System.UriKind]::Absolute, [ref]$baseUri)) {
            if ($baseUri.Scheme -in @("https", "http", "file")) {
                return (New-Object System.Uri($baseUri, $Location)).AbsoluteUri
            }
        }

        $baseDirectory = Split-Path -Parent $BaseLocation
        return [System.IO.Path]::GetFullPath((Join-Path $baseDirectory $Location))
    }

    return [System.IO.Path]::GetFullPath((Join-Path $script:LauncherDir $Location))
}

function Get-UpdateText([string]$Location) {
    $resolved = Resolve-UpdateLocation $Location
    $uri = $null
    if ([System.Uri]::TryCreate($resolved, [System.UriKind]::Absolute, [ref]$uri) -and $uri.Scheme -in @("https", "http")) {
        $client = New-Object System.Net.WebClient
        $client.Encoding = [System.Text.Encoding]::UTF8
        $client.Headers.Add("User-Agent", "IKA-Gaming-Launcher/$($script:LauncherVersion)")
        try {
            return $client.DownloadString($uri)
        } finally {
            $client.Dispose()
        }
    }

    $localPath = $(if ($uri -and $uri.Scheme -eq "file") { $uri.LocalPath } else { $resolved })
    if (-not (Test-Path -LiteralPath $localPath -PathType Leaf)) {
        throw "Manifesto de atualizacao nao encontrado: $localPath"
    }
    return Get-Content -LiteralPath $localPath -Raw
}

function Get-SafeUpdateTargetPath([string]$Scope, [string]$RelativePath) {
    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        throw "O manifesto possui um caminho de destino vazio."
    }
    if ([System.IO.Path]::IsPathRooted($RelativePath) -or $RelativePath.Contains(":")) {
        throw "Caminho absoluto nao permitido no manifesto: $RelativePath"
    }

    $normalizedScope = $Scope.ToLowerInvariant()
    $root = switch ($normalizedScope) {
        "launcher" { $script:LauncherDir }
        "client" { $script:Config.ClientPath }
        default { throw "Escopo de atualizacao invalido: $Scope" }
    }
    if ([string]::IsNullOrWhiteSpace($root)) {
        throw "A pasta de destino do escopo $Scope nao esta configurada."
    }

    $rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd("\") + "\"
    $relativeNormalized = $RelativePath.Replace("/", "\").TrimStart("\")
    $candidate = [System.IO.Path]::GetFullPath((Join-Path $rootFull $relativeNormalized))
    if (-not $candidate.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "O manifesto tentou acessar uma pasta externa: $RelativePath"
    }
    return $candidate
}

function Get-FileSha256([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return "" }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Install-PendingLoadScreens {
    $archive = Join-Path $script:Config.ClientPath "IKA-LoadScreens-v0.6-Payload.zip"
    if (-not (Test-Path -LiteralPath $archive -PathType Leaf)) { return $false }

    $archiveHash = "db1b9b945963063b297235fd87035955d578b6994a9d42c2f24efee1bbd08e68"
    $exeHash = "c1f14dbcb1e274d7d67eac479dcdb81479994373dcd922908c7ea12f06899f8f"
    $mpqHash = "a7e43a8b43fcad72a20a22bf038f44747e2b4e464a11114edd9fa1638c174666"
    $targetExe = Join-Path $script:Config.ClientPath "Wow-IKA-LoadScreens.exe"
    $targetMpq = Join-Path $script:Config.ClientPath "Data\patch-Y.MPQ"

    if ((Get-FileSha256 $targetExe) -eq $exeHash -and
        (Get-FileSha256 $targetMpq) -eq $mpqHash) {
        return $false
    }
    if ((Get-FileSha256 $archive) -ne $archiveHash) {
        throw "O pacote das LoadScreens foi baixado com hash incorreto."
    }
    if (Get-Process -Name "Wow*" -ErrorAction SilentlyContinue) {
        throw "Feche o jogo e abra novamente o launcher para concluir as LoadScreens."
    }

    $tag = [Guid]::NewGuid().ToString("N")
    $staging = Join-Path $script:UpdateStagingRoot ("loadscreens-" + $tag)
    $backup = Join-Path $script:UpdateBackupRoot ("loadscreens-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    $exeExisted = Test-Path -LiteralPath $targetExe -PathType Leaf
    $mpqExisted = Test-Path -LiteralPath $targetMpq -PathType Leaf
    $backupExe = Join-Path $backup "Wow-IKA-LoadScreens.exe"
    $backupMpq = Join-Path $backup "patch-Y.MPQ"

    try {
        Expand-Archive -LiteralPath $archive -DestinationPath $staging -Force
        $payloadRoot = Join-Path $staging "IKA-LoadScreens-v0.6-Payload"
        $sourceExe = Join-Path $payloadRoot "Wow-IKA-LoadScreens.exe"
        $sourceMpq = Join-Path $payloadRoot "patch-Y.MPQ"
        if ((Get-FileSha256 $sourceExe) -ne $exeHash -or
            (Get-FileSha256 $sourceMpq) -ne $mpqHash) {
            throw "Os arquivos internos das LoadScreens estao divergentes."
        }
        if ($exeExisted) { Copy-Item -LiteralPath $targetExe -Destination $backupExe -Force }
        if ($mpqExisted) { Copy-Item -LiteralPath $targetMpq -Destination $backupMpq -Force }
        Copy-Item -LiteralPath $sourceExe -Destination $targetExe -Force
        Copy-Item -LiteralPath $sourceMpq -Destination $targetMpq -Force
        if ((Get-FileSha256 $targetExe) -ne $exeHash -or
            (Get-FileSha256 $targetMpq) -ne $mpqHash) {
            throw "A verificacao final das LoadScreens falhou."
        }
        [ordered]@{
            Version = "0.6"
            Status = "Installed"
            Backup = $backup
            InstalledAt = (Get-Date).ToString("o")
        } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $script:Config.ClientPath "IKA-LoadScreens-v0.6.json") -Encoding UTF8
        return $true
    } catch {
        if ($exeExisted -and (Test-Path -LiteralPath $backupExe)) {
            Copy-Item -LiteralPath $backupExe -Destination $targetExe -Force
        } elseif (Test-Path -LiteralPath $targetExe) {
            Remove-Item -LiteralPath $targetExe -Force
        }
        if ($mpqExisted -and (Test-Path -LiteralPath $backupMpq)) {
            Copy-Item -LiteralPath $backupMpq -Destination $targetMpq -Force
        } elseif (Test-Path -LiteralPath $targetMpq) {
            Remove-Item -LiteralPath $targetMpq -Force
        }
        throw
    } finally {
        if (Test-Path -LiteralPath $staging -PathType Container) {
            Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Copy-UpdateStream(
    [string]$SourceLocation,
    [string]$Destination,
    [System.ComponentModel.BackgroundWorker]$Worker,
    [long]$CompletedBytes,
    [long]$TotalBytes,
    [string]$StatusText
) {
    $destinationParent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
    }

    $uri = $null
    $sourceStream = $null
    $response = $null
    if ([System.Uri]::TryCreate($SourceLocation, [System.UriKind]::Absolute, [ref]$uri) -and $uri.Scheme -in @("https", "http")) {
        $request = [System.Net.HttpWebRequest]::Create($uri)
        $request.UserAgent = "IKA-Gaming-Launcher/$($script:LauncherVersion)"
        $request.AllowAutoRedirect = $true
        $request.Timeout = 15000
        $request.ReadWriteTimeout = 30000
        $response = $request.GetResponse()
        $sourceStream = $response.GetResponseStream()
    } else {
        $localPath = $(if ($uri -and $uri.Scheme -eq "file") { $uri.LocalPath } else { $SourceLocation })
        if (-not (Test-Path -LiteralPath $localPath -PathType Leaf)) {
            throw "Arquivo de atualizacao nao encontrado: $localPath"
        }
        $sourceStream = [System.IO.File]::OpenRead($localPath)
    }

    $temporaryDestination = "$Destination.download"
    $destinationStream = $null
    try {
        $destinationStream = New-Object System.IO.FileStream(
            $temporaryDestination,
            [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None)
        $buffer = New-Object byte[] 65536
        $currentBytes = [long]0
        while (($read = $sourceStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            if ($Worker.CancellationPending) { throw "Atualizacao cancelada." }
            $destinationStream.Write($buffer, 0, $read)
            $currentBytes += $read
            $overall = $CompletedBytes + $currentBytes
            $percent = $(if ($TotalBytes -gt 0) { [int][Math]::Min(95, [Math]::Floor(($overall * 95.0) / $TotalBytes)) } else { 5 })
            $Worker.ReportProgress($percent, $StatusText)
        }
    } finally {
        if ($destinationStream) { $destinationStream.Dispose() }
        if ($sourceStream) { $sourceStream.Dispose() }
        if ($response) { $response.Dispose() }
    }

    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        Remove-Item -LiteralPath $Destination -Force
    }
    Move-Item -LiteralPath $temporaryDestination -Destination $Destination -Force
}

function Show-SettingsWindow {
    $window = New-Object System.Windows.Window
    $window.Title = "Configuracoes - IKA Gaming"
    $window.Width = 620
    $window.Height = 330
    $window.WindowStartupLocation = "CenterOwner"
    $window.ResizeMode = "NoResize"
    $window.Background = "#10110E"
    $window.Foreground = "#E8D7A4"
    $window.Owner = $script:MainWindow

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "24"
    foreach ($height in @(42, 42, 42, 60, 50)) {
        $row = New-Object System.Windows.Controls.RowDefinition
        $row.Height = $height
        $grid.RowDefinitions.Add($row)
    }
    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = 150
    $col2 = New-Object System.Windows.Controls.ColumnDefinition
    $col2.Width = 390
    $grid.ColumnDefinitions.Add($col1)
    $grid.ColumnDefinitions.Add($col2)

    function Add-Label([string]$Text, [int]$Row) {
        $label = New-Object System.Windows.Controls.TextBlock
        $label.Text = $Text
        $label.VerticalAlignment = "Center"
        $label.FontSize = 15
        [System.Windows.Controls.Grid]::SetRow($label, $Row)
        [System.Windows.Controls.Grid]::SetColumn($label, 0)
        $grid.Children.Add($label) | Out-Null
    }

    Add-Label "Pasta do WoW:" 0
    Add-Label "Endereco do realm:" 1
    Add-Label "Porta do realmd:" 2

    $pathPanel = New-Object System.Windows.Controls.DockPanel
    [System.Windows.Controls.Grid]::SetRow($pathPanel, 0)
    [System.Windows.Controls.Grid]::SetColumn($pathPanel, 1)
    $browse = New-Object System.Windows.Controls.Button
    $browse.Content = "..."
    $browse.Width = 42
    $browse.Margin = "8,0,0,0"
    [System.Windows.Controls.DockPanel]::SetDock($browse, "Right")
    $pathBox = New-Object System.Windows.Controls.TextBox
    $pathBox.Text = $script:Config.ClientPath
    $pathBox.VerticalContentAlignment = "Center"
    $pathPanel.Children.Add($browse) | Out-Null
    $pathPanel.Children.Add($pathBox) | Out-Null
    $grid.Children.Add($pathPanel) | Out-Null

    $addressBox = New-Object System.Windows.Controls.TextBox
    $addressBox.Text = $script:Config.RealmAddress
    $addressBox.VerticalContentAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($addressBox, 1)
    [System.Windows.Controls.Grid]::SetColumn($addressBox, 1)
    $grid.Children.Add($addressBox) | Out-Null

    $portBox = New-Object System.Windows.Controls.TextBox
    $portBox.Text = [string]$script:Config.RealmPort
    $portBox.VerticalContentAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($portBox, 2)
    [System.Windows.Controls.Grid]::SetColumn($portBox, 1)
    $grid.Children.Add($portBox) | Out-Null

    $hint = New-Object System.Windows.Controls.TextBlock
    $hint.Text = "No teste externo, use o IP 26.x.x.x do Radmin do PC servidor. Nao informe usuario ou senha do jogo."
    $hint.TextWrapping = "Wrap"
    $hint.Foreground = "#9FCB62"
    $hint.Margin = "0,12,0,0"
    [System.Windows.Controls.Grid]::SetRow($hint, 3)
    [System.Windows.Controls.Grid]::SetColumnSpan($hint, 2)
    $grid.Children.Add($hint) | Out-Null

    $buttons = New-Object System.Windows.Controls.StackPanel
    $buttons.Orientation = "Horizontal"
    $buttons.HorizontalAlignment = "Right"
    $save = New-Object System.Windows.Controls.Button
    $save.Content = "SALVAR"
    $save.Width = 120
    $save.Height = 36
    $save.Margin = "8,0,0,0"
    $cancel = New-Object System.Windows.Controls.Button
    $cancel.Content = "CANCELAR"
    $cancel.Width = 120
    $cancel.Height = 36
    $cancel.Margin = "8,0,0,0"
    $buttons.Children.Add($save) | Out-Null
    $buttons.Children.Add($cancel) | Out-Null
    [System.Windows.Controls.Grid]::SetRow($buttons, 4)
    [System.Windows.Controls.Grid]::SetColumnSpan($buttons, 2)
    $grid.Children.Add($buttons) | Out-Null

    $browse.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Selecione a pasta que contem Wow.exe"
        $dialog.SelectedPath = $pathBox.Text
        if ($dialog.ShowDialog() -eq "OK") { $pathBox.Text = $dialog.SelectedPath }
    })

    $cancel.Add_Click({ $window.Close() })
    $save.Add_Click({
        $port = 0
        if (-not [int]::TryParse($portBox.Text, [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
            [System.Windows.MessageBox]::Show("Informe uma porta valida entre 1 e 65535.", "IKA Gaming", "OK", "Warning") | Out-Null
            return
        }
        $wow = Join-Path $pathBox.Text.Trim().TrimEnd("\") "Wow.exe"
        if (-not (Test-Path -LiteralPath $wow -PathType Leaf)) {
            [System.Windows.MessageBox]::Show("Wow.exe nao foi encontrado na pasta selecionada.", "IKA Gaming", "OK", "Warning") | Out-Null
            return
        }
        if ([string]::IsNullOrWhiteSpace($addressBox.Text)) {
            [System.Windows.MessageBox]::Show("Informe o endereco do servidor.", "IKA Gaming", "OK", "Warning") | Out-Null
            return
        }
        Save-LauncherConfig $pathBox.Text $addressBox.Text $port
        Update-ServerStatus
        $window.Close()
    })

    $window.Content = $grid
    $window.ShowDialog() | Out-Null
}

function Update-ServerStatus {
    if (Test-RealmConnection $script:Config.RealmAddress $script:Config.RealmPort) {
        $script:IsServerOnline = $true
        $script:StatusImage.Source = $script:StatusOnlineBitmap
    } else {
        $script:IsServerOnline = $false
        $script:StatusImage.Source = $script:StatusOfflineBitmap
    }
}

$script:Config = Get-LauncherConfig
$script:LabelSettings = "CONFIGURA$([char]0x00C7)$([char]0x00D5)ES"
$script:LabelNews = "NOT$([char]0x00CD)CIAS"
$script:LabelHunts = "CA$([char]0x00C7)ADAS DI$([char]0x00C1)RIAS"
$script:LabelProgress = "PROGRESS$([char]0x00C3)O EQUILIBRADA"
$script:LabelVerification = "VERIFICA$([char]0x00C7)$([char]0x00C3)O IKA GAMING"

$script:MainWindow = New-Object System.Windows.Window
$script:MainWindow.Title = "IKA Gaming Launcher"
$script:MainWindow.Width = 1280
$script:MainWindow.Height = 720
$script:MainWindow.ResizeMode = "NoResize"
$script:MainWindow.WindowStyle = "None"
$script:MainWindow.WindowStartupLocation = "CenterScreen"
$script:MainWindow.Background = "Black"
$script:MainWindow.FontFamily = "Georgia"

$canvas = New-Object System.Windows.Controls.Canvas
$canvas.Width = 1280
$canvas.Height = 720
$backgroundPath = Join-Path $script:LauncherDir "launcher-background.png"
if (-not (Test-Path -LiteralPath $backgroundPath -PathType Leaf)) {
    throw "launcher-background.png nao encontrado."
}

$image = New-Object System.Windows.Controls.Image
$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.UriSource = New-Object System.Uri($backgroundPath)
$bitmap.CacheOption = "OnLoad"
$bitmap.EndInit()
$image.Source = $bitmap
$image.Stretch = "Fill"
$image.Width = 1280
$image.Height = 720
$canvas.Children.Add($image) | Out-Null

function Add-CanvasChild($Control, [double]$Left, [double]$Top) {
    [System.Windows.Controls.Canvas]::SetLeft($Control, $Left)
    [System.Windows.Controls.Canvas]::SetTop($Control, $Top)
    $canvas.Children.Add($Control) | Out-Null
}

function New-GoldText([string]$Text, [double]$Size, [string]$Color = "#F5D980") {
    $block = New-Object System.Windows.Controls.TextBlock
    $block.Text = $Text
    $block.FontFamily = "Georgia"
    $block.FontSize = $Size
    $block.FontWeight = "Bold"
    $block.Foreground = $Color
    $block.TextAlignment = "Center"
    $block.Effect = New-Object System.Windows.Media.Effects.DropShadowEffect
    $block.Effect.Color = "Black"
    $block.Effect.BlurRadius = 5
    $block.Effect.ShadowDepth = 2
    return $block
}

function New-GoldPanel([double]$Width, [double]$Height) {
    $panel = New-Object System.Windows.Controls.Border
    $panel.Width = $Width
    $panel.Height = $Height
    $panel.Background = "#E60A0D09"
    $panel.BorderBrush = "#C89B35"
    $panel.BorderThickness = "2"
    $panel.CornerRadius = "7"
    $panel.Padding = "18"
    return $panel
}

function Get-LauncherBitmap([string]$RelativePath) {
    $assetPath = Join-Path $script:LauncherDir $RelativePath
    if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
        throw "Recurso visual nao encontrado: $RelativePath"
    }
    $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $bitmap.BeginInit()
    $bitmap.UriSource = New-Object System.Uri($assetPath)
    $bitmap.CacheOption = "OnLoad"
    $bitmap.EndInit()
    $bitmap.Freeze()
    return $bitmap
}

function New-TextEffect([string]$Color, [double]$Blur, [double]$Opacity) {
    $effect = New-Object System.Windows.Media.Effects.DropShadowEffect
    $effect.Color = $Color
    $effect.BlurRadius = $Blur
    $effect.Opacity = $Opacity
    $effect.ShadowDepth = 0
    return $effect
}

function New-GoldScrollBarStyle {
    $styleXaml = @'
<Style xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       TargetType="{x:Type ScrollBar}">
  <Setter Property="Width" Value="14"/>
  <Setter Property="Background" Value="Transparent"/>
  <Setter Property="Template">
    <Setter.Value>
      <ControlTemplate TargetType="{x:Type ScrollBar}">
        <Grid Background="Transparent">
          <Grid.RowDefinitions>
            <RowDefinition Height="14"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="14"/>
          </Grid.RowDefinitions>

          <RepeatButton Grid.Row="0" Command="{x:Static ScrollBar.LineUpCommand}"
                        Focusable="False" Background="Transparent" BorderThickness="0">
            <RepeatButton.Template>
              <ControlTemplate TargetType="{x:Type RepeatButton}">
                <Grid Background="Transparent">
                  <Path Data="M 2 9 L 7 3 L 12 9 Z" Fill="#C89B35"
                        HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Grid>
              </ControlTemplate>
            </RepeatButton.Template>
          </RepeatButton>

          <Border Grid.Row="1" Width="8" HorizontalAlignment="Center"
                  CornerRadius="4" Background="#A0060805"
                  BorderBrush="#705B2A" BorderThickness="1">
            <Track x:Name="PART_Track" IsDirectionReversed="True" Margin="1">
              <Track.DecreaseRepeatButton>
                <RepeatButton Command="{x:Static ScrollBar.PageUpCommand}"
                              Focusable="False" Background="Transparent" BorderThickness="0"/>
              </Track.DecreaseRepeatButton>
              <Track.Thumb>
                <Thumb MinHeight="42" MaxHeight="72">
                  <Thumb.Template>
                    <ControlTemplate TargetType="{x:Type Thumb}">
                      <Border CornerRadius="3" BorderBrush="#E1BC53" BorderThickness="1">
                        <Border.Background>
                          <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                            <GradientStop Color="#735511" Offset="0"/>
                            <GradientStop Color="#D4AA36" Offset="0.5"/>
                            <GradientStop Color="#735511" Offset="1"/>
                          </LinearGradientBrush>
                        </Border.Background>
                      </Border>
                    </ControlTemplate>
                  </Thumb.Template>
                </Thumb>
              </Track.Thumb>
              <Track.IncreaseRepeatButton>
                <RepeatButton Command="{x:Static ScrollBar.PageDownCommand}"
                              Focusable="False" Background="Transparent" BorderThickness="0"/>
              </Track.IncreaseRepeatButton>
            </Track>
          </Border>

          <RepeatButton Grid.Row="2" Command="{x:Static ScrollBar.LineDownCommand}"
                        Focusable="False" Background="Transparent" BorderThickness="0">
            <RepeatButton.Template>
              <ControlTemplate TargetType="{x:Type RepeatButton}">
                <Grid Background="Transparent">
                  <Path Data="M 2 4 L 7 10 L 12 4 Z" Fill="#C89B35"
                        HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Grid>
              </ControlTemplate>
            </RepeatButton.Template>
          </RepeatButton>
        </Grid>
      </ControlTemplate>
    </Setter.Value>
  </Setter>
</Style>
'@
    $stringReader = New-Object System.IO.StringReader($styleXaml)
    $xmlReader = [System.Xml.XmlReader]::Create($stringReader)
    try {
        return [System.Windows.Markup.XamlReader]::Load($xmlReader)
    } finally {
        $xmlReader.Dispose()
        $stringReader.Dispose()
    }
}

function New-ImageButton(
    [string]$Text,
    [string]$Asset,
    [double]$Width,
    [double]$Height,
    [double]$FontSize,
    [bool]$Primary,
    [double]$FrameOutsetX,
    [double]$FrameOutsetY,
    [double]$FrameOpacity = 1.0
) {
    $root = New-Object System.Windows.Controls.Grid
    $root.Width = $Width
    $root.Height = $Height
    $root.ClipToBounds = $false

    $frame = New-Object System.Windows.Controls.Image
    $frame.Source = Get-LauncherBitmap $Asset
    $frame.Stretch = "Fill"
    $frame.Width = $Width + ($FrameOutsetX * 2)
    $frame.Height = $Height + ($FrameOutsetY * 2)
    $frame.HorizontalAlignment = "Center"
    $frame.VerticalAlignment = "Center"
    $frame.Opacity = $FrameOpacity
    $frame.IsHitTestVisible = $false
    $root.Children.Add($frame) | Out-Null

    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = $Text
    $label.FontFamily = "Georgia"
    $label.FontSize = $FontSize
    $label.FontWeight = "Bold"
    $label.Foreground = "#FFE8A7"
    $label.HorizontalAlignment = "Center"
    $label.VerticalAlignment = "Center"
    $label.TextAlignment = "Center"
    $label.IsHitTestVisible = $false
    $normalEffect = New-TextEffect "Black" 4 0.8
    $label.Effect = $normalEffect
    $root.Children.Add($label) | Out-Null

    $hitArea = New-Object System.Windows.Controls.Button
    $hitArea.Width = $Width
    $hitArea.Height = $Height
    $hitArea.Background = "Transparent"
    $hitArea.BorderThickness = "0"
    $hitArea.Opacity = 0.01
    $hitArea.Focusable = $false
    $hitArea.Cursor = "Hand"

    $state = New-Object PSObject -Property @{
        Label = $label
        NormalEffect = $normalEffect
        HoverEffect = $(if ($Primary) { New-TextEffect "#65FF42" 13 0.68 } else { New-TextEffect "#D8B94E" 6 0.48 })
        Primary = $Primary
    }
    $hitArea.Tag = $state
    $hitArea.Add_MouseEnter({ param($sender, $eventArgs)
        $sender.Tag.Label.Effect = $sender.Tag.HoverEffect
        $sender.Tag.Label.Foreground = $(if ($sender.Tag.Primary) { "#FFF2B8" } else { "White" })
    })
    $hitArea.Add_MouseLeave({ param($sender, $eventArgs)
        $sender.Tag.Label.Effect = $sender.Tag.NormalEffect
        $sender.Tag.Label.Foreground = "#FFE8A7"
    })
    $root.Children.Add($hitArea) | Out-Null

    return New-Object PSObject -Property @{
        Root = $root
        Button = $hitArea
        Label = $label
        Frame = $frame
    }
}

function New-CommunityLinkButton(
    [string]$Title,
    [string]$Subtitle,
    [string]$IconAsset,
    [double]$Width,
    [double]$Height
) {
    $root = New-Object System.Windows.Controls.Grid
    $root.Width = $Width
    $root.Height = $Height

    $frame = New-Object System.Windows.Controls.Image
    $frame.Source = Get-LauncherBitmap "assets\button-main.png"
    $frame.Stretch = "Fill"
    $frame.Width = $Width
    $frame.Height = $Height
    $frame.IsHitTestVisible = $false
    $root.Children.Add($frame) | Out-Null

    $icon = New-Object System.Windows.Controls.Image
    $icon.Source = Get-LauncherBitmap $IconAsset
    $icon.Width = 50
    $icon.Height = 50
    $icon.HorizontalAlignment = "Left"
    $icon.VerticalAlignment = "Center"
    $icon.Margin = "27,0,0,0"
    $icon.IsHitTestVisible = $false
    $root.Children.Add($icon) | Out-Null

    $copy = New-Object System.Windows.Controls.StackPanel
    $copy.HorizontalAlignment = "Left"
    $copy.VerticalAlignment = "Center"
    $copy.Margin = "92,0,0,0"
    $copy.IsHitTestVisible = $false

    $titleBlock = New-Object System.Windows.Controls.TextBlock
    $titleBlock.Text = $Title
    $titleBlock.FontFamily = "Georgia"
    $titleBlock.FontSize = 18
    $titleBlock.FontWeight = "Bold"
    $titleBlock.Foreground = "#F2D77D"
    $titleBlock.Effect = New-TextEffect "Black" 4 0.85
    $copy.Children.Add($titleBlock) | Out-Null

    $subtitleBlock = New-Object System.Windows.Controls.TextBlock
    $subtitleBlock.Text = $Subtitle
    $subtitleBlock.FontFamily = "Segoe UI"
    $subtitleBlock.FontSize = 12
    $subtitleBlock.Foreground = "#D1C8AA"
    $subtitleBlock.Margin = "0,3,0,0"
    $subtitleBlock.Effect = New-TextEffect "Black" 3 0.75
    $copy.Children.Add($subtitleBlock) | Out-Null
    $root.Children.Add($copy) | Out-Null

    $arrow = New-Object System.Windows.Controls.TextBlock
    $arrow.Text = "$([char]0x2197)"
    $arrow.FontFamily = "Segoe UI Symbol"
    $arrow.FontSize = 22
    $arrow.Foreground = "#E1C66E"
    $arrow.HorizontalAlignment = "Right"
    $arrow.VerticalAlignment = "Center"
    $arrow.Margin = "0,0,29,0"
    $arrow.IsHitTestVisible = $false
    $root.Children.Add($arrow) | Out-Null

    $hitArea = New-Object System.Windows.Controls.Button
    $hitArea.Width = $Width
    $hitArea.Height = $Height
    $hitArea.Background = "Transparent"
    $hitArea.BorderThickness = "0"
    $hitArea.Opacity = 0.01
    $hitArea.Focusable = $false
    $hitArea.Cursor = "Hand"
    $hitArea.Tag = New-Object PSObject -Property @{
        Frame = $frame
        Title = $titleBlock
        NormalEffect = $titleBlock.Effect
        HoverEffect = (New-TextEffect "#54E46F" 10 0.55)
    }
    $hitArea.Add_MouseEnter({ param($sender, $eventArgs)
        $sender.Tag.Frame.Opacity = 1.0
        $sender.Tag.Title.Foreground = "#FFF0B8"
        $sender.Tag.Title.Effect = $sender.Tag.HoverEffect
    })
    $hitArea.Add_MouseLeave({ param($sender, $eventArgs)
        $sender.Tag.Frame.Opacity = 0.96
        $sender.Tag.Title.Foreground = "#F2D77D"
        $sender.Tag.Title.Effect = $sender.Tag.NormalEffect
    })
    $root.Children.Add($hitArea) | Out-Null

    return New-Object PSObject -Property @{
        Root = $root
        Button = $hitArea
    }
}

function New-FlameAnimationLayer(
    [string]$Asset,
    [double]$Left,
    [double]$Top,
    [double]$Width,
    [double]$Height,
    [double]$PhaseOffset
) {
    $flameImage = New-Object System.Windows.Controls.Image
    $flameImage.Source = Get-LauncherBitmap $Asset
    $flameImage.Stretch = "Fill"
    $flameImage.Width = $Width
    $flameImage.Height = $Height
    $flameImage.Opacity = 0.48
    $flameImage.IsHitTestVisible = $false

    $scale = New-Object System.Windows.Media.ScaleTransform
    $scale.CenterX = $Width / 2
    $scale.CenterY = $Height
    $translate = New-Object System.Windows.Media.TranslateTransform
    $transformGroup = New-Object System.Windows.Media.TransformGroup
    $transformGroup.Children.Add($scale) | Out-Null
    $transformGroup.Children.Add($translate) | Out-Null
    $flameImage.RenderTransform = $transformGroup

    Add-CanvasChild $flameImage $Left $Top
    return [pscustomobject]@{
        Image = $flameImage
        Scale = $scale
        Translate = $translate
        PhaseOffset = $PhaseOffset
    }
}

$portalFrameDirectory = Join-Path $script:LauncherDir "assets\portal-animation"
$portalFrameFiles = @(Get-ChildItem -LiteralPath $portalFrameDirectory -Filter "portal-*.png" -File | Sort-Object Name)
if ($portalFrameFiles.Count -ne 40) {
    throw "Animacao do portal incompleta. Reinstale o pacote completo."
}

$script:PortalFrames = @($portalFrameFiles | ForEach-Object {
    Get-LauncherBitmap ("assets\portal-animation\" + $_.Name)
})
$script:PortalFrameIndex = 0

$script:PortalAnimationImage = New-Object System.Windows.Controls.Image
$script:PortalAnimationImage.Source = $script:PortalFrames[0]
$script:PortalAnimationImage.Stretch = "Fill"
$script:PortalAnimationImage.Width = 120
$script:PortalAnimationImage.Height = 170
$script:PortalAnimationImage.IsHitTestVisible = $false
Add-CanvasChild $script:PortalAnimationImage 580 130

$script:FlameAnimations = @(
    (New-FlameAnimationLayer "assets\flames\flame-left-outer.png" 25 180 78 100 0.0),
    (New-FlameAnimationLayer "assets\flames\flame-left-inner.png" 440 260 58 78 1.7),
    (New-FlameAnimationLayer "assets\flames\flame-right-inner.png" 780 260 58 78 3.4),
    (New-FlameAnimationLayer "assets\flames\flame-right-outer.png" 1175 180 80 100 5.1)
)

$script:PortalAnimationTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:PortalAnimationTimer.Interval = [TimeSpan]::FromMilliseconds(83)
$script:PortalAnimationTimer.Add_Tick({
    $script:PortalFrameIndex = ($script:PortalFrameIndex + 1) % $script:PortalFrames.Count
    $script:PortalAnimationImage.Source = $script:PortalFrames[$script:PortalFrameIndex]

    $phase = (2.0 * [Math]::PI * $script:PortalFrameIndex) / $script:PortalFrames.Count
    foreach ($flame in $script:FlameAnimations) {
        $slowWave = [Math]::Sin(($phase * 2.0) + $flame.PhaseOffset)
        $fastWave = [Math]::Sin(($phase * 5.0) + ($flame.PhaseOffset * 0.7))
        $flame.Image.Opacity = 0.46 + (0.12 * $slowWave) + (0.05 * $fastWave)
        $flame.Scale.ScaleX = 1.0 + (0.018 * $fastWave)
        $flame.Scale.ScaleY = 1.0 + (0.055 * $slowWave) + (0.018 * $fastWave)
        $flame.Translate.Y = -1.4 * $fastWave
    }
})
$script:PortalAnimationTimer.Start()

$title = New-GoldText "IKA GAMING" 62
$title.Width = 800
Add-CanvasChild $title 240 24
$subtitle = New-GoldText "THE BURNING CRUSADE" 21 "#E8D29A"
$subtitle.Width = 600
$subtitle.FontWeight = "Normal"
Add-CanvasChild $subtitle 340 102

$newsRoot = New-Object System.Windows.Controls.Grid
$newsRoot.Width = 535
$newsRoot.Height = 318

$newsFrame = New-Object System.Windows.Controls.Image
$newsFrame.Source = Get-LauncherBitmap "assets\news-panel-frame.png"
$newsFrame.Stretch = "Fill"
$newsFrame.Width = 535
$newsFrame.Height = 318
$newsFrame.IsHitTestVisible = $false
$newsRoot.Children.Add($newsFrame) | Out-Null

$newsTitle = New-GoldText $script:LabelNews 24
$newsTitle.Width = 470
$newsTitle.HorizontalAlignment = "Center"
$newsTitle.VerticalAlignment = "Top"
$newsTitle.Margin = "0,16,0,0"
$newsRoot.Children.Add($newsTitle) | Out-Null

$newsScroll = New-Object System.Windows.Controls.ScrollViewer
$newsScroll.Margin = "26,55,19,26"
$newsScroll.Background = "Transparent"
$newsScroll.BorderThickness = "0"
$newsScroll.HorizontalScrollBarVisibility = "Disabled"
$newsScroll.VerticalScrollBarVisibility = "Visible"
$newsScroll.CanContentScroll = $false
$newsScroll.Resources.Add([System.Windows.Controls.Primitives.ScrollBar], (New-GoldScrollBarStyle))

$newsStack = New-Object System.Windows.Controls.StackPanel
foreach ($entry in @(
    @("SISTEMA IKA REFORGE", "Evolua seus equipamentos e supere seus limites."),
    @($script:LabelHunts, "Complete suas cacadas e conquiste recompensas."),
    @($script:LabelProgress, "Uma jornada justa, duradoura e recompensadora.")
)) {
    $entryBorder = New-Object System.Windows.Controls.Border
    $entryBorder.BorderBrush = "#705B2A"
    $entryBorder.BorderThickness = "0,0,0,1"
    $entryBorder.Padding = "4,8,8,10"
    $entryBorder.Margin = "0,0,2,4"
    $entryStack = New-Object System.Windows.Controls.StackPanel
    $entryTitle = New-Object System.Windows.Controls.TextBlock
    $entryTitle.Text = $entry[0]
    $entryTitle.FontSize = 17
    $entryTitle.FontWeight = "Bold"
    $entryTitle.Foreground = "#F2D37B"
    $entryTitle.Effect = New-TextEffect "Black" 4 0.75
    $entryBody = New-Object System.Windows.Controls.TextBlock
    $entryBody.Text = $entry[1]
    $entryBody.FontSize = 13
    $entryBody.Foreground = "#E7DEC1"
    $entryBody.Margin = "0,4,0,0"
    $entryBody.TextWrapping = "Wrap"
    $entryBody.Effect = New-TextEffect "Black" 3 0.7
    $entryStack.Children.Add($entryTitle) | Out-Null
    $entryStack.Children.Add($entryBody) | Out-Null
    $entryBorder.Child = $entryStack
    $newsStack.Children.Add($entryBorder) | Out-Null
}
$newsScroll.Content = $newsStack
$newsRoot.Children.Add($newsScroll) | Out-Null
Add-CanvasChild $newsRoot 55 325

$script:StatusOnlineBitmap = Get-LauncherBitmap "assets\status-online.png"
$script:StatusOnlineHoverBitmap = Get-LauncherBitmap "assets\status-online-hover.png"
$script:StatusOfflineBitmap = Get-LauncherBitmap "assets\status-offline.png"
$script:IsServerOnline = $false

$statusRoot = New-Object System.Windows.Controls.Grid
$statusRoot.Width = 565
$statusRoot.Height = 120
$statusRoot.ClipToBounds = $false

$script:StatusImage = New-Object System.Windows.Controls.Image
$script:StatusImage.Source = $script:StatusOfflineBitmap
$script:StatusImage.Stretch = "Fill"
$script:StatusImage.Width = 565
$script:StatusImage.Height = 120
$script:StatusImage.IsHitTestVisible = $false
$statusRoot.Children.Add($script:StatusImage) | Out-Null

$statusHitArea = New-Object System.Windows.Controls.Button
$statusHitArea.Width = 565
$statusHitArea.Height = 120
$statusHitArea.Background = "Transparent"
$statusHitArea.BorderThickness = "0"
$statusHitArea.Opacity = 0.01
$statusHitArea.Focusable = $false
$statusHitArea.Cursor = "Arrow"
$statusHitArea.Add_MouseEnter({
    if ($script:IsServerOnline) {
        $script:StatusImage.Source = $script:StatusOnlineHoverBitmap
    }
})
$statusHitArea.Add_MouseLeave({
    if ($script:IsServerOnline) {
        $script:StatusImage.Source = $script:StatusOnlineBitmap
    }
})
$statusRoot.Children.Add($statusHitArea) | Out-Null
Add-CanvasChild $statusRoot 650 322

$playControl = New-ImageButton "JOGAR" "assets\button-main.png" 565 128 48 $true 12 14
Add-CanvasChild $playControl.Root 650 455
$playButton = $playControl.Button
$settingsControl = New-ImageButton $script:LabelSettings "assets\button-secondary.png" 265 46 15 $false 6 6 0.64
Add-CanvasChild $settingsControl.Root 650 597
$settingsButton = $settingsControl.Button
$verifyControl = New-ImageButton "VERIFICAR ARQUIVOS" "assets\button-secondary.png" 285 46 15 $false 6 6 0.64
Add-CanvasChild $verifyControl.Root 930 597
$verifyButton = $verifyControl.Button

$communityControl = New-ImageButton "COMUNIDADE" "assets\button-secondary.png" 155 32 12 $false 3 3 0.64
Add-CanvasChild $communityControl.Root 125 22
$communityButton = $communityControl.Button

$version = New-Object System.Windows.Controls.TextBlock
$version.Text = "Versao $($script:LauncherVersion)"
$version.FontSize = 13
$version.Foreground = "#CDBE91"
Add-CanvasChild $version 55 675

$copyright = New-Object System.Windows.Controls.TextBlock
$copyright.Text = "$([char]0x00A9) 2026 IKA-eSports. Todos os direitos reservados."
$copyright.FontSize = 12
$copyright.Foreground = "#D8C796"
$copyright.Effect = New-TextEffect "Black" 3 0.8
Add-CanvasChild $copyright 155 677

$script:VerifyProgressRoot = New-Object System.Windows.Controls.Grid
$script:VerifyProgressRoot.Width = 500
$script:VerifyProgressRoot.Height = 18

$verifyProgressTrack = New-Object System.Windows.Controls.Border
$verifyProgressTrack.Width = 500
$verifyProgressTrack.Height = 18
$verifyProgressTrack.Background = "#C0070B08"
$verifyProgressTrack.BorderBrush = "#9C7A2A"
$verifyProgressTrack.BorderThickness = "1"
$verifyProgressTrack.CornerRadius = "6"
$script:VerifyProgressRoot.Children.Add($verifyProgressTrack) | Out-Null

$script:VerifyProgressFill = New-Object System.Windows.Controls.Border
$script:VerifyProgressFill.Width = 0
$script:VerifyProgressFill.Height = 14
$script:VerifyProgressFill.HorizontalAlignment = "Left"
$script:VerifyProgressFill.VerticalAlignment = "Center"
$script:VerifyProgressFill.Margin = "2,0,0,0"
$script:VerifyProgressFill.Background = "#126B32"
$script:VerifyProgressFill.CornerRadius = "5"
$script:VerifyProgressFill.Effect = New-TextEffect "#28D05B" 7 0.38
$script:VerifyProgressRoot.Children.Add($script:VerifyProgressFill) | Out-Null

$script:VerifyProgressText = New-Object System.Windows.Controls.TextBlock
$script:VerifyProgressText.Text = "PRONTO PARA VERIFICAR"
$script:VerifyProgressText.FontFamily = "Georgia"
$script:VerifyProgressText.FontSize = 10
$script:VerifyProgressText.FontWeight = "Bold"
$script:VerifyProgressText.Foreground = "#E9D9A4"
$script:VerifyProgressText.HorizontalAlignment = "Center"
$script:VerifyProgressText.VerticalAlignment = "Center"
$script:VerifyProgressText.Effect = New-TextEffect "Black" 3 0.9
$script:VerifyProgressText.IsHitTestVisible = $false
$script:VerifyProgressRoot.Children.Add($script:VerifyProgressText) | Out-Null
Add-CanvasChild $script:VerifyProgressRoot 700 676

$minimizeControl = New-ImageButton "-" "assets\button-compact.png" 42 30 16 $false 0 0
Add-CanvasChild $minimizeControl.Root 1170 18
$minimize = $minimizeControl.Button
$closeControl = New-ImageButton "X" "assets\button-compact.png" 42 30 15 $false 0 0
Add-CanvasChild $closeControl.Root 1218 18
$close = $closeControl.Button
$minimize.Add_Click({ $script:MainWindow.WindowState = "Minimized" })
$close.Add_Click({ $script:MainWindow.Close() })

$script:CommunityDim = New-Object System.Windows.Controls.Border
$script:CommunityDim.Width = 1280
$script:CommunityDim.Height = 720
$script:CommunityDim.Background = "#73000302"
$script:CommunityDim.Visibility = "Collapsed"
Add-CanvasChild $script:CommunityDim 0 0

$script:CommunityDialog = New-Object System.Windows.Controls.Border
$script:CommunityDialog.Width = 560
$script:CommunityDialog.Height = 350
$script:CommunityDialog.Background = "#D9040B06"
$script:CommunityDialog.BorderBrush = "#C89B35"
$script:CommunityDialog.BorderThickness = "2"
$script:CommunityDialog.CornerRadius = "7"
$script:CommunityDialog.Effect = New-TextEffect "#1C8B3D" 18 0.35
$script:CommunityDialog.Visibility = "Collapsed"

$communityCanvas = New-Object System.Windows.Controls.Canvas
$communityCanvas.Width = 560
$communityCanvas.Height = 350
$script:CommunityDialog.Child = $communityCanvas

$communityTitle = New-GoldText "COMUNIDADE" 27
$communityTitle.Width = 560
[System.Windows.Controls.Canvas]::SetLeft($communityTitle, 0)
[System.Windows.Controls.Canvas]::SetTop($communityTitle, 24)
$communityCanvas.Children.Add($communityTitle) | Out-Null

$communitySubtitle = New-Object System.Windows.Controls.TextBlock
$communitySubtitle.Text = "Acompanhe as novidades e entre para a comunidade IKA-eSports."
$communitySubtitle.Width = 520
$communitySubtitle.FontFamily = "Segoe UI"
$communitySubtitle.FontSize = 13
$communitySubtitle.Foreground = "#CFC5A6"
$communitySubtitle.TextAlignment = "Center"
$communitySubtitle.Effect = New-TextEffect "Black" 3 0.8
[System.Windows.Controls.Canvas]::SetLeft($communitySubtitle, 20)
[System.Windows.Controls.Canvas]::SetTop($communitySubtitle, 64)
$communityCanvas.Children.Add($communitySubtitle) | Out-Null

$discordControl = New-CommunityLinkButton "DISCORD" "discord.gg/5XRcna4j9" "assets\icon-discord.png" 470 86
[System.Windows.Controls.Canvas]::SetLeft($discordControl.Root, 45)
[System.Windows.Controls.Canvas]::SetTop($discordControl.Root, 96)
$communityCanvas.Children.Add($discordControl.Root) | Out-Null

$instagramControl = New-CommunityLinkButton "INSTAGRAM" "@go_ika" "assets\icon-instagram.png" 470 86
[System.Windows.Controls.Canvas]::SetLeft($instagramControl.Root, 45)
[System.Windows.Controls.Canvas]::SetTop($instagramControl.Root, 190)
$communityCanvas.Children.Add($instagramControl.Root) | Out-Null

$communityNote = New-Object System.Windows.Controls.TextBlock
$communityNote.Text = "Clique em uma rede social para abrir o canal oficial."
$communityNote.Width = 520
$communityNote.FontFamily = "Segoe UI"
$communityNote.FontSize = 11
$communityNote.Foreground = "#AAA48E"
$communityNote.TextAlignment = "Center"
[System.Windows.Controls.Canvas]::SetLeft($communityNote, 20)
[System.Windows.Controls.Canvas]::SetTop($communityNote, 307)
$communityCanvas.Children.Add($communityNote) | Out-Null

$communityCloseControl = New-ImageButton "X" "assets\button-compact.png" 34 28 13 $false 0 0
[System.Windows.Controls.Canvas]::SetLeft($communityCloseControl.Root, 512)
[System.Windows.Controls.Canvas]::SetTop($communityCloseControl.Root, 13)
$communityCanvas.Children.Add($communityCloseControl.Root) | Out-Null

Add-CanvasChild $script:CommunityDialog 360 185

$script:HideCommunity = {
    $script:CommunityDialog.Visibility = "Collapsed"
    $script:CommunityDim.Visibility = "Collapsed"
}
$script:ShowCommunity = {
    $script:CommunityDim.Visibility = "Visible"
    $script:CommunityDialog.Visibility = "Visible"
}

$communityButton.Add_Click({ & $script:ShowCommunity })
$communityCloseControl.Button.Add_Click({ & $script:HideCommunity })
$script:CommunityDim.Add_MouseLeftButtonDown({ param($sender, $eventArgs)
    & $script:HideCommunity
    $eventArgs.Handled = $true
})
$discordControl.Button.Add_Click({
    try {
        Start-Process -FilePath "https://discord.gg/5XRcna4j9"
    } catch {
        [System.Windows.MessageBox]::Show("Nao foi possivel abrir o Discord.", "IKA Gaming", "OK", "Warning") | Out-Null
    }
})
$instagramControl.Button.Add_Click({
    try {
        Start-Process -FilePath "https://www.instagram.com/go_ika?igsi=dWZtNHJhZnNra3I1"
    } catch {
        [System.Windows.MessageBox]::Show("Nao foi possivel abrir o Instagram.", "IKA Gaming", "OK", "Warning") | Out-Null
    }
})

$canvas.Add_MouseLeftButtonDown({ param($sender, $eventArgs)
    if ($eventArgs.ChangedButton -eq "Left") { $script:MainWindow.DragMove() }
})

function Set-FileVerificationProgress([int]$Percent, [string]$StatusText) {
    $safePercent = [Math]::Max(0, [Math]::Min(100, $Percent))
    $script:VerifyProgressFill.Width = 496 * ($safePercent / 100.0)
    $script:VerifyProgressText.Text = "$StatusText  $safePercent%"
}

function Invoke-UpdateEngine([System.ComponentModel.BackgroundWorker]$Worker) {
    $source = Get-UpdateSource
    if (-not $source.Enabled) {
        return New-Object PSObject -Property @{ State = "Disabled" }
    }

    $Worker.ReportProgress(1, "LENDO MANIFESTO...")
    $manifestLocation = Resolve-UpdateLocation $source.ManifestUrl
    $manifest = (Get-UpdateText $source.ManifestUrl) | ConvertFrom-Json
    if ([int]$manifest.SchemaVersion -ne 1) {
        throw "Versao de manifesto nao suportada. Use SchemaVersion 1."
    }

    $releaseVersion = $(if ($manifest.ReleaseVersion) { [string]$manifest.ReleaseVersion } else { "sem versao" })
    $manifestFiles = @($manifest.Files)
    if ($manifestFiles.Count -eq 0) {
        return New-Object PSObject -Property @{
            State = "NoUpdates"
            ReleaseVersion = $releaseVersion
            UpdatedCount = 0
        }
    }

    $updates = New-Object System.Collections.ArrayList
    $seenTargets = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $totalBytes = [long]0
    $fileNumber = 0
    foreach ($entry in $manifestFiles) {
        $fileNumber++
        $relativePath = [string]$entry.Path
        $scope = ([string]$entry.Scope).ToLowerInvariant()
        $expectedHash = ([string]$entry.Sha256).ToLowerInvariant()
        $expectedSize = [long]$entry.Size
        if ($expectedHash -notmatch '^[a-f0-9]{64}$') {
            throw "SHA-256 invalido no manifesto: $relativePath"
        }
        if ($expectedSize -lt 0) {
            throw "Tamanho invalido no manifesto: $relativePath"
        }

        $targetPath = Get-SafeUpdateTargetPath $scope $relativePath
        if (-not $seenTargets.Add($targetPath)) {
            throw "Arquivo duplicado no manifesto: $relativePath"
        }

        $Worker.ReportProgress(2, "COMPARANDO $fileNumber/$($manifestFiles.Count)...")
        $currentHash = Get-FileSha256 $targetPath
        if ($currentHash -eq $expectedHash) { continue }

        $relativeNormalized = $relativePath.Replace("/", "\").TrimStart("\")
        $fileLocation = Resolve-UpdateLocation ([string]$entry.Url) $manifestLocation
        $null = $updates.Add((New-Object PSObject -Property @{
            Scope = $scope
            RelativePath = $relativeNormalized
            SourceLocation = $fileLocation
            TargetPath = $targetPath
            Sha256 = $expectedHash
            Size = $expectedSize
            StagedPath = ""
        }))
        $totalBytes += $expectedSize
    }

    if ($updates.Count -eq 0) {
        return New-Object PSObject -Property @{
            State = "NoUpdates"
            ReleaseVersion = $releaseVersion
            UpdatedCount = 0
        }
    }

    $stagingRoot = Join-Path $script:UpdateStagingRoot ([Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
    $completedBytes = [long]0

    try {
        foreach ($item in $updates) {
            $item.StagedPath = Join-Path $stagingRoot (Join-Path $item.Scope $item.RelativePath)
            $statusName = [System.IO.Path]::GetFileName($item.RelativePath).ToUpperInvariant()
            Copy-UpdateStream $item.SourceLocation $item.StagedPath $Worker $completedBytes $totalBytes "BAIXANDO $statusName..."

            $downloadedFile = Get-Item -LiteralPath $item.StagedPath
            if ($item.Size -gt 0 -and $downloadedFile.Length -ne $item.Size) {
                throw "Tamanho incorreto apos o download: $($item.RelativePath)"
            }
            $downloadedHash = Get-FileSha256 $item.StagedPath
            if ($downloadedHash -ne $item.Sha256) {
                throw "Falha na verificacao SHA-256: $($item.RelativePath)"
            }
            $completedBytes += $downloadedFile.Length
        }

        $backupRoot = Join-Path $script:UpdateBackupRoot (Get-Date -Format "yyyyMMdd-HHmmss")
        $applied = New-Object System.Collections.ArrayList
        try {
            $applyIndex = 0
            foreach ($item in $updates) {
                $applyIndex++
                $applyPercent = 95 + [int][Math]::Floor(($applyIndex * 4.0) / $updates.Count)
                $Worker.ReportProgress($applyPercent, "APLICANDO ARQUIVOS...")

                $backupPath = Join-Path $backupRoot (Join-Path $item.Scope $item.RelativePath)
                $targetExisted = Test-Path -LiteralPath $item.TargetPath -PathType Leaf
                if ($targetExisted) {
                    $backupParent = Split-Path -Parent $backupPath
                    if (-not (Test-Path -LiteralPath $backupParent -PathType Container)) {
                        New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
                    }
                    Copy-Item -LiteralPath $item.TargetPath -Destination $backupPath -Force
                }

                $targetParent = Split-Path -Parent $item.TargetPath
                if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
                    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                }
                [System.IO.File]::Copy($item.StagedPath, $item.TargetPath, $true)
                $null = $applied.Add((New-Object PSObject -Property @{
                    TargetPath = $item.TargetPath
                    BackupPath = $backupPath
                    Existed = $targetExisted
                }))
            }
        } catch {
            for ($index = $applied.Count - 1; $index -ge 0; $index--) {
                $appliedItem = $applied[$index]
                if ($appliedItem.Existed -and (Test-Path -LiteralPath $appliedItem.BackupPath -PathType Leaf)) {
                    [System.IO.File]::Copy($appliedItem.BackupPath, $appliedItem.TargetPath, $true)
                } elseif (Test-Path -LiteralPath $appliedItem.TargetPath -PathType Leaf) {
                    Remove-Item -LiteralPath $appliedItem.TargetPath -Force
                }
            }
            throw
        }

        $requiresRestart = @($updates | Where-Object { $_.Scope -eq "launcher" }).Count -gt 0
        return New-Object PSObject -Property @{
            State = "Updated"
            ReleaseVersion = $releaseVersion
            UpdatedCount = $updates.Count
            BackupPath = $backupRoot
            RequiresRestart = $requiresRestart
        }
    } finally {
        if (Test-Path -LiteralPath $stagingRoot -PathType Container) {
            Remove-Item -LiteralPath $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Clear-UpdateRuntime {
    if ($script:UpdatePollTimer) {
        $script:UpdatePollTimer.Stop()
    }
    if ($script:UpdatePowerShell) {
        $script:UpdatePowerShell.Dispose()
        $script:UpdatePowerShell = $null
    }
    if ($script:UpdateRunspace) {
        $script:UpdateRunspace.Close()
        $script:UpdateRunspace.Dispose()
        $script:UpdateRunspace = $null
    }
    $script:UpdateAsyncResult = $null
}

function Complete-UpdateCheck {
    $result = $null
    $errorMessage = ""
    try {
        if ($script:UpdatePowerShell -and $script:UpdateAsyncResult) {
            $null = $script:UpdatePowerShell.EndInvoke($script:UpdateAsyncResult)
        }
        if ($script:UpdateState) {
            $result = $script:UpdateState.Result
            $errorMessage = [string]$script:UpdateState.ErrorMessage
        }
    } catch {
        $errorMessage = $_.Exception.Message
    } finally {
        Clear-UpdateRuntime
    }

    $playButton.IsEnabled = $true
    $settingsButton.IsEnabled = $true
    $verifyButton.IsEnabled = $true
    $communityButton.IsEnabled = $true

    if ($script:UpdateState -and $script:UpdateState.CancelRequested) {
        Set-FileVerificationProgress 0 "ATUALIZACAO CANCELADA"
        return
    }
    if (-not [string]::IsNullOrWhiteSpace($errorMessage)) {
        Set-FileVerificationProgress 0 "FALHA NA ATUALIZACAO"
        [System.Windows.MessageBox]::Show(
            "A atualizacao nao foi aplicada.`n`n$errorMessage",
            "Atualizador IKA Gaming",
            "OK",
            "Error") | Out-Null
        return
    }

    if (-not $result) {
        Set-FileVerificationProgress 0 "FALHA NA ATUALIZACAO"
        [System.Windows.MessageBox]::Show(
            "A atualizacao nao retornou um resultado valido.",
            "Atualizador IKA Gaming",
            "OK",
            "Error") | Out-Null
        return
    }

    switch ($result.State) {
        "Disabled" {
            Set-FileVerificationProgress 0 "PRONTO PARA VERIFICAR"
        }
        "NoUpdates" {
            Set-FileVerificationProgress 100 "ARQUIVOS ATUALIZADOS"
        }
        "Updated" {
            Set-FileVerificationProgress 100 "ATUALIZACAO CONCLUIDA"
            $restartMessage = $(if ($result.RequiresRestart) { "`n`nFeche e abra novamente o launcher para carregar os novos recursos." } else { "" })
            [System.Windows.MessageBox]::Show(
                "$($result.UpdatedCount) arquivo(s) atualizado(s) para a versao $($result.ReleaseVersion).$restartMessage",
                "Atualizador IKA Gaming",
                "OK",
                "Information") | Out-Null
        }
    }
}

$script:UpdatePollTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:UpdatePollTimer.Interval = [TimeSpan]::FromMilliseconds(80)
$script:UpdatePollTimer.Add_Tick({
    if ($script:UpdateState) {
        $progress = [int]$script:UpdateState.Progress
        $statusText = [string]$script:UpdateState.StatusText
        if ([string]::IsNullOrWhiteSpace($statusText)) { $statusText = "ATUALIZANDO..." }
        Set-FileVerificationProgress $progress $statusText
    }

    if ($script:UpdateAsyncResult -and $script:UpdateAsyncResult.IsCompleted) {
        Complete-UpdateCheck
    }
})

function Start-UpdateCheck {
    try {
        $source = Get-UpdateSource
        if (-not $source.Enabled) {
            Set-FileVerificationProgress 0 "PRONTO PARA VERIFICAR"
            return
        }
    } catch {
        Set-FileVerificationProgress 0 "FONTE DE ATUALIZACAO INVALIDA"
        [System.Windows.MessageBox]::Show($_.Exception.Message, "Atualizador IKA Gaming", "OK", "Warning") | Out-Null
        return
    }

    if ($script:UpdateAsyncResult -and -not $script:UpdateAsyncResult.IsCompleted) { return }
    if (-not (Test-Path -LiteralPath $script:UpdaterWorkerPath -PathType Leaf)) {
        Set-FileVerificationProgress 0 "MOTOR DE ATUALIZACAO AUSENTE"
        [System.Windows.MessageBox]::Show(
            "O arquivo IKA-UpdaterWorker.ps1 nao foi encontrado.",
            "Atualizador IKA Gaming",
            "OK",
            "Error") | Out-Null
        return
    }

    $playButton.IsEnabled = $false
    $settingsButton.IsEnabled = $false
    $verifyButton.IsEnabled = $false
    $communityButton.IsEnabled = $false
    Set-FileVerificationProgress 0 "VERIFICANDO ATUALIZACOES..."

    try {
        $script:UpdateState = [hashtable]::Synchronized(@{
            Progress = 0
            StatusText = "VERIFICANDO ATUALIZACOES..."
            Result = $null
            ErrorMessage = ""
            Completed = $false
            CancelRequested = $false
        })

        $script:UpdateRunspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $script:UpdateRunspace.ApartmentState = "MTA"
        $script:UpdateRunspace.ThreadOptions = "ReuseThread"
        $script:UpdateRunspace.Open()

        $script:UpdatePowerShell = [System.Management.Automation.PowerShell]::Create()
        $script:UpdatePowerShell.Runspace = $script:UpdateRunspace
        $null = $script:UpdatePowerShell.AddCommand($script:UpdaterWorkerPath)
        $null = $script:UpdatePowerShell.AddParameter("LauncherDir", $script:LauncherDir)
        $null = $script:UpdatePowerShell.AddParameter("ClientDir", $script:Config.ClientPath)
        $null = $script:UpdatePowerShell.AddParameter("LauncherVersion", $script:LauncherVersion)
        $null = $script:UpdatePowerShell.AddParameter("UpdateSourcePath", $script:UpdateSourcePath)
        $null = $script:UpdatePowerShell.AddParameter("UpdateStagingRoot", $script:UpdateStagingRoot)
        $null = $script:UpdatePowerShell.AddParameter("UpdateBackupRoot", $script:UpdateBackupRoot)
        $null = $script:UpdatePowerShell.AddParameter("SharedState", $script:UpdateState)
        $script:UpdateAsyncResult = $script:UpdatePowerShell.BeginInvoke()
        $script:UpdatePollTimer.Start()
    } catch {
        Clear-UpdateRuntime
        $playButton.IsEnabled = $true
        $settingsButton.IsEnabled = $true
        $verifyButton.IsEnabled = $true
        $communityButton.IsEnabled = $true
        Set-FileVerificationProgress 0 "FALHA NA ATUALIZACAO"
        [System.Windows.MessageBox]::Show(
            "Nao foi possivel iniciar o motor de atualizacao.`n`n$($_.Exception.Message)",
            "Atualizador IKA Gaming",
            "OK",
            "Error") | Out-Null
    }
}

function Complete-FileVerification {
    $script:FileVerificationTimer.Stop()
    $playButton.IsEnabled = $true
    $settingsButton.IsEnabled = $true
    $verifyButton.IsEnabled = $true
    $communityButton.IsEnabled = $true
    Set-FileVerificationProgress 100 "VERIFICACAO CONCLUIDA"

    $realmFiles = @(Get-RealmlistTargets)
    $realmDisplay = $realmFiles -join "`n"
    $message = @"
Wow.exe: $(if ($script:VerifyWowOk) { 'OK' } else { 'NAO ENCONTRADO' })
Pasta Data: $(if ($script:VerifyDataOk) { 'OK' } else { 'NAO ENCONTRADA' })
Pasta Interface: $(if ($script:VerifyInterfaceOk) { 'OK' } else { 'NAO ENCONTRADA' })

Arquivos catalogados: $($script:VerifyFiles.Count)
Arquivos vazios encontrados: $($script:VerifyEmptyFiles)
Arquivos inacessiveis: $($script:VerifyUnreadableFiles)

Realmlist usado:
$realmDisplay

Esta verificacao confere a estrutura e nao modifica arquivos MPQ.
"@
    [System.Windows.MessageBox]::Show($message, $script:LabelVerification, "OK", "Information") | Out-Null
}

$script:FileVerificationTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:FileVerificationTimer.Interval = [TimeSpan]::FromMilliseconds(25)
$script:FileVerificationTimer.Add_Tick({
    if (-not $script:VerifyFiles -or $script:VerifyFiles.Count -eq 0) {
        Complete-FileVerification
        return
    }

    $endIndex = [Math]::Min(
        $script:VerifyIndex + $script:VerifyBatchSize,
        $script:VerifyFiles.Count
    )
    while ($script:VerifyIndex -lt $endIndex) {
        $currentFile = $script:VerifyFiles[$script:VerifyIndex]
        try {
            if ($currentFile.Length -eq 0) {
                $script:VerifyEmptyFiles++
            }
        } catch {
            $script:VerifyUnreadableFiles++
        }
        $script:VerifyIndex++
    }

    $percent = [int][Math]::Floor(($script:VerifyIndex * 100.0) / $script:VerifyFiles.Count)
    Set-FileVerificationProgress $percent "VERIFICANDO ARQUIVOS..."
    if ($script:VerifyIndex -ge $script:VerifyFiles.Count) {
        Complete-FileVerification
    }
})

function Start-FileVerification {
    if ($script:UpdateAsyncResult -and -not $script:UpdateAsyncResult.IsCompleted) {
        [System.Windows.MessageBox]::Show(
            "Aguarde a verificacao de atualizacoes terminar.",
            $script:LabelVerification,
            "OK",
            "Information") | Out-Null
        return
    }

    if (-not (Test-Path -LiteralPath $script:Config.ClientPath -PathType Container)) {
        [System.Windows.MessageBox]::Show(
            "Pasta do cliente WoW nao encontrada. Abra as configuracoes e selecione a pasta correta.",
            $script:LabelVerification,
            "OK",
            "Warning") | Out-Null
        return
    }

    $playButton.IsEnabled = $false
    $settingsButton.IsEnabled = $false
    $verifyButton.IsEnabled = $false
    $communityButton.IsEnabled = $false
    Set-FileVerificationProgress 0 "PREPARANDO LISTA..."

    try {
        $script:VerifyWowOk = Test-Path -LiteralPath (Get-WowExecutable) -PathType Leaf
        $script:VerifyDataOk = Test-Path -LiteralPath (Join-Path $script:Config.ClientPath "Data") -PathType Container
        $script:VerifyInterfaceOk = Test-Path -LiteralPath (Join-Path $script:Config.ClientPath "Interface") -PathType Container
        $script:VerifyFiles = @(Get-ChildItem -LiteralPath $script:Config.ClientPath -File -Recurse -Force -ErrorAction SilentlyContinue)
        $script:VerifyIndex = 0
        $script:VerifyEmptyFiles = 0
        $script:VerifyUnreadableFiles = 0
        $script:VerifyBatchSize = [Math]::Max(1, [Math]::Ceiling($script:VerifyFiles.Count / 100.0))
        $script:FileVerificationTimer.Start()
    } catch {
        $playButton.IsEnabled = $true
        $settingsButton.IsEnabled = $true
        $verifyButton.IsEnabled = $true
        $communityButton.IsEnabled = $true
        Set-FileVerificationProgress 0 "FALHA NA VERIFICACAO"
        [System.Windows.MessageBox]::Show(
            $_.Exception.Message,
            $script:LabelVerification,
            "OK",
            "Error") | Out-Null
    }
}

$playButton.Add_Click({
    try {
        $wow = Get-WowExecutable
        if (-not (Test-Path -LiteralPath $wow -PathType Leaf)) {
            [System.Windows.MessageBox]::Show("Wow.exe nao encontrado. Abra as configuracoes e selecione a pasta correta.", "IKA Gaming", "OK", "Warning") | Out-Null
            return
        }
        Set-GameRealmlist
        Start-Process -FilePath $wow -WorkingDirectory $script:Config.ClientPath
        $script:MainWindow.Close()
    } catch {
        [System.Windows.MessageBox]::Show($_.Exception.Message, "IKA Gaming", "OK", "Error") | Out-Null
    }
})

$settingsButton.Add_Click({ Show-SettingsWindow })
$verifyButton.Add_Click({
    Start-FileVerification
})

$script:MainWindow.Content = $canvas
$script:MainWindow.Add_ContentRendered({
    try {
        if (Install-PendingLoadScreens) {
            [System.Windows.MessageBox]::Show(
                "IKA LoadScreens v0.6 instalada automaticamente com sucesso.",
                "IKA Gaming Launcher",
                "OK",
                "Information") | Out-Null
        }
    } catch {
        [System.Windows.MessageBox]::Show(
            "As LoadScreens nao foram instaladas. Os arquivos anteriores foram preservados.`n`n$($_.Exception.Message)",
            "IKA Gaming Launcher",
            "OK",
            "Error") | Out-Null
    }
    Update-ServerStatus
    Start-UpdateCheck
})
$script:MainWindow.Add_Closed({
    if ($script:PortalAnimationTimer) {
        $script:PortalAnimationTimer.Stop()
    }
    if ($script:FileVerificationTimer) {
        $script:FileVerificationTimer.Stop()
    }
    if ($script:UpdatePollTimer) {
        $script:UpdatePollTimer.Stop()
    }
    if ($script:UpdateState) {
        $script:UpdateState.CancelRequested = $true
    }
    if ($script:UpdatePowerShell -and $script:UpdateAsyncResult -and -not $script:UpdateAsyncResult.IsCompleted) {
        $script:UpdatePowerShell.Stop()
    }
    Clear-UpdateRuntime
})
$script:MainWindow.ShowDialog() | Out-Null
