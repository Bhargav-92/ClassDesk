import {
  CalendarDays,
  GraduationCap,
  PanelLeftClose,
  Users,
  Wallet
} from "lucide-react";
import { useState, type ReactNode } from "react";
import ThemeToggle from "./ThemeToggle";
export function TeacherLayout({
	title,
	children,
}: {
	title: "Students" | "Fees" | "Attendance";
	studentCount?: number;
	children: ReactNode;
}) {
	const [collapsed, setCollapsed] = useState(false);
	return (
		<div className={`teacher-app ${collapsed ? "sidebar-collapsed" : ""}`}>
			<aside className="sidebar">
				<a className="brand" href="/">
					<span className="brand-mark">
						<GraduationCap />
					</span>
					<span>
						classdesk<span className="brand-dot">.</span>
					</span>
				</a>

				<span className="nav-caption">WORKSPACE</span>
				<nav aria-label="Workspace">
					<a
						className={`nav-item ${title === "Students" ? "active" : ""}`}
						href="/"
						aria-current={title === "Students" ? "page" : undefined}
					>
						<Users />
						Students
					</a>
					<a
						className={`nav-item ${title === "Attendance" ? "active" : ""}`}
						href="/attendance"
						aria-current={title === "Attendance" ? "page" : undefined}
					>
						<CalendarDays />
						Attendance
					</a>
					<a
						className={`nav-item ${title === "Fees" ? "active" : ""}`}
						href="/fees"
						aria-current={title === "Fees" ? "page" : undefined}
					>
						<Wallet />
						Fees
					</a>
				</nav>
			</aside>
			<div className="main-shell">
				<header className="topbar">
					<div className="breadcrumb">
						<button
							className="icon-button sidebar-toggle"
							aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
							onClick={() => setCollapsed(!collapsed)}
						>
							<PanelLeftClose />
						</button>
						<span>Workspace</span>
						<span className="breadcrumb-divider">/</span>
						<strong>{title}</strong>
					</div>
					<div className="topbar-right">
						<nav className="mobile-page-nav" aria-label="Pages">
							<a
								href="/"
								aria-current={title === "Students" ? "page" : undefined}
							>
								Students
							</a>
							<a
								href="/fees"
								aria-current={title === "Fees" ? "page" : undefined}
							>
								Fees
							</a>
							<a
								href="/attendance"
								aria-current={title === "Attendance" ? "page" : undefined}
							>
								Attendance
							</a>
						</nav>
						<span className="portal-label">Teacher portal</span>
						<ThemeToggle />
						<span className="avatar top-avatar">T</span>
					</div>
				</header>
				<main className="directory">{children}</main>
			</div>
		</div>
	);
}
