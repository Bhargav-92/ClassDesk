import { NextFunction, Request, Response } from "express";
import { pool } from "../../db/index.js";
import { sendSuccess } from "../../utils/api-response.js";


export function getHealth(
  req:Request,
  res: Response
): void {
   sendSuccess(res, {
    message: "ClassDesk backend is running"
   })
}

export async function getDataBaseHealth (
  req: Request,
  res: Response, 
  next : NextFunction
):Promise<void> {
  try {
     await pool.query("Select 1")

     sendSuccess(res, {
      message:"PostgreSQL is connected"
     })
     
  }catch (error){
    next(error)
  }
}