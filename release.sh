#!/bin/bash
# Script de release pour Notty
# Usage: ./release.sh v1.1 "Description de la release"

set -e

VERSION=$1
NOTES=${2:-"Release $VERSION"}
REPO="NovationLabs/Notty"
TAP_REPO="NovationLabs/homebrew-notty"

if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh <version> [notes]"
    echo "Exemple: ./release.sh v1.1 \"Ajout du resize\""
    exit 1
fi

echo "==> Push du code..."
git push origin main

echo "==> Création de la release $VERSION..."
gh release create "$VERSION" --repo "$REPO" --title "$VERSION" --notes "$NOTES"

echo "==> Calcul du sha256..."
SHA=$(curl -sL "https://github.com/$REPO/archive/refs/tags/$VERSION.tar.gz" | shasum -a 256 | awk '{print $1}')
echo "    sha256: $SHA"

echo "==> Mise à jour de la formule Homebrew..."
TAP_DIR=$(brew --repo "$TAP_REPO" 2>/dev/null || echo "")

# Si le tap n'est pas installé localement, on le clone
if [ -z "$TAP_DIR" ] || [ ! -d "$TAP_DIR" ]; then
    echo "    Clonage du tap..."
    brew tap "$TAP_REPO" 2>/dev/null || true
    TAP_DIR=$(brew --repo "$TAP_REPO")
fi

FORMULA="$TAP_DIR/Formula/notty.rb"

# Remplacer l'URL et le sha256 dans la formule
sed -i '' "s|url \".*\"|url \"https://github.com/$REPO/archive/refs/tags/$VERSION.tar.gz\"|" "$FORMULA"
sed -i '' "s|sha256 \".*\"|sha256 \"$SHA\"|" "$FORMULA"

echo "==> Push de la formule..."
cd "$TAP_DIR"
git add Formula/notty.rb
git commit -m "[MODIFIED]: bump to $VERSION"
git push origin main

echo ""
echo "Done! $VERSION est live."
echo "Les utilisateurs peuvent faire: brew update && brew upgrade notty"
