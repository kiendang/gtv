import { createServer } from "node:http";
import "dotenv/config";
import { grafserv } from "postgraphile/grafserv/node";
import { pgl } from "./pql";

const serv = pgl.createServ(grafserv);

const server = createServer();
server.on("error", (e) => {
  console.error(e);
});

serv.addTo(server).catch((e) => {
  console.error(e);
  process.exit(1);
});

const port = process.env.PORT;
server.listen(port);

console.log(`Server listening at http://localhost:${port}`);
