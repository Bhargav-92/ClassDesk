import { useMutation, useQueryClient } from "@tanstack/react-query";
import { createAttendance } from "../api/create-attendance";

export function useCreateAttendance() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: createAttendance,
		meta: { successMessage: "Attendance saved successfully" },
		onSuccess: async () => {
			await queryClient.invalidateQueries();
		},
	});
}
