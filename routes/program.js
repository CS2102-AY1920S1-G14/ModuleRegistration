const express = require('express');
const router = express.Router();
const sql = require('../sql');

const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

let programs;

router.get('/', function(req, res, next) {
	pool.query(sql.query.load_programs, (err, p) => {
		if (err) {
		  unknownError(err, res);
		} else {
		  programs = p;
		  next();
    }
	});
});

router.get('/', function(req, res, next) {
  pool.query(sql.query.load_modules, (err, modules) => {
    if (err) {
      unknownError(err, res);
    } else {
      res.render('program', {
        title: 'Programmes',
        programs: programs.rows,
          role: req.session.role,
        username: req.session.username,
        modules: modules.rows,

      });
    }
  });
});

let program;

router.post('/', function(req, res, next) {
  program = req.body.program;

	pool.query(sql.query.add_program, [program], (err, data) => {
		if (err) {
      insertError('Programs', err, res);
		} else {
		  next();
    }
	});
});

router.post('/', function(req, res, next) {
  const modules = req.body.modules;

  for (let i = 0; i < modules.length; i++) {
    pool.query(sql.query.add_require,
      [program, modules[i]], (err, data) => {
      if (err) {
        insertError('Require', err, res);
      }
    });
  }
  // TODO: prompt admin insert queries successful
  return res.redirect('/program');
});

// TODO: As of now, unable to delete programs that are being referenced in Students

router.get('/delete_program', function(req, res, next) {
  const prog_name = req.query.program;

  pool.query(sql.query.delete_program, [prog_name], (err, data) => {
    if (err) {
      deleteError('Program', err, res);
    } else {
      return res.redirect('/program');
    }
  });
});

function deleteError(database, err, res) {
  console.error('Unable to delete from ' + database, err);
  return res.redirect('/program?delete=fail');
}

function unknownError(err, res) {
  console.error('Something went wrong', err);
  return res.redirect('/dashboard_admin?load_program=fail');
}

function insertError(database, err, res) {
  console.error('Unable to insert into ' + database, err);
  return res.redirect('/program?insert=fail');
}

module.exports = router;
