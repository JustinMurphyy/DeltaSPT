@echo off
title SPT Fika Friend Pack Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0FRIEND-INSTALL.ps1"
if errorlevel 1 pause

