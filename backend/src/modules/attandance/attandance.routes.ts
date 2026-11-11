import { Router } from "express";
import { getAttandance } from "./attandance.controller.js";

export const attandanceRoute = Router()

attandanceRoute.get('/', getAttandance)