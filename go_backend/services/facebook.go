package services

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"brainiac_backend/models"
)

// FacebookService gestisce l'integrazione con Facebook
type FacebookService struct {
	AppToken string
	AppID    string
	AppSecret string
}

// NewFacebookService crea una nuova istanza del servizio
func NewFacebookService() *FacebookService {
	return &FacebookService{
		AppToken: os.Getenv("FACEBOOK_TOKEN"),
		AppID:    os.Getenv("FACEBOOK_APP_ID"),
		AppSecret: os.Getenv("FACEBOOK_APP_SECRET"),
	}
}

// ValidateUserToken valida il token ricevuto dal frontend
func (fs *FacebookService) ValidateUserToken(userToken string) (*models.FacebookUser, error) {
	// Usa App Access Token (app_id|app_secret) per validare user token
	appAccessToken := fmt.Sprintf("%s|%s", fs.AppID, fs.AppSecret)
	
	// Endpoint: GET /debug_token
	url := fmt.Sprintf(
		"https://graph.facebook.com/v18.0/debug_token?input_token=%s&access_token=%s",
		userToken,
		appAccessToken,
	)

	resp, err := http.Get(url)
	if err != nil {
		return nil, fmt.Errorf("errore nella validazione del token: %w", err)
	}
	defer resp.Body.Close()

	var validation models.FacebookTokenValidation
	if err := json.NewDecoder(resp.Body).Decode(&validation); err != nil {
		return nil, fmt.Errorf("errore nel parsing della risposta: %w", err)
	}

	if !validation.Data.IsValid {
		return nil, fmt.Errorf("token non valido")
	}

	// Se il token è valido, recupera i dati dell'utente
	return fs.GetUserInfo(userToken, validation.Data.UserID)
}

// GetUserInfo recupera le informazioni dell'utente da Facebook
func (fs *FacebookService) GetUserInfo(userToken, userID string) (*models.FacebookUser, error) {
	// Endpoint: GET /{user-id}
	url := fmt.Sprintf(
		"https://graph.facebook.com/v18.0/%s?fields=id,name,email&access_token=%s",
		userID,
		userToken,
	)

	resp, err := http.Get(url)
	if err != nil {
		return nil, fmt.Errorf("errore nel recupero info utente: %w", err)
	}
	defer resp.Body.Close()

	var userData models.FacebookUserData
	if err := json.NewDecoder(resp.Body).Decode(&userData); err != nil {
		return nil, fmt.Errorf("errore nel parsing: %w", err)
	}

	if userData.Error.Message != "" {
		return nil, fmt.Errorf("errore da Facebook: %s", userData.Error.Message)
	}

	return &models.FacebookUser{
		ID:    userData.ID,
		Name:  userData.Name,
		Email: userData.Email,
	}, nil
}

// GetUserPages recupera le pagine associate all'utente
func (fs *FacebookService) GetUserPages(userToken string) ([]map[string]interface{}, error) {
	// Endpoint: GET /me/accounts
	url := fmt.Sprintf(
		"https://graph.facebook.com/v18.0/me/accounts?access_token=%s",
		userToken,
	)

	resp, err := http.Get(url)
	if err != nil {
		return nil, fmt.Errorf("errore nel recupero pagine: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("errore nel parsing: %w", err)
	}

	if data, ok := result["data"].([]interface{}); ok {
		pages := make([]map[string]interface{}, len(data))
		for i, page := range data {
			if p, ok := page.(map[string]interface{}); ok {
				pages[i] = p
			}
		}
		return pages, nil
	}

	return nil, fmt.Errorf("nessuna pagina trovata")
}

// PostToPage pubblica un post su una pagina Facebook
func (fs *FacebookService) PostToPage(pageID, pageToken, message string) (string, error) {
	// Endpoint: POST /{page-id}/feed
	url := fmt.Sprintf(
		"https://graph.facebook.com/v18.0/%s/feed?message=%s&access_token=%s",
		pageID,
		message,
		pageToken,
	)

	req, err := http.NewRequest("POST", url, nil)
	if err != nil {
		return "", fmt.Errorf("errore nella creazione richiesta: %w", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("errore nel publish: %w", err)
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("errore nel parsing: %w", err)
	}

	if id, ok := result["id"].(string); ok {
		return id, nil
	}

	return "", fmt.Errorf("errore nella pubblicazione")
}
