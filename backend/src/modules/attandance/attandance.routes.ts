import { Router } from "express";
import { addAttandance, getAttandance } from "./attandance.controller.js";

export const attandanceRoute = Router()

attandanceRoute.get('/', getAttandance)
attandanceRoute.post('/',addAttandance)