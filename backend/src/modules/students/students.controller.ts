import { NextFunction, Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { listStudents } from "./students.service.js";

export async function getStudents(
  req:Request,
  res:Response,
  next: NextFunction
){
 try {
  const studentList  = await listStudents() 
  sendSuccess(res, {
    message:"Students fetched Successfully",
    data:studentList
  });
 } catch(error){ 
  next(error)
 }
}