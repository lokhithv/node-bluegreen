const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => res.send(`Hello from Node App! Time: ${new Date()}`));
app.get('/health', (req, res) => res.send('OK'));

app.listen(port, () => console.log(`App running on port ${port}`));
