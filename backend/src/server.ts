import app from './app';
import { config } from './config/env';

const server = app.listen(config.port, () => {
  console.log(`========================================`);
  console.log(`🚀 SplitMate API running on port ${config.port}`);
  console.log(`🌐 Environment: ${config.nodeEnv}`);
  console.log(`🔗 Health check: http://localhost:${config.port}/api/health`);
  console.log(`========================================`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

export default server;
