import { Router, type RequestHandler } from "express";
import { z } from "zod";
import { AppError } from "../../utils/app-error.js";
import { sendSuccess } from "../../utils/api-response.js";
import { demoUser, login, logout, verifySession } from "./auth.service.js";

const loginSchema = z.object({email:z.string().trim().email().max(254),password:z.string().min(1).max(128)});
export const requireAuth: RequestHandler = (req,res,next) => {
 res.setHeader("Cache-Control", "no-store");
 const token = req.headers.authorization?.startsWith("Bearer ") ? req.headers.authorization.slice(7) : "";
 if (!verifySession(token)) return next(new AppError(401, "Please sign in to continue"));
 next();
};
export const authRouter=Router();
authRouter.use((_req,res,next)=>{res.setHeader("Cache-Control","no-store");next();});
authRouter.post("/login",(req,res,next)=>{
 try {
  const result=loginSchema.safeParse(req.body);
  if(!result.success) throw new AppError(400,"Enter a valid email and password");
  sendSuccess(res,{message:"Signed in successfully",data:login(result.data.email,result.data.password)});
 } catch(error){next(error);}
});
authRouter.get("/me",requireAuth,(_req,res)=>{sendSuccess(res,{message:"Session verified",data:demoUser});});
authRouter.post("/logout",requireAuth,(req,res)=>{logout(req.headers.authorization!.slice(7));sendSuccess(res,{message:"Signed out successfully"});});
