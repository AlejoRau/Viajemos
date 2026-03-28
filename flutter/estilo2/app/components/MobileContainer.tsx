import { ReactNode } from "react";

interface MobileContainerProps {
  children: ReactNode;
  className?: string;
}

export function MobileContainer({ children, className = "" }: MobileContainerProps) {
  return (
    <div className={`max-w-md mx-auto ${className}`}>
      {children}
    </div>
  );
}
