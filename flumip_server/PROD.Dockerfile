FROM dart:3.12.2 AS build

WORKDIR /app
COPY . .

RUN dart pub get
# `dart build cli`, not `dart compile exe`: Serverpod 4 brings in a transitive
# sqlite3 with a native build hook, and `dart compile exe` does not run build
# hooks, so its output is missing the native libraries and fails at runtime.
RUN dart build cli --target bin/main.dart --output build

FROM alpine:latest

# The bundle needs a directory of its own: bin/main resolves its native
# libraries relative to itself, so copying bundle/ to / would drop .so files
# into alpine's own /lib. WorkingDirectory has to be set explicitly too,
# because config/, web/ and migrations/ are resolved relative to it.
WORKDIR /app

ENV runmode=production
ENV serverid=prodduction
ENV logging=normal
ENV role=monolith

COPY --from=build /runtime/ /
COPY --from=build /app/build/bundle/ /app/bundle/
COPY --from=build /app/confi[g]/ /app/config/
COPY --from=build /app/we[b]/ /app/web/
COPY --from=build /app/migration[s]/ /app/migrations/


EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

ENTRYPOINT ./bundle/bin/main --mode=$runmode --server-id=$serverid --logging=$logging --role=$role --apply-migrations
