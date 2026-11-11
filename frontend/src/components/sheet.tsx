import * as Dialog from "@radix-ui/react-dialog";
import { X } from "lucide-react";
import type { ReactNode } from "react";

export function Sheet({
	open,
	onOpenChange,
	title,
	description,
	children,
	busy = false,
}: {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	title: string;
	description: string;
	children: ReactNode;
	busy?: boolean;
}) {
	return (
		<Dialog.Root
			open={open}
			onOpenChange={(next) => {
				if (!busy) onOpenChange(next);
			}}
		>
			<Dialog.Portal>
				<Dialog.Overlay className="sheet-overlay" />
				<Dialog.Content
					className="sheet-content"
					onEscapeKeyDown={(e) => {
						if (busy) e.preventDefault();
					}}
					onInteractOutside={(e) => {
						if (busy) e.preventDefault();
					}}
				>
					<header className="sheet-header">
						<div>
							<Dialog.Title>{title}</Dialog.Title>
							<Dialog.Description>{description}</Dialog.Description>
						</div>
						<Dialog.Close
							className="icon-button"
							aria-label="Close form"
							disabled={busy}
						>
							<X />
						</Dialog.Close>
					</header>
					{children}
				</Dialog.Content>
			</Dialog.Portal>
		</Dialog.Root>
	);
}

export const SheetRoot = Dialog.Root;
export const SheetTitle = Dialog.Title;
export const SheetDescription = Dialog.Description;
export function SheetContent({ children }: { children: ReactNode }) {
	return (
		<Dialog.Portal>
			<Dialog.Overlay className="sheet-overlay" />
			<Dialog.Content className="sheet-content">{children}</Dialog.Content>
		</Dialog.Portal>
	);
}
export function SheetHeader({ children }: { children: ReactNode }) {
	return <header className="sheet-header">{children}</header>;
}
export function SheetFooter({ children }: { children: ReactNode }) {
	return <footer className="sheet-footer">{children}</footer>;
}
