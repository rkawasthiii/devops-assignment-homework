const http = require("http");

function greeting(name = "World") {
  return `Hello ${name} from the CI/CD demo app!`;
}

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/html" });
  res.end(`<h1>${greeting()}</h1>`);
});

if (require.main === module) {
  server.listen(3000, () => console.log("Demo app on :3000"));
}

module.exports = { greeting };
