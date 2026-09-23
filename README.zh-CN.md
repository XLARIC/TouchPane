# TouchPane

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md)

让 macOS 外接触摸显示器拥有更接近原生的触控体验。

TouchPane 会把 USB HID 触摸输入转换为鼠标移动、点击、滚动、拖动、
多指手势、快捷键和可选的悬浮键盘。它是
[touchMyMac](https://github.com/jinghuichen/touchMyMac) 的改名增强分支；
后者基于 Sebastian Hueber 的
[Touch-Up](https://github.com/shueber/Touch-Up) 与 TouchUpCore。

## TouchPane 新增与修复

TouchPane 1.2.0 包含以下修改和新增内容：

- 新增 WingCool/ASM-156UCT 绝对坐标鼠标 HID 支持，对应 USB 设备
  `VID 27c0`、`PID 0858`。
- 修复多显示器下的指针定位：即使鼠标原本停在其他屏幕，触摸外接屏时也会
  自动移动到该触摸屏。
- 修复显示器旋转 90 度后，触摸坐标仍按未旋转方向计算的问题。
- 新增 **跟随系统、浅色、深色** 三种外观选项，默认 **跟随系统**。
- 新增 **跟随系统、English、简体中文、繁體中文** 四种语言选项，默认
  **跟随系统**；系统语言不受支持时兜底为英文。
- 修复设置窗口左侧栏只能点击文字的问题，现在整行空白区域都可以点击切换。
- 新增固定自签名证书的构建和安装流程，让相同身份的后续版本尽量保留
  macOS 的“辅助功能”和“输入监控”权限。
- 新增 HID、触摸、手势、动作和权限状态的实时诊断。
- 改进触摸抬起判断、噪声容错、手势识别、可配置快捷键动作和悬浮键盘流程。
- 应用名称及 Bundle ID 由 TouchMyMac 改为 TouchPane。

## 功能

- 单指轻点点击
- 单指拖动滚动，可调速度和惯性
- 按住后移动进行拖拽
- 双指辅助点击（右键）
- 双指捏合缩放
- 三指上滑打开调度中心
- 四指上滑／下滑显示或隐藏悬浮键盘
- 四指左滑触发自定义快捷键序列
- 五指按住持续按下指定按键或组合键
- 自动或手动绑定触摸屏与显示器
- 实时输入和手势诊断
- 外观和语言跟随系统

## 已测试硬件

- ASM-156UCT 外接触摸显示器
- WingCool USB HID 触摸屏（`VID 27c0`、`PID 0858`）
- LG Smart Monitor Swing（由上游分支测试）

其他 USB HID 触摸屏也可能兼容，但不同设备的报告格式和信号噪声会有差异。

## 系统要求

- macOS 12 或更高版本
- USB HID 触摸屏
- “辅助功能”权限
- 对于通过鼠标类 HID 接口输出触摸数据的设备，还需要“输入监控”权限

## 下载与首次运行

请从 [GitHub Releases](https://github.com/XLARIC/TouchPane/releases) 下载最新的
`.dmg` 和对应的 `.sha256` 文件。

免费发布版使用项目固定的自签名证书，**没有经过 Apple 公证**，所以 macOS
不会自动信任它。

### 如果提示“Apple 无法验证 DMG”

你可能会看到“Apple 无法验证 `TouchPane-1.2.0-macOS-universal.dmg`
是否包含可能危害 Mac 安全或泄漏隐私的恶意软件”，而窗口中只有
**完成**和**移到废纸篓**。这是当前自签名版本预期会出现的提示，但只有在确认
文件来自本仓库且 SHA-256 校验一致后才应继续：

1. 点击 **完成**，不要选择“移到废纸篓”。
2. 打开 **系统设置 → 隐私与安全性**。
3. 向下滚动到 **安全性**，找到 TouchPane DMG 被阻止的提示，点击
   **仍要打开**。
4. 使用 Mac 登录密码或触控 ID 验证，然后确认 **打开**。
5. DMG 打开后，把 `TouchPane.app` 拖到“应用程序”文件夹。
6. 打开 TouchPane。如果 macOS 再次阻止应用本身，请针对 `TouchPane.app`
   重复上述 **隐私与安全性 → 仍要打开** 操作。
7. 在 **辅助功能** 和 **输入监控** 中允许 TouchPane，然后退出并重新打开。

Apple 说明，“仍要打开”按钮通常只会在尝试打开后的约一小时内显示。参阅
[Apple 官方说明](https://support.apple.com/102445)。不要全局关闭 Gatekeeper。

完整的首次运行顺序如下：

1. 校验下载的 DMG 文件。
2. 如果需要，通过 **隐私与安全性 → 仍要打开** 允许并打开 DMG。
3. 把 `TouchPane.app` 拖到“应用程序”文件夹。
4. 如果 macOS 再次提示，用相同方式允许 TouchPane 应用本身。
5. 授权“辅助功能”和“输入监控”，然后重新打开 TouchPane。

通常只需授权一次。只有后续版本继续使用相同的应用名称、Bundle ID、安装路径
和签名证书时，macOS 才能继续识别为同一个应用。

可在“终端”中校验发布文件：

```bash
cd ~/Downloads
shasum -a 256 -c TouchPane-1.2.0-macOS-universal.dmg.sha256
```

## 从源码构建

用 Xcode 打开：

```bash
open TouchPane.xcodeproj
```

也可以创建稳定的本地签名身份，然后构建、安装并启动：

```bash
./scripts/setup_local_signing.sh
./scripts/build_install_run.sh --configuration Release
```

设置脚本会在登录钥匙串中创建 `TouchPane Local Code Signing`，不会把证书或
私钥写入仓库。第一次切换到这个身份时，仍需重新授权一次“辅助功能”和
“输入监控”。

生成通用架构发布 DMG：

```bash
./scripts/build_release.sh
```

发布文件会生成在 `dist/`。正式发布前请阅读 [RELEASING.md](RELEASING.md)。

## 项目结构

- `TouchPane/`：应用界面、设置、状态栏、诊断和悬浮键盘
- `Core/`：HID 解析、触摸跟踪、手势识别和输入事件发送
- `scripts/`：签名、本地安装和发布打包脚本

## 安全与隐私

TouchPane 在本机运行，处理触摸输入时不需要网络连接。“辅助功能”权限用于发送
鼠标和键盘事件；某些触摸屏 HID 接口还需要“输入监控”权限。

不要把签名证书、私钥、`.p12` 文件或密码提交到仓库。贡献者应使用自己的签名
身份；官方发布包必须始终使用维护者保管的同一个发布证书。

## 致谢

TouchPane 派生自
[jinghuichen/touchMyMac](https://github.com/jinghuichen/touchMyMac)，后者基于
Sebastian Hueber 的 [shueber/Touch-Up](https://github.com/shueber/Touch-Up)
和 TouchUpCore。相关版权声明均保留在源码和许可证中。

## 许可证

[MIT](LICENSE)
