import { Router } from "express";
import { getDataBaseHealth, getHealth } from "./health.controller.js";

export const healthRouter = Router()

healthRouter.get("/", getHealth)
healthRouter.get("/db", getDataBaseHealth)