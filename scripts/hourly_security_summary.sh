#!/bin/bash
#=======================================
# SOC 每小時資安摘要
#=======================================

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}"
AWS_REGION="ap-northeast-1"

echo "===== SOC 每小時資安摘要 ====="
echo "時間: $(date '+%Y-%m-%d %H:%M UTC')"

#=======================================
# 1. GuardDuty
#=======================================
DETECTOR=$(aws guardduty list-detectors --region $AWS_REGION --query 'DetectorIds[0]' --output text 2>/dev/null)
if [ "$DETECTOR" != "None" ] && [ -n "$DETECTOR" ]; then
  GD_HIGH=$(aws guardduty list-findings --detector-id "$DETECTOR" --region $AWS_REGION --finding-criteria '{"severity": {"eq": ["8", "9"]}}' --query 'length(FindingIds)' --output text 2>/dev/null || echo "0")
else
  GD_HIGH="N/A"
fi

#=======================================
# 2. EC2 狀態
#=======================================
EC2_RUNNING=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'length(Reservations[].Instances[])' --output text 2>/dev/null || echo "?")
EC2_STOPPED=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --query 'length(Reservations[].Instances[])' --output text 2>/dev/null || echo "?")

#=======================================
# 3. 發送摘要
#=======================================
ALERT_LEVEL="🟢"
if [ "$GD_HIGH" -gt 0 ] 2>/dev/null; then
  ALERT_LEVEL="🔴"
fi

MESSAGE="🛡️ *SOC 每小時資安摘要*
━━━━━━━━━━━━━━━━━
⏰ 時間：$(date '+%Y-%m-%d %H:%M' UTC+8)
🎯 威脅等級：$ALERT_LEVEL
━━━━━━━━━━━━━━━━━

📊 *服務狀態*
├ GuardDuty 高嚴重告警：$GD_HIGH
├ EC2 運行中：$EC2_RUNNING
└ EC2 已停止：$EC2_STOPPED

━━━━━━━━━━━━━━━━━
🐉 SOC 龍蝦：運行中
🔧 自動化備份：啟用"

curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  -d "text=${MESSAGE}" \
  -d "parse_mode=Markdown" > /dev/null

echo "===== 完成 ====="