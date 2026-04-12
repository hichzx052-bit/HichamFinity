/**
 * HichamFinity — سيرفر TikTok LIVE
 * يتصل بتيك توك ويرسل الأحداث للتطبيق عبر WebSocket
 * 
 * الاستخدام:
 *   npm install
 *   node server.js
 * 
 * المطور: Hichamdzz
 */

const { WebcastPushConnection } = require('tiktok-live-connector');
const { WebSocketServer } = require('ws');
const express = require('express');
const http = require('http');

const PORT = process.env.PORT || 3000;

// Express للـ health check
const app = express();
const server = http.createServer(app);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', name: 'HichamFinity Server', version: '1.0.0' });
});

app.get('/', (req, res) => {
  res.json({
    name: 'HichamFinity Server',
    version: '1.0.0',
    developer: 'Hichamdzz',
    endpoints: {
      health: '/health',
      websocket: 'ws://localhost:' + PORT + '/live?username=TIKTOK_USERNAME'
    }
  });
});

// WebSocket Server
const wss = new WebSocketServer({ server, path: '/live' });

wss.on('connection', (ws, req) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const username = url.searchParams.get('username');

  if (!username) {
    ws.send(JSON.stringify({ type: 'error', message: 'username مطلوب' }));
    ws.close();
    return;
  }

  console.log(`🔗 اتصال جديد — البث: @${username}`);

  // الاتصال بـ TikTok LIVE
  const tiktok = new WebcastPushConnection(username, {
    processInitialData: true,
    enableExtendedGiftInfo: true,
    enableWebsocketUpgrade: true,
    requestPollingIntervalMs: 2000,
  });

  // ربط الأحداث
  tiktok.connect().then(state => {
    console.log(`✅ متصل بالبث — Room ID: ${state.roomId}`);
    ws.send(JSON.stringify({
      type: 'connected',
      roomId: state.roomId,
      roomInfo: state.roomInfo,
    }));
  }).catch(err => {
    console.error(`❌ فشل الاتصال: ${err.message}`);
    ws.send(JSON.stringify({ type: 'error', message: err.message }));
    ws.close();
  });

  // حدث: مشاهد دخل البث
  tiktok.on('member', (data) => {
    ws.send(JSON.stringify({
      type: 'join',
      id: Date.now().toString(),
      username: data.uniqueId,
      displayName: data.nickname,
      profilePicUrl: data.profilePictureUrl,
      timestamp: Date.now(),
    }));
  });

  // حدث: تعليق
  tiktok.on('chat', (data) => {
    ws.send(JSON.stringify({
      type: 'comment',
      id: Date.now().toString(),
      username: data.uniqueId,
      displayName: data.nickname,
      profilePicUrl: data.profilePictureUrl,
      message: data.comment,
      timestamp: Date.now(),
    }));
  });

  // حدث: هدية
  tiktok.on('gift', (data) => {
    // فقط لما الهدية تنتهي (streak end) أو مو streak
    if (data.giftType === 1 && !data.repeatEnd) return;

    ws.send(JSON.stringify({
      type: 'gift',
      id: Date.now().toString(),
      username: data.uniqueId,
      displayName: data.nickname,
      profilePicUrl: data.profilePictureUrl,
      giftName: data.giftName || data.describe,
      giftCount: data.repeatCount || 1,
      giftValue: (data.diamondCount || 0) * (data.repeatCount || 1),
      timestamp: Date.now(),
    }));
  });

  // حدث: لايك
  tiktok.on('like', (data) => {
    ws.send(JSON.stringify({
      type: 'like',
      id: Date.now().toString(),
      username: data.uniqueId,
      displayName: data.nickname,
      profilePicUrl: data.profilePictureUrl,
      likeCount: data.likeCount || 1,
      timestamp: Date.now(),
    }));
  });

  // حدث: متابعة
  tiktok.on('follow', (data) => {
    ws.send(JSON.stringify({
      type: 'follow',
      id: Date.now().toString(),
      username: data.uniqueId,
      displayName: data.nickname,
      profilePicUrl: data.profilePictureUrl,
      timestamp: Date.now(),
    }));
  });

  // حدث: مشاركة
  tiktok.on('share', (data) => {
    ws.send(JSON.stringify({
      type: 'share',
      id: Date.now().toString(),
      username: data.uniqueId,
      displayName: data.nickname,
      profilePicUrl: data.profilePictureUrl,
      timestamp: Date.now(),
    }));
  });

  // حدث: اشتراك
  tiktok.on('subscribe', (data) => {
    ws.send(JSON.stringify({
      type: 'subscribe',
      id: Date.now().toString(),
      username: data.uniqueId,
      displayName: data.nickname,
      profilePicUrl: data.profilePictureUrl,
      timestamp: Date.now(),
    }));
  });

  // معلومات الغرفة (عدد المشاهدين)
  tiktok.on('roomUser', (data) => {
    ws.send(JSON.stringify({
      type: 'roomInfo',
      viewerCount: data.viewerCount,
    }));
  });

  // انتهاء البث
  tiktok.on('streamEnd', () => {
    ws.send(JSON.stringify({ type: 'streamEnd' }));
    ws.close();
  });

  // لما العميل يقفل الاتصال
  ws.on('close', () => {
    console.log(`📴 انقطع الاتصال — @${username}`);
    tiktok.disconnect();
  });

  ws.on('error', (err) => {
    console.error(`WebSocket error: ${err.message}`);
    tiktok.disconnect();
  });
});

server.listen(PORT, () => {
  console.log(`
  ╔══════════════════════════════════════╗
  ║     🎬 HichamFinity Server v1.0     ║
  ║     Port: ${PORT}                        ║
  ║     Developer: Hichamdzz             ║
  ╚══════════════════════════════════════╝
  `);
});
