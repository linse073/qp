@echo off
echo - start
set DIR=%~dp0
start /B /WAIT /D %DIR% lua sprotodump.lua %DIR%../..
echo - finish
pause