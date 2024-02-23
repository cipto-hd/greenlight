package greenlight

//go:generate go run gen.go
func version() string {
	return Version
}
