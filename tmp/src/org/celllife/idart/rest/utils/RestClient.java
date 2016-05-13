package org.celllife.idart.rest.utils;

import org.apache.http.entity.StringEntity;
import org.apache.log4j.Logger;
import org.celllife.idart.rest.ApiAuthRest;


/**
 * 
 * @author helio.machabane
 *
 */
public class RestClient {
	
	private static Logger log = Logger.getLogger(RestClient.class);

	//SET VALUE FOR CONNECT TO OPENMRS
	public RestClient() {
		ApiAuthRest.setURLBase("http://192.168.100.1:8080/openmrs/ws/rest/v1/");
		ApiAuthRest.setUsername("Admin");
		ApiAuthRest.setPassword("openmrsadmin04");
	}
	
	public boolean postOpenMRSEncounter(String encounterDatetime, String nidUuid, String encounterType, String strFacilityUuid, 
			String filaUuid, String providerUuid, String regimeUuid, 
			String strRegimenAnswerUuid, String dispensedAmountUuid, String packSize, 
			String dosageUuid, String customizedDosage, String returnVisitUuid, String strNextPickUp) throws Exception { 
	 	StringEntity inputAddPerson = new StringEntity(
	 			"{\"encounterDatetime\": \""+encounterDatetime+"\", \"patient\": \""+nidUuid+"\", \"encounterType\": \""+encounterType+"\", "
	 			  + "\"location\":\""+strFacilityUuid+"\", \"form\":\""+filaUuid+"\", \"provider\":\""+providerUuid+"\", "
	 			  + "\"obs\":[{\"person\":\""+nidUuid+"\",\"obsDatetime\":\""+encounterDatetime+"\",\"concept\":"
	 			  + "\""+regimeUuid+"\",\"value\":\""+strRegimenAnswerUuid+"\"},{\"person\":"
	 			  + "\""+nidUuid+"\",\"obsDatetime\":\""+encounterDatetime+"\",\"concept\":\""+dispensedAmountUuid+"\","
	 			  + "\"value\":\""+packSize+"\"},{\"person\":\""+nidUuid+"\",\"obsDatetime\":\""+encounterDatetime+"\",\"concept\":"
	 			  + "\""+dosageUuid+"\",\"value\":\""+customizedDosage+"\"},{\"person\":\""+nidUuid+"\","
	 			  + "\"obsDatetime\":\""+encounterDatetime+"\",\"concept\":\""+returnVisitUuid+"\",\"value\":\""+strNextPickUp+"\"}]}"
	 			);
	 		 	
	 		 	inputAddPerson.setContentType("application/json");
	 		 	//log.info("AddPerson = " + ApiAuthRest.getRequestPost("encounter",inputAddPerson));
				return ApiAuthRest.getRequestPost("encounter",inputAddPerson); 
	}
	
	public String getOpenMRSResource(String resourceParameter) {
		String resource = null;
		try {
			resource = ApiAuthRest.getRequestGet(resourceParameter);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return resource;
	}
}
