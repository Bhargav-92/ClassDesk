import { Router } from "express";
import { requireAuth } from "../../middleware/auth.middleware.js";
import { getCurrentUser, loginController, logoutController } from "./auth.controller.js";

export const authRouter = Router();

authRouter.use((_req, res, next) => {
  res.setHeader("Cache-Control", "no-store");
  next();
});
authRouter.post("/login", loginController);
authRouter.get("/me", requireAuth, getCurrentUser);
authRouter.post("/logout", requireAuth, logoutController);
