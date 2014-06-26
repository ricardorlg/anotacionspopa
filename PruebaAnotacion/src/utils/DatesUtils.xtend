package utils

import java.text.SimpleDateFormat
import java.util.Date

class DatesUtils {
	val static formats = #[
		"yyyy-MM-dd'T'HH:mm:ss.SSS",
		"yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
		"yyyy-MM-dd'T'HH:mm:ss",
		"yyyy-MM-dd'T'HH:mm",
		"yyyy-MM-dd",
		"dd/mm/yyyy"
	]

	def static Date parses(String dateToFormat) {
		for (format : formats) {
			try {
				var formater = new SimpleDateFormat(format);
				return formater.parse(dateToFormat);
			} catch (Exception e) {
			}
		}
		return null
	}
}
