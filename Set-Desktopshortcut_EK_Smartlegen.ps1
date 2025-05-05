$null = $WshShell = New-Object -comObject WScript.Shell
$path = "C:\Users\Public\Desktop\Kvalitetsportalen.url"
$targetpath = "https://smartlegenssykehjem.datakvalitet.net/"
$iconlocation = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$iconfile = "IconFile=" + $iconlocation
$Shortcut = $WshShell.CreateShortcut($path)
$Shortcut.TargetPath = $targetpath
$Shortcut.Save()

Add-Content $path "HotKey=0"
Add-Content $path "$iconfile"
Add-Content $path "IconIndex=0"