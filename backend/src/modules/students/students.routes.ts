import { Router } from "express";
import { addStudent, getStudents } from "./students.controller.js";

export const studentRouter = Router();

studentRouter.get("/", getStudents);
studentRouter.post("/", addStudent);
// studentRouter.delete('/students/:id')
// studentRouter.patch('/students/:id')

