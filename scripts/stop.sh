#!/bin/bash
#=======================================
# SOC 龍蝦 — 停機腳本
# 停機後省錢，只留 EBS
#=======================================

set -e

# 顏色輸出
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}===== SOC 龍蝦 — 停機 =====${NC}"

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
# 1. 停止 OpenClaw Gateway
#---------------------------------------
echo ""
echo "停止 OpenClaw Gateway..."

ssh -o StrictHostKeyChecking=no \
  -o ConnectTimeout=10 \
  -i "${SSH_KEY:-$HOME/.ssh/soc-hermes.pem}" \
  ubuntu@"$INSTANCE_IP" \
  "openclaw gateway stop 2>/dev/null || sudo systemctl stop openclaw-gateway" \
  2>/dev/null || echo "（嘗試 SSH 停止...）"

sleep 2

#---------------------------------------
# 2. 停止 Lightsail 執行個體
#---------------------------------------
echo ""
echo "停止 Lightsail 執行個體..."

aws lightsail stop-instance \
  --region "$LIGHTSAIL_REGION" \
  --instance-name "$INSTANCE_NAME" \
  2>/dev/null

#---------------------------------------
# 3. 等到執行個體變成「停止」
#---------------------------------------
echo "等待執行個體停止..."
for i in {1..30}; do
  STATUS=$(aws lightsail get-instance \
    --region "$LIGHTSAIL_REGION" \
    --instance-name "$INSTANCE_NAME" \
    --query 'instance.state.name' \
    --output text 2>/dev/null)
  
  echo -n "."
  
  if [ "$STATUS" = "stopped" ]; then
    echo ""
    echo "執行個體已停止！"
    break
  fi
  
  sleep 2
done

#---------------------------------------
# 4. 計算節省的成本
#---------------------------------------
echo ""
echo "===== 停機完成 ====="
echo ""
echo "💰 停機後費用："
echo "   • 只留 80GB SSD：~$3/月"
echo "   • 比執行中省：~$9-21/月"
echo ""
echo "要恢復使用時，執行：./start.sh"
echo ""

#---------------------------------------
# 5. 發送到 Telegram 通知
#---------------------------------------
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  MESSAGE="💾 *SOC 龍蝦已停機*
━━━━━━━━━━━━━━━━━
⏰ 時間：$(date '+%Y-%m-%d %H:%M' UTC+8)
🎯 狀態：已停止（省錢模式）
🖥️ 執行個體：$INSTANCE_NAME
💰 節省：~$9-21/月
━━━━━━━━━━━━━━━━━
🔄 恢復使用時執行 ./start.sh"

  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=Markdown" > /dev/null
fi

echo "===== 完成 ====="