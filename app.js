var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var lessMiddleware = require('less-middleware');
const { createProxyMiddleware } = require('http-proxy-middleware');
var logger = require('morgan');

var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'hbs');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(lessMiddleware(path.join(__dirname, 'public')));
app.use(express.static(path.join(__dirname, 'public')));
if (app.get('env') === 'development') {
  app.use("/fwd/reddisk", createProxyMiddleware({
    target: 'http://mcft.io',
    changeOrigin: true,
    pathRewrite: { '^/fwd/reddisk': '/reddisk' }
  }))
}
app.use("/reddisk", express.static("/mnt/minecraft/oc/62e65afb-e9d7-46f3-869b-d5324ed52d7a/home"))
app.use("/ryandisk", express.static("/mnt/minecraft/oc/36f37951-cc56-4d32-9e78-b52c8db76fb7"))
app.use('/', indexRouter);
app.use('/users', usersRouter);

// catch 404 and forward to error handler
app.use(function (req, res, next) {
  next(createError(404));
});

// error handler
app.use(function (err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;
