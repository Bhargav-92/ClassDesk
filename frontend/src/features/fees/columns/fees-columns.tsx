import { dateLabel, money } from "@/lib/format";
import type { ColumnDef } from "@tanstack/react-table";
import type { FeePayment } from "../types/fees";
export const feesColumns: ColumnDef<FeePayment>[] = [
	{
		accessorKey: "studentName",
		header: "Student",
		cell: ({ getValue }) => (
			<strong className="amount">{getValue<string>() || "—"}</strong>
		),
	},
	{
		accessorKey: "feesAmount",
		header: "Amount paid",
		cell: ({ getValue }) => (
			<strong className="amount">{money(getValue<number>())}</strong>
		),
	},
	{
		accessorKey: "paidOn",
		header: "Paid on",
		cell: ({ getValue }) => dateLabel(getValue<string>()),
		filterFn: (row, id, value: string) =>
			!value || String(row.getValue(id)).startsWith(value),
	},
	{
		accessorKey: "recordedAt",
		header: "Recorded at",
		cell: ({ getValue }) =>
			new Intl.DateTimeFormat("en-IN", {
				dateStyle: "medium",
				timeStyle: "short",
				timeZone: "Asia/Kolkata",
			}).format(new Date(getValue<string>())),
	},
];
