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
	Wallet,
	ArrowDownUp,
	ChevronLeft,
	ChevronRight,
	X,
} from "lucide-react";
import { TeacherLayout } from "@/components/teacher-layout";
import { Spinner } from "@/components/app-loader";
import { money } from "@/lib/format";
import { useFees } from "../hooks/useFees";
import { feesColumns } from "../columns/fees-columns";
import type { FeePayment } from "../types/fees";
const empty: FeePayment[] = [];
export function FeesPage() {
	const query = useFees();
	const data = query.data?.data ?? empty;
	const loading = !query.data && (query.isPending || query.isFetching);
	const [search, setSearch] = useState("");
	const [sorting, setSorting] = useState<SortingState>([
		{ id: "paidOn", desc: true },
	]);
	const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([]);
	const table = useReactTable({
		data,
		columns: feesColumns,
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
		<TeacherLayout title="Fees">
			<div className="page-heading">
				<div>
					<div className="eyebrow">YOUR CLASSROOM ACCOUNTS</div>
					<h1>
						Fees<span className="heading-dot">.</span>
					</h1>
					<p>Every payment, neatly recorded.</p>
				</div>
				<button
					className="button"
					disabled={query.isFetching}
					onClick={() => {
						void query.refetch();
					}}
				>
					<RefreshCw className={query.isFetching ? "spinning" : ""} />
					Refresh payments
				</button>
			</div>
			<section className="summary-strip" aria-label="Payment summary">
				<div>
					<span className="stat-icon">
						<Wallet />
					</span>
					<div>
						<span>Total received</span>
						<strong>
							{query.data
								? money(data.reduce((sum, p) => sum + p.feesAmount, 0))
								: "—"}
							<small>all recorded payments</small>
						</strong>
					</div>
				</div>
				<div>
					<div>
						<span>Payments</span>
						<strong>
							{query.data ? data.length : "—"}
							<small>payment records</small>
						</strong>
					</div>
				</div>
				<div>
					<div>
						<span>Monthly fee records</span>
						<strong>
							{query.data ? new Set(data.map((p) => p.monthlyFeeId)).size : "—"}
							<small>with payments recorded</small>
						</strong>
					</div>
				</div>
			</section>
			<section className="directory-panel" aria-label="Payment history">
				<div className="panel-heading">
					<div>
						<h2>
							Payment history{" "}
							<span className="count-badge">
								{query.data ? data.length : "—"}
							</span>
						</h2>
						<p>Full and partial payments, shown as individual records.</p>
					</div>
				</div>
				<div className="table-toolbar">
					<label className="search-field">
						<Search />
						<input
							aria-label="Search payments"
							placeholder="Search student name or payment reference…"
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
							Paid in{" "}
							<input
								type="month"
								aria-label="Payment month"
								value={
									(table.getColumn("paidOn")?.getFilterValue() as string) ?? ""
								}
								onChange={(e) =>
									table.getColumn("paidOn")?.setFilterValue(e.target.value)
								}
							/>
						</label>
						{columnFilters.length > 0 && (
							<button
								className="text-button"
								onClick={() => setColumnFilters([])}
							>
								Clear month
							</button>
						)}
					</div>
				</div>
				{query.isError && !loading && (
					<div className="empty-state" role="alert">
						<h3>Payments couldn’t be loaded</h3>
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
									<td colSpan={feesColumns.length}>
										<Spinner label="Loading payments…" />
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
							<Wallet />
						</span>
						<h3>
							{data.length
								? "No matching payments"
								: "No payments recorded yet"}
						</h3>
						<p>
							{data.length
								? "Try another student name, reference or payment month."
								: "Payments recorded in your classroom will appear here."}
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
						of {count} payments
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
