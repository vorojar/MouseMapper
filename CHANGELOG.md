# Changelog

## 1.1.0 (2026-03-29)

### Added
- Windows 版本（C + Win32 API，单 exe 零依赖）
- WH_MOUSE_LL 全局钩子 + SendInput 异步工作线程
- 系统托盘图标 + 右键菜单（自启开关/退出）
- 首次运行自动生成 config.json + 设置开机自启
- 自定义鼠标图标（嵌入 exe 资源）
- 启动气泡提示
- 防多开（Mutex）

## 1.0.0 (2026-03-28)

- 初始版本
- 基于 CGEventTap 拦截鼠标侧键/中键事件
- 支持映射到任意键盘按键，包括 fn、Command、Shift 等单独修饰键
- 支持 click（点击触发）和 hold（按住映射）两种模式
- JSON 配置文件，支持多路径自动查找
- launchd 开机自启支持
- install.sh / uninstall.sh 一键安装卸载
