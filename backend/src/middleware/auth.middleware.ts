import type { Request, RequestHandler } from "express";
import { verifySession } from "../modules/auth/auth.service.js";
import { AppError } from "../utils/app-error.js";
import { HTTP_STATUS } from "../utils/http-status.js";

export function getSessionToken(req: Request): string {
  const authorization = req.headers.authorization;
  return authorization?.startsWith("Bearer ") ? authorization.slice(7) : "";
}

export const requireAuth: RequestHandler = (req, res, next) => {
  res.setHeader("Cache-Control", "no-store");
  if (!verifySession(getSessionToken(req))) {
    return next(new AppError(HTTP_STATUS.UNAUTHORIZED, "Please sign in to continue"));
  }
  next();
};
