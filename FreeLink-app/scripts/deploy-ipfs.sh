#!/bin/bash
# scripts/deploy-ipfs.sh

APK_PATH="dist/freelink.apk"

if [ ! -f "$APK_PATH" ]; then
  echo "❌ APK not found at $APK_PATH"
  exit 1
fi

echo "🌍 Uploading APK to IPFS..."

# Add APK and get CID
CID=$(ipfs add -q "$APK_PATH")
if [ -z "$CID" ]; then
  echo "❌ Failed to add APK to IPFS. Is IPFS daemon running?"
  echo "💡 Run: ipfs daemon"
  exit 1
fi

echo "🔗 APK uploaded to IPFS: $CID"
echo "🌐 Public link: https://ipfs.io/ipfs/$CID"

# Write release info
cat <<EOF > dist/release.json
{
  "version": "v1.0.0",
  "apk_cid": "$CID",
  "download_url": "https://ipfs.io/ipfs/$CID/freelink.apk",
  "sha256": "$(sha256sum $APK_PATH | awk '{print $1}')",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "📄 release.json updated with CID and SHA-256"
