# Android Cast Assistant - Liquid Glass UI (Windows PowerShell 5.1+)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

if (-not ('NeoGlassPanel' -as [type])) {
  Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class NeoGlassPanel : Panel
{
    public Color SurfaceColor { get; set; }
    public Color BorderColor { get; set; }
    public int CornerRadius { get; set; }

    public NeoGlassPanel()
    {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint |
            ControlStyles.OptimizedDoubleBuffer | ControlStyles.SupportsTransparentBackColor, true);
        BackColor = Color.Transparent;
        SurfaceColor = Color.FromArgb(150, 37, 52, 76);
        BorderColor = Color.FromArgb(65, 226, 237, 255);
        CornerRadius = 18;
    }

    private GraphicsPath RoundedPath(Rectangle r)
    {
        int d = Math.Min(CornerRadius * 2, Math.Min(r.Width, r.Height));
        GraphicsPath p = new GraphicsPath();
        p.AddArc(r.Left, r.Top, d, d, 180, 90);
        p.AddArc(r.Right - d, r.Top, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        p.AddArc(r.Left, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }

    protected override void OnPaintBackground(PaintEventArgs e)
    {
        base.OnPaintBackground(e);
        if (Width < 4 || Height < 4) return;

        e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
        Rectangle bounds = new Rectangle(0, 0, Width - 1, Height - 1);
        using (GraphicsPath path = RoundedPath(bounds))
        using (SolidBrush fill = new SolidBrush(SurfaceColor))
        using (Pen border = new Pen(BorderColor, 1.0f))
        using (Pen sheen = new Pen(Color.FromArgb(28, Color.White), 1.0f))
        {
            e.Graphics.FillPath(fill, path);
            e.Graphics.DrawPath(border, path);
            e.Graphics.DrawLine(sheen, CornerRadius, 1, Width - CornerRadius, 1);
        }
    }
}

public static class NeoGlassBackdrop
{
    [StructLayout(LayoutKind.Sequential)]
    private struct AccentPolicy
    {
        public int AccentState;
        public int AccentFlags;
        public int GradientColor;
        public int AnimationId;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct CompositionAttributeData
    {
        public int Attribute;
        public IntPtr Data;
        public int SizeOfData;
    }

    [DllImport("user32.dll")]
    private static extern int SetWindowCompositionAttribute(IntPtr hwnd, ref CompositionAttributeData data);

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int value, int size);

    public static void Apply(IntPtr hwnd)
    {
        AccentPolicy policy = new AccentPolicy();
        policy.AccentState = 4;
        policy.AccentFlags = 2;
        policy.GradientColor = unchecked((int)0xC01D2B43);

        int size = Marshal.SizeOf(typeof(AccentPolicy));
        IntPtr pointer = Marshal.AllocHGlobal(size);
        try
        {
            Marshal.StructureToPtr(policy, pointer, false);
            CompositionAttributeData data = new CompositionAttributeData();
            data.Attribute = 19;
            data.Data = pointer;
            data.SizeOfData = size;
            SetWindowCompositionAttribute(hwnd, ref data);
        }
        finally
        {
            Marshal.FreeHGlobal(pointer);
        }

        int cornerPreference = 2;
        DwmSetWindowAttribute(hwnd, 33, ref cornerPreference, sizeof(int));
        int captionColor = 0x002B1D14;
        DwmSetWindowAttribute(hwnd, 35, ref captionColor, sizeof(int));
        int textColor = 0x00F7F4EE;
        DwmSetWindowAttribute(hwnd, 36, ref textColor, sizeof(int));
    }
}
"@
}

$Runtime = Join-Path $env:LOCALAPPDATA 'Neo7Cast\scrcpy'
$Form = New-Object Windows.Forms.Form
$Form.Text = 'Android 手机投屏助手'
$Form.StartPosition = 'CenterScreen'
$Form.Size = New-Object Drawing.Size(600, 690)
$Form.MinimumSize = New-Object Drawing.Size(600, 690)
$Form.MaximumSize = New-Object Drawing.Size(600, 690)
$Form.FormBorderStyle = [Windows.Forms.FormBorderStyle]::FixedSingle
$Form.MaximizeBox = $false
$Form.Font = New-Object Drawing.Font('Microsoft YaHei UI', 9)
$Form.BackColor = [Drawing.Color]::FromArgb(18, 26, 42)
$Form.ForeColor = [Drawing.Color]::FromArgb(239, 244, 255)

$Form.Add_Paint({
  param($sender, $e)
  $g = $e.Graphics
  $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $orbA = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(24, 103, 139, 255))
  $orbB = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(18, 172, 111, 255))
  $g.FillEllipse($orbA, 340, -108, 300, 250)
  $g.FillEllipse($orbB, -118, 420, 280, 260)
  $orbA.Dispose()
  $orbB.Dispose()
})

$badge = New-Object Windows.Forms.Label
$badge.Text = 'CAST'
$badge.Location = New-Object Drawing.Point(26, 27)
$badge.Size = New-Object Drawing.Size(62, 28)
$badge.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$badge.BackColor = [Drawing.Color]::FromArgb(68, 95, 143, 255)
$badge.ForeColor = [Drawing.Color]::FromArgb(220, 233, 255)
$badge.Font = New-Object Drawing.Font('Microsoft YaHei UI', 8, [Drawing.FontStyle]::Bold)
$Form.Controls.Add($badge)

$title = New-Object Windows.Forms.Label
$title.Text = 'Android 投屏助手'
$title.Font = New-Object Drawing.Font('Microsoft YaHei UI', 17, [Drawing.FontStyle]::Bold)
$title.ForeColor = [Drawing.Color]::FromArgb(247, 249, 255)
$title.Location = New-Object Drawing.Point(104, 22)
$title.Size = New-Object Drawing.Size(430, 34)
$title.BackColor = [Drawing.Color]::Transparent
$Form.Controls.Add($title)

$desc = New-Object Windows.Forms.Label
$desc.Text = 'USB 连接 · 在电脑上显示并操作 Android 手机'
$desc.Location = New-Object Drawing.Point(27, 68)
$desc.Size = New-Object Drawing.Size(520, 26)
$desc.ForeColor = [Drawing.Color]::FromArgb(177, 194, 220)
$desc.BackColor = [Drawing.Color]::Transparent
$Form.Controls.Add($desc)

$statusCard = New-Object NeoGlassPanel
$statusCard.Location = New-Object Drawing.Point(24, 110)
$statusCard.Size = New-Object Drawing.Size(536, 58)
$Form.Controls.Add($statusCard)

$status = New-Object Windows.Forms.Label
$status.Text = '状态：正在检查组件…'
$status.Location = New-Object Drawing.Point(20, 16)
$status.Size = New-Object Drawing.Size(494, 26)
$status.ForeColor = [Drawing.Color]::FromArgb(174, 207, 255)
$status.BackColor = [Drawing.Color]::Transparent
$status.AutoEllipsis = $true
$statusCard.Controls.Add($status)

$deviceCard = New-Object NeoGlassPanel
$deviceCard.Location = New-Object Drawing.Point(24, 181)
$deviceCard.Size = New-Object Drawing.Size(536, 158)
$Form.Controls.Add($deviceCard)

$deviceTitle = New-Object Windows.Forms.Label
$deviceTitle.Text = '已连接的 USB 设备'
$deviceTitle.Location = New-Object Drawing.Point(20, 13)
$deviceTitle.Size = New-Object Drawing.Size(310, 25)
$deviceTitle.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10, [Drawing.FontStyle]::Bold)
$deviceTitle.ForeColor = [Drawing.Color]::FromArgb(241, 246, 255)
$deviceTitle.BackColor = [Drawing.Color]::Transparent
$deviceCard.Controls.Add($deviceTitle)

$deviceHint = New-Object Windows.Forms.Label
$deviceHint.Text = 'ADB'
$deviceHint.Location = New-Object Drawing.Point(450, 14)
$deviceHint.Size = New-Object Drawing.Size(58, 22)
$deviceHint.TextAlign = [Drawing.ContentAlignment]::MiddleRight
$deviceHint.ForeColor = [Drawing.Color]::FromArgb(152, 178, 215)
$deviceHint.BackColor = [Drawing.Color]::Transparent
$deviceCard.Controls.Add($deviceHint)

$devices = New-Object Windows.Forms.ListBox
$devices.Location = New-Object Drawing.Point(18, 45)
$devices.Size = New-Object Drawing.Size(500, 96)
$devices.Font = New-Object Drawing.Font('Consolas', 10)
$devices.BackColor = [Drawing.Color]::FromArgb(230, 21, 30, 47)
$devices.ForeColor = [Drawing.Color]::FromArgb(233, 241, 255)
$devices.BorderStyle = [Windows.Forms.BorderStyle]::None
$devices.IntegralHeight = $false
$deviceCard.Controls.Add($devices)

function Get-ScrcpyPath {
  $p = Get-ChildItem -LiteralPath $Runtime -Filter 'scrcpy.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($p) { return $p.FullName }
  return $null
}
function Ensure-Scrcpy {
  $found = Get-ScrcpyPath
  if ($found) { return $found }
  $status.Text = '状态：首次准备运行组件（从官方 GitHub 下载）…'
  $Form.Refresh()
  $api = Invoke-RestMethod -Uri 'https://api.github.com/repos/Genymobile/scrcpy/releases/latest' -Headers @{ 'User-Agent'='Neo7Cast' }
  $asset = $api.assets | Where-Object { $_.name -match '^scrcpy-win64-v.*\.zip$' } | Select-Object -First 1
  if (-not $asset) { throw '未找到官方 Windows 64 位压缩包。请稍后重试。' }
  New-Item -ItemType Directory -Path $Runtime -Force | Out-Null
  $zip = Join-Path $env:TEMP 'neo7cast-scrcpy.zip'
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -Headers @{ 'User-Agent'='Neo7Cast' }
  Expand-Archive -LiteralPath $zip -DestinationPath $Runtime -Force
  Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
  $found = Get-ScrcpyPath
  if (-not $found) { throw '官方压缩包已解压，但没有找到 scrcpy.exe。' }
  return $found
}
function Get-AdbPath {
  $p = Get-ChildItem -LiteralPath $Runtime -Filter 'adb.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($p) { return $p.FullName }
  return $null
}
function Refresh-Devices {
  try {
    $adb = Get-AdbPath
    if (-not $adb) { $null = Ensure-Scrcpy; $adb = Get-AdbPath }
    $raw = & $adb devices 2>&1
    $devices.Items.Clear()
    $online = @()
    foreach ($line in $raw) {
      if ($line -match '^([^\s]+)\s+(device|unauthorized|offline)$') {
        $serial = $matches[1]
        $state = $matches[2]
        if ($serial -notmatch ':\d+$') {
          [void]$devices.Items.Add(($serial + '    ' + $state))
          if ($state -eq 'device') { $online += $serial }
        }
      }
    }
    if ($online.Count -gt 0) {
      $status.Text = '状态：已连接 ' + $online.Count + ' 台设备，选中设备后点击开始投屏。'
    } elseif ($devices.Items.Count -gt 0) {
      $status.Text = '状态：手机已连接，请解锁手机并在弹窗中允许 USB 调试。'
    } else {
      $status.Text = '状态：未发现设备。请插入支持数据传输的 USB 线并开启 USB 调试。'
    }
  } catch {
    $status.Text = '状态：' + $_.Exception.Message
  }
}

$btnRefresh = New-Object Windows.Forms.Button
$btnRefresh.Text = '刷新设备'
$btnRefresh.Location = New-Object Drawing.Point(24, 356)
$btnRefresh.Size = New-Object Drawing.Size(174, 46)
$btnRefresh.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$btnRefresh.FlatAppearance.BorderSize = 1
$btnRefresh.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(105, 137, 185, 246)
$btnRefresh.BackColor = [Drawing.Color]::FromArgb(42, 54, 77)
$btnRefresh.ForeColor = [Drawing.Color]::FromArgb(224, 235, 255)
$btnRefresh.Cursor = [Windows.Forms.Cursors]::Hand
$Form.Controls.Add($btnRefresh)
$btnRefresh.Add_Click({ Refresh-Devices })

$btnStart = New-Object Windows.Forms.Button
$btnStart.Text = '开始投屏'
$btnStart.Location = New-Object Drawing.Point(210, 356)
$btnStart.Size = New-Object Drawing.Size(350, 46)
$btnStart.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$btnStart.FlatAppearance.BorderSize = 0
$btnStart.BackColor = [Drawing.Color]::FromArgb(91, 133, 255)
$btnStart.ForeColor = [Drawing.Color]::White
$btnStart.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10, [Drawing.FontStyle]::Bold)
$btnStart.Cursor = [Windows.Forms.Cursors]::Hand
$Form.Controls.Add($btnStart)
$btnStart.Add_Click({
  try {
    $scrcpy = Ensure-Scrcpy
    $adb = Get-AdbPath
    & $adb start-server | Out-Null
    $raw = & $adb devices
    $online = @($raw | Where-Object { $_ -match '^([^\s]+)\s+device$' -and ($_ -split '\s+')[0] -notmatch ':\d+$' } | ForEach-Object { ($_ -split '\s+')[0] })
    if ($online.Count -eq 0) {
      [Windows.Forms.MessageBox]::Show('没有已授权的手机。检查手机屏幕上的 USB 调试授权弹窗，然后点“刷新设备”。','尚未连接') | Out-Null
      return
    }
    $selected = $null
    if ($devices.SelectedItem) { $selected = (($devices.SelectedItem.ToString()) -split '\s+')[0] }
    if (-not $selected -or $online -notcontains $selected) { $selected = $online[0] }
    Start-Process -FilePath $scrcpy -ArgumentList @('-s', $selected, '--window-title', 'Android')
    $status.Text = '状态：投屏窗口已启动。关闭窗口即可结束投屏。'
  } catch {
    [Windows.Forms.MessageBox]::Show($_.Exception.Message,'启动失败') | Out-Null
  }
})

$helpCard = New-Object NeoGlassPanel
$helpCard.Location = New-Object Drawing.Point(24, 418)
$helpCard.Size = New-Object Drawing.Size(536, 218)
$Form.Controls.Add($helpCard)

$helpTitle = New-Object Windows.Forms.Label
$helpTitle.Text = '连接指南'
$helpTitle.Location = New-Object Drawing.Point(20, 15)
$helpTitle.Size = New-Object Drawing.Size(280, 26)
$helpTitle.Font = New-Object Drawing.Font('Microsoft YaHei UI', 10, [Drawing.FontStyle]::Bold)
$helpTitle.ForeColor = [Drawing.Color]::FromArgb(241, 246, 255)
$helpTitle.BackColor = [Drawing.Color]::Transparent
$helpCard.Controls.Add($helpTitle)

$help = New-Object Windows.Forms.Label
$help.Text = @'
1. 设置 → 关于手机 → 连续点击“版本号/软件版本”约 7 次，开启开发者选项。
2. 在开发者选项中开启“USB 调试”。
3. 用数据线连接手机，解锁并允许 USB 调试授权，然后点“刷新设备”。
4. 选中设备，点击“开始投屏”。若未识别，请更换数据线或安装手机 USB 驱动。

支持 Android 5.0 及以上且允许 ADB 调试的设备；部分厂商可能有限制。
'@
$help.Location = New-Object Drawing.Point(20, 49)
$help.Size = New-Object Drawing.Size(496, 150)
$help.ForeColor = [Drawing.Color]::FromArgb(185, 201, 225)
$help.BackColor = [Drawing.Color]::Transparent
$help.Font = New-Object Drawing.Font('Microsoft YaHei UI', 8.5)
$helpCard.Controls.Add($help)

$Form.Add_Shown({
  try { [NeoGlassBackdrop]::Apply($Form.Handle) } catch {}
  try {
    $null = Ensure-Scrcpy
    Refresh-Devices
  } catch {
    $status.Text = '状态：组件下载失败。请检查网络后点“刷新设备”重试。'
  }
})
[void]$Form.ShowDialog()

