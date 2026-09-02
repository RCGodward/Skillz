@echo off
rem Copy a skill from this repo into a client repo (or into %USERPROFILE%\.claude\skills).
rem   install.bat <skill> <target-repo>
rem   install.bat <skill> --user
rem Windows counterpart of install.sh. Run from cmd.exe or PowerShell.

setlocal

set "src_root=%~dp0"
if "%src_root:~-1%"=="\" set "src_root=%src_root:~0,-1%"

set "skill=%~1"
set "target=%~2"

if "%skill%"=="" goto usage
if "%target%"=="" goto usage

set "src=%src_root%\%skill%"
if not exist "%src%\SKILL.md" (
  echo no such skill: %skill% 1>&2
  goto usage
)

rem Branch with labels rather than an if/else block: a variable set inside a
rem parenthesised block is not visible to the rest of that block without
rem delayed expansion, and "target" is edited before it is used.
if /i "%target%"=="--user" goto user_dest

if "%target:~-1%"=="\" set "target=%target:~0,-1%"
if not exist "%target%\" goto no_dir
set "dest=%target%\.claude\skills\%skill%"
goto have_dest

:user_dest
set "dest=%USERPROFILE%\.claude\skills\%skill%"

:have_dest
for %%p in ("%dest%") do set "dest_parent=%%~dpp"
if not exist "%dest_parent%" mkdir "%dest_parent%"
if exist "%dest%" rmdir /s /q "%dest%"

xcopy "%src%" "%dest%\" /E /I /Q /Y /H >nul
if errorlevel 1 (
  echo copy failed: %src% -^> %dest% 1>&2
  exit /b 1
)

rem Eval fixtures are for developing the skill, not for the repo it is installed into.
if exist "%dest%\evals" rmdir /s /q "%dest%\evals"

echo installed %skill% -^> %dest%
exit /b 0

:no_dir
echo no such directory: %target% 1>&2
exit /b 1

:usage
echo usage: install.bat ^<skill^> ^<target-repo^|--user^>
echo skills:
for /d %%d in ("%src_root%\*") do if exist "%%d\SKILL.md" echo    %%~nxd
exit /b 1
