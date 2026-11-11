import { studentName, parentName } from "./student-display";

import { dateLabel, money } from "@/lib/format";
import type { ColumnDef } from "@tanstack/react-table";
import type { Student } from "../types/students";

export const studentColumns: ColumnDef<Student>[] = [
	{
		id: "name",
		accessorFn: studentName,
		header: "Student",
		enableHiding: false,
		cell: ({ row }) => (
			<div className="student-name">
				<span
					className={`avatar avatar-${studentName(row.original).charCodeAt(0) % 4}`}
				>
					{studentName(row.original)
						.split(" ")
						.map((n) => n[0])
						.slice(0, 2)
						.join("")}
				</span>
				<div>
					<strong>{studentName(row.original)}</strong>
					<small>Student</small>
				</div>
			</div>
		),
	},
	{
		id: "parentName",
		accessorFn: parentName,
		header: "Parent / guardian",
		cell: ({ getValue }) => getValue<string | null>() || "—",
	},
	{
		accessorKey: "parentWhatsapp",
		header: "WhatsApp",
		cell: ({ getValue }) => {
			const phone = getValue<string | null>();
			return phone ? (
				<a
					className="contact-link"
					href={`https://wa.me/${phone.replace(/\D/g, "")}`}
					target="_blank"
					rel="noreferrer"
				>
					{phone}
				</a>
			) : (
				<span className="muted">Not added</span>
			);
		},
	},
	{
		accessorKey: "joinedOn",
		header: "Joined on",
		cell: ({ getValue }) => dateLabel(getValue<string>()),
	},
	{
		accessorKey: "monthlyFee",
		header: "Monthly fee",
		cell: ({ getValue }) => (
			<strong className="amount">{money(getValue<number>())}</strong>
		),
	},
	{
		accessorKey: "feeDueDay",
		header: "Fee due day",
		filterFn: (row, id, value) => !value || String(row.getValue(id)) === value,
		cell: ({ getValue }) => (
			<span className="day-badge">Day {getValue<number>()}</span>
		),
	},
];
