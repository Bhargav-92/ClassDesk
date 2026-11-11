import { useQuery } from "@tanstack/react-query";
import { getFees } from "../api/get-fees";
import { feeKeys } from "../queries/keys";
export function useFees() {
	return useQuery({
		queryKey: feeKeys.list(),
		queryFn: ({ signal }) => getFees(signal),
	});
}
