import { createFileRoute } from "@tanstack/react-router";
import { StudentDirectory } from "@/features/students";
export const Route = createFileRoute("/")({ component: StudentDirectory });
