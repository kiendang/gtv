import "graphile-config";
import "postgraphile";
import { PgSimplifyInflectionPreset } from "@graphile/simplify-inflection";
import { makePgService } from "postgraphile/adaptors/pg";
import { PostGraphileAmberPreset } from "postgraphile/presets/amber";
import "dotenv/config";
import { TitleQueryPlugin } from "./title";
import { IMDBTitleURLPlugin } from "./url";

const preset: GraphileConfig.Preset = {
  extends: [PostGraphileAmberPreset, PgSimplifyInflectionPreset],
  pgServices: [
    makePgService({
      connectionString: process.env.DATABASE_URL,
      schemas: ["api"],
    }),
  ],
  grafserv: {
    graphqlPath: "/graphql",
    graphiql: true,
    graphiqlOnGraphQLGET: true,
  },
  grafast: {
    explain: true,
  },
  schema: {
    defaultBehavior: "-insert -update -delete",
    pgSimplifyAllRows: false,
  },
  plugins: [TitleQueryPlugin, IMDBTitleURLPlugin],
  disablePlugins: ["NodeAccessorPlugin"],
};

export default preset;
