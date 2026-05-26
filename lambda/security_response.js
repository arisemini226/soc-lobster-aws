// Lambda Function: SOC Security Response
// 當 GuardDuty 發現攻擊時，自動發送 Telegram 通知

const https = require('https');

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID;

// 發送 Telegram 訊息
function sendTelegram(message) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      chat_id: TELEGRAM_CHAT_ID,
      text: message,
      parse_mode: 'Markdown'
    });

    const options = {
      hostname: 'api.telegram.org',
      path: `/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        console.log('Telegram response:', data);
        resolve(data);
      });
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

// 主處理函數
exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  try {
    const finding = event.detail;
    const findingType = finding.type;
    const severity = finding.severity;
    const instanceId = finding.resource?.instanceDetails?.instanceId;
    const region = event.region;
    const timestamp = new Date().toISOString();

    const alertMessage = `🚨 *SOC 資安警報*
━━━━━━━━━━━━━━━━━
⏰ 時間：${timestamp}
🔴 威脅類型：${findingType}
⚠️ 嚴重度：${severity}/10
🖥️ 受影響實例：${instanceId || 'N/A'}
🌍 區域：${region}
📝 描述：${finding.description || '無'}
━━━━━━━━━━━━━━━━━
⏳ 正在自動處理中...`;

    await sendTelegram(alertMessage);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Security alert sent',
        findingType,
        severity,
        instanceId
      })
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};