#!/bin/bash

# Script interattivo per testare le automazioni Facebook
# BrainiacPlus - Interactive Facebook Test

BACKEND_URL="http://localhost:8080"

echo "=================================================="
echo "🧠 BrainiacPlus - Test Automazioni Facebook"
echo "   Interactive Token Setup"
echo "=================================================="
echo ""

# Controlla se jq è installato
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq non è installato. Installalo con: sudo apt install jq"
    exit 1
fi

# Controlla se il backend è in esecuzione
echo "🔍 Controllo backend..."
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Backend attivo su porta 8080"
else
    echo "❌ Backend non raggiungibile!"
    echo "   Avvialo con: cd go_backend && go run main.go"
    exit 1
fi
echo ""

# Richiedi il token
echo "📝 Per ottenere un token valido:"
echo "   1. Vai su: https://developers.facebook.com/tools/explorer/"
echo "   2. Seleziona la tua app (2102048307277114)"
echo "   3. Clicca 'Generate Access Token'"
echo "   4. Richiedi permessi: pages_show_list, pages_manage_posts"
echo "   5. Copia il token"
echo ""
read -p "🔑 Incolla il tuo Facebook Access Token: " FACEBOOK_TOKEN

if [ -z "$FACEBOOK_TOKEN" ]; then
    echo "❌ Nessun token fornito!"
    exit 1
fi

echo ""
echo "=================================================="
echo "🧪 Iniziando i test..."
echo "=================================================="
echo ""

# Test 1: Verifica token direttamente con Facebook
echo "📌 Test 1: Verifica Token con Facebook API"
echo "--------------------------------------------------"
FB_RESPONSE=$(curl -s "https://graph.facebook.com/v18.0/me?fields=id,name,email&access_token=$FACEBOOK_TOKEN")
FB_ERROR=$(echo "$FB_RESPONSE" | jq -r '.error.message // "none"')

if [ "$FB_ERROR" != "none" ]; then
    echo "❌ Token non valido!"
    echo "   Errore: $FB_ERROR"
    echo "   Code: $(echo "$FB_RESPONSE" | jq -r '.error.code')"
    echo ""
    echo "Per favore, genera un nuovo token e riprova."
    exit 1
else
    USER_NAME=$(echo "$FB_RESPONSE" | jq -r '.name')
    USER_ID=$(echo "$FB_RESPONSE" | jq -r '.id')
    USER_EMAIL=$(echo "$FB_RESPONSE" | jq -r '.email // "non disponibile"')
    
    echo "✅ Token valido!"
    echo "   👤 Nome: $USER_NAME"
    echo "   🆔 ID: $USER_ID"
    echo "   📧 Email: $USER_EMAIL"
fi
echo ""

# Test 2: Autenticazione tramite backend
echo "📌 Test 2: Autenticazione Backend"
echo "--------------------------------------------------"
AUTH_RESPONSE=$(curl -s -X POST $BACKEND_URL/api/facebook/auth \
  -H "Content-Type: application/json" \
  -d "{\"access_token\": \"$FACEBOOK_TOKEN\"}")

IS_VALID=$(echo "$AUTH_RESPONSE" | jq -r '.valid')
if [ "$IS_VALID" = "true" ]; then
    echo "✅ Autenticazione backend riuscita!"
else
    echo "⚠️  Autenticazione backend fallita"
    echo "   Risposta: $(echo "$AUTH_RESPONSE" | jq .)"
fi
echo ""

# Test 3: Permessi token
echo "📌 Test 3: Verifica Permessi"
echo "--------------------------------------------------"
PERMISSIONS=$(curl -s "https://graph.facebook.com/v18.0/me/permissions?access_token=$FACEBOOK_TOKEN")
GRANTED=$(echo "$PERMISSIONS" | jq -r '.data[] | select(.status == "granted") | .permission')

if [ -z "$GRANTED" ]; then
    echo "⚠️  Nessun permesso trovato o errore"
else
    echo "✅ Permessi attivi:"
    echo "$GRANTED" | while read perm; do
        echo "   ✓ $perm"
    done
fi
echo ""

# Test 4: Recupero pagine
echo "📌 Test 4: Recupero Pagine Facebook"
echo "--------------------------------------------------"
PAGES_RESPONSE=$(curl -s "https://graph.facebook.com/v18.0/me/accounts?access_token=$FACEBOOK_TOKEN")
PAGES=$(echo "$PAGES_RESPONSE" | jq -r '.data[]? | "\(.name)|\(.id)|\(.access_token)"')

if [ -z "$PAGES" ]; then
    echo "⚠️  Nessuna pagina trovata"
    echo "   Nota: Devi essere admin/editor di almeno una pagina Facebook"
    echo "   Risposta: $(echo "$PAGES_RESPONSE" | jq .)"
else
    PAGE_COUNT=$(echo "$PAGES" | wc -l)
    echo "✅ Trovate $PAGE_COUNT pagina/e:"
    echo ""
    
    PAGE_NUM=1
    declare -a PAGE_IDS
    declare -a PAGE_TOKENS
    
    echo "$PAGES" | while IFS='|' read name id token; do
        echo "   $PAGE_NUM. 📄 $name"
        echo "      ID: $id"
        PAGE_IDS[$PAGE_NUM]=$id
        PAGE_TOKENS[$PAGE_NUM]=$token
        PAGE_NUM=$((PAGE_NUM + 1))
    done
    echo ""
    
    # Opzione di test post
    read -p "🎯 Vuoi testare la pubblicazione di un post? (s/n): " TEST_POST
    
    if [ "$TEST_POST" = "s" ] || [ "$TEST_POST" = "S" ]; then
        read -p "   Scegli il numero della pagina (1-$PAGE_COUNT): " PAGE_CHOICE
        
        # Recupera i dati della pagina scelta
        SELECTED_PAGE=$(echo "$PAGES" | sed -n "${PAGE_CHOICE}p")
        IFS='|' read PAGE_NAME PAGE_ID PAGE_TOKEN <<< "$SELECTED_PAGE"
        
        echo ""
        echo "📝 Pagina selezionata: $PAGE_NAME"
        read -p "   Scrivi il messaggio del post (ENTER per usare messaggio di test): " POST_MESSAGE
        
        if [ -z "$POST_MESSAGE" ]; then
            POST_MESSAGE="🧠 Test automatico da BrainiacPlus! Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        fi
        
        echo ""
        echo "📤 Pubblicando post..."
        
        POST_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/facebook/post" \
          -H "Content-Type: application/json" \
          -d "{\"page_id\": \"$PAGE_ID\", \"page_token\": \"$PAGE_TOKEN\", \"message\": \"$POST_MESSAGE\"}")
        
        POST_ID=$(echo "$POST_RESPONSE" | jq -r '.post_id // "error"')
        
        if [ "$POST_ID" != "error" ] && [ "$POST_ID" != "null" ]; then
            echo "✅ Post pubblicato con successo!"
            echo "   🆔 Post ID: $POST_ID"
            echo "   📄 Pagina: $PAGE_NAME"
            echo "   💬 Messaggio: $POST_MESSAGE"
        else
            echo "❌ Errore nella pubblicazione"
            echo "   Risposta: $(echo "$POST_RESPONSE" | jq .)"
        fi
    fi
fi
echo ""

# Test 5: Informazioni debug token
echo "📌 Test 5: Debug Token Info"
echo "--------------------------------------------------"
DEBUG_TOKEN=$(curl -s "https://graph.facebook.com/v18.0/debug_token?\
input_token=$FACEBOOK_TOKEN&\
access_token=2102048307277114|5cc547de365531456ec19ddc1a335cb7")

IS_VALID_DEBUG=$(echo "$DEBUG_TOKEN" | jq -r '.data.is_valid')
APP_ID=$(echo "$DEBUG_TOKEN" | jq -r '.data.app_id')
EXPIRES=$(echo "$DEBUG_TOKEN" | jq -r '.data.expires_at')
SCOPES=$(echo "$DEBUG_TOKEN" | jq -r '.data.scopes[]?')

if [ "$IS_VALID_DEBUG" = "true" ]; then
    echo "✅ Token valido (debug info)"
    echo "   🆔 App ID: $APP_ID"
    
    if [ "$EXPIRES" != "0" ] && [ "$EXPIRES" != "null" ]; then
        EXPIRE_DATE=$(date -d "@$EXPIRES" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "N/A")
        echo "   ⏰ Scade: $EXPIRE_DATE"
    else
        echo "   ⏰ Scade: Mai (long-lived token)"
    fi
    
    if [ ! -z "$SCOPES" ]; then
        echo "   🔑 Scopes:"
        echo "$SCOPES" | while read scope; do
            echo "      • $scope"
        done
    fi
else
    echo "⚠️  Problemi con il token"
    echo "$DEBUG_TOKEN" | jq .
fi
echo ""

echo "=================================================="
echo "✅ Test completati!"
echo "=================================================="
echo ""

# Opzione per salvare il token nel .env
read -p "💾 Vuoi salvare questo token nel file .env? (s/n): " SAVE_TOKEN

if [ "$SAVE_TOKEN" = "s" ] || [ "$SAVE_TOKEN" = "S" ]; then
    cd /home/giuseppe-genna/brainiac_plus/go_backend
    
    if grep -q "^FACEBOOK_TOKEN=" .env; then
        # Sostituisci il token esistente
        sed -i "s|^FACEBOOK_TOKEN=.*|FACEBOOK_TOKEN=$FACEBOOK_TOKEN|" .env
        echo "✅ Token aggiornato in .env"
    else
        # Aggiungi il token
        echo "FACEBOOK_TOKEN=$FACEBOOK_TOKEN" >> .env
        echo "✅ Token aggiunto a .env"
    fi
    
    echo ""
    echo "⚠️  Ricorda di riavviare il backend per applicare le modifiche:"
    echo "   pkill -f 'go run main.go'"
    echo "   cd /home/giuseppe-genna/brainiac_plus/go_backend && go run main.go &"
fi

echo ""
echo "📚 Per più informazioni, leggi: FACEBOOK_TOKEN_GUIDE.md"
