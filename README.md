# SOC 龍蝦系統 — AI 資安自動化 on AWS Lightsail

> 用兩隻龍蝦協作：協調者（小黑）+ 執行者（Hermes），用 AI Agent 自動化 SOC 維運

## 🐉 兩隻龍蝦架構

```
用戶（你）
    ↓ Telegram / LINE
┌─────────────────┐      ┌─────────────────────────────┐
│ 小黑隊長（Zeabur）│ ←──→ │ Hermes（AWS Lightsail）     │
│ 協調、規劃、回覆  │      │ 執行 AWS 命令、資安腳本      │
└─────────────────┘      └─────────────────────────────┘
                                   ↓
                          串接 Bedrock AI
```

## 🚀 快速啟動（12 分鐘完成）

### Step 1：建立 Lightsail 執行個體（5 分鐘）

```
1. 登入 https://lightsail.aws.amazon.com
2. 選擇區域：Tokyo (ap-northeast-1)
3. 建立執行個體：
   - 平台：Linux/Unix
   - 藍圖：OpenClaw ⭐
   - 規格：4GB RAM（推薦）或 2GB（實驗用）
4. 命名：soc-hermes
5. 等待狀態變成「執行中」（約 2-3 分鐘）
```

### Step 2：設定 Bedrock IAM（2 分鐘）

```
1. 在 Lightsail 執行個體頁面，選擇「入門」標籤
2. 找到「啟用 Amazon Bedrock」區塊
3. 點「複製指令碼」→「啟動 CloudShell」
4. 貼上指令碼，按 Enter
5. 出現「完成」就 ok 了
```

### Step 3：連接 Telegram（3 分鐘）

```
1. 去 Telegram @BotFather 建立新 Bot
   → /newbot → 命名 → 拿 token

2. SSH 到 Lightsail（在網頁裡直接點「使用 SSH 連線」）
   執行：openclaw channels add
   選擇 Telegram，貼上 Bot Token

3. 允許你的 Telegram ID（從允許清單設定）
```

### Step 4：設定我（小黑）能控制 Hermes

```
把你的 Lightsail SSH 連線資訊告訴我，
我就可以 SSH 進去用 CLI 控制 Hermes。
```

---

## 📁 專案結構

```
soc-lobster-aws/
├── docs/
│   ├── IMPLEMENTATION.md     ← 實作手册（Lightsail 版）
│   ├── ARCHITECTURE.md       ← 架構说明
│   ├── QUICK_REFERENCE.md    ← 快速指令卡
│   └── ARCHITECTURE.md       ← 燈龍蝦溝通方式
├── scripts/
│   ├── start.sh             ← 開機（省錢恢复）
│   ├── stop.sh              ← 停機（省錢）
│   ├── destroy.sh           ← 刪除乾淨（不再需要時）
│   ├── status.sh            ← 狀態查詢
│   ├── hourly_summary.sh    ← 每小時資安摘要
│   ├── cve_update.sh        ← CVE 情資更新
│   └── security_snapshot.sh  ← 自動化快照
├── terraform/
│   └── security_services.tf ← GuardDuty + Security Hub + Lambda（可選）
├── docker/
│   └── docker-compose.yml   ← Docker 服務（實驗用）
└── README.md
```

## 🎯 功能

- ✅ 每小時資安摘要（Telegram）
- ✅ CVE 情資自動更新
- ✅ 自動化快照 + Human-in-the-loop 審批
- ✅ GuardDuty → EventBridge → Lambda 自動化鏈
- ✅ Bedrock AI（Claude）直接用，無需 API Key
- ✅ Stop/Start 省錢模式

## 💰 成本（實驗模式）

| 模式 | 規格 | 成本/小時 | 成本/月 |
|------|------|-----------|---------|
| 執行中 | 4GB RAM | $0.017 | ~$12 |
| 執行中 | 2GB RAM | $0.009 | ~$7 |
| **停機（只留 EBS）** | 80GB SSD | ~$0.004 | ~$3 |

**實驗模式：~$7-12/月（停機時 $3/月）**

## ⚡ 下一步

1. 建立 Lightsail 執行個體
2. 拿到 Access Key ID + Secret
3. 我幫你測試 SSH 控制

---

*Built with OpenClaw + AWS Lightsail + ❤️*
*Author: Arisemini226 / 小黑 ⚡*