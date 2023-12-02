import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { useEffect } from 'react';
import Login from './components/login/Login';
import GameTable from './components/table/Table';
import Game from './components/game/Game';
import ProtectedRoute from './components/protectedRoute';
import ProfilePicture from './components/profile-picture/ProfilePicture';
import background from './assets/poker-background.jpg';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(
    sessionStorage.getItem('isAuthenticated') === 'true'
  );

  useEffect(() => {
    sessionStorage.setItem('isAuthenticated', isAuthenticated.toString());
  }, [isAuthenticated]);

  return (
    <Router>
      <div className="App">
        <Routes>
          <Route path="/" element={<Login setIsAuthenticated={setIsAuthenticated} />} />
          <Route path="/game-table" element={
            <ProtectedRoute isAuthenticated={isAuthenticated} authenticationPath="/">
              {/* <div className='fluid-container' style={{
                backgroundImage: `url(${background})`,
              }}> */}
              <ProfilePicture />
              <GameTable />
              {/* </div> */}
            </ProtectedRoute>
          } />
          <Route path="/table/:gameId" element={
            <ProtectedRoute isAuthenticated={isAuthenticated} authenticationPath="/">
              <Game />
            </ProtectedRoute>
          } />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
