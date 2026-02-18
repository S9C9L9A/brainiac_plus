package models

// FacebookUser represents a Facebook user
type FacebookUser struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

// FacebookAuthRequest is used for frontend auth request
type FacebookAuthRequest struct {
	AccessToken string `json:"access_token"`
	UserID      string `json:"user_id"`
}

// FacebookAuthResponse is returned after validation
type FacebookAuthResponse struct {
	Valid   bool           `json:"valid"`
	User    FacebookUser   `json:"user,omitempty"`
	Message string         `json:"message"`
	Token   string         `json:"token,omitempty"` // JWT per sessione interna
}

// FacebookTokenValidation response from Facebook Graph API
type FacebookTokenValidation struct {
	Data struct {
		IsValid bool   `json:"is_valid"`
		UserID  string `json:"user_id"`
		AppID   string `json:"app_id"`
	} `json:"data"`
	Error struct {
		Message string `json:"message"`
		Type    string `json:"type"`
		Code    int    `json:"code"`
	} `json:"error"`
}

// FacebookUserData response from Facebook Graph API
type FacebookUserData struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
	Error struct {
		Message string `json:"message"`
		Type    string `json:"type"`
		Code    int    `json:"code"`
	} `json:"error,omitempty"`
}
