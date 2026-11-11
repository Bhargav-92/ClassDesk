import {
	createContext,
	useContext,
	useEffect,
	useState,
	type ReactNode,
} from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Spinner } from "@/components/app-loader";
import { toast } from "sonner";
import { getSession, logout } from "../api/auth";
import { LoginForm } from "./login-form";
import type { AuthUser } from "../types/auth";
const AuthContext = createContext<{
	user: AuthUser;
	signOut: () => void;
} | null>(null);
export function useAuth() {
	const value = useContext(AuthContext);
	if (!value) throw new Error("Auth provider is missing");
	return value;
}
export function AuthGate({ children }: { children: ReactNode }) {
	const client = useQueryClient();
	const [ready, setReady] = useState(false);
	const [token, setToken] = useState<string | null>(null);
	useEffect(() => {
		try {
			setToken(sessionStorage.getItem("classdesk-token"));
		} catch {
			/* Sign in remains available if storage is blocked. */
		}
		setReady(true);
		const expired = () => {
			setToken(null);
			client.clear();
		};
		window.addEventListener("classdesk:unauthorized", expired);
		return () => window.removeEventListener("classdesk:unauthorized", expired);
	}, [client]);
	const session = useQuery({
		queryKey: ["auth", "session"],
		queryFn: getSession,
		enabled: ready && Boolean(token),
		retry: false,
		staleTime: 60_000,
	});
	if (!ready || (token && session.isPending))
		return <Spinner label="Opening your classroom…" />;
	if (!token || session.isError)
		return (
			<LoginForm
				onAuthenticated={(next, user) => {
					sessionStorage.setItem("classdesk-token", next);
					client.clear();
					client.setQueryData(["auth", "session"], {
						success: true,
						message: "Signed in",
						data: user,
					});
					setToken(next);
				}}
			/>
		);
	if (!session.data) return <Spinner />;
	async function signOut() {
		try {
			const result = await logout();
			toast.success(result.message);
		} catch {
			/* Clear local state even when the API cannot be reached. */
		} finally {
			sessionStorage.removeItem("classdesk-token");
			setToken(null);
			client.clear();
		}
	}
	return (
		<AuthContext.Provider value={{ user: session.data.data, signOut }}>
			{children}
		</AuthContext.Provider>
	);
}
