#!/bin/bash
#=======================================
# SOC 龍蝦 — 狀態查詢
#=======================================

set -e

# 顏色輸出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "===== SOC 龍蝦 — 狀態查詢 ====="
echo ""

# 讀取設定
if [ -f ~/.soc/config ]; then
  source ~/.soc/config
fi

# 預設值
LIGHTSAIL_REGION="${LIGHTSAIL_REGION:-ap-northeast-1}"
INSTANCE_NAME="${INSTANCE_NAME:-soc-hermes}"

#---------------------------------------
# 1. Lightsail 執行個體狀態
#---------------------------------------
echo "查詢 Lightsail 執行個體..."

STATUS=$(aws lightsail get-instance \
  --region "$LIGHTSAIL_REGION" \
  --instance-name "$INSTANCE_NAME" \
  --query 'instance.state.name' \
  --output text 2>/dev/null || echo "unknown")

IP=$(aws lightsail get-instance \
  --region "$LIGHTSAIL_REGION" \
  --instance-name "$INSTANCE_NAME" \
  --query 'instance.publicIpAddress' \
  --output text 2>/dev/null || echo "N/A")

case "$STATUS" in
  "running")
    echo -e "${GREEN}✓${NC}  Lightsail: 執行中"
    ;;
  "stopped")
    echo -e "${YELLOW}○${NC}  Lightsail: 已停止"
    ;;
  "starting"|"stopping")
    echo -e "${YELLOW}◐${NC}  Lightsail: $STATUS"
    ;;
  *)
    echo -e "${RED}✗${NC}  Lightsail: $STATUS"
    ;;
esac

echo "   IP: $IP"

#---------------------------------------
# 2. OpenClaw Gateway 狀態
#---------------------------------------
if [ "$STATUS" = "running" ]; then
  echo ""
  echo "查詢 OpenClaw Gateway..."
  
  GATEWAY_STATUS=$(ssh -o StrictHostKeyChecking=no \
    -o ConnectTimeout=5 \
    -i "${SSH_KEY:-$HOME/.ssh/soc-hermes.pem}" \
    ubuntu@"$IP" \
    "openclaw gateway status 2>/dev/null" \
    2>/dev/null | grep -i "running\|started\|active" || echo "unknown")
  
  if echo "$GATEWAY_STATUS" | grep -qi "running\|started\|active"; then
    echo -e "${GREEN}✓${NC}  OpenClaw: 執行中"
  else
    echo -e "${YELLOW}○${NC}  OpenClaw: 未啟動"
  fi
else
  echo ""
  echo -e "${YELLOW}○${NC}  OpenClaw: 執行個體已停止"
fi

#---------------------------------------
# 3. 最近活動
#---------------------------------------
echo ""
echo "===== 狀態查詢完成 ====="