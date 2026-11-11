import type { ErrorRequestHandler, RequestHandler } from "express";
import { AppError } from "../utils/app-error.js";

export const notFound: RequestHandler = (_req, _res, next) => {
  next(new AppError(404, "Route not found"));
};

export const errorHandler: ErrorRequestHandler = (error: unknown, _req, res, next) => {
  if (res.headersSent) return next(error);

  let status = 500;
  let message = "An unexpected error occurred";
  if (error instanceof AppError) {
    status = error.statusCode;
    message = error.message;
  } else if (typeof error === "object" && error !== null && "type" in error) {
    if (error.type === "entity.parse.failed") {
      status = 400;
      message = "Request body must contain valid JSON";
    } else if (error.type === "entity.too.large") {
      status = 413;
      message = "Request body is too large";
    }
  }

  if (status >= 500) console.error("Request failed:", error);
  res.status(status).json({ success: false, message });
};
