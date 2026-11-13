import type { RequestHandler } from "express";
import { getSessionToken } from "../../middleware/auth.middleware.js";
import { sendSuccess } from "../../utils/api-response.js";
import { demoUser, login, logout } from "./auth.service.js";
import { parseLogin } from "./auth.validation.js";

export const loginController: RequestHandler = (req, res, next) => {
  try {
    const credentials = parseLogin(req.body);
    const result = login(credentials.email, credentials.password);
    sendSuccess(res, { message: "Signed in successfully", data: result });
  } catch (error) {
    next(error);
  }
};

export const getCurrentUser: RequestHandler = (_req, res) => {
  sendSuccess(res, { message: "Session verified", data: demoUser });
};

export const logoutController: RequestHandler = (req, res) => {
  logout(getSessionToken(req));
  sendSuccess(res, { message: "Signed out successfully" });
};
