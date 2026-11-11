import { NextFunction, Request, Response } from "express";
import { parseCreateStudent } from "./students.validation.js";

import { sendSuccess } from "../../utils/api-response.js";
import { createStudent, listStudents } from "./students.service.js";

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

export async function addStudent(
  req:Request,
  res:Response,
  next:NextFunction
){
  try {
    const student = await createStudent(parseCreateStudent(req.body))
    sendSuccess(res,{
      message:"Student Created Successfully",
      data: student
    })
  }catch(error){
    next(error)
  }
}
