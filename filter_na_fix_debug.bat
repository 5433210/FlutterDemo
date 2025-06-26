@echo off

REM 过滤NA修复调试日志的Windows批处理脚本

echo 开始监听NA修复调试日志...
echo 请在应用中测试输入'na'来验证修复效果
echo 按Ctrl+C停止监听
echo ==========================

REM 使用adb logcat过滤日志
adb logcat | findstr "[NA_FIX_DEBUG]"
