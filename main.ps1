Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$s='[DllImport("user32.dll")][return: MarshalAs(UnmanagedType.Bool)]public static extern bool BlockInput(bool fBlockIt);'
Add-Type -MemberDefinition $s -Name U -Namespace W
[W.U]::BlockInput($true)
sleep 2
[W.U]::BlockInput($false)


(New-Object -ComObject Wscript.Shell).Popup("Hello, this is a pop-up message",5,"Title",0x0)
