const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// Create a MySQL connection
const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'jayanthan2006@',
  database: 'ranking'
});

app.get('/api/rank', (req, res) => {
  const query = 'SELECT *from rankings'; // Assuming `students` table has columns `id` and `name`

  connection.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching  ranking :', err);
      return res.status(500).json({ error: 'Failed to retrieve ' });
    }
    res.status(200).json(results);
  });
});

app.get('/api/result', (req, res) => {
  const query = 'SELECT *from results'; // Assuming `students` table has columns `id` and `name`

  connection.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching  ranking :', err);
      return res.status(500).json({ error: 'Failed to retrieve ' });
    }
    res.status(200).json(results);
  });
});
// Start the server
app.listen(5002, () => {
  console.log('Server is running on port 5002');
});
