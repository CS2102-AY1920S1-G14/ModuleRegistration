const express = require('express');
const router = express.Router();
const sql = require('../sql');

const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL
});

router.get('/', function(req, res, next) {
	pool.query(sql.query.load_rounds, (err, rounds) => {
		if (err) {
			unknownError(err, res);
		} else {
			res.render('round', {
				title: 'Round',
				rounds: rounds.rows
			});
		}
	});
});

router.post('/', function(req, res, next) {
	const reg_start_timestamp = req.body.reg_start_date +
		" " + req.body.reg_start_time;
	const reg_end_timestamp = req.body.reg_end_date +
		" " + req.body.reg_end_time;

	pool.query(sql.query.add_round, [
		reg_start_timestamp,
		reg_end_timestamp
	], (err, data) => {
		if (err) {
			insertError('Rounds', err, res);
		} else {
			// TODO: prompt admin insert queries successful
			return res.redirect('/round');
		}
	});
});

function unknownError(err, res) {
	console.error(err);
	return res.redirect('/dashboard_admin?load_round=fail');
}

function insertError(database, err, res) {
	console.error('Unable to insert into ' + database, err);
	return res.redirect('/round?insert=fail');
}

module.exports = router;