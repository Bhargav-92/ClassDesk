import { useEffect, useState } from "react";
import { Moon, Sun } from "lucide-react";
export default function ThemeToggle() {
	const [dark, setDark] = useState(false);
	useEffect(() => {
		setDark(document.documentElement.classList.contains("dark"));
		const media = window.matchMedia("(prefers-color-scheme: dark)");
		const update = () => {
			if (
				localStorage.getItem("theme") === "light" ||
				localStorage.getItem("theme") === "dark"
			)
				return;
			document.documentElement.classList.toggle("dark", media.matches);
			document.documentElement.style.colorScheme = media.matches
				? "dark"
				: "light";
			setDark(media.matches);
		};
		media.addEventListener("change", update);
		return () => media.removeEventListener("change", update);
	}, []);
	return (
		<button
			className="icon-button theme-toggle"
			type="button"
			aria-label={`Switch to ${dark ? "light" : "dark"} mode`}
			title={`Switch to ${dark ? "light" : "dark"} mode`}
			onClick={() => {
				const next = !dark;
				setDark(next);
				document.documentElement.classList.toggle("dark", next);
				document.documentElement.style.colorScheme = next ? "dark" : "light";
				try {
					localStorage.setItem("theme", next ? "dark" : "light");
				} catch {
					/* Theme remains usable without storage. */
				}
			}}
		>
			{dark ? <Sun /> : <Moon />}
		</button>
	);
}
