import { useQuery } from "@tanstack/react-query";
import { getStudents } from "../api/get-students";
import { studentKeys } from "../queries/keys";

export function useStudents() {
	return useQuery({
		queryKey: studentKeys.list(),
		queryFn: ({ signal }) => getStudents(signal),
	});
}
