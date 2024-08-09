const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const { createProxyMiddleware } = require('http-proxy-middleware');
const logger = require('morgan');

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
app.use(express.static(path.join(__dirname, 'public')));
if (app.get('env') === 'development') {
  app.use("/fwd/reddisk", createProxyMiddleware({
    target: 'http://mcft.io',
    changeOrigin: true,
    pathRewrite: { '^/fwd/reddisk': '/reddisk' }
  }))
  app.use("/fwd/erl", createProxyMiddleware({
    target: 'http://mcft.io',
    changeOrigin: true,
    pathRewrite: { '^/fwd/erl': '/erl' }
  }))
}
app.use("/erl", express.static("/mnt/minecraft/oc/0c11ce4a-8e80-41a8-9a0f-72a9dad4bf47/webroot"))
app.use("/reddisk", express.static("/mnt/minecraft/oc/b9203fd5-03cf-469b-96e0-165f7f0e6b5b"))
app.use("/oreproc", express.static("/mnt/minecraft/oc/c65ea0a6-b487-4ba9-b06a-3bc0ce0647f6"))
app.use("/ryandisk", express.static("/mnt/minecraft/oc/29a6e1dc-ac9a-4af0-a3fe-76e48cb36d6e"))
app.use("/ryanlog", express.static("/mnt/minecraft/oc/82d19e6a-70af-4f0c-a0bd-504a1e3f028f"))
app.use('/', indexRouter);
app.use('/users', usersRouter);
let latestText = ""
app.post('/request', function (req, res) {
  if (req.body.text) {
    latestText = req.body.text;
    res.status(200).send('Text received');
  } else {
    res.status(400).send('No text provided');
  }
})
app.get('/latest', (req, res) => {
  res.status(200).send({ text: latestText });
});

app.use(function (req, res) {
  res.status(404).send();
});

module.exports = app;
