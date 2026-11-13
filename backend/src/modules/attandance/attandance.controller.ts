import { NextFunction, Request, Response } from "express";
import { sendSuccess } from "../../utils/api-response.js";
import { attandanceList, createAttandance } from "./attandance.service.js";
import { parseCreateAttendance } from "./attandance.validation.js";
import { HTTP_STATUS } from "../../utils/http-status.js";

export async function getAttandance(
  req:Request,
  res:Response,
  next:NextFunction
){
 try{
  const attandance = await attandanceList()

 sendSuccess(res,{
  message:"Attandance fetch successfully",
  data:attandance
 })
 }catch(error){
  next(error)
 }
}

export async function addAttandance(
  req:Request,
  res:Response,
  next:NextFunction
){
  try{
    const attandance = await createAttandance(parseCreateAttendance(req.body))

    sendSuccess(res,{
      message:"Attendance marked successfully",
      statusCode: HTTP_STATUS.CREATED,
      data:attandance
    })
  }catch(error){
    next(error)
  }
}
