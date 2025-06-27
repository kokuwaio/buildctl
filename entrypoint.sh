#!/usr/bin/env bash
set -eu;

##
## workaround until we have a env `CI_COMMIT_TIMESTAMP`
## see https://github.com/woodpecker-ci/woodpecker/issues/5245
##

if [[ -z "${CI_COMMIT_TIMESTAMP:-}" ]]; then
	git config --global --add safe.directory "$PWD"
	CI_COMMIT_TIMESTAMP=$(git log -1 --format="%at")
fi

##
## check input
##

if [[ -n "${PLUGIN_ENV_FILE:-}" ]]; then
	if [[ ! -f "$PLUGIN_ENV_FILE" ]]; then
		echo "Env file $PLUGIN_ENV_FILE not found."
		exit 1
	fi
	# shellcheck source=/dev/null
	source "$PLUGIN_ENV_FILE"
fi

BUILDCTL_CONTEXT=${PLUGIN_CONTEXT:-$(pwd)}
BUILDCTL_DOCKERFILE=$(dirname "${PLUGIN_DOCKERFILE:-$BUILDCTL_CONTEXT/Dockerfile}")
if [[ ! -f $BUILDCTL_DOCKERFILE/Dockerfile ]]; then
	echo "Dockerfile $BUILDCTL_DOCKERFILE/Dockerfile not found!"
	exit 1
fi

BUILDCTL_FRONTEND=${PLUGIN_FRONTEND:-dockerfile.v0}
if [[ "$BUILDCTL_FRONTEND" != "dockerfile.v0" ]]; then
	echo "Only frontend 'dockerfile.v0' tested and supported yet."
	exit 1
fi

SOURCE_DATE_EPOCH=${PLUGIN_SOURCE_DATE_EPOCH:-${CI_COMMIT_TIMESTAMP:-0}}

if [[ -n "${PLUGIN_AUTH:-}" ]]; then
	echo "$PLUGIN_AUTH" | jq -r 'to_entries|map({(.key):{"auth":(.value.username+":"+.value.password)|@base64}})|add|{"auths":.}' > "$HOME/.docker/config.json"
	echo "Stored credentials at $HOME/.docker/config.json"
	echo
fi

##
## build command
##

COMMAND="buildctl build"
if [[ -n "${PLUGIN_ADDR:-}" ]]; then
	COMMAND+=" --addr=$PLUGIN_ADDR"
fi
COMMAND+=" --frontend=$BUILDCTL_FRONTEND"
COMMAND+=" --local=context=$BUILDCTL_CONTEXT"
COMMAND+=" --local=dockerfile=$BUILDCTL_DOCKERFILE"
if [[ -n  "${PLUGIN_PLATFORM:-}" ]]; then
	COMMAND+=" --opt=platform=$PLUGIN_PLATFORM"
fi
if [[ -n  "${PLUGIN_TARGET:-}" ]]; then
	COMMAND+=" --opt=target=$PLUGIN_TARGET"
fi
if [[ -n  "${PLUGIN_BUILD_ARGS:-}" ]]; then
	COMMAND+="$(eval "echo \"${PLUGIN_BUILD_ARGS//\"/\\\"}\"" | jq --join-output 'keys[] as $k|" --opt=build-arg:\($k)=\(.[$k])"')"
fi
COMMAND+=" --opt=build-arg:SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH"

# https://github.com/moby/buildkit/blob/master/README.md#output
if [[ -n "${PLUGIN_NAME:-}" ]]; then
	PLUGIN_NAME="$(eval "echo \"${PLUGIN_NAME//\"/\\\"}\"")"
	OUTPUT="type=image"
	if [[ "$PLUGIN_NAME" =~ .*,.* ]]; then
		# https://github.com/moby/buildkit/issues/797#issuecomment-1561601104
		OUTPUT+=",\"name=$PLUGIN_NAME\""
	else
		OUTPUT+=",name=$PLUGIN_NAME"
	fi
	if [[ -n "${PLUGIN_ANNOTATION:-}" ]]; then
		OUTPUT+="$(eval "echo \"${PLUGIN_ANNOTATION//\"/\\\"}\"" | jq --join-output 'keys[] as $k|",annotation.\($k)=\(.[$k])"')"
	fi
	OUTPUT+=",push=${PLUGIN_PUSH:-true},oci-mediatypes=true,compression=estargz,compression-level=9,rewrite-timestamp=true"
	COMMAND+=" --output='$OUTPUT'"
fi

##
## execute command
##

echo
echo Reproduce with docker:
echo
echo "  docker buildx build ${PLUGIN_CONTEXT:-.} \\"
if [[ -n  "${PLUGIN_TARGET:-}" ]]; then
	echo "    --target=$PLUGIN_TARGET \\"
fi
echo "    --no-cache \\"
echo "    --provenance=false \\"
echo "    --build-arg=SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH \\"
if [[ -n  "${PLUGIN_PLATFORM:-}" ]]; then
	echo "    --platform=$PLUGIN_PLATFORM \\"
fi
if [[ -n "${OUTPUT:-}" ]]; then
	echo "    --output='${OUTPUT//push=true/push=false}'"
fi
echo
echo Running now:
echo
echo -e "  ${COMMAND// --/ \\n    --}"
echo
eval "$COMMAND"
