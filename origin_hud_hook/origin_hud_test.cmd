@set @x=0 /* 
@echo off
cd cstrike/sprites
del hud.txt
rename origin_hud.txt hud.txt
cd cstrike_russian/sprites
del hud.txt
rename origin_hud.txt hud.txt
goto:eof */ if(isFinite(WScript.Arguments(0))) WScript.Sleep(WScript.Arguments(0))