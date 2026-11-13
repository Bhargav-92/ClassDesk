import cors from "cors";
import express from "express";
import { env } from "./config/env.js";
import { requireAuth } from "./middleware/auth.middleware.js";
import { errorHandler, notFound } from "./middleware/error-handler.js";
import { attandanceRoute } from "./modules/attandance/attandance.routes.js";
import { authRouter } from "./modules/auth/auth.routes.js";
import { feesRouter } from "./modules/fees/fees.routes.js";
import { getHealth } from "./modules/health/health.controller.js";
import { healthRouter } from "./modules/health/health.routes.js";
import { studentRouter } from "./modules/students/students.routes.js";

export const app = express();

app.disable("x-powered-by");
app.use(cors({ origin: env.frontendUrl, credentials: true }));
app.use(express.json({ limit: "100kb" }));

app.get("/", getHealth);

app.use("/api/health", healthRouter);

app.use("/api/auth", authRouter);
app.use("/api", requireAuth);

// students routes
app.use("/api/students", studentRouter);

// fees routes
app.use("/api/fees", feesRouter);

// attandance routes
app.use("/api/attandance",attandanceRoute)



app.use(notFound);
app.use(errorHandler);

