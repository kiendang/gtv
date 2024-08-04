import type { PgSelectSingleStep } from "postgraphile/@dataplan/pg";
import { loadOne } from "postgraphile/grafast";
import { gql, makeExtendSchemaPlugin } from "postgraphile/utils";

function url($title: PgSelectSingleStep) {
  return loadOne($title.get("tconst"), (tconsts: readonly string[]) =>
    tconsts.map((tconst) => `https://www.imdb.com/title/${tconst}/`),
  );
}

const urlPlan = Object.fromEntries(
  ["Movie", "Series", "Episode"].map((type) => [type, { url }]),
);

export const IMDBTitleURLPlugin = makeExtendSchemaPlugin((_) => {
  return {
    typeDefs: gql`
      extend interface Title {
        url: String!
      }

      extend type Movie {
        url: String!
      }

      extend type Series {
        url: String!
      }

      extend type Episode {
        url: String!
      }
    `,
    plans: urlPlan,
  };
});
