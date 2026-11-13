export interface AuthUser {
	id: string;
	name: string;
	email: string;
}
export interface LoginPayload {
	email: string;
	password: string;
}
