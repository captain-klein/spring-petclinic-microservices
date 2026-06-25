#!/usr/bin/env bash

set -euo pipefail

REPOSITORY_PREFIX="${REPOSITORY_PREFIX:-springcommunity}"
VERSION="${VERSION:-local}"

SERVICES=(
  spring-petclinic-config-server
  spring-petclinic-discovery-server
  spring-petclinic-api-gateway
  spring-petclinic-visits-service
  spring-petclinic-vets-service
  spring-petclinic-customers-service
  spring-petclinic-admin-server
  spring-petclinic-genai-service
)

for SERVICE in "${SERVICES[@]}"; do
  echo "============================================================"
  echo "Building Maven artifact: ${SERVICE}"
  echo "============================================================"
  ./mvnw -pl "${SERVICE}" -am clean package -DskipTests

  echo "Preparing Docker artifact: ${SERVICE}.jar"
  cp "${SERVICE}"/target/*.jar "./${SERVICE}.jar"

  echo "Building Docker image: ${REPOSITORY_PREFIX}/${SERVICE}:${VERSION}"
  docker build \
    -f docker/Dockerfile \
    --build-arg ARTIFACT_NAME="${SERVICE}" \
    --build-arg EXPOSED_PORT=8080 \
    -t "${REPOSITORY_PREFIX}/${SERVICE}:${VERSION}" \
    .

  rm -f "./${SERVICE}.jar"
done
