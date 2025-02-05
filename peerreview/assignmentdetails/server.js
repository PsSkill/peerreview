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
  database: 'assignment_db'
});

app.get('/api/students', (req, res) => {
  const query = 'SELECT id, name FROM students'; // Assuming `students` table has columns `id` and `name`

  connection.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching student names:', err);
      return res.status(500).json({ error: 'Failed to retrieve students' });
    }
    res.status(200).json(results);
  });
});

// API endpoint to save assignment data
app.post('/api/assignments', (req, res) => {
  const { title, date, start_time, stop_time, explanation, number_of_students, numberoftasks, numberofranks, task_details, total_time } = req.body;

  const query = `
    INSERT INTO assignments (
      title, date, start_time, stop_time, explanation, number_of_students, numberoftasks, numberofranks, task_details, total_time
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  connection.query(
    query,
    [title, date, start_time, stop_time, explanation, number_of_students, numberoftasks, numberofranks, JSON.stringify(task_details), total_time],
    (err, results) => {
      if (err) {
        console.error('Error inserting data:', err);
        return res.status(500).json({ error: 'Failed to save assignment' });
      }
      res.status(201).json({ message: 'Assignment saved successfully', id: results.insertId });
    }
  );
});

// API endpoint to get all assignments data
app.get('/api/assignments', (req, res) => {
  const { title } = req.query; // Get the title from query parameter

  let query = 'SELECT * FROM assignments';
  if (title) {
    query += ' WHERE title = ?'; // Add a condition if title is provided
  }

  connection.query(query, [title], (err, results) => {
    if (err) {
      console.error('Error fetching data:', err);
      return res.status(500).json({ error: 'Failed to retrieve assignments' });
    }
    res.status(200).json(results); // Send the data back as a JSON response
  });
});

// Start the server
app.listen(5001, () => {
  console.log('Server is running on port 5001');
});
