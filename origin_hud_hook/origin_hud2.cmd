@set @x=0 /* 
@echo off
chcp 866
TITLE "THE ORIGIN"
cd cstrike 
copy hud.txt .\sprites\hud.txt
cd ..
cd cstrike_russian
copy hud.txt .\sprites\hud.txt
cls
COLOR fc
echo Zombie-mod.ru
echo The Origin CSO zombie mod
echo.
echo.
echo. Заменён файл hud.txt
echo. Напишите в консоли "_restart" без кавычек.
echo. И установка завершена!
echo.
pause
TIMEOUT 3
*/ if(isFinite(WScript.Arguments(0))) WScript.Sleep(WScript.Arguments(0))