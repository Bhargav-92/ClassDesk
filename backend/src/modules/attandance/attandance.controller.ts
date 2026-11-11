import { NextFunction, Request, Response } from "express";
import { sendSuccess } from "../../utils/api-response.js";
import { attandanceList } from "./attandance.service.js";

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