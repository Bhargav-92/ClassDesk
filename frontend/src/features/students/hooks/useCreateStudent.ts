import { useMutation, useQueryClient } from "@tanstack/react-query";
import { createStudent } from "../api/create-student";

export function useCreateStudent() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: createStudent,
		meta: { successMessage: "Student created successfully" },
		onSuccess: async () => {
			await queryClient.invalidateQueries();
		},
	});
}
