import { AuthGate } from "@/features/auth/components/auth-gate";
import { AppToaster } from "@/components/app-toaster";
import { createQueryClient } from "@/lib/query-client";
import { QueryClientProvider } from "@tanstack/react-query";
import { HeadContent, Scripts, createRootRoute } from "@tanstack/react-router";
import { useState } from "react";
import appCss from "../styles.css?url";

const THEME_INIT_SCRIPT = `(function(){try{var stored=localStorage.getItem('theme');var dark=stored==='dark'||(stored!=='light'&&matchMedia('(prefers-color-scheme: dark)').matches);document.documentElement.classList.toggle('dark',dark);document.documentElement.style.colorScheme=dark?'dark':'light';}catch(e){}})();`;
export const Route = createRootRoute({
	head: () => ({
		meta: [
			{ charSet: "utf-8" },
			{ name: "viewport", content: "width=device-width, initial-scale=1" },
			{ title: "Students · Classdesk" },
			{
				name: "description",
				content:
					"Your classroom, in one place. A simple workspace for teachers.",
			},
		],
		links: [{ rel: "stylesheet", href: appCss }],
	}),
	shellComponent: RootDocument,
});
function RootDocument({ children }: { children: React.ReactNode }) {
	const [queryClient] = useState(createQueryClient);
	return (
		<html lang="en" suppressHydrationWarning>
			<head>
				<script dangerouslySetInnerHTML={{ __html: THEME_INIT_SCRIPT }} />
				<HeadContent />
			</head>
			<body>
				<QueryClientProvider client={queryClient}>
					<AuthGate>{children}</AuthGate>
					<AppToaster />
				</QueryClientProvider>
				<Scripts />
			</body>
		</html>
	);
}
