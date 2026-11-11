import { createFileRoute } from "@tanstack/react-router";
import { FeesPage } from "@/features/fees";
export const Route = createFileRoute("/fees")({
	component: FeesPage,
	head: () => ({ meta: [{ title: "Fees · Classdesk" }] }),
});
