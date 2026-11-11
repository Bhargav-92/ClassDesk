import { z } from "zod";

export const createStudentSchema = z.object({
	fname: z.string().trim().min(1, "First name is required").max(100),
	lname: z.string().trim().min(1, "Last name is required").max(100),
	parentfName: z.string().trim().max(100),
	parentlName: z.string().trim().max(100),
	parentWhatsapp: z.string().trim().max(16),
	joinedOn: z.string().min(1, "Joining date is required"),
	monthlyFeeRupees: z
		.number({ error: "Enter the monthly fee" })
		.min(0)
		.max(21474836.47),
});
