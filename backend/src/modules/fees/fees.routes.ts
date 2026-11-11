import { Router } from "express";
import { getFees } from "./fees.controller.js";

export const feesRouter = Router();

feesRouter.get("/", getFees);
