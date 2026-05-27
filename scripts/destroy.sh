#!/bin/bash
#=======================================
# SOC 龍蝦 — 完全刪除
# 刪除 Lightsail 執行個體（不可逆！）
#=======================================

set -e

echo "============================================"
echo "  ⚠️  危險操作：刪除 Lightsail 執行個體  ⚠️"
echo "============================================"
echo ""
echo "即將刪除：$INSTANCE_NAME"
echo "影響："
echo "  • 執行個體永久刪除"
echo "  • 所有資料永久消失"
echo "  • SSH 連線中斷"
echo ""
echo "如果你確定要刪除，請輸入：DELETE"
echo -n ">> "
read CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
  echo "取消刪除操作。"
  exit 1
fi

# 預設值
LIGHTSAIL_REGION="${LIGHTSAIL_REGION:-ap-northeast-1}"
INSTANCE_NAME="${INSTANCE_NAME:-soc-hermes}"

echo ""
echo "正在刪除執行個體..."

aws lightsail delete-instance \
  --region "$LIGHTSAIL_REGION" \
  --instance-name "$INSTANCE_NAME" \
  2>/dev/null

echo ""
echo "===== 刪除完成 ====="
echo ""
echo "💰 費用已歸零"
echo "🔧 如需重新建立，請參考 IMPLEMENTATION.md"
echo ""

# 發送到 Telegram
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  MESSAGE="🗑️ *SOC 龍蝦已刪除*
━━━━━━━━━━━━━━━━━
⏰ 時間：$(date '+%Y-%m-%d %H:%M' UTC+8)
🖥️ 執行個體：$INSTANCE_NAME
⚠️ 狀態：永久刪除
💰 費用：已歸零"

  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${MESSAGE}" \
    -d "parse_mode=Markdown" > /dev/null
fi

echo "===== 完成 ====="