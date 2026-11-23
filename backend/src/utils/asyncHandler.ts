import type { Request, RequestHandler, Response } from 'express';

export const asyncHandler =
  (fn: (req: Request, res: Response) => Promise<unknown>): RequestHandler =>
  (req, res, next) => {
    Promise.resolve().then(() => fn(req, res)).catch(next);
  };
