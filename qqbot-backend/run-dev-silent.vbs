' Launch the QQ Bot DEV console (console-dev.bat) without a black console window.
' Mirrors run-silent.vbs but targets console-dev.bat, which listens on 0.0.0.0
' so the phone on the same Wi-Fi can connect.
Option Explicit

Dim fso, sh, base, target
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")

base = fso.GetParentFolderName(WScript.ScriptFullName)
target = fso.BuildPath(base, "console-dev.bat")

' 0 = hidden window, False = do not wait for it to finish
sh.Run """" & target & """ -silent", 0, False
