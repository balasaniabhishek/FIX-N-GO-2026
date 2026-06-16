const { Aedes } = require('aedes');
const aedes = new Aedes();
const net = require('net');
const ws = require('websocket-stream');
const http = require('http');

// Removed custom authenticate to allow all connections

// 1. TCP Server for the Node.js backend (Port 1883)
const tcpServer = net.createServer((conn) => aedes.handle(conn));
tcpServer.listen(1883, function () {
  console.log('✅ Aedes Local MQTT Broker started');
  console.log('➡️  TCP listening on port 1883 (For Backend)');
});

// 2. WebSocket Server for the Flutter apps (Port 9001)
const httpServer = http.createServer();
ws.createServer({ server: httpServer }, (stream) => aedes.handle(stream));
httpServer.listen(9001, function () {
  console.log('➡️  WebSocket listening on port 9001 (For Flutter Apps)');
});

aedes.on('client', function (client) {
  console.log(`[Client Connected] ${client.id}`);
});

aedes.on('clientError', function (client, err) {
  console.error(`[Client Error] ${client.id}:`, err.message);
});

aedes.on('connectionError', function (client, err) {
  console.error(`[Connection Error]:`, err.message);
});

aedes.on('clientDisconnect', function (client) {
  console.log(`[Client Disconnected] ${client.id}`);
});
