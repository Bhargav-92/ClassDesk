import type { RequestHandler } from "express";
import { getSessionToken } from "../../middleware/auth.middleware.js";
import { sendSuccess } from "../../utils/api-response.js";
import { getSessionUser, login, logout } from "./auth.service.js";
import { parseLogin } from "./auth.validation.js";

export const loginController: RequestHandler = async (req, res, next) => {
  try {
    const credentials = parseLogin(req.body);
    const result = await login(credentials.email, credentials.password);
    sendSuccess(res, { message: "Signed in successfully", data: result });
  } catch (error) {
    next(error);
  }
};

export const getCurrentUser: RequestHandler = (req, res) => {
  sendSuccess(res, { message: "Session verified", data: getSessionUser(getSessionToken(req)) });
};

export const logoutController: RequestHandler = (req, res) => {
  logout(getSessionToken(req));
  sendSuccess(res, { message: "Signed out successfully" });
};
