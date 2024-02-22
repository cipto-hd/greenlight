package main

import (
	_ "expvar"
	"net/http"

	"github.com/julienschmidt/httprouter"
)

type MethodPathHandlerFunc struct {
	Method      string
	Path        string
	HandlerFunc http.HandlerFunc
}

// Update the routes() method to return a http.Handler instead of a *httprouter.Router.
func (app *application) routes() http.Handler {
	// Initialize a new httprouter router instance.
	router := httprouter.New()

	// Convert the notFoundResponse() helper to a http.Handler using the
	// http.HandlerFunc() adapter, and then set it as the custom error handler for 404
	// Not Found responses.
	router.NotFound = http.HandlerFunc(app.notFoundResponse)
	// Likewise, convert the methodNotAllowedResponse() helper to a http.Handler and set
	// it as the custom error handler for 405 Method Not Allowed responses.
	router.MethodNotAllowed = http.HandlerFunc(app.methodNotAllowedResponse)

	// Register the relevant methods, URL patterns and handler functions for our
	// endpoints using the HandlerFunc() method. Note that http.MethodGet and
	// http.MethodPost are constants which equate to the strings "GET" and "POST"
	// respectively.
	router.HandlerFunc(http.MethodGet, "/v1/healthcheck", app.healthcheckHandler)

	// handler func for  /v1/users** endpoints
	// Use the requirePermission("movie:read",v.HandlerFunc)) middleware
	// on our two /v1/movies** GET endpoints.
	for _, v := range []MethodPathHandlerFunc{
		{
			Method:      http.MethodGet,
			Path:        "/v1/movies",
			HandlerFunc: app.listMoviesHandler,
		},
		{
			Method:      http.MethodGet,
			Path:        "/v1/movies/:id",
			HandlerFunc: app.showMovieHandler,
		},
	} {
		router.Handler(v.Method, v.Path, app.requirePermission("movies:read", v.HandlerFunc))
	}

	// Use the requirePermission("movie:read",v.HandlerFunc)) middleware
	// on our two /v1/movies** POST/PATCH/DELETE endpoints.
	for _, v := range []MethodPathHandlerFunc{
		{
			Method:      http.MethodPost,
			Path:        "/v1/movies",
			HandlerFunc: app.createMovieHandler,
		},
		{
			Method:      http.MethodPatch,
			Path:        "/v1/movies/:id",
			HandlerFunc: app.updateMovieHandler,
		},
		{
			Method:      http.MethodDelete,
			Path:        "/v1/movies/:id",
			HandlerFunc: app.deleteMovieHandler,
		},
	} {
		router.Handler(v.Method, v.Path, app.requirePermission("movies:write", v.HandlerFunc))
	}

	// handler func for  /v1/users** endpoints
	router.HandlerFunc(http.MethodPost, "/v1/users", app.registerUserHandler)
	router.HandlerFunc(http.MethodPut, "/v1/users/activated", app.activateUserHandler)
	router.HandlerFunc(http.MethodPut, "/v1/users/password", app.updateUserPasswordHandler)

	// handler func for  /v1/tokens** endpoints
	router.HandlerFunc(http.MethodPost, "/v1/tokens/authentication", app.createAuthenticationTokenHandler)
	router.HandlerFunc(http.MethodPost, "/v1/tokens/activation", app.createActivationTokenHandler)
	router.HandlerFunc(http.MethodPost, "/v1/tokens/password-reset", app.createPasswordResetTokenHandler)

	// Register a new GET /debug/vars endpoint pointing to the expvar handler.
	router.HandlerFunc(http.MethodGet, "/debug/vars", app.requirePermission("debug:read", func(w http.ResponseWriter, r *http.Request) {
		/* This checking based on r.Host is not reliable, prefer authentication
		using token and authorization based on user-permission*/

		/* if !strings.Contains(r.Host, "localhost") && !strings.Contains(r.Host, "127.0.0.1") {
			app.logger.PrintInfo(r.Host, map[string]string{
				"X-FORWARDED-FOR": r.Header.Get("X-FORWARDED-FOR"),
				"X-Real-IP":       r.Header.Get("X-Real-IP"),
				"RemoteAddr":      r.RemoteAddr,
			})
			app.notFoundResponse(w, r)
			return
		} */

		if h, p := http.DefaultServeMux.Handler(r); p != "" {
			/* app.logger.PrintInfo(r.Host, map[string]string{
				"X-FORWARDED-FOR": r.Header.Get("X-FORWARDED-FOR"),
				"X-Real-IP":       r.Header.Get("X-Real-IP"),
				"RemoteAddr":      r.RequestURI,
			}) */
			h.ServeHTTP(w, r)
		}
	}))

	// Return the httprouter instance.
	// middleware executed from left to right
	return app.metrics(app.recoverPanic(app.enableCORS(app.rateLimit(app.authenticate(router)))))
}
