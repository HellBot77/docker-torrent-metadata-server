FROM alpine/git AS base

ARG TAG=latest
RUN git clone https://github.com/schardev/torrent-metadata.git && \
    cd torrent-metadata && \
    ([[ "$TAG" = "latest" ]] || git checkout ${TAG}) && \
    rm -rf .git

FROM node:slim AS build

WORKDIR /torrent-metadata
COPY --from=base /git/torrent-metadata .
RUN npm install --global pnpm && \
    pnpm --filter server install --frozen-lockfile && \
    pnpm --filter server build && \
    rm -rf node_modules && \
    rm -rf packages/server/node_modules && \
    pnpm --filter server install --prod --frozen-lockfile --node-linker hoisted

FROM node:slim

WORKDIR /torrent-metadata
COPY --from=build /torrent-metadata/packages/server/package.json ./
COPY --from=build /torrent-metadata/node_modules ./node_modules
COPY --from=build /torrent-metadata/packages/server/dist ./dist

EXPOSE 3001
CMD ["npm", "start"]
