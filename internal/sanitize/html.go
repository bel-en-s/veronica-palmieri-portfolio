package sanitize

import (
	"strings"

	"github.com/microcosm-cc/bluemonday"
)

var policy = bluemonday.UGCPolicy()

func HTML(input string) string {
	result := policy.Sanitize(input)
	result = strings.ReplaceAll(result, "\n", "<br>\n")
	return result
}
