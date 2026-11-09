@echo off
chcp 65001 >nul
setlocal
set "DLK_SELF=%~f0"
set "DLK_DIR=%LOCALAPPDATA%\DeadlockDiskKeepalive"
if /i "%~nx0"=="Remove-DeadlockDiskKeepalive.bat" goto remove
if /i "%~1"=="--watch" goto watch
if /i "%~1"=="--test" goto test
if /i "%~1"=="--remove" goto remove
if not exist "%DLK_DIR%" mkdir "%DLK_DIR%"
if errorlevel 1 goto fail
if /i not "%DLK_SELF%"=="%DLK_DIR%\DeadlockDiskKeepalive.bat" copy /y "%DLK_SELF%" "%DLK_DIR%\DeadlockDiskKeepalive.bat" >nul
if errorlevel 1 goto fail
copy /y "%DLK_DIR%\DeadlockDiskKeepalive.bat" "%DLK_DIR%\Remove-DeadlockDiskKeepalive.bat" >nul
if errorlevel 1 goto fail
set "DLK_LINK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Deadlock Disk Keepalive.lnk"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$w=New-Object -ComObject WScript.Shell;$s=$w.CreateShortcut($env:DLK_LINK);$s.TargetPath=$env:ComSpec;$q=[char]34;$s.Arguments='/c '+$q+$q+$env:DLK_DIR+'\DeadlockDiskKeepalive.bat'+$q+' --watch'+$q;$s.WorkingDirectory=$env:DLK_DIR;$s.WindowStyle=7;$s.Save()"
if errorlevel 1 goto fail
start "" /min "%COMSPEC%" /c ""%DLK_DIR%\DeadlockDiskKeepalive.bat" --watch"
echo Готово! Фоновое чтение включится при запуске Deadlock и остановится после выхода из игры.
echo Done! Background reading starts with Deadlock and stops when you exit the game.
echo Чтобы отключить функцию, запустите Remove-DeadlockDiskKeepalive.bat в папке %DLK_DIR%.
echo To disable it, run Remove-DeadlockDiskKeepalive.bat in %DLK_DIR%.
echo Нажмите любую клавишу, чтобы закрыть окно. / Press any key to close this window.
pause >nul
exit /b 0
:test
set "DLK_TEST=1"
goto watch
:watch
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$s=[IO.File]::ReadAllText($env:DLK_SELF);$m='# POWERSHELL_PAYLOAD_BEGIN';$i=$s.LastIndexOf($m);if($i -lt 0){exit 2};Invoke-Expression $s.Substring($i+$m.Length)"
exit /b %errorlevel%
:remove
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:LOCALAPPDATA 'DeadlockDiskKeepalive\stop.flag';New-Item -ItemType Directory -Path (Split-Path $p) -Force | Out-Null;New-Item -ItemType File -Path $p -Force | Out-Null;$l=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\Deadlock Disk Keepalive.lnk';Remove-Item -LiteralPath $l -ErrorAction SilentlyContinue"
echo Функция отключена. Фоновое чтение остановится в течение нескольких секунд.
echo Disabled. Background reading will stop within a few seconds.
echo Нажмите любую клавишу, чтобы закрыть окно. / Press any key to close this window.
pause >nul
exit /b 0
:fail
echo Не удалось выполнить установку. Проверьте сообщения об ошибках выше.
echo Installation failed. Check the error messages above.
echo Нажмите любую клавишу, чтобы закрыть окно. / Press any key to close this window.
pause >nul
exit /b 1
# POWERSHELL_PAYLOAD_BEGIN
$ErrorActionPreference='Stop'
$dir=Join-Path $env:LOCALAPPDATA 'DeadlockDiskKeepalive'
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$log=Join-Path $dir 'keepalive.log'
$stop=Join-Path $dir 'stop.flag'
$mutex=[Threading.Mutex]::new($false,'Local\DeadlockDiskKeepaliveFriend')
$held=$false
try {
 try { $held=$mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $held=$true }
 if(!$held){exit 0}
 Remove-Item -LiteralPath $stop -ErrorAction SilentlyContinue
 Add-Type -TypeDefinition '
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public sealed class DiskReader : IDisposable {
 [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
 static extern SafeFileHandle CreateFile(string path,uint access,uint share,IntPtr security,uint creation,uint flags,IntPtr template);
 [DllImport("kernel32.dll", SetLastError=true)]
 static extern IntPtr VirtualAlloc(IntPtr address,UIntPtr size,uint type,uint protection);
 [DllImport("kernel32.dll", SetLastError=true)]
 static extern bool VirtualFree(IntPtr address,UIntPtr size,uint type);
 [DllImport("kernel32.dll", SetLastError=true)]
 static extern bool SetFilePointerEx(SafeFileHandle file,long distance,out long position,uint method);
 [DllImport("kernel32.dll", SetLastError=true)]
 static extern bool ReadFile(SafeFileHandle file,IntPtr buffer,uint size,out uint bytes,IntPtr overlapped);
 readonly SafeFileHandle file;
 readonly IntPtr buffer;
 public DiskReader(string path) {
  file=CreateFile(path,0x80000000,7,IntPtr.Zero,3,0x30000000,IntPtr.Zero);
  if(file.IsInvalid) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
  buffer=VirtualAlloc(IntPtr.Zero,(UIntPtr)4096,0x3000,4);
  if(buffer==IntPtr.Zero){file.Dispose();throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());}
 }
 public void Read() {
  long position;uint count;
  if(!SetFilePointerEx(file,0,out position,0)||!ReadFile(file,buffer,4096,out count,IntPtr.Zero))
   throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
  if(count!=4096) throw new Exception("Short read");
 }
 public void Dispose(){file.Dispose();VirtualFree(buffer,UIntPtr.Zero,0x8000);}
}'
 $reader=$null
 $activePath=$null
 $test=$env:DLK_TEST -eq '1'
 $end=if($test){[DateTime]::Now.AddSeconds(8)}else{[DateTime]::MaxValue}
 $deadline=[DateTime]::MinValue
 $reads=0
 try {
  while([DateTime]::Now -lt $end -and !(Test-Path -LiteralPath $stop)) {
   if([DateTime]::Now -ge $deadline) {
    $deadline=[DateTime]::Now.AddSeconds(2)
    if($test){$game=Get-Process -Name steam -ErrorAction SilentlyContinue | Select-Object -First 1}
    else{$game=Get-Process -Name deadlock -ErrorAction SilentlyContinue | Select-Object -First 1}
    $gamePath=if($game){try{$game.Path}catch{$null}}else{$null}
    if($gamePath -ne $activePath) {
     if($reader){$reader.Dispose();$reader=$null;Add-Content $log "$(Get-Date -Format o) stopped reads=$reads";$reads=0}
     $activePath=$gamePath
     if($activePath){$reader=[DiskReader]::new($activePath);Add-Content $log "$(Get-Date -Format o) started $activePath"}
    }
   }
   if($reader){$reader.Read();$reads++;Start-Sleep -Milliseconds 50}
   else{Start-Sleep -Milliseconds 500}
  }
 } finally {
  if($reader){$reader.Dispose();Add-Content $log "$(Get-Date -Format o) stopped reads=$reads"}
 }
} catch {
 Add-Content -Path $log -Value "$(Get-Date -Format o) ERROR $($_.Exception.Message)"
 if($env:DLK_TEST -eq '1'){throw}
} finally {
 if($held){$mutex.ReleaseMutex()}
 $mutex.Dispose()
}
