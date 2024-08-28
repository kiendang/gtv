import { createServer } from "node:http";
import "dotenv/config";
import cors from "cors";
import express from "express";
import { grafserv } from "postgraphile/grafserv/express/v4";
import { pgl } from "./pql";

const serv = pgl.createServ(grafserv);

const app = express();
app.use(cors());

const server = createServer(app);
server.on("error", (e) => {
  console.error(e);
});

serv.addTo(app, server).catch((e) => {
  console.error(e);
  process.exit(1);
});

const port = process.env.PORT;
server.listen(port);

console.log(`Server listening at http://localhost:${port}`);
