const express = require('express');
const router = express.Router();
const sql = require('../sql');

const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

router.get('/', function(req, res, next) {
	pool.query(sql.query.load_modules, (err, modules) => {
		if (err) {
			unknownError(err, res);
		} else {
			res.render('module', {
				title: 'Modules',
				modules: modules.rows,
				role: req.session.role,
				username: req.session.username
			});
		}
	});
});

router.post('/', function(req, res, next) {
	pool.query(sql.query.add_module, [
		req.body.mod_code,
		req.body.mod_name,
		req.session.username
	], (err, data) => {
		if (err) {
			insertError('Module', err, res);
		} else {
			return res.redirect('/module');
		}
	});
});

function unknownError(err, res) {
	console.error('Something went wrong', err);
	return res.redirect('/dashboard_admin?load_module=fail');
}

function insertError(database, err, res) {
	console.error('Unable to insert into ' + database, err);
	return res.redirect('/module?insert=fail');
}

module.exports = router;
