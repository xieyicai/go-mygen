@echo off
RD /S /Q output
go-mygen -h 192.168.60.230 -P 4000 -u logistics -p logistics -d logistics
pause