import React, { FC, ReactNode } from "react";

interface ModalProps {
  children: ReactNode;
  onClose: () => void;
}

const Modal: FC<ModalProps> = ({ children, onClose }) => {
  return (
    <div style={styles.backdrop}>
      <div style={styles.modal}>
        <button style={styles.closeButton} onClick={onClose}>X</button>
        {children}
      </div>
    </div>
  );
};

// Updated styles with specific types for CSS properties
const styles = {
  backdrop: {
    position: 'fixed' as const, // Using 'as const' for specific CSS property types
    top: 0,
    left: 0,
    width: '100%',
    height: '100%',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000,
  },
  modal: {
    backgroundColor: 'white',
    padding: '20px',
    borderRadius: '8px',
    boxShadow: '0 4px 8px rgba(0, 0, 0, 0.1)',
    minWidth: '300px',
    minHeight: '200px',
    display: 'flex' as const, // Explicit type for 'display'
    flexDirection: 'column' as const, // Explicit type for 'flexDirection'
    alignItems: 'center' as const, // Explicit type for 'alignItems'
  },
  closeButton: {
    alignSelf: 'flex-end' as const, // Explicit type for 'alignSelf'
    background: 'none',
    border: 'none',
    fontSize: '16px',
    cursor: 'pointer'
  }
};

export default Modal;
