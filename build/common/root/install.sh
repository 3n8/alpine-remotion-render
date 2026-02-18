#!/bin/bash

set -e

echo "[info] Setting up Remotion render environment..."

echo "[info] Cleaning up..."
rm -rf /var/cache/apk/*
rm -rf /tmp/*

echo "[info] Remotion render setup complete"
