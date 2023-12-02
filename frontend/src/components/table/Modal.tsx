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

const styles = {
  backdrop: {
    position: 'fixed' as const,
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
    display: 'flex' as const, 
    flexDirection: 'column' as const, 
    alignItems: 'center' as const,
  },
  closeButton: {
    alignSelf: 'flex-end' as const,
    background: 'none',
    border: 'none',
    fontSize: '16px',
    cursor: 'pointer'
  }
};

export default Modal;
