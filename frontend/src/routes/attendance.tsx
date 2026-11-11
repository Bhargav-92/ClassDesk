import { createFileRoute } from "@tanstack/react-router";
import { AttendancePage } from "@/features/attendance";
export const Route = createFileRoute("/attendance")({
	component: AttendancePage,
	head: () => ({ meta: [{ title: "Attendance · Classdesk" }] }),
});
