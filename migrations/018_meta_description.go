package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

// Agrega meta_description + meta_description_en a site_settings para SEO / OG.
func init() {
	m.Register(func(app core.App) error {
		col, err := app.FindCollectionByNameOrId("site_settings")
		if err != nil {
			return err
		}
		if col.Fields.GetByName("meta_description") == nil {
			col.Fields.Add(&core.TextField{Name: "meta_description", Max: 300})
		}
		if col.Fields.GetByName("meta_description_en") == nil {
			col.Fields.Add(&core.TextField{Name: "meta_description_en", Max: 300})
		}
		return app.Save(col)
	}, func(app core.App) error { return nil })
}
