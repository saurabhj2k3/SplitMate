import express, { Express, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import routes from './routes';
import { errorHandler } from './middleware/error.middleware';
import { config } from './config/env';

export function createApp(): Express {
  const app = express();

  // Security Middleware
  app.use(helmet());
  app.use(
    cors({
      origin: config.corsOrigin === '*' ? true : config.corsOrigin.split(','),
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
    })
  );

  // Body parser
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Root Welcome Endpoint
  app.get('/', (req: Request, res: Response) => {
    res.status(200).json({
      status: 'online',
      message: '🚀 SplitMate Backend API is running successfully.',
      version: '1.0.0',
      healthCheck: '/api/health',
      baseApiUrl: '/api/v1',
      endpoints: {
        auth: '/api/v1/auth',
        groups: '/api/v1/groups',
        expenses: '/api/v1/expenses',
        settlements: '/api/v1/settlements',
        balances: '/api/v1/balances',
        activities: '/api/v1/activities',
      },
    });
  });

  // Health check
  app.get('/api/health', (req: Request, res: Response) => {
    res.status(200).json({
      status: 'healthy',
      app: 'SplitMate API',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
    });
  });

  // Base API routes
  app.use('/api/v1', routes);

  // 404 handler
  app.use((req: Request, res: Response) => {
    res.status(404).json({
      success: false,
      message: `Route ${req.method} ${req.originalUrl} not found.`,
    });
  });

  // Global Error Handler
  app.use(errorHandler);

  return app;
}

export const app = createApp();
export default app;
