@ECHO OFF
ECHO ��װģ���ļ�
go-bindata -pkg main -o ./bindata.go assets/tpl/
ECHO.
ECHO ����
go build -v
ECHO.
ECHO ��װ
MOVE /Y go-mygen.exe C:\Users\xieyicai\go\bin\
ECHO.
ECHO ����
RD /S /Q output
"D:\Program Files\Windows Resource Kits\sleep.exe" 1
go-mygen -h 192.168.60.230 -P 4000 -u logistics -p logistics -d logistics

PAUSE
