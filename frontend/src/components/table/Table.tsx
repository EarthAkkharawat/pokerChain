import React from 'react';
import { useNavigate } from 'react-router-dom';

const GameTable: React.FC = () => {
    const navigate = useNavigate();

    const joinTable = (tableId: number) => {
        // Logic to join the table
        console.log(`Joining table ${tableId}`);
        navigate(`/table/${tableId}`);
        // You might want to route to a specific table view here
    };

    return (
        <div>
            <h2>Available Poker Tables</h2>
            {/* Sample data for tables. Replace with your own data source */}
            {[1, 2, 3].map(tableId => (
                <div key={tableId} onClick={() => joinTable(tableId)}>
                    <p>Table {tableId}</p>
                    <button>Join Table</button>
                </div>
            ))}
        </div>
    );
};

export default GameTable;
