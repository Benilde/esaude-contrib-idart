package org.celllife.idart.rest.utils;

import java.io.UnsupportedEncodingException;

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
		ApiAuthRest.setURLBase("http://localhost:8080/openmrs/ws/rest/v1/");
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
	
	public boolean postOpenMRSPatient(String gender, String firstName, String middleName, String lastName, String birthDate, String nid) throws Exception {
		StringEntity inputAddPatient = new StringEntity(
				"{\"person\":"
					+"{"
						+"\"gender\": \""+gender+"\","
						+"\"names\":"
						+"[{\"givenName\": \""+firstName+"\", \"middleName\": \""+middleName+"\", \"familyName\": \""+lastName+"\"}], \"birthdate\": \""+birthDate+"\""
					+"},"
					+"\"identifiers\":"
					+"["
						+"{"
							+"\"identifier\": \""+nid+"\", \"identifierType\": \"e2b966d0-1d5f-11e0-b929-000c29ad1d07\","
							+"\"location\": \"e2b32fc2-1d5f-11e0-b929-000c29ad1d07\", \"preferred\": \"true\""
						+"}"
					+"]"
				+"}"
				);
	 	
		inputAddPatient.setContentType("application/json");
 		//log.info("AddPerson = " + ApiAuthRest.getRequestPost("encounter",inputAddPerson));
		return ApiAuthRest.getRequestPost("patient",inputAddPatient); 
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
