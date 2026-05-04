#!/bin/bash

# Script di test per le automazioni Facebook di BrainiacPlus
# Test delle API Facebook con il token fornito

BACKEND_URL="http://localhost:8080"
FACEBOOK_TOKEN="EAAd3zUKn7ToBQla4F65ayrZBcm2ZBzW2SUOlXlCWSz3MXfAIwVd1oaKUu0MmxwMKvj1BWLMbIgyEzKJJVPqVZB1NkGMMXa4Hny4Fcd6YEeQfCUQ6RGjpdfCLHJ1IKRBoZC7LEpmeZCSOdVA5T0PaBaeduGqIlkKYMJKzZAcK2gLkB7gheZBle3QIj3TAPY2XZBLKVtMqIEXD8MH9yY7hPJOCN80GKZBNIZA8j5ifFoNJaywZCJFVL5AFUwVhOzWRz9dGZAIih3ZBPrJ9eyZBso2W70vSluUkAvEVQF"

echo "=================================================="
echo "🧠 BrainiacPlus - Test Automazioni Facebook"
echo "=================================================="
echo ""

# Test 1: Health check del backend
echo "📌 Test 1: Health Check Backend"
echo "--------------------------------------------------"
curl -s $BACKEND_URL/health | jq .
echo ""
echo ""

# Test 2: Autenticazione Facebook
echo "📌 Test 2: Autenticazione Facebook"
echo "--------------------------------------------------"
AUTH_RESPONSE=$(curl -s -X POST $BACKEND_URL/api/facebook/auth \
  -H "Content-Type: application/json" \
  -d "{\"access_token\": \"$FACEBOOK_TOKEN\"}")

echo "$AUTH_RESPONSE" | jq .

# Verifica se l'autenticazione è riuscita
IS_VALID=$(echo "$AUTH_RESPONSE" | jq -r '.valid')
echo ""
if [ "$IS_VALID" = "true" ]; then
    echo "✅ Autenticazione riuscita!"
    USER_NAME=$(echo "$AUTH_RESPONSE" | jq -r '.user.name')
    USER_ID=$(echo "$AUTH_RESPONSE" | jq -r '.user.id')
    echo "   👤 Utente: $USER_NAME (ID: $USER_ID)"
else
    echo "❌ Autenticazione fallita!"
    echo "   Errore: $(echo "$AUTH_RESPONSE" | jq -r '.message')"
fi
echo ""
echo ""

# Test 3: Recupero pagine Facebook
echo "📌 Test 3: Recupero Pagine Facebook"
echo "--------------------------------------------------"
PAGES_RESPONSE=$(curl -s -X GET $BACKEND_URL/api/facebook/pages \
  -H "X-Facebook-Token: $FACEBOOK_TOKEN")

echo "$PAGES_RESPONSE" | jq .

# Conta le pagine
PAGE_COUNT=$(echo "$PAGES_RESPONSE" | jq '.pages | length')
echo ""
if [ "$PAGE_COUNT" -gt 0 ]; then
    echo "✅ Trovate $PAGE_COUNT pagina/e!"
    echo ""
    echo "Elenco pagine:"
    echo "$PAGES_RESPONSE" | jq -r '.pages[] | "   📄 \(.name) (ID: \(.id))"'
else
    echo "⚠️  Nessuna pagina trovata o errore:"
    echo "$PAGES_RESPONSE" | jq .
fi
echo ""
echo ""

# Test 4: Test diretto API Facebook Graph
echo "📌 Test 4: Test Diretto Facebook Graph API"
echo "--------------------------------------------------"
echo "Verifico il token direttamente con Facebook..."
FB_USER_INFO=$(curl -s "https://graph.facebook.com/v18.0/me?fields=id,name,email&access_token=$FACEBOOK_TOKEN")
echo "$FB_USER_INFO" | jq .
echo ""

# Verifica se ci sono errori
FB_ERROR=$(echo "$FB_USER_INFO" | jq -r '.error.message // "none"')
if [ "$FB_ERROR" != "none" ]; then
    echo "❌ Errore Facebook API: $FB_ERROR"
    echo "   Tipo: $(echo "$FB_USER_INFO" | jq -r '.error.type')"
    echo "   Code: $(echo "$FB_USER_INFO" | jq -r '.error.code')"
else
    echo "✅ Token Facebook valido!"
    echo "   👤 $(echo "$FB_USER_INFO" | jq -r '.name')"
fi
echo ""
echo ""

# Test 5: Verifica permessi del token
echo "📌 Test 5: Verifica Permessi Token"
echo "--------------------------------------------------"
PERMISSIONS=$(curl -s "https://graph.facebook.com/v18.0/me/permissions?access_token=$FACEBOOK_TOKEN")
echo "$PERMISSIONS" | jq .
echo ""
echo "Permessi attivi:"
echo "$PERMISSIONS" | jq -r '.data[] | select(.status == "granted") | "   ✓ \(.permission)"'
echo ""
echo ""

echo "=================================================="
echo "✅ Test completati!"
echo "=================================================="
