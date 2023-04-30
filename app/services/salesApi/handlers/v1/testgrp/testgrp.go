package testgrp

import (
	"context"
	"errors"
	"math/rand"
	"net/http"

	"github.com/BrunoKazadi/sales-api/business/sys/validate"
	"github.com/BrunoKazadi/sales-api/foundation/web"
	"go.uber.org/zap"
)

// Handlers manages the set of check enpoints.
type Handlers struct {
	Log *zap.SugaredLogger
}

// Test handler is for development.
func (h Handlers) Test(ctx context.Context, w http.ResponseWriter, r *http.Request) error {

	if n := rand.Intn(100); n%2 == 0 {
		//return errors.New("Untrusted error")
		return validate.NewRequestError(errors.New("trusted error"), http.StatusBadRequest)
		//return web.NewShutdownError("restart service")
		//panic("testing panic")
	}
	status := struct {
		Status string
	}{
		Status: "OK",
	}

	statusCode := http.StatusOK
	h.Log.Infow("readiness", "statusCode", statusCode, "method", r.Method, "path", r.URL.Path, "remoteaddr", r.RemoteAddr)

	return web.Respond(ctx, w, status, statusCode)

}
