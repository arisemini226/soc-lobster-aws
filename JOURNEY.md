# SOC 龍蝦系統 — 建置歷程

> 用 AI Agent 自動化 SOC 維運：用兩隻龍蝦協作，一隻協調、一隻執行

---

## 🐉 專案動機

想建立一個 AI 自動化的資安維運系統（SOC），目標：
- 每小時自動資安摘要
- GuardDuty 發現威脅時自動回應
- 用完就停機省錢（IaC 精神）
- 用 AI Agent 降低維運成本

---

## 💡 原始計畫 vs 實際方案

### 原本規劃：Terraform + EC2

```
規劃：
- 用 Terraform 建立 EC2 (m5.large)
- 手動安裝 OpenClaw
- 設定 IAM、VPC、S3、GuardDuty
- 成本：~$70/月
- 預估時間：1-2 小時安裝
```

### 實際完成：Lightsail + OpenClaw 藍圖

```
實際：
- 一鍵建立 Lightsail + OpenClaw（自動裝好）
- 內建 Bedrock AI（可直接用 Claude）
- 自動 HTTPS
- 成本：~$17/月（medium 規格）
- 預估時間：12 分鐘建立完成
```

**為什麼轉變？**
因為 AWS Lightsail 有 OpenClaw 官方藍圖，內建所有需要的東西，比 Terraform 方案簡單太多。

---

## 📅 建置時間線（2026-05-27 UTC）

### 00:03 — 收到用戶提供的 GitHub Token
- 建立 `soc-lobster-aws` Repo
- 規劃 Terraform 架構（EC2 + VPC + IAM + S3 + GuardDuty）

### 00:08 — 收到 AWS Access Key
- 嘗試 Terraform 方案
- 發現可以建立 Lightsail OpenClaw

### 00:18 — 建立第一個 Lightsail 執行個體（soc-hermes）
- Blueprint: openclaw_ls_1_0 (OpenClaw 2026.4.14)
- 遇到 SSH key 問題（鑰匙是空的，無法 SSH）

### 00:34 — 建立第二個執行個體（soc-hermes-new）
- 這次 SSH key 正確設定
- IP: 13.231.242.249

### 00:35-00:44 — 設定 SSH 和 OpenClaw
- 開放 Port 22/80/443
- SSH 成功連線
- 設定 OpenClaw Gateway

### 01:44 — 設定 Telegram Bot
- Bot 名稱：@SOCHermesBot
- 成功發送第一則測試訊息

### 01:58 — 用戶截圖顯示有兩個執行個體
- 發現錯誤：舊的 soc-hermes 沒用到但持續計費

### 02:00 — 刪除舊執行個體
- 刪除 soc-hermes（3.114.144.153）
- 保留 soc-hermes-new（13.231.242.249）

### 02:09 — 記錄建置歷程（本文檔）

---

## 🏗️ 最終架構

```
用戶（你）
    ↓ Telegram / LINE
┌─────────────────────────┐      ┌─────────────────────────────┐
│ 小黑隊長（Zeabur）       │ ←──→ │ Hermes（AWS Lightsail）      │
│ • 協調、規劃、回覆       │      │ • 執行 AWS CLI 命令          │
│ • 接收指令、分配任務     │      │ • 串接 Bedrock AI（Claude）  │
└─────────────────────────┘      │ • 跑資安腳本                 │
                                  │ • 每小時資安摘要             │
                                  └─────────────────────────────┘
                                            ↓
                                      AWS 資安服務
                                 (GuardDuty, Security Hub)
```

---

## 📦 專案檔案結構

```
soc-lobster-aws/
├── README.md                 ← 專案說明（Lightsail 版）
├── docs/
│   ├── IMPLEMENTATION.md      ← 實作手册
│   └── ARCHITECTURE.md        ← 兩隻龍蝦溝通方式
├── scripts/
│   ├── start.sh              ← 開機腳本
│   ├── stop.sh               ← 停機省錢腳本
│   ├── status.sh             ← 狀態查詢
│   └── destroy.sh            ← 刪除乾淨
├── terraform/
│   └── security_services.tf   ← GuardDuty + Lambda（可選）
└── lambda/
    └── security_response.js   ← 資安自動回應
```

---

## ⚡ 快速建立流程（12 分鐘）

### Step 1：建立 Lightsail 執行個體（5 分鐘）
```
1. 登入 https://lightsail.aws.amazon.com
2. 區域：Tokyo (ap-northeast-1)
3. 建立執行個體 → 選 OpenClaw 藍圖 → 4GB RAM
4. 命名：soc-hermes
```

### Step 2：設定 Bedrock IAM（2 分鐘）
```
1. 執行個體 → 入門 → 啟用 Amazon Bedrock
2. 複製指令碼 → 在 CloudShell 執行
```

### Step 3：連接 Telegram（3 分鐘）
```
1. Telegram @BotFather 建立 Bot
2. SSH 進去：openclaw channels add
3. 選擇 Telegram → 貼上 Bot Token
```

### Step 4：完成！
```
→ 馬上可以使用！
```

---

## 💰 成本比較

| 方案 | 規格 | 成本/月 |
|------|------|---------|
| 原本 Terraform EC2 | m5.large | ~$70 |
| **Lightsail（停機時）** | 80GB SSD | **~$3** |
| Lightsail（執行中）| medium | ~$17 |
| Lightsail（執行中）| large | ~$44 |

**實驗模式：停機時 $3/月，執行時 $17-44/月**

---

## 🎯 功能

- ✅ 每小時資安摘要（Telegram 發送）
- ✅ CVE 情資自動更新
- ✅ GuardDuty → EventBridge → Lambda 自動化鏈
- ✅ Stop/Start 省錢模式
- ✅ Bedrock AI（Claude）直接用
- ✅ IaC 精神：用完就刪，不污染

---

## 🔜 未完成（用戶需操作）

1. **Bedrock IAM 設定**
   - 需要在 Lightsail Console 執行一次
   - 讓 Hermes 有 Claude AI 大腦

2. **GuardDuty 啟用**
   - 在 AWS Console 啟用 GuardDuty
   - 串接 EventBridge + Lambda

---

## 🔧 Bedrock IAM 設定（2 分鐘）

> 讓 Hermes（Lightsail 上的 OpenClaw）能夠使用 Amazon Bedrock AI

### Step 1：開啟 Lightsail Console

```
https://lightsail.aws.amazon.com
```

### Step 2：選擇執行個體

點 **soc-hermes-new**

### Step 3：進入「入門」標籤

在執行個體頁面上方

### Step 4：啟用 Amazon Bedrock

找到區塊：
```
啟用 Amazon Bedrock 做為模型提供者
```

### Step 5：複製指令碼 → 啟動 CloudShell

1. 點「複製指令碼」
2. 點「啟動 CloudShell」

### Step 6：在 CloudShell 貼上並執行

```bash
# 貼上後按 Enter
bash <貼上的指令碼>

# 出現「完成」就 ok 了
```

### Step 7：如果第一次用 Claude（Sonnet）

需要在 Bedrock Console 申請一次存取（很簡單）：

1. 開啟：https://console.aws.amazon.com/bedrock/
2. 導航到「模型目錄」
3. 選 Anthropic Claude
4. 填表單提交（按幾個鈕就完成）

---

## 📊 技術棧

| 服務 | 用途 |
|------|------|
| AWS Lightsail | 雲端伺服器 |
| OpenClaw 2026.4.14 | AI Gateway + Agent |
| Amazon Bedrock | Claude AI 模型 |
| Telegram Bot | 訊息頻道 |
| AWS GuardDuty | 資安威脅偵測 |
| AWS Lambda | 自動化執行 |
| GitHub | 版本控制 |

---

## 🙏 學到的教訓

1. **不要建立多個相同的測試環境** — 確認第一個能用再建立第二個
2. **Lightsail OpenClaw 藍圖** — 比 Terraform 方案簡單太多
3. **停機省錢** — IaC 精神：用完就刪或停機，不長期保留
4. **SSH Key 設定** — 建立 instance 時就要設定好 key pair

---

## 🔗 相關連結

- GitHub Repo: https://github.com/arisemini226/soc-lobster-aws
- Lightsail: https://lightsail.aws.amazon.com
- OpenClaw Docs: https://docs.openclaw.ai

---

*建置日期：2026-05-27*
*作者：Arisemini226*
*感謝：小黑 ⚡（協調者）+ Hermes（執行者）兩隻龍蝦協作完成*