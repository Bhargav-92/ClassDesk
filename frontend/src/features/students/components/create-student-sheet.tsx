import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2, X } from "lucide-react";
import { useForm } from "react-hook-form";
import {
	SheetRoot as Sheet,
	SheetContent,
	SheetHeader,
	SheetTitle,
	SheetDescription,
	SheetFooter,
} from "@/components/sheet";
import { useCreateStudent } from "../hooks/useCreateStudent";
import { createStudentSchema } from "../schemas/create-student-schema";
import type { StudentFormValues } from "../types/students";

type CreateStudentSheetProps = {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	onSaved?: () => void;
};
const defaultValues: StudentFormValues = {
	fname: "",
	lname: "",
	parentfName: "",
	parentlName: "",
	parentWhatsapp: "",
	joinedOn: "",
	monthlyFeeRupees: 0,
};
const fields = [
	{ name: "fname", label: "First name", type: "text" },
	{ name: "lname", label: "Last name", type: "text" },
	{ name: "parentfName", label: "Parent first name (optional)", type: "text" },
	{ name: "parentlName", label: "Parent last name (optional)", type: "text" },
	{ name: "parentWhatsapp", label: "WhatsApp number (optional)", type: "tel" },
	{ name: "joinedOn", label: "Joining date", type: "date" },
	{ name: "monthlyFeeRupees", label: "Monthly fee (₹)", type: "number" },
] as const;

export function CreateStudentSheet({
	open,
	onOpenChange,
	onSaved,
}: CreateStudentSheetProps) {
	const mutation = useCreateStudent();
	const {
		register,
		handleSubmit,
		reset,
		formState: { errors },
	} = useForm<StudentFormValues>({
		resolver: zodResolver(createStudentSchema),
		defaultValues,
	});
	function handleOpenChange(nextOpen: boolean) {
		if (mutation.isPending) return;
		if (!nextOpen) {
			reset();
			mutation.reset();
		}
		onOpenChange(nextOpen);
	}
	function onSubmit({ monthlyFeeRupees, ...values }: StudentFormValues) {
		mutation.mutate(
			{
				...values,
				parentfName: values.parentfName || null,
				parentlName: values.parentlName || null,
				parentWhatsapp: values.parentWhatsapp || null,
				monthlyFee: Math.round(monthlyFeeRupees * 100),
			},
			{
				onSuccess: () => {
					reset();
					mutation.reset();
					onOpenChange(false);
					onSaved?.();
				},
			},
		);
	}
	return (
		<Sheet open={open} onOpenChange={handleOpenChange}>
			<SheetContent>
				<SheetHeader>
					<div>
						<SheetTitle>Add student</SheetTitle>
						<SheetDescription>
							Welcome a student to your classroom.
						</SheetDescription>
					</div>
					<button
						type="button"
						className="icon-button"
						aria-label="Close form"
						disabled={mutation.isPending}
						onClick={() => handleOpenChange(false)}
					>
						<X />
					</button>
				</SheetHeader>
				<form
					className="sheet-form"
					noValidate
					onSubmit={handleSubmit(onSubmit)}
				>
					<div className="sheet-body">
						<fieldset className="form-fields" disabled={mutation.isPending}>
							<legend className="sr-only">Student details</legend>
							{fields.map(({ name, label, type }) => (
								<div className="form-field" key={name}>
									<label htmlFor={`student-${name}`}>{label}</label>
									<input
										id={`student-${name}`}
										type={type}
										step={name === "monthlyFeeRupees" ? "0.01" : undefined}
										min={name === "monthlyFeeRupees" ? 0 : undefined}
										aria-invalid={Boolean(errors[name])}
										aria-describedby={
											errors[name] ? `${name}-error` : undefined
										}
										{...register(name, { valueAsNumber: type === "number" })}
									/>
									{errors[name] && (
										<p className="field-error" id={`${name}-error`}>
											{errors[name]?.message}
										</p>
									)}
								</div>
							))}
						</fieldset>
						{mutation.isError && (
							<p className="form-error" role="alert">
								{mutation.error.message}
							</p>
						)}
					</div>
					<SheetFooter>
						<button
							type="button"
							className="button"
							disabled={mutation.isPending}
							onClick={() => handleOpenChange(false)}
						>
							Cancel
						</button>
						<button
							type="submit"
							className="button primary"
							disabled={mutation.isPending}
						>
							{mutation.isPending ? (
								<>
									<Loader2 className="spinning" />
									Adding…
								</>
							) : (
								"Add student"
							)}
						</button>
					</SheetFooter>
				</form>
			</SheetContent>
		</Sheet>
	);
}
