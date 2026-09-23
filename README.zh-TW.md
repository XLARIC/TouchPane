# TouchPane

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md)

讓 macOS 外接觸控顯示器擁有更接近原生的觸控體驗。

TouchPane 會把 USB HID 觸控輸入轉換為游標移動、點按、捲動、拖曳、
多指手勢、快速鍵和可選的懸浮鍵盤。它是
[touchMyMac](https://github.com/jinghuichen/touchMyMac) 的改名增強分支；
後者以 Sebastian Hueber 的
[Touch-Up](https://github.com/shueber/Touch-Up) 與 TouchUpCore 為基礎。

## TouchPane 新增與修復

TouchPane 1.2.0 包含以下修改和新增內容：

- 新增 WingCool/ASM-156UCT 絕對座標滑鼠 HID 支援，對應 USB 裝置
  `VID 27c0`、`PID 0858`。
- 修復多顯示器下的游標定位：即使游標原本停在其他螢幕，觸控外接螢幕時也會
  自動移至該觸控螢幕。
- 修復顯示器旋轉 90 度後，觸控座標仍依未旋轉方向計算的問題。
- 新增 **跟隨系統、淺色、深色** 三種外觀選項，預設為 **跟隨系統**。
- 新增 **跟隨系統、English、简体中文、繁體中文** 四種語言選項，預設為
  **跟隨系統**；系統語言不受支援時以英文作為後備語言。
- 修復設定視窗側邊欄只能點選文字的問題，現在整列空白區域都能點選切換。
- 新增固定自簽名憑證的建置及安裝流程，讓相同身分的後續版本盡量保留
  macOS 的「輔助使用」和「輸入監控」權限。
- 新增 HID、觸控、手勢、動作和權限狀態的即時診斷。
- 改進觸控離開判斷、雜訊容錯、手勢辨識、可設定快速鍵動作和懸浮鍵盤流程。
- 應用程式名稱及 Bundle ID 由 TouchMyMac 改為 TouchPane。

## 功能

- 單指輕觸點按
- 單指拖曳捲動，可調整速度和慣性
- 按住後移動進行拖曳
- 雙指輔助點按（右鍵）
- 雙指撥捏縮放
- 三指向上滑動開啟「指揮中心」
- 四指向上／向下滑動顯示或隱藏懸浮鍵盤
- 四指向左滑動觸發自訂快速鍵序列
- 五指按住以持續按下指定按鍵或組合鍵
- 自動或手動綁定觸控螢幕與顯示器
- 即時輸入和手勢診斷
- 外觀和語言跟隨系統

## 已測試硬體

- ASM-156UCT 外接觸控顯示器
- WingCool USB HID 觸控螢幕（`VID 27c0`、`PID 0858`）
- LG Smart Monitor Swing（由上游分支測試）

其他 USB HID 觸控螢幕也可能相容，但不同裝置的報告格式和訊號雜訊會有差異。

## 系統需求

- macOS 12 或以上版本
- USB HID 觸控螢幕
- 「輔助使用」權限
- 對於透過滑鼠類 HID 介面輸出觸控資料的裝置，還需要「輸入監控」權限

## 下載與首次執行

請從 [GitHub Releases](https://github.com/XLARIC/TouchPane/releases) 下載最新的
`.dmg` 和對應的 `.sha256` 檔案。

免費發行版使用專案固定的自簽名憑證，**未經 Apple 公證**，因此 macOS
不會自動信任它。

### 如果顯示「Apple 無法驗證 DMG」

你可能會看到「Apple 無法驗證 `TouchPane-1.2.0-macOS-universal.dmg`
是否包含可能危害 Mac 安全或洩漏隱私的惡意軟體」，而視窗中只有
**完成**和**丟到垃圾桶**。這是目前自簽名版本預期會出現的提示，但只有在確認
檔案來自本儲存庫且 SHA-256 驗證一致後才應繼續：

1. 按一下 **完成**，不要選擇「丟到垃圾桶」。
2. 開啟 **系統設定 → 隱私權與安全性**。
3. 向下捲動至 **安全性**，找到 TouchPane DMG 遭封鎖的提示，按一下
   **仍要打開**。
4. 使用 Mac 登入密碼或觸控 ID 驗證，然後確認 **打開**。
5. DMG 開啟後，將 `TouchPane.app` 拖到「應用程式」檔案夾。
6. 開啟 TouchPane。如果 macOS 再次封鎖應用程式本身，請針對
   `TouchPane.app` 重複上述 **隱私權與安全性 → 仍要打開** 操作。
7. 在 **輔助使用** 和 **輸入監控** 中允許 TouchPane，然後結束並重新開啟。

Apple 說明，「仍要打開」按鈕通常只會在嘗試開啟後約一小時內顯示。請參閱
[Apple 官方說明](https://support.apple.com/102445)。請勿全面停用 Gatekeeper。

完整的首次執行順序如下：

1. 驗證下載的 DMG 檔案。
2. 如有需要，透過 **隱私權與安全性 → 仍要打開** 允許並開啟 DMG。
3. 將 `TouchPane.app` 拖到「應用程式」檔案夾。
4. 如果 macOS 再次提示，請以相同方式允許 TouchPane 應用程式本身。
5. 授權「輔助使用」和「輸入監控」，然後重新開啟 TouchPane。

通常只需授權一次。只有後續版本繼續使用相同的應用程式名稱、Bundle ID、
安裝路徑和簽名憑證時，macOS 才能繼續將它識別為同一個應用程式。

可在「終端機」中驗證發行檔案：

```bash
cd ~/Downloads
shasum -a 256 -c TouchPane-1.2.0-macOS-universal.dmg.sha256
```

## 從原始碼建置

使用 Xcode 開啟：

```bash
open TouchPane.xcodeproj
```

也可以建立穩定的本機簽名身分，然後建置、安裝並啟動：

```bash
./scripts/setup_local_signing.sh
./scripts/build_install_run.sh --configuration Release
```

設定指令稿會在登入鑰匙圈中建立 `TouchPane Local Code Signing`，不會把憑證
或私密金鑰寫入儲存庫。第一次切換到這個身分時，仍需重新授權一次
「輔助使用」和「輸入監控」。

產生通用架構發行 DMG：

```bash
./scripts/build_release.sh
```

發行檔案會產生於 `dist/`。正式發行前請閱讀 [RELEASING.md](RELEASING.md)。

## 專案結構

- `TouchPane/`：應用程式介面、設定、狀態列、診斷和懸浮鍵盤
- `Core/`：HID 解析、觸控追蹤、手勢辨識和輸入事件傳送
- `scripts/`：簽名、本機安裝和發行封裝指令稿

## 安全與隱私

TouchPane 在本機執行，處理觸控輸入時不需要網路連線。「輔助使用」權限用於
傳送滑鼠和鍵盤事件；部分觸控螢幕 HID 介面還需要「輸入監控」權限。

請勿將簽名憑證、私密金鑰、`.p12` 檔案或密碼提交到儲存庫。貢獻者應使用
自己的簽名身分；正式發行套件必須一直使用維護者保管的同一張發行憑證。

## 致謝

TouchPane 衍生自
[jinghuichen/touchMyMac](https://github.com/jinghuichen/touchMyMac)，後者以
Sebastian Hueber 的 [shueber/Touch-Up](https://github.com/shueber/Touch-Up)
和 TouchUpCore 為基礎。相關著作權聲明均保留於原始碼和授權條款中。

## 授權條款

[MIT](LICENSE)
