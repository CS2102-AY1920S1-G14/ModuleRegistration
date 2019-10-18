const createError = require('http-errors');
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
const session = require('express-session');

/* Using dotenv */
require('dotenv').config();

const {
  NODE_ENV = 'development',
  SESSION_NAME = 'sid',
  SESSION_SECRET = 'secret',
  SESSION_LIFETIME = 1000 * 60 * 60 * 2
} = process.env;

const IN_PROD = NODE_ENV === 'production';

const app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

/* Configure Session */
app.use(session({
  name: SESSION_NAME,
  // Symmetric key used to sign the cookie
  secret: SESSION_SECRET,
  // Does not force the session to be saved back to the session store
  resave: false,
  // Does not force an uninitialized (new but unmodified) session to be saved
  // back to the session store
  saveUninitialized: false,
  cookie: {
    // JS on client-side won't be able to access the cookies
    httpOnly: true,
    // 2 hours before cookies expire
    maxAge: SESSION_LIFETIME,
    // Browser will only accept cookies from same domain
    sameSite: true,
    // HTTP in development and HTTPS in production
    secure: IN_PROD
  }
}));

const redirectLogin = (req, res, next) => {
  console.log(req.session.username);
  if (!req.session.username) {
    res.redirect('/login');
  } else {
    next()
  }
};

const redirectHome = (req, res, next) => {
  console.log(req.session.username);
  if (req.session.username) {
    if (req.session.role === 'Student') {
      res.redirect('/dashboard_student')
    } else {
      res.redirect('/dashboard_admin')
    }
  } else {
    next()
  }
};

// TODO: Have middleware to ensure all unauthenticated users be rerouted to login page

app.use('/', require('./routes/index'));

/* Login Page */
app.use('/login', require('./routes/login'));

/* Register Page */
app.use('/register', require('./routes/register'));

/* Student Dashboard Page */
app.use('/dashboard_student', require('./routes/dashboard_student'));

/* Admin Dashboard Page */
app.use('/dashboard_admin', require('./routes/dashboard_admin'));

/* Register Module Page */
app.use('/register_module', require('./routes/register_module'));

/* Program Page */
app.use('/program', require('./routes/program'));

/* Module Page */
app.use('/module', require('./routes/module'));

/* Rounds Page */
app.use('/round', require('./routes/round'));

/* Delete Program Page */
app.use('/delete_program', require('./routes/delete_program'));

/* Delete Module Page */
app.use('/delete_module', require('./routes/delete_module'));

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;
