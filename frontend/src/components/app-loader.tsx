import { LoaderCircle } from "lucide-react";

export function Spinner({ label = "Loading…" }: { label?: string }) {
	return (
		<div className="loading-state" role="status" aria-live="polite">
			<LoaderCircle className="spinning" aria-hidden="true" />
			<span>{label}</span>
		</div>
	);
}
