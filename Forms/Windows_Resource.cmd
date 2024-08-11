@ECHO OFF
rem Start windres -i Cursors.rc -o Cursors.res
rem "C:\(Act)\Compile\CB\MinGW\bin\windres.exe" -i Cursors.rc -o Cursors.res
set path=C:\(Act)\Compile\CB\MinGW\bin;%Path% 
path
windres.exe -i Cursors.rc -o Cursors.res


