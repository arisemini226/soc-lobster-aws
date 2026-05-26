# SOC Lobster - AI 資安自動化 on AWS

> 兩隻龍蝦協作：協調者（小黑）+ 執行者（Hermes），用 AI Agent 自動化 SOC 維運

## 🐉 兩隻龍蝦架構

```
用戶（Telegram）
    ↓
┌─────────────────┐      ┌─────────────────┐
│ 小黑（Zeabur）   │ ←──→ │ Hermes（AWS）   │
│ 協調者          │      │ 執行者         │
│ AI + 指令解析   │      │ AWS CLI + 資安  │
└─────────────────┘      └─────────────────┘
```

## 🚀 快速啟動

```bash
# 1. 在 AWS 建立 IAM User：soc-operator（AdministratorAccess）

# 2. 設定 AWS credentials
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."

# 3. 執行 Terraform
cd terraform
terraform init
terraform plan
terraform apply

# 4. SSH 到 EC2 安裝 OpenClaw
ssh -i soc-key-pair.pem ec2-user@<IP>
curl -fsSL https://openclaw.ai/install.sh | bash
```

## 📁 專案結構

```
aws-soc/
├── terraform/          # IaC（EC2、VPC、IAM、S3、GuardDuty）
├── docker/             # Docker Compose（Wazuh、Grafana、OpenSearch）
├── scripts/            # 自動化腳本
├── lambda/             # Lambda 資安回應
└── docs/              # 文件
```

## 🎯 功能

- ✅ 每小時資安摘要（Telegram）
- ✅ CVE 情資自動更新
- ✅ Terraform plan → approve → apply
- ✅ 自動化快照 + Human-in-the-loop 審批
- ✅ GuardDuty → EventBridge → Lambda 自動化鏈

## 💰 成本

| 服務 | 預估 |
|------|------|
| EC2 (m5.large) | ~$70/月 |
| S3 + CloudWatch | ~$10/月 |
| **總計** | **~$80/月** |

## 📚 文件

- [IMPLEMENTATION.md](docs/IMPLEMENTATION.md) - 完整實作手册
- [SOC_Runbook.md](docs/SOC_Runbook.md) - 資安自動化劇本
- [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) - 快速指令卡

---

*Built with OpenClaw + AWS + ❤️*
*Author: Arisemini226 / 小黑 ⚡*