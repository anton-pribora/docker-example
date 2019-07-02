import React from 'react';
import './App.css';

const config = require('./Config');

function App() {
  return (
    <div className="App">
      <h1>My awesome react app and more!</h1>
      <cite>{config.cite}</cite>
      <hr/>
      <code>
        <pre>
          APP Version: {config.app.version}
          {"\n"}
          APP Env: {config.app.env}
          {"\n"}
          APP Name: {config.app.name}
        </pre>
      </code>
    </div>
  );
}

export default App;