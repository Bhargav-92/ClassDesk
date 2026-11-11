import cors from "cors";
import express from "express";
import { env } from "./config/env.js";
import { errorHandler, notFound } from "./middleware/error-handler.js";
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

// students routes
app.use("/api/students", studentRouter);

// fees routes
app.use("/api/fees", feesRouter);

app.use(notFound);
app.use(errorHandler);
