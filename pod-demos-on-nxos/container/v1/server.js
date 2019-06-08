var http = require('http');

var handleRequest = function(request, response) {
  console.log('Received request for URL: ' + request.url);
  response.writeHead(200);
  response.write('This is version 1 of the container\n\n');
  response.end('Running on IP ' + request.socket.localAddress + '. URL PATH ' + request.url + '\n');
};

var www = http.createServer(handleRequest);
www.listen(1234);
