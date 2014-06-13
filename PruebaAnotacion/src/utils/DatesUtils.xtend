package utils

import java.text.SimpleDateFormat
import java.util.Date

class DatesUtils {
	private static SimpleDateFormat formater=new SimpleDateFormat("dd/mm/yyyy")
	
	def static Date parses(String dateToFormat){
		formater.parse(dateToFormat)
	}
	}