import { gql, makeExtendSchemaPlugin } from "postgraphile/utils";

export const TitleQueryPlugin = makeExtendSchemaPlugin((build) => {
  const { titles } = build.input.pgRegistry.pgResources;

  return {
    typeDefs: gql`
      extend type Query {
        title(tconst: String!): Title
      }
    `,
    plans: {
      Query: {
        title(_, { $tconst }) {
          return titles.find({ tconst: $tconst }).single();
        },
      },
    },
  };
});
