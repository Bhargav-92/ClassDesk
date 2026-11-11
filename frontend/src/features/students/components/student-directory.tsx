import { CreateStudentSheet } from "./create-student-sheet";
import { studentName, parentName } from "../columns/student-display";
import { Spinner } from "@/components/app-loader";
import { useState } from "react";

import {
	flexRender,
	getCoreRowModel,
	getFilteredRowModel,
	getPaginationRowModel,
	getSortedRowModel,
	useReactTable,
} from "@tanstack/react-table";
import type {
	ColumnFiltersState,
	SortingState,
	VisibilityState,
} from "@tanstack/react-table";
import {
	ArrowDownToLine,
	ArrowDownUp,
	ArrowUp,
	ArrowDown,
	ChevronLeft,
	ChevronRight,
	Columns3,
	Search,
	SlidersHorizontal,
	Users,
	RefreshCw,
	X,
	Wallet,
	ArrowUpRight,
} from "lucide-react";
import { TeacherLayout } from "@/components/teacher-layout";
import { money } from "@/lib/format";
import { useStudents } from "../hooks/useStudents";
import { studentColumns } from "../columns/students-columns";

const emptyStudents: never[] = [];
export function StudentDirectory() {
	const query = useStudents();
	const [sheetOpen, setSheetOpen] = useState(false);
	const students = query.data?.data ?? emptyStudents;
	const isLoadingStudents =
		!query.data && (query.isPending || query.isFetching);
	const [search, setSearch] = useState("");
	const [sorting, setSorting] = useState<SortingState>([
		{ id: "name", desc: false },
	]);
	const [filters, setFilters] = useState<ColumnFiltersState>([]);
	const [visibility, setVisibility] = useState<VisibilityState>({});
	const [showFilters, setShowFilters] = useState(false);
	const [pagination, setPagination] = useState({ pageIndex: 0, pageSize: 10 });
	const table = useReactTable({
		data: students,
		columns: studentColumns,
		enableRowSelection: false,
		state: {
			globalFilter: search,
			sorting,
			columnFilters: filters,
			columnVisibility: visibility,
			pagination,
		},
		onGlobalFilterChange: setSearch,
		onSortingChange: setSorting,
		onColumnFiltersChange: setFilters,
		onColumnVisibilityChange: setVisibility,
		onPaginationChange: setPagination,
		getRowId: (row) => row.id,
		getCoreRowModel: getCoreRowModel(),
		getFilteredRowModel: getFilteredRowModel(),
		getSortedRowModel: getSortedRowModel(),
		getPaginationRowModel: getPaginationRowModel(),
	});
	const totalFee = students.reduce((sum, s) => sum + s.monthlyFee, 0);
	const contactCount = students.filter((s) => Boolean(s.parentWhatsapp)).length;
	const filteredCount = table.getFilteredRowModel().rows.length;
	function exportStudents() {
		const rows = table.getFilteredRowModel().rows;
		const escape = (value: unknown) =>
			`"${String(value ?? "")
				.replace(/^[=+@-]/, "'$&")
				.replaceAll('"', '""')}"`;
		const csv = [
			[
				"Student",
				"Parent / guardian",
				"WhatsApp",
				"Joined on",
				"Monthly fee (INR)",
				"Fee due date",
			],
			...rows.map(({ original: s }) => [
				studentName(s),
				parentName(s),
				s.parentWhatsapp,
				s.joinedOn,
				s.monthlyFee / 100,
				s.feeDueDate,
			]),
		]
			.map((row) => row.map(escape).join(","))
			.join("\r\n");
		const url = URL.createObjectURL(
			new Blob(["\uFEFF", csv], { type: "text/csv;charset=utf-8;" }),
		);
		const link = document.createElement("a");
		link.href = url;
		link.download = "classdesk-students.csv";
		link.click();
		URL.revokeObjectURL(url);
	}
	return (
		<TeacherLayout
			title="Students"
			studentCount={query.data ? students.length : undefined}
		>
			<div className="page-heading">
				<div>
					<div className="eyebrow">YOUR CLASSROOM, AT A GLANCE</div>
					<h1>
						Students<span className="heading-dot">.</span>
					</h1>
					<p>A familiar face. Every detail you need.</p>
				</div>
				<div className="page-actions">
					<button
						type="button"
						className="button primary"
						onClick={() => {
							setSheetOpen(true);
						}}
					>
						Add student
					</button>
					<button
						className="button"
						onClick={exportStudents}
						disabled={!filteredCount}
					>
						<ArrowDownToLine />
						Export students
					</button>
				</div>
			</div>
			<CreateStudentSheet
				open={sheetOpen}
				onOpenChange={setSheetOpen}
				onSaved={() => {
					setSearch("");
					setFilters([]);
					table.setPageIndex(0);
				}}
			/>
			<section className="summary-strip" aria-label="Student summary">
				<div>
					<span className="stat-icon">
						<Users />
					</span>
					<div>
						<span>Total students</span>
						<strong>
							{query.data ? students.length : "—"}
							<small>in your classroom</small>
						</strong>
					</div>
				</div>
				<div>
					<span className="stat-icon">
						<Wallet />
					</span>
					<div>
						<span>Monthly fees</span>
						<strong>
							{query.data ? money(totalFee) : "—"}
							<small>scheduled total</small>
						</strong>
					</div>
				</div>
				<div>
					<span className="stat-icon">
						<ArrowUpRight />
					</span>
					<div>
						<span>Parent contacts</span>
						<strong>
							{query.data ? contactCount : "—"}
							<small>with WhatsApp added</small>
						</strong>
					</div>
				</div>
			</section>
			<section className="directory-panel" aria-label="Student directory">
				<div className="panel-heading">
					<div>
						<h2>
							Student directory{" "}
							<span className="count-badge">
								{query.data ? students.length : "—"}
							</span>
						</h2>
						<p>Keep your students and their details close.</p>
					</div>
					<button
						className="icon-button"
						aria-label="Refresh students"
						disabled={query.isFetching}
						onClick={() => {
							void query.refetch();
						}}
					>
						<RefreshCw className={query.isFetching ? "spinning" : ""} />
					</button>
				</div>
				<div className="table-toolbar">
					<label className="search-field">
						<Search />
						<input
							placeholder="Search students, parents, numbers…"
							aria-label="Search students"
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
						<button
							className={`button ${showFilters ? "pressed" : ""}`}
							aria-expanded={showFilters}
							onClick={() => setShowFilters(!showFilters)}
						>
							<SlidersHorizontal />
							Filters{filters.length > 0 && <span className="filter-dot" />}
						</button>
						<details className="column-menu">
							<summary className="button">
								<Columns3 />
								Columns
							</summary>
							<div className="column-options">
								{table
									.getAllLeafColumns()
									.filter((c) => c.getCanHide())
									.map((column) => (
										<label key={column.id}>
											<input
												type="checkbox"
												checked={column.getIsVisible()}
												onChange={column.getToggleVisibilityHandler()}
											/>
											{String(column.columnDef.header)}
										</label>
									))}
							</div>
						</details>
					</div>
				</div>
				{showFilters && (
					<div className="filter-bar">
						<label>
							Parent / guardian
							<input
								placeholder="Filter by parent name"
								value={
									(table.getColumn("parentName")?.getFilterValue() as string) ??
									""
								}
								onChange={(e) =>
									table.getColumn("parentName")?.setFilterValue(e.target.value)
								}
							/>
						</label>
						<label>
							Fee due date
							<input
								type="date"
								aria-label="Filter by fee due date"
								value={
									(table.getColumn("feeDueDate")?.getFilterValue() as string) ??
									""
								}
								onChange={(e) =>
									table.getColumn("feeDueDate")?.setFilterValue(e.target.value)
								}
							/>
						</label>
						<button
							className="text-button"
							onClick={() => {
								setFilters([]);
								setSearch("");
							}}
						>
							Reset filters
						</button>
					</div>
				)}
				<div className="table-scroll">
					<table>
						<thead>
							{table.getHeaderGroups().map((group) => (
								<tr key={group.id}>
									{group.headers.map((header) => (
										<th
											key={header.id}
											scope="col"
											aria-sort={
												header.column.getCanSort()
													? header.column.getIsSorted() === "asc"
														? "ascending"
														: header.column.getIsSorted() === "desc"
															? "descending"
															: "none"
													: undefined
											}
										>
											{header.column.getCanSort() ? (
												<button
													onClick={header.column.getToggleSortingHandler()}
												>
													{flexRender(
														header.column.columnDef.header,
														header.getContext(),
													)}
													{header.column.getIsSorted() === "asc" ? (
														<ArrowUp />
													) : header.column.getIsSorted() === "desc" ? (
														<ArrowDown />
													) : (
														<ArrowDownUp />
													)}
												</button>
											) : (
												flexRender(
													header.column.columnDef.header,
													header.getContext(),
												)
											)}
										</th>
									))}
								</tr>
							))}
						</thead>
						<tbody>
							{isLoadingStudents ? (
								<tr>
									<td colSpan={table.getVisibleLeafColumns().length}>
										<Spinner label="Loading students…" />
									</td>
								</tr>
							) : (
								table.getRowModel().rows.map((row) => (
									<tr key={row.id}>
										{row.getVisibleCells().map((cell) => (
											<td key={cell.id}>
												{flexRender(
													cell.column.columnDef.cell,
													cell.getContext(),
												)}
											</td>
										))}
									</tr>
								))
							)}
						</tbody>
					</table>
				</div>
				{query.isError && !isLoadingStudents ? (
					<div className="empty-state" role="alert">
						<span className="empty-icon">
							<RefreshCw />
						</span>
						<h3>Let’s reconnect to your classroom</h3>
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
				) : !isLoadingStudents && !filteredCount ? (
					<div className="empty-state">
						<span className="empty-icon">
							<Users />
						</span>
						<h3>
							{students.length
								? "No students match your search"
								: "Your classroom starts here"}
						</h3>
						<p>
							{students.length
								? "Try another name or clear your filters."
								: "Students will appear here once they are added to your classroom."}
						</p>
						{students.length > 0 && (
							<button
								className="button"
								onClick={() => {
									setSearch("");
									setFilters([]);
								}}
							>
								Clear filters
							</button>
						)}
					</div>
				) : null}
				<footer className="table-footer">
					<span>
						{filteredCount
							? `${pagination.pageIndex * pagination.pageSize + 1}–${Math.min((pagination.pageIndex + 1) * pagination.pageSize, filteredCount)}`
							: "0"}{" "}
						of {filteredCount} students
					</span>
					<div>
						<label>
							Rows per page
							<select
								value={pagination.pageSize}
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
							Page {pagination.pageIndex + 1} of{" "}
							{Math.max(1, table.getPageCount())}
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
			<div className="page-footnote">
				<span>
					<span className="small-brand">classdesk.</span> More time for what
					matters.
				</span>
				<span>Made for the everyday classroom</span>
			</div>
		</TeacherLayout>
	);
}
