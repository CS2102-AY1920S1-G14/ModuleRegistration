const express = require('express');
const router = express.Router();
const sql = require('../sql');

const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

let modules;

router.get('/', function(req, res, next) {
	pool.query(sql.query.load_modules, (err, m) => {
		if (err) {
		  unknownError(err, res);
		} else {
		  modules = m;
		  next();
    }
	});
});

router.get('/', function(req, res, next) {
  pool.query(sql.query.load_prereqs, (err, p) => {
    if (err) {
      unknownError(err, res);
    } else {
      res.render('prereq', {
        title: 'Prerequisites',
        children: modules.rows,
        prereqs: p.rows,
        username: req.session.username,
        role: req.session.role
      });
    }
  });
});

router.get('/select_child', function(req, res, next) {
  const child = req.query.child;
  const childDigits = getDigitsInString(child);
  let parents = [];

  pool.query(sql.query.load_modules, (err, m) => {
    if (err) {
      getError('Modules', err, res);
    } else {
      let trigger = true;
      if (trigger) {
        let modules = m.rows;
        for (let i = 0; i < modules.length; i++) {
          if (childDigits > getDigitsInString(modules[i].mod_code)) {
            parents.push({mod_code: modules[i].mod_code, mod_name: modules[i].mod_name});
          }
        }
        trigger = false;
      }
      if (!trigger) {
        res.render('prereq_child', {
          title: 'Prerequisite',
          child: child,
          parents: parents,
        });
      }
    }
  });
});

// RULES:
// 1. No duplicate entries of (parent, child)
// 2. Parent is always larger than child

router.post('/select_child', function(req, res, next) {
  const child = req.query.child;
  const parents = req.body.parents;

  if (typeof parents === 'string') {
    pool.query(sql.query.auth_prereq, [parents, child], (err, data) => {
      if (err) {
        getError('Prereq', err, res);
      } else if (data.rows[0].exists) {
        return res.redirect('/prereq');
      } else {
        pool.query(sql.query.add_prereq, [parents, child], (err, data) => {
          if (err) {
            insertError('Prereq', err, res);
          } else {
            return res.redirect('/prereq');
          }
        });
      }
    });
  } else {
    for (let i = 0; i < parents.length; i++) {
      pool.query(sql.query.auth_prereq, [parents[i], child], (err, data) => {
        if (err) {
          getError('Prereq', err, res);
        } else if (!data.rows[0].exists) {
          pool.query(sql.query.add_prereq, [parents[i], child], (err, data) => {
            if (err) {
              insertError('Prereq', err, res);
            }
            if (i === parents.length - 1) {
              return res.redirect('/prereq');
            }
          });
        }
      });
    }
  }
});

router.get('/delete_prereq', function(req, res, next) {
  const parent = req.query.parent;
  const child = req.query.child;

  pool.query(sql.query.delete_prereq, [parent, child], (err, data) => {
    if (err) {
      deleteError('Prereq', err, res);
    } else {
      return res.redirect('/prereq');
    }
  });
});

function getDigitsInString(word) {
  let digits = "";
  for (let i = 0; i < word.length; i++) {
    const char = word.charAt(i);
    if (char >= '0' && char <= '9') {
      digits += char;
    }
  }
  return digits;
}

function getError(database, err, res) {
  console.error('Unable to get from ' + database, err);
  return res.redirect('/prereq?get=fail');
}

function deleteError(database, err, res) {
  console.error('Unable to delete from ' + database, err);
  return res.redirect('/prereq?delete=fail');
}

function unknownError(err, res) {
  console.error('Something went wrong', err);
  return res.redirect('/dashboard_admin?load_prereq=fail');
}

function insertError(database, err, res) {
  console.error('Unable to insert into ' + database, err);
  return res.redirect('/prereq?insert=fail');
}

module.exports = router;
