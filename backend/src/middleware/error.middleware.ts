import { Request, Response, NextFunction } from 'express';
import { sendError } from '../utils/api-response';

export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  next: NextFunction
): void {
  console.error('[SplitMate Error Log]:', err);

  // Handle Zod validation errors
  if (err.name === 'ZodError') {
    const formattedErrors = err.errors.map((e: any) => ({
      field: e.path.join('.'),
      message: e.message,
    }));
    sendError(res, 'Validation failed. Please check your inputs.', 422, formattedErrors);
    return;
  }

  // Handle Prisma errors gracefully
  if (err.code && typeof err.code === 'string' && err.code.startsWith('P')) {
    if (err.code === 'P2002') {
      sendError(res, 'A record with this unique value already exists.', 409);
      return;
    }
    if (err.code === 'P2025') {
      sendError(res, 'The requested item was not found.', 404);
      return;
    }
    sendError(res, 'Database operation could not be completed. Please try again.', 400);
    return;
  }

  // Handle standard custom error messages
  const message = err.message || 'An unexpected error occurred. Please try again later.';
  const statusCode = err.statusCode || 500;

  sendError(res, message, statusCode);
}
