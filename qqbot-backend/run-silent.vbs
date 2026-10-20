' Launch the QQ Bot console without showing a black console window.
' Called by console.bat when started with the -silent flag.
Option Explicit

Dim fso, sh, base, target
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")

base = fso.GetParentFolderName(WScript.ScriptFullName)
target = fso.BuildPath(base, "console.bat")

' 0 = hidden window, False = do not wait for it to finish
sh.Run """" & target & """ -NoBrowser", 0, False
