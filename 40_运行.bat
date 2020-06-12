@echo off
RD /S /Q output
@rem go-mygen -h 192.168.60.231 -P 3306 -u idea_home -p decorate -d idea_home
go-mygen -h 192.168.60.230 -P 4000 -u logistics -p logistics -d logistics
pause