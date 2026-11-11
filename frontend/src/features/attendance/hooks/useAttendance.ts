import { useQuery } from "@tanstack/react-query";
import { getAttendance } from "../api/get-attendance";
import { attendanceKeys } from "../queries/keys";
export function useAttendance() {
	return useQuery({
		queryKey: attendanceKeys.list(),
		queryFn: ({ signal }) => getAttendance(signal),
	});
}
