import { Router } from "express";
import { getStudents } from "./students.controller.js";

export const studentRouter = Router();

studentRouter.get("/", getStudents);
// studentRouter.post('/students')
// studentRouter.delete('/students/:id')
// studentRouter.patch('/students/:id')
