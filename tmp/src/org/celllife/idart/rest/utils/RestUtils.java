package org.celllife.idart.rest.utils;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * 
 * @author helio.machabane
 *
 */
public abstract class RestUtils {

	public static String castDateToString (Date date ) {
		
		SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
		
		String strDate = dateFormat.format(date);
		
		return strDate;	
	}
}
