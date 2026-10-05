#!/usr/bin/env bash
# Run Zoom bot in a container and join the meeting via docker run.
# Requires: scribe stack running (redis) and network scribe_dev_scribe_default.
#
# Usage:
#   ./run-zoom-bot.sh
#   # Or from repo root: ./services/scribe-bot/run-zoom-bot.sh
#
# For interactive terminal (see logs, Ctrl+C to stop): add -it after --rm in the docker run line.

set -e

MEETING_URL="${ZOOM_MEETING_URL:?Set ZOOM_MEETING_URL (e.g. https://us05web.zoom.us/j/12345?pwd=xxx)}"
BOT_NAME="${ZOOM_BOT_NAME:-Scribe Bot}"
REDIS_URL="${REDIS_URL:-redis://redis:6379/0}"
ZOOM_CLIENT_ID="${ZOOM_CLIENT_ID:?Set ZOOM_CLIENT_ID}"
ZOOM_CLIENT_SECRET="${ZOOM_CLIENT_SECRET:?Set ZOOM_CLIENT_SECRET}"

# Extract meeting number and passcode from URL (e.g. .../j/81137509581?pwd=xxx)
if [[ "$MEETING_URL" =~ /j/([0-9]+) ]]; then
  MEETING_NUMBER="${BASH_REMATCH[1]}"
else
  echo "Error: ZOOM_MEETING_URL must contain /j/<meeting_number>" >&2
  exit 1
fi

BOT_CONFIG="{\"platform\":\"zoom\",\"meetingUrl\":\"$MEETING_URL\",\"botName\":\"$BOT_NAME\",\"token\":\"docker-run\",\"connectionId\":\"docker-run\",\"nativeMeetingId\":\"$MEETING_NUMBER\",\"meeting_id\":1,\"redisUrl\":\"$REDIS_URL\",\"automaticLeave\":{\"waitingRoomTimeout\":300000,\"noOneJoinedTimeout\":120000,\"everyoneLeftTimeout\":60000}}"

echo "Joining Zoom meeting: $MEETING_URL"
echo "Bot name: $BOT_NAME"
echo "Network: scribe_dev_scribe_default"
echo ""

docker run --rm \
  --platform linux/amd64 \
  --network scribe_dev_scribe_default \
  -e "BOT_CONFIG=$BOT_CONFIG" \
  -e "ZOOM_CLIENT_ID=$ZOOM_CLIENT_ID" \
  -e "ZOOM_CLIENT_SECRET=$ZOOM_CLIENT_SECRET" \
  scribe/scribe-bot:dev
