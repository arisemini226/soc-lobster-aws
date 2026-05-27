# SOC 龍蝦系統 — 實作手册（Lightsail 版）

> 目標：在 AWS Lightsail 建立可控的 OpenClaw 節點（代號：Hermes）
> 時間：12 分鐘建立 + 5 分鐘測試 = 17 分鐘完成

---

## 🐉 系統架構

```
你（協調者）
    ↓ Telegram / LINE
┌──────────────────────────────────────────┐
│ 小黑隊長（Zeabur）                         │
│ • 接收指令                                │
│ • 協調任務                                │
│ • 回覆結果                                │
└────────────┬─────────────────────────────┘
             ↓
┌──────────────────────────────────────────┐
│ Hermes（AWS Lightsail OpenClaw）          │
│ • SSH 遠端控制                           │
│ • 執行 AWS CLI 命令                      │
│ • 串接 Bedrock AI                        │
│ • 跑資安腳本                              │
└──────────────────────────────────────────┘
             ↓
          AWS 資安服務
     (GuardDuty, Security Hub, WAF)
```

---

## 📋 Step 1：建立 Lightsail 執行個體

### 1.1 登入 Lightsail

```
網址：https://lightsail.aws.amazon.com
區域：Asia Pacific (Tokyo) — ap-northeast-1
```

### 1.2 建立執行個體

| 設定 | 選擇 |
|------|------|
| 平台 | Linux/Unix |
| 藍圖 | **OpenClaw** ⭐ |
| 規格 | 4GB RAM（推薦）/ 2GB（實驗用）|
| 命名 | soc-hermes |

等待狀態變成「執行中」（約 2-3 分鐘）。

### 1.3 複製 SSH 連線資訊

建立完成後，點擊執行個體，複製：
- 公有 IP
- 預設使用者名稱：`ubuntu`（或Lightsail顯示的）

---

## 📋 Step 2：設定 Bedrock IAM

### 2.1 開啟 CloudShell

```
1. 在 Lightsail 執行個體頁面
2. 選擇「入門」標籤
3. 找到「啟用 Amazon Bedrock 做為模型提供者」區塊
4. 點「複製指令碼」
5. 點「啟動 CloudShell」
```

### 2.2 執行指令碼

```bash
# 貼上複製的指令碼
bash <貼上>

# 等待，出現「完成」就ok
```

### 2.3 第一次使用 Anthropic（如果需要的話）

如果這是第一次用 Claude，需要在 Bedrock 主控台提交簡短表單：
```
網址：https://console.aws.amazon.com/bedrock/
導航：模型目錄 → Anthropic Claude → 申請存取
```

---

## 📋 Step 3：連接 Telegram

### 3.1 建立 Telegram Bot

```
1. Telegram 找 @BotFather
2. 送 /newbot
3. 命名（例如：SOC Hermes Bot）
4. 拿 bot token（格式：123456789:ABCdef...）
```

### 3.2 SSH 連線到 Lightsail

在 Lightsail 網頁直接點「使用 SSH 連線」，會開啟瀏覽器 SSH 終端。

### 3.3 設定 Telegram 頻道

```bash
# 執行
openclaw channels add

# 選 Telegram
# 貼上 Bot Token
# 按 Enter 完成
```

### 3.4 允許你的 Telegram ID

```
1. 在 OpenClaw 儀表板 → 頻道 → Telegram
2. 把你的 Telegram ID（數字格式）加入允許清單
3. 從 Telegram 發送 /start 給你的 Bot
4. 在 SSH 執行：
   openclaw pairing approve telegram [配對碼]
```

---

## 📋 Step 4：讓我（小黑）能控制 Hermes

### 4.1 準備 SSH 資訊

需要：
- Lightsail 公有 IP
- SSH Key（你在建立時下載的 .pem 檔案）

### 4.2 設定 SSH Key 權限

```bash
# 在我的主機（Zeabur）設定
chmod 400 ~/Downloads/soc-hermes.pem
```

### 4.3 測試 SSH 連線

```bash
ssh -i ~/Downloads/soc-hermes.pem ubuntu@<公有IP>
```

如果成功，代表我可以直接 SSH 進去控制 Hermes。

### 4.4 我能做的

- SSH 進去執行 `openclaw` CLI
- 執行 `aws` CLI 控制 AWS 服務
- 跑 docker-compose 架設資安服務
- 執行 bash 腳本

---

## ⚡ 日常操作

### 開機（恢復使用）
```bash
# 在 Lightsail 按鈕
或 SSH 進去後：
openclaw gateway start
```

### 停機（省錢）
```bash
# 在 Lightsail 按鈕
或 SSH 進去後：
openclaw gateway stop
```

### 完全刪除
```bash
# 在 Lightsail 按鈕刪除執行個體
# 所有費用歸零
```

---

## 💡 小技巧

1. **停機省錢**：不用時停機，每月 $3（只有 SSD 費用）
2. **靜態 IP**：建議連接靜態 IP，这样 IP 不會變
3. **快照備份**：可以在 Lightsail 建立快照備份

---

## 🔧 故障排除

| 問題 | 解決 |
|------|------|
| SSH 連線失敗 | 檢查 Security Group 是否有 port 22 |
| Bedrock 無法使用 | 檢查 IAM Role 是否設定成功 |
| Telegram 無法連接 | 檢查 Bot Token 是否正確 |

---

## 📊 成本總結

| 狀態 | 2GB RAM | 4GB RAM |
|------|---------|---------|
| 執行中 | ~$0.009/hr ≈ $7/月 | ~$0.017/hr ≈ $12/月 |
| 停機（EBS only）| ~$3/月 | ~$3/月 |
| 快照（100GB）| +$10/月 | +$10/月 |

---

*最後更新: 2026-05-27 00:15 UTC*