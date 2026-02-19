const http = require('http');
const path = require('path');
const fs = require('fs');
const { bundle } = require('@remotion/bundler');
const { renderMedia, getCompositions } = require('@remotion/renderer');

const PORT = process.env.PORT || process.env.REMOTION_PORT || 3003;
const CONFIG_FILE = '/config/remotion.conf';

let config = {
  port: PORT,
  gpu: 'auto'
};

if (fs.existsSync(CONFIG_FILE)) {
  const configContent = fs.readFileSync(CONFIG_FILE, 'utf8');
  configContent.split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) {
      config[key.trim().toLowerCase()] = value.trim();
    }
  });
}

const PORT_NUM = parseInt(config.port) || 3003;

const server = http.createServer(async (req, res) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ 
      status: 'ok', 
      message: 'Remotion Render API Server',
      version: '1.0.0',
      endpoints: [
        'GET / - This help',
        'GET /health - Health check',
        'GET /compositions - List available compositions',
        'POST /render - Render a video'
      ]
    }));
    return;
  }

  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', port: PORT_NUM }));
    return;
  }

  if (req.url === '/compositions') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ 
      message: 'Mount a Remotion project to /config to list compositions',
      note: 'Create /config/remotion-project with your src/ and package.json'
    }));
    return;
  }

  if (req.url === '/render' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        const options = JSON.parse(body);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ 
          status: 'rendering',
          message: 'Render endpoint ready - configure your project at /config/remotion-project',
          receivedOptions: options
        }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
      }
    });
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not found' }));
});

server.listen(PORT_NUM, '0.0.0.0', () => {
  console.log(`Remotion Render API Server running on port ${PORT_NUM}`);
  console.log(`GPU acceleration: ${config.gpu}`);
});
