const express = require('express');
const router = express.Router();
const sql = require('../sql');
const bcrypt = require('bcryptjs');

const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

var success = false;

/* GET Register Page */
router.get('/', function(req, res, next) {
  pool.query(sql.query.load_programs, (err, data) => {
    if (err) {
      unknownError(err, res);
    } else {
      res.render('register', {
        title: 'Register',
        programs: data.rows,
        data_undefined: req.query.data_undefined,
        password_hash: req.query.password_hash,
        insert_database: req.query.insert_database,
        no_role: req.query.no_role,
        unknown: req.query.unknown,
        user_already_exist: req.query.user_already_exist,
        success: false
      });
    }
  });
});

router.post('/', function(req, res, next) {
  const username = req.body.username;

  // Check if username exists
  pool.query(sql.query.auth_user, [username], (err, data) => {
    if (err) {
      unknownError(err, res);
    } else if (data.rows[0].exists) {
      userExistsError(res);
    } else {
      next();
    }
  });
});

const saltRounds = 10;
router.post('/', function(req, res, next) {
  const username = req.body.username;
  const password = req.body.password;

  // Generate hash
  bcrypt.genSalt(saltRounds, function (err, salt) {
    if (err) {
      hashFailedError(err, res);
    }
    bcrypt.hash(password, salt, function(err, hash) {
      if (err) {
        hashFailedError(err, res);
      }
      // Insert user to Users
      else {
        pool.query(sql.query.add_user, [username, hash], (err, data) => {
          if (err) {
            insertError('Users', err, res);
          } else if (data === undefined) {
            dataUndefinedError(res);
          } else {
            next();
          }
        });
      }
    })
  });
});

router.post('/', function(req, res, next) {
  const username = req.body.username;
  const role = req.body.role;
  const seniority = req.body.seniority;
  const program = req.body.program;

  // If user is a Student, insert to Students
  if (role === 'Student') {
    pool.query(sql.query.add_student, [username, seniority, program], (err, data) => {
      if (err) {
        success = false;
        insertError('Students', err, res);
      } else if (data === undefined) {
        success = false;
        dataUndefinedError(res);
      } else {
        success = true;
        res.redirect('/register');
      }
    });
    // TODO: prompt student registration successful
  }
  // If user is an Admin, insert to Admins
  else if (role === 'Admin') {
    pool.query(sql.query.add_admin, [username], (err, data) => {
      if (err) {
        success = false;
        insertError('Admins', err, res);
      } else if (data === undefined) {
        success = false;
        dataUndefinedError(res);
      } else {
        success = true;
        res.redirect('/register');
      }
    });
    // TODO prompt admin registration successful
  }
  // User's role is neither a Student or an Admin
  else {
    noRoleError(res);
  }
});

function dataUndefinedError(res) {
  console.error('Data is undefined');
  return res.redirect('/register?data_undefined=fail');
}

function hashFailedError(err, res) {
  console.error('Hash failed');
  return res.redirect('/register?password_hash=fail');
}

function insertError(databaseName, err, res) {
  console.error('Unable to insert into ' + databaseName, err);
  return res.redirect('/register?insert_database=fail');
}

function noRoleError(res) {
  console.error('Role is neither a Student nor an Admin');
  return res.redirect('/register?no_role=fail');
}

function unknownError(err, res) {
  console.error('Something went wrong', err);
  return res.redirect('/register?unknown=fail');
}

function userExistsError(res) {
  console.info('User already exists in database');
  return res.redirect('/register?user_already_exist=fail');
}

module.exports = router;