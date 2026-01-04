# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM maven:3.9.9-eclipse-temurin-17 AS build

WORKDIR /workspace
COPY . .

RUN mvn -DskipTests package \
    && mkdir -p /app \
    && JAR="$(ls -1 target/*.jar | grep -v 'original' | head -1)" \
    && cp "$JAR" /app/app.jar

FROM eclipse-temurin:17-jre-jammy

RUN useradd --system --uid 10001 appuser

WORKDIR /app
COPY --from=build --chown=appuser:appuser /app/app.jar /app/app.jar

USER appuser

ENV JVM_OPTS=""
ENV PORT=8080

EXPOSE 8080

CMD ["sh", "-c", "java $JVM_OPTS -Dserver.port=$PORT -jar /app/app.jar"]
