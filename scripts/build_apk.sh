#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IMAGE_NAME="k8s-node-builder"
BUILD_TYPE="${1:-debug}"
OUTPUT_DIR="${PROJECT_ROOT}/build"

mkdir -p "${OUTPUT_DIR}"

if ! docker image inspect "${IMAGE_NAME}" &>/dev/null; then
    echo "=== Building Docker build environment ==="
    docker build -t "${IMAGE_NAME}" -f "${PROJECT_ROOT}/docker/Dockerfile.build" "${PROJECT_ROOT}"
fi

echo "=== Building k8s Node APK (${BUILD_TYPE}) inside Docker ==="

docker run --rm \
    -v "${PROJECT_ROOT}:/src:ro" \
    -v "${OUTPUT_DIR}:/out" \
    "${IMAGE_NAME}" \
    bash -c "
set -e
flutter create --no-pub --project-name k8s --org com.ai2th --platforms android /tmp/workspace
cd /tmp/workspace
cp -r /src/lib/. lib/
cp /src/pubspec.yaml pubspec.yaml
cp -r /src/android/app/src/main/kotlin/. android/app/src/main/kotlin/
cp /src/android/app/src/main/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
# Add assets and libs if present
[ -d /src/android/app/src/main/assets ] && cp -r /src/android/app/src/main/assets/. android/app/src/main/assets/ || true
[ -d /src/android/app/src/main/jniLibs ] && cp -r /src/android/app/src/main/jniLibs/. android/app/src/main/jniLibs/ || true

printf 'flutter.sdk=/opt/flutter\nsdk.dir=/opt/android-sdk\n' > android/local.properties
flutter pub get
flutter build apk --${BUILD_TYPE}
cp build/app/outputs/flutter-apk/app-${BUILD_TYPE}.apk /out/kubxr-${BUILD_TYPE}.apk
"

echo "✅ Build complete: ${OUTPUT_DIR}/kubxr-${BUILD_TYPE}.apk"

if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    echo "=== Pushing Artifact to Registry ==="
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

    # Wrap APK in a minimal image for storage in registry
    cat <<EOF > "${OUTPUT_DIR}/Dockerfile.artifact"
FROM scratch
COPY kubxr-${BUILD_TYPE}.apk /kubxr-${BUILD_TYPE}.apk
EOF

    IMAGE_TAG="${DOCKER_USERNAME}/kubxr:${BUILD_TYPE}"
    docker build -t "\$IMAGE_TAG" -f "${OUTPUT_DIR}/Dockerfile.artifact" "${OUTPUT_DIR}"
    docker push "\$IMAGE_TAG"
    echo "✅ Artifact pushed: \$IMAGE_TAG"
fi
