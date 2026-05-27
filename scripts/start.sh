#!/bin/bash
#=======================================
# SOC 龍蝦 — 開機腳本
# 執行後恢復 Lightsail 執行個體
#=======================================

set -e

# 顏色輸出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}===== SOC 龍蝦 — 開機 =====${NC}"

# 讀取設定
if [ -f ~/.soc/config ]; then
  source ~/.soc/config
fi

# 預設值
LIGHTSAIL_REGION="${LIGHTSAIL_REGION:-ap-northeast-1}"
INSTANCE_NAME="${INSTANCE_NAME:-soc-hermes}"

echo "區域: $LIGHTSAIL_REGION"
echo "執行個體: $INSTANCE_NAME"

#---------------------------------------
# 1. 啟動 Lightsail 執行個體
#---------------------------------------
echo ""
echo "啟動 Lightsail 執行個體..."
aws lightsail start-instance \
  --region "$LIGHTSAIL_REGION" \
  --instance-name "$INSTANCE_NAME" \
  2>/dev/null

#---------------------------------------
# 2. 等到執行個體變成「執行中」
#---------------------------------------
echo "等待執行個體啟動..."
for i in {1..30}; do
  STATUS=$(aws lightsail get-instance \
    --region "$LIGHTSAIL_REGION" \
    --instance-name "$INSTANCE_NAME" \
    --query 'instance.state.name' \
    --output text 2>/dev/null)
  
  echo -n "."
  
  if [ "$STATUS" = "running" ]; then
    echo ""
    echo -e "${GREEN}執行個體已啟動！${NC}"
    break
  fi
  
  sleep 2
done

#---------------------------------------
# 3. 啟動 OpenClaw Gateway
#---------------------------------------
echo ""
echo "啟動 OpenClaw Gateway..."

# SSH 並啟動
ssh -o StrictHostKeyChecking=no \
  -o ConnectTimeout=10 \
  -i "${SSH_KEY:-$HOME/.ssh/soc-hermes.pem}" \
  ubuntu@"$INSTANCE_IP" \
  "openclaw gateway start 2>/dev/null || sudo systemctl start openclaw-gateway" \
  2>/dev/null || echo "（嘗試 SSH 啟動...）"

#---------------------------------------
# 4. 顯示狀態
#---------------------------------------
echo ""
echo "===== 開機完成 ====="
echo ""
echo "Lightsail: https://lightsail.aws.amazon.com/ls/home?region=$LIGHTSAIL_REGION"
echo "OpenClaw: http://$INSTANCE_IP:18789"
echo ""

#---------------------------------------
# 5. 發送到 Telegram 通知
#---------------------------------------
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  MESSAGE="✅ *SOC 龍蝦已開機*
━━━━━━━━━━━━━━━━━
⏰ 時間：$(date '+%Y-%m-%d %H:%M' UTC+8)
🎯 狀態：執行中
🖥️ 執行個體：$INSTANCE_NAME
🌐 IP：$INSTANCE_IP
━━━━━━━━━━━━━━━━━
🐉 準備接受任務！"

  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=Markdown" > /dev/null
fi

echo "===== 完成 ====="