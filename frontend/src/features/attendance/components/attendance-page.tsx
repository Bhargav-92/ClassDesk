import { useState } from "react";
import {
	flexRender,
	getCoreRowModel,
	getFilteredRowModel,
	getSortedRowModel,
	getPaginationRowModel,
	useReactTable,
} from "@tanstack/react-table";
import type { SortingState, ColumnFiltersState } from "@tanstack/react-table";
import {
	Search,
	RefreshCw,
	CalendarDays,
	ArrowDownUp,
	ChevronLeft,
	ChevronRight,
	X,
} from "lucide-react";
import { TeacherLayout } from "@/components/teacher-layout";
import { Spinner } from "@/components/app-loader";
import { useAttendance } from "../hooks/useAttendance";
import { attendanceColumns } from "../columns/attendance-columns";
import type { AttendanceRecord } from "../types/attendance";
const empty: AttendanceRecord[] = [];
export function AttendancePage() {
	const query = useAttendance();
	const data = query.data?.data ?? empty;
	const loading = !query.data && (query.isPending || query.isFetching);
	const [search, setSearch] = useState("");
	const [sorting, setSorting] = useState<SortingState>([
		{ id: "classDate", desc: true },
	]);
	const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([]);
	const table = useReactTable({
		data,
		columns: attendanceColumns,
		enableRowSelection: false,
		state: { globalFilter: search, sorting, columnFilters },
		onGlobalFilterChange: setSearch,
		onSortingChange: setSorting,
		onColumnFiltersChange: setColumnFilters,
		getRowId: (r) => r.id,
		getCoreRowModel: getCoreRowModel(),
		getFilteredRowModel: getFilteredRowModel(),
		getSortedRowModel: getSortedRowModel(),
		getPaginationRowModel: getPaginationRowModel(),
		initialState: { pagination: { pageSize: 10 } },
	});
	const count = table.getFilteredRowModel().rows.length;
	const page = table.getState().pagination;
	return (
		<TeacherLayout title="Attendance">
			<div className="page-heading">
				<div>
					<div className="eyebrow">THE CLASSROOM REGISTER</div>
					<h1>
						Attendance<span className="heading-dot">.</span>
					</h1>
					<p>A clear record of who was here.</p>
				</div>
				<button
					className="button"
					disabled={query.isFetching}
					onClick={() => {
						void query.refetch();
					}}
				>
					<RefreshCw className={query.isFetching ? "spinning" : ""} />
					Refresh attendance
				</button>
			</div>
			<section className="summary-strip" aria-label="Attendance summary">
				{(["present", "absent", "late"] as const).map((status) => (
					<div key={status}>
						<span className="stat-icon">
							<CalendarDays />
						</span>
						<div>
							<span className="status-label">{status}</span>
							<strong>
								{query.data
									? table
											.getFilteredRowModel()
											.rows.filter((r) => r.original.status === status).length
									: "—"}
								<small>matching records</small>
							</strong>
						</div>
					</div>
				))}
			</section>
			<section className="directory-panel" aria-label="Attendance register">
				<div className="panel-heading">
					<div>
						<h2>
							Attendance register{" "}
							<span className="count-badge">
								{query.data ? data.length : "—"}
							</span>
						</h2>
						<p>Browse attendance by student, class date and status.</p>
					</div>
				</div>
				<div className="table-toolbar">
					<label className="search-field">
						<Search />
						<input
							aria-label="Search attendance"
							placeholder="Search student name…"
							value={search}
							onChange={(e) => setSearch(e.target.value)}
						/>
						{search && (
							<button
								className="icon-button"
								aria-label="Clear search"
								onClick={() => setSearch("")}
							>
								<X />
							</button>
						)}
					</label>
					<div className="toolbar-actions">
						<label className="payment-month">
							Status
							<select
								aria-label="Attendance status"
								value={
									(table.getColumn("status")?.getFilterValue() as string) ?? ""
								}
								onChange={(e) =>
									table.getColumn("status")?.setFilterValue(e.target.value)
								}
							>
								<option value="">All statuses</option>
								<option value="present">Present</option>
								<option value="absent">Absent</option>
								<option value="late">Late</option>
							</select>
						</label>
						<label className="payment-month">
							Class date{" "}
							<input
								type="date"
								aria-label="Class date"
								value={
									(table.getColumn("classDate")?.getFilterValue() as string) ??
									""
								}
								onChange={(e) =>
									table.getColumn("classDate")?.setFilterValue(e.target.value)
								}
							/>
						</label>
						{columnFilters.length > 0 && (
							<button
								className="text-button"
								onClick={() => setColumnFilters([])}
							>
								Clear filters
							</button>
						)}
					</div>
				</div>
				{query.isError && !loading && (
					<div className="empty-state" role="alert">
						<h3>Attendance couldn’t be loaded</h3>
						<p>{query.error.message}</p>
						<button
							className="button"
							onClick={() => {
								void query.refetch();
							}}
						>
							Try again
						</button>
					</div>
				)}
				<div className="table-scroll">
					<table>
						<thead>
							{table.getHeaderGroups().map((g) => (
								<tr key={g.id}>
									{g.headers.map((h) => (
										<th
											key={h.id}
											scope="col"
											aria-sort={
												h.column.getIsSorted() === "asc"
													? "ascending"
													: h.column.getIsSorted() === "desc"
														? "descending"
														: "none"
											}
										>
											<button onClick={h.column.getToggleSortingHandler()}>
												{flexRender(h.column.columnDef.header, h.getContext())}
												<ArrowDownUp />
											</button>
										</th>
									))}
								</tr>
							))}
						</thead>
						<tbody>
							{loading ? (
								<tr>
									<td colSpan={attendanceColumns.length}>
										<Spinner label="Loading attendance…" />
									</td>
								</tr>
							) : (
								table.getRowModel().rows.map((r) => (
									<tr key={r.id}>
										{r.getVisibleCells().map((c) => (
											<td key={c.id}>
												{flexRender(c.column.columnDef.cell, c.getContext())}
											</td>
										))}
									</tr>
								))
							)}
						</tbody>
					</table>
				</div>
				{!loading && !query.isError && !count && (
					<div className="empty-state">
						<span className="empty-icon">
							<CalendarDays />
						</span>
						<h3>
							{data.length
								? "No matching attendance"
								: "No attendance recorded yet"}
						</h3>
						<p>
							{data.length
								? "Try another student name, class date or status."
								: "Attendance records will appear here once they are entered."}
						</p>
						{data.length > 0 && (
							<button
								className="button"
								onClick={() => {
									setSearch("");
									setColumnFilters([]);
								}}
							>
								Clear filters
							</button>
						)}
					</div>
				)}
				<footer className="table-footer">
					<span>
						{count
							? `${page.pageIndex * page.pageSize + 1}–${Math.min((page.pageIndex + 1) * page.pageSize, count)}`
							: "0"}{" "}
						of {count} records
					</span>
					<div>
						<label>
							Rows per page
							<select
								value={page.pageSize}
								onChange={(e) => table.setPageSize(Number(e.target.value))}
							>
								{[10, 20, 50].map((n) => (
									<option key={n} value={n}>
										{n}
									</option>
								))}
							</select>
						</label>
						<span>
							Page {page.pageIndex + 1} of {Math.max(1, table.getPageCount())}
						</span>
						<button
							className="icon-button"
							aria-label="Previous page"
							disabled={!table.getCanPreviousPage()}
							onClick={() => table.previousPage()}
						>
							<ChevronLeft />
						</button>
						<button
							className="icon-button"
							aria-label="Next page"
							disabled={!table.getCanNextPage()}
							onClick={() => table.nextPage()}
						>
							<ChevronRight />
						</button>
					</div>
				</footer>
			</section>
		</TeacherLayout>
	);
}
