import { NextFunction, Request, Response } from "express";
import { sendSuccess } from "../../utils/api-response.js";
import { listFees } from "./fees.service.js";

export async function getFees(
  req:Request,
  res:Response,
  next:NextFunction
){
  try{
    const feesList = await listFees()

  sendSuccess(res,{
    message:"Fees fetched successfully",
    data:feesList
  })
  }catch(error){
    next(error)
  }
}