const express = require('express');
const app = express();
const port = 3000;

// Detect which environment this container represents (default: BLUE)
const ENV_COLOR = process.env.ENV_COLOR || "BLUE";

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>${ENV_COLOR} Environment</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            text-align: center;
            background-color: ${ENV_COLOR === "BLUE" ? "#007BFF" : "#28A745"};
            color: white;
            padding: 50px;
          }
          h1 {
            font-size: 50px;
          }
          p {
            font-size: 20px;
          }
        </style>
      </head>
      <body>
        <h1>${ENV_COLOR} ENVIRONMENT</h1>
        <p>Hello from Node App! Time: ${new Date().toLocaleTimeString()}</p>
        <p>Running on port ${port}</p>
      </body>
    </html>
  `);
});

app.get('/health', (req, res) => res.send('OK'));

app.listen(port, () => {
  console.log(`✅ ${ENV_COLOR} App running on port ${port}`);
});
