package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

// Agrega text_align y columns a sections para control de layout.
func init() {
	m.Register(func(app core.App) error {
		col, err := app.FindCollectionByNameOrId("sections")
		if err != nil {
			return err
		}
		if col.Fields.GetByName("text_align") == nil {
			col.Fields.Add(&core.SelectField{
				Name:      "text_align",
				MaxSelect: 1,
				Values:    []string{"left", "center", "right", "justify"},
			})
		}
		if col.Fields.GetByName("columns") == nil {
			col.Fields.Add(&core.SelectField{
				Name:      "columns",
				MaxSelect: 1,
				Values:    []string{"1", "2"},
			})
		}
		return app.Save(col)
	}, func(app core.App) error { return nil })
}
