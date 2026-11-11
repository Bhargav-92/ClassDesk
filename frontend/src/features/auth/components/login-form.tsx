import ThemeToggle from "@/components/ThemeToggle";
import { zodResolver } from "@hookform/resolvers/zod";
import { GraduationCap, Loader2 } from "lucide-react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { useLogin } from "../hooks/useLogin";
import type { AuthUser } from "../types/auth";
const schema = z.object({
	email: z.email("Enter a valid email"),
	password: z.string().min(1, "Enter your password").max(128),
});
export function LoginForm({
	onAuthenticated,
}: {
	onAuthenticated: (token: string, user: AuthUser) => void;
}) {
	const mutation = useLogin();
	const {
		register,
		handleSubmit,
		formState: { errors },
	} = useForm<z.infer<typeof schema>>({
		resolver: zodResolver(schema),
		defaultValues: { email: "", password: "" },
	});
	return (
		<main className="login-page">
			<div className="login-theme">
				<ThemeToggle />
			</div>
			<section className="login-panel">
				<a href="/" className="brand">
					<span className="brand-mark">
						<GraduationCap />
					</span>
					classdesk.
				</a>
				<div className="eyebrow">TEACHER WORKSPACE</div>
				<h1>
					Welcome back<span className="heading-dot">.</span>
				</h1>
				<p className="login-intro">Sign in to your classroom.</p>
				<form
					noValidate
					onSubmit={handleSubmit((values) =>
						mutation.mutate(values, {
							onSuccess: (result) =>
								onAuthenticated(result.data.token, result.data.user),
						}),
					)}
				>
					<fieldset className="form-fields" disabled={mutation.isPending}>
						<legend className="sr-only">Sign in</legend>
						<div className="form-field">
							<label htmlFor="login-email">Email</label>
							<input
								id="login-email"
								type="email"
								placeholder="example@gmail.com"
								{...register("email")}
							/>
							{errors.email && (
								<p className="field-error" id="email-error">
									{errors.email.message}
								</p>
							)}
						</div>
						<div className="form-field">
							<label htmlFor="login-password">Password</label>
							<input
								id="login-password"
								type="password"
								placeholder="*******"
								{...register("password")}
							/>
							{errors.password && (
								<p className="field-error" id="password-error">
									{errors.password.message}
								</p>
							)}
						</div>
					</fieldset>
					{mutation.isError && (
						<p className="form-error" role="alert">
							{mutation.error.message}
						</p>
					)}
					<button
						type="submit"
						className="button primary login-submit"
						disabled={mutation.isPending}
					>
						{mutation.isPending && <Loader2 className="spinning" />}
						{mutation.isPending ? "Signing in…" : "Sign in"}
					</button>
				</form>
				<p className="login-note">
					A little less admin. A little more teaching.
				</p>
			</section>
		</main>
	);
}
