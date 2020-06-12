@ECHO OFF
ECHO 封装模板文件
go-bindata -pkg main -o ./bindata.go assets/tpl/
ECHO.
ECHO 编译
go build -v
ECHO.
ECHO 安装
MOVE /Y go-mygen.exe C:\Users\xieyicai\go\bin\
ECHO.
ECHO 运行
RD /S /Q output
"D:\Program Files\Windows Resource Kits\sleep.exe" 1
go-mygen -h 192.168.60.230 -P 4000 -u logistics -p logistics -d logistics

PAUSE
