import { z } from "zod";


const requiredName = (label: string) =>
  z.string().trim().min(1, `${label} is required`).max(100, `${label} must be 100 characters or fewer`);
const optionalName = z.string().trim().max(100).nullish().transform(value => value || null);

function todayInIndia() {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Kolkata", year: "numeric", month: "2-digit", day: "2-digit",
  }).formatToParts(new Date());
  const part = (type: string) => parts.find(p => p.type === type)?.value;
  return `${part("year")}-${part("month")}-${part("day")}`;
}

export const createStudentSchema = z.strictObject({
  fname: requiredName("First name"),
  lname: requiredName("Last name"),
  parentfName: optionalName,
  parentlName: optionalName,
  parentWhatsapp: z.string().trim()
    .refine(value => !value || /^\+?[1-9]\d{7,14}$/.test(value), "WhatsApp number must contain 8–15 digits with an optional + country code")
    .nullish().transform(value => value || null),
  joinedOn: z.iso.date({ error: "Joining date must be a valid YYYY-MM-DD date" }),
  monthlyFee: z.number().int().min(0).max(2147483647), // Paise; PostgreSQL integer range.
});


