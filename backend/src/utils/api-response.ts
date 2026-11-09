import type { Response } from "express";
import { HTTP_STATUS } from "./http-status.js";

type SuccessOptions<T> = {
  message: string;
  data?: T;
  statusCode?:
    | typeof HTTP_STATUS.OK
    | typeof HTTP_STATUS.CREATED;
};

export function sendSuccess<T>(
  res: Response,
  {
    message,
    data,
    statusCode = HTTP_STATUS.OK,
  }: SuccessOptions<T>,
): void {
  res.status(statusCode).json({
    success: true,
    message,
    ...(data !== undefined ? { data } : {}),
  });
}

export function sendNoContent(res: Response): void {
  res.status(HTTP_STATUS.NO_CONTENT).end();
}