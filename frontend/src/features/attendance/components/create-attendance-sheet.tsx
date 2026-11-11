import { useForm } from "react-hook-form";
import { LoaderCircle } from "lucide-react";
import { Sheet } from "@/components/sheet";
import { Spinner } from "@/components/app-loader";
import { useStudents } from "@/features/students";
import { studentName } from "@/features/students/columns/student-display";
import { useCreateAttendance } from "../hooks/useCreateAttendance";
import type { CreateAttendancePayload } from "../types/attendance";

function todayInIndia() {
	const parts = new Intl.DateTimeFormat("en-CA", {
		timeZone: "Asia/Kolkata",
		year: "numeric",
		month: "2-digit",
		day: "2-digit",
	}).formatToParts(new Date());
	const get = (type: string) => parts.find((p) => p.type === type)?.value;
	return `${get("year")}-${get("month")}-${get("day")}`;
}
export function CreateAttendanceSheet({
	open,
	onOpenChange,
	onSaved,
}: {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	onSaved: () => void;
}) {
	return open ? (
		<AttendanceForm onOpenChange={onOpenChange} onSaved={onSaved} />
	) : null;
}
function AttendanceForm({
	onOpenChange,
	onSaved,
}: {
	onOpenChange: (open: boolean) => void;
	onSaved: () => void;
}) {
	const students = useStudents();
	const mutation = useCreateAttendance();
	const today = todayInIndia();
	const {
		register,
		handleSubmit,
		getValues,
		formState: { errors, isSubmitting },
	} = useForm<CreateAttendancePayload>({
		defaultValues: { studentId: "", classDate: today, status: "present" },
		mode: "onBlur",
	});
	const busy = isSubmitting || mutation.isPending;
	async function submit(values: CreateAttendancePayload) {
		try {
			await mutation.mutateAsync(values);
			onSaved();
			onOpenChange(false);
		} catch {
			/* Mutation error is rendered without clearing the form. */
		}
	}
	const options = [...(students.data?.data ?? [])].sort((a, b) =>
		studentName(a).localeCompare(studentName(b)),
	);
	return (
		<Sheet
			open
			onOpenChange={onOpenChange}
			title="Mark attendance"
			description="Record a student’s attendance for a class."
			busy={busy}
		>
			{students.isPending ? (
				<Spinner label="Loading students…" />
			) : students.isError ? (
				<div className="sheet-body" role="alert">
					<p>{students.error.message}</p>
					<button
						className="button"
						onClick={() => {
							void students.refetch();
						}}
					>
						Retry loading students
					</button>
				</div>
			) : (
				<form className="sheet-form" noValidate onSubmit={handleSubmit(submit)}>
					<div className="sheet-body">
						<fieldset
							className="form-fields"
							disabled={busy || !options.length}
						>
							<legend className="sr-only">Attendance details</legend>
							<div
								className="form-field"
								data-invalid={Boolean(errors.studentId)}
							>
								<label htmlFor="attendance-student">
									Student <span aria-hidden="true">*</span>
								</label>
								<select
									id="attendance-student"
									aria-invalid={Boolean(errors.studentId)}
									aria-describedby={
										errors.studentId ? "student-error" : undefined
									}
									{...register("studentId", {
										required: "Choose a student.",
										validate: (value) =>
											options.some((s) => s.id === value) ||
											"Choose an existing student.",
									})}
								>
									<option value="">Choose a student</option>
									{options.map((s) => (
										<option key={s.id} value={s.id}>
											{studentName(s)} · Joined {s.joinedOn} ·{" "}
											{s.id.slice(0, 8)}
										</option>
									))}
								</select>
								{errors.studentId && (
									<p className="field-error" id="student-error">
										{errors.studentId.message}
									</p>
								)}
							</div>
							<div
								className="form-field"
								data-invalid={Boolean(errors.classDate)}
							>
								<label htmlFor="attendance-date">
									Class date <span aria-hidden="true">*</span>
								</label>
								<input
									id="attendance-date"
									type="date"
									max={today}
									aria-invalid={Boolean(errors.classDate)}
									aria-describedby={
										errors.classDate ? "date-error" : "date-hint"
									}
									{...register("classDate", {
										required: "Choose a class date.",
										validate: (value) => {
											if (
												!/^\d{4}-\d{2}-\d{2}$/.test(value) ||
												Number.isNaN(Date.parse(value)) ||
												new Date(value).toISOString().slice(0, 10) !== value
											)
												return "Enter a valid date.";
											if (value > today)
												return "Choose today or an earlier date.";
											const student = options.find(
												(s) => s.id === getValues("studentId"),
											);
											return (
												!student ||
												value >= student.joinedOn ||
												"The class date must be on or after the student joined."
											);
										},
									})}
								/>
								<p className="field-hint" id="date-hint">
									Dates follow India Standard Time.
								</p>
								{errors.classDate && (
									<p className="field-error" id="date-error">
										{errors.classDate.message}
									</p>
								)}
							</div>
							<div className="form-field">
								<label htmlFor="attendance-status">
									Status <span aria-hidden="true">*</span>
								</label>
								<select
									id="attendance-status"
									aria-invalid={Boolean(errors.status)}
									{...register("status", {
										required: "Choose a status.",
										validate: (value) =>
											["present", "absent", "late"].includes(value) ||
											"Choose a valid status.",
									})}
								>
									<option value="present">Present</option>
									<option value="absent">Absent</option>
									<option value="late">Late</option>
								</select>
								{errors.status && (
									<p className="field-error">{errors.status.message}</p>
								)}
							</div>
						</fieldset>
						{!options.length && (
							<p role="status">
								Add a student to your classroom before marking attendance.
							</p>
						)}
						{mutation.isError && (
							<p className="form-error" role="alert">
								{mutation.error.message}
							</p>
						)}
					</div>
					<footer className="sheet-footer">
						<button
							type="button"
							className="button"
							disabled={busy}
							onClick={() => onOpenChange(false)}
						>
							Cancel
						</button>
						<button
							type="submit"
							className="button primary"
							disabled={busy || !options.length}
						>
							{busy && <LoaderCircle className="spinning" />}
							{busy ? "Saving…" : "Save attendance"}
						</button>
					</footer>
				</form>
			)}
		</Sheet>
	);
}
