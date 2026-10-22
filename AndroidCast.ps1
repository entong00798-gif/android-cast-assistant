# Neo7 投屏助手 - Windows PowerShell 5.1+
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$Runtime = Join-Path $env:LOCALAPPDATA 'Neo7Cast\scrcpy'
$Form = New-Object Windows.Forms.Form
$Form.Text = 'Android 手机投屏助手'
$Form.StartPosition = 'CenterScreen'
$Form.Size = New-Object Drawing.Size(520, 475)
$Form.MinimumSize = New-Object Drawing.Size(520, 475)
$Form.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)
$Form.BackColor = [Drawing.Color]::FromArgb(246,248,251)
$title = New-Object Windows.Forms.Label
$title.Text = 'Android 手机投屏 · USB 连接'
$title.Font = New-Object Drawing.Font('Microsoft YaHei UI', 16, [Drawing.FontStyle]::Bold)
$title.ForeColor = [Drawing.Color]::FromArgb(32,48,70)
$title.Location = New-Object Drawing.Point(24,20); $title.Size = New-Object Drawing.Size(450,34)
$Form.Controls.Add($title)
$desc = New-Object Windows.Forms.Label
$desc.Text = '通过 USB 连接支持 ADB 调试的 Android 手机和平板，并在电脑上显示和操作。'
$desc.Location = New-Object Drawing.Point(26,62); $desc.Size = New-Object Drawing.Size(455,42)
$Form.Controls.Add($desc)
$status = New-Object Windows.Forms.Label
$status.Text = '状态：正在检查组件…'; $status.Location = New-Object Drawing.Point(26,113); $status.Size = New-Object Drawing.Size(455,26)
$status.ForeColor = [Drawing.Color]::FromArgb(36,91,154); $Form.Controls.Add($status)
$devices = New-Object Windows.Forms.ListBox
$devices.Location = New-Object Drawing.Point(26,145); $devices.Size = New-Object Drawing.Size(450,55)
$devices.Font = New-Object Drawing.Font('Consolas', 10); $Form.Controls.Add($devices)
function Get-ScrcpyPath { $p = Get-ChildItem -LiteralPath $Runtime -Filter 'scrcpy.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1; if ($p) { return $p.FullName }; return $null }
function Ensure-Scrcpy {
  $found = Get-ScrcpyPath; if ($found) { return $found }
  $status.Text = '状态：首次准备运行组件（从官方 GitHub 下载）…'; $Form.Refresh()
  $api = Invoke-RestMethod -Uri 'https://api.github.com/repos/Genymobile/scrcpy/releases/latest' -Headers @{ 'User-Agent'='Neo7Cast' }
  $asset = $api.assets | Where-Object { $_.name -match '^scrcpy-win64-v.*\.zip$' } | Select-Object -First 1
  if (-not $asset) { throw '未找到官方 Windows 64 位压缩包。请稍后重试。' }
  New-Item -ItemType Directory -Path $Runtime -Force | Out-Null
  $zip = Join-Path $env:TEMP 'neo7cast-scrcpy.zip'
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -Headers @{ 'User-Agent'='Neo7Cast' }
  Expand-Archive -LiteralPath $zip -DestinationPath $Runtime -Force
  Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
  $found = Get-ScrcpyPath; if (-not $found) { throw '官方压缩包已解压，但没有找到 scrcpy.exe。' }; return $found
}
function Get-AdbPath { $p = Get-ChildItem -LiteralPath $Runtime -Filter 'adb.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1; if ($p) { return $p.FullName }; return $null }
function Refresh-Devices {
  try {
    $adb = Get-AdbPath; if (-not $adb) { $null = Ensure-Scrcpy; $adb = Get-AdbPath }
    $raw = & $adb devices 2>&1; $devices.Items.Clear(); $online = @()
    foreach ($line in $raw) {
      if ($line -match '^([^\s]+)\s+(device|unauthorized|offline)$') {
        $serial = $matches[1]; $state = $matches[2]
        if ($serial -notmatch ':\d+$') { [void]$devices.Items.Add(($serial + '    ' + $state)); if ($state -eq 'device') { $online += $serial } }
      }
    }
    if ($online.Count -gt 0) { $status.Text = '状态：已连接 ' + $online.Count + ' 台设备，选中设备后点击开始投屏。' }
    elseif ($devices.Items.Count -gt 0) { $status.Text = '状态：手机已连接，请解锁手机并在弹窗中允许 USB 调试。' }
    else { $status.Text = '状态：未发现设备。请插入支持数据传输的 USB 线并开启 USB 调试。' }
  } catch { $status.Text = '状态：' + $_.Exception.Message }
}
$btnRefresh = New-Object Windows.Forms.Button
$btnRefresh.Text = '刷新设备'; $btnRefresh.Location = New-Object Drawing.Point(26,212); $btnRefresh.Size = New-Object Drawing.Size(130,38)
$btnRefresh.Add_Click({ Refresh-Devices }); $Form.Controls.Add($btnRefresh)
$btnStart = New-Object Windows.Forms.Button
$btnStart.Text = '开始投屏'; $btnStart.Location = New-Object Drawing.Point(170,212); $btnStart.Size = New-Object Drawing.Size(140,38)
$btnStart.BackColor = [Drawing.Color]::FromArgb(38,112,205); $btnStart.ForeColor = [Drawing.Color]::White; $btnStart.FlatStyle = 'Flat'
$btnStart.Add_Click({
  try {
    $scrcpy = Ensure-Scrcpy; $adb = Get-AdbPath; & $adb start-server | Out-Null; $raw = & $adb devices
    $online = @($raw | Where-Object { $_ -match '^([^\s]+)\s+device$' -and ($_ -split '\s+')[0] -notmatch ':\d+$' } | ForEach-Object { ($_ -split '\s+')[0] })
    if ($online.Count -eq 0) { [Windows.Forms.MessageBox]::Show('没有已授权的手机。检查手机屏幕上的 USB 调试授权弹窗，然后点“刷新设备”。','尚未连接') | Out-Null; return }
    $selected = $null; if ($devices.SelectedItem) { $selected = (($devices.SelectedItem.ToString()) -split '\s+')[0] }
    if (-not $selected -or $online -notcontains $selected) { $selected = $online[0] }
    Start-Process -FilePath $scrcpy -ArgumentList @('-s', $selected, '--window-title', 'Android')
    $status.Text = '状态：投屏窗口已启动。关闭窗口即可结束投屏。'
  } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'启动失败') | Out-Null }
}); $Form.Controls.Add($btnStart)
$help = New-Object Windows.Forms.Label
$help.Text = @'
Android 手机设置步骤（菜单名称因品牌和系统版本而异）
1. 设置 → 关于手机 → 连续点击“版本号/软件版本”约 7 次，开启开发者选项。
2. 在系统设置中找到“开发者选项”，开启“USB 调试”。
3. 用支持数据传输的 USB 线连接电脑；解锁手机并允许 USB 调试授权。

兼容范围：Android 5.0 及以上且厂商未禁用 ADB。部分品牌需安装 USB 驱动；受企业策略限制或厂商禁用调试的设备无法连接。
'@
$help.Location = New-Object Drawing.Point(26,270); $help.Size = New-Object Drawing.Size(450,155)
$help.ForeColor = [Drawing.Color]::FromArgb(75,83,96); $Form.Controls.Add($help)
$Form.Add_Shown({ try { $null = Ensure-Scrcpy; Refresh-Devices } catch { $status.Text = '状态：组件下载失败。请检查网络后点“刷新设备”重试。' } })
[void]$Form.ShowDialog()

