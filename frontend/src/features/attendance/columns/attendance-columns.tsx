import type { ColumnDef } from "@tanstack/react-table";
import { dateLabel } from "@/lib/format";
import type { AttendanceRecord } from "../types/attendance";
export const attendanceColumns: ColumnDef<AttendanceRecord>[] = [
	{
		accessorKey: "studentName",
		header: "Student",
		cell: ({ getValue }) => (
			<strong className="amount">{getValue<string>() || "—"}</strong>
		),
	},
	{
		accessorKey: "classDate",
		header: "Class date",
		cell: ({ getValue }) => dateLabel(getValue<string>()),
		filterFn: "equalsString",
	},
	{
		accessorKey: "status",
		header: "Status",
		filterFn: "equalsString",
		cell: ({ getValue }) => (
			<span className={`attendance-status status-${getValue<string>()}`}>
				{getValue<string>()}
			</span>
		),
	},
];
