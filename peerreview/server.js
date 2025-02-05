const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const port = 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// MySQL connection
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root', // Replace with your MySQL username
  password: 'jayanthan2006@', // Replace with your MySQL password
  database: 'assignment', // Replace with your database name
});

// Connect to MySQL
db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err);
  } else {
    console.log('Connected to MySQL database');
  }
});

app.post('/api/assignments', (req, res) => {
    const { title, date, startTime, stopTime } = req.body;
  
    // Validate title
    if (!title || typeof title !== 'string') {
      return res.status(400).json({ error: 'Title is required and must be a string' });
    }
  
    const query = 'INSERT INTO assignments (title, date, start_time, stop_time) VALUES (?, ?, ?, ?)';
    db.query(query, [title, date, startTime, stopTime], (err, result) => {
      if (err) {
        console.error('Error creating assignment:', err);
        res.status(500).json({ error: 'Something went wrong' });
      } else {
        res.status(201).json({ id: result.insertId, title, date, startTime, stopTime });
      }
    });
  });
// Get all assignments
app.get('/api/assignments', (req, res) => {
  const query = 'SELECT * FROM assignments';
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching assignments:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});

// Create a new task for an assignment
app.post('/api/tasks', (req, res) => {
  const { assignmentId, taskTitle, taskTime } = req.body;
  const query = 'INSERT INTO tasks (assignment_id, task_title, task_time) VALUES (?, ?, ?)';
  db.query(query, [assignmentId, taskTitle, taskTime], (err, result) => {
    if (err) {
      console.error('Error creating task:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(201).json({ id: result.insertId, assignmentId, taskTitle, taskTime });
    }
  });
});

// Get tasks for a specific assignment
app.get('/api/tasks/:assignmentId', (req, res) => {
  const { assignmentId } = req.params;
  const query = 'SELECT * FROM tasks WHERE assignment_id = ?';
  db.query(query, [assignmentId], (err, results) => {
    if (err) {
      console.error('Error fetching tasks:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
 app.get('/api/student', (req, res) => {
  const query = 'SELECT *FROM student';
  
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching student details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
// Get all faculty details
app.get('/api/faculty', (req, res) => {
  const query = 'SELECT * FROM faculty';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching faculty details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/api/student', (req, res) => {
  const query = 'SELECT * FROM students';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching faculty details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/api/questions', (req, res) => {
  const query = 'SELECT * FROM questions';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching   details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
app.get('/api/rank', (req, res) => {
  const query = 'SELECT * FROM rankassignments';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching   details:', err);
      res.status(500).json({ error: 'Something went wrong' });
    } else {
      res.status(200).json(results);
    }
  });
});
// Start the server
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});