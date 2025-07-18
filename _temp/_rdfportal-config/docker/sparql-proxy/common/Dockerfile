FROM node:20

RUN useradd --create-home --home-dir /app app

USER app
WORKDIR /app
COPY --chown=app:app . .

RUN mkdir /app/logs

ARG ROOT_PATH=/
RUN npm ci && npm run build
CMD npm start
