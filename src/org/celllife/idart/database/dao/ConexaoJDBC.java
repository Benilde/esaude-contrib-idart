package org.celllife.idart.database.dao;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Vector;

import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;
import org.celllife.idart.commonobjects.iDartProperties;
import org.celllife.idart.database.hibernate.PrescriptionToPatient;
import org.celllife.idart.gui.alert.RiscoRoptura;
import org.celllife.idart.gui.sync.dispense.SyncLinha;
import org.celllife.idart.gui.sync.patients.SyncLinhaPatients;



/**
 * Esta classe efectua conexao com a BD postgres e tem metodo para a manipulacao dos dados
 * @author EdiasJambaia
 *
 */

public class ConexaoJDBC {
	
	private static Logger log = Logger.getLogger(ConexaoJDBC.class);
Connection conn_db;  // Conexão com o servidor de banco de dados
Statement st;   // Declaração para executar os comandos

/**
 * Conexao a base de dado
 * @param usr
 * @param pwd
 * @throws SQLException
 * @throws ClassNotFoundException
 */
	
	public void conecta(String usr, String pwd) throws SQLException, ClassNotFoundException 
{

		DOMConfigurator.configure("log4j.xml");
		
		//String url = "jdbc:postgresql://192.168.0.105/pharm?charSet=LATIN1";
		String url = iDartProperties.hibernateConnectionUrl;
		               
		
	//System.out.println(" url "+iDartProperties.hibernateConnectionUrl);	
		
		log.info("Conectando ao banco de dados\nURL = " + url);



// Carregar o driver
Class.forName("org.postgresql.Driver");

// Conectar com o servidor de banco de dados

conn_db = DriverManager.getConnection(url, usr, pwd);

 

log.info("Conectado...Criando a declaração");


st = conn_db.createStatement();


}
	

	
	/**
	 * Retorna a conexao com a base de dados
	 * @param usr
	 * @param pwd
	 * @return
	 * @throws SQLException
	 * @throws ClassNotFoundException
	 */
	
	public Connection retornaConexao(String usr, String pwd) throws SQLException, ClassNotFoundException 
{



String url = iDartProperties.hibernateConnectionUrl;

// Carregar o driver
Class.forName("org.postgresql.Driver");

// Conectar com o servidor de banco de dados


conn_db = DriverManager.getConnection(url, usr, pwd);


//st = conn_db.createStatement();

return conn_db;

}
	
	
	
/**
 * Devolve a lista de PrescriptionToPatient, na verdade so devolve lista de tamanho 1
 * @param patientid
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */

public List<PrescriptionToPatient> listPtP(String patientid ) throws ClassNotFoundException, SQLException{
	
	conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	
	String query=""
			+ "SELECT "
			+ "p.id, "
			+ "p.current, "
			+ "p.duration, "
			+ "p.reasonforupdate, "
			+ "p.notes, "
			+ "pt.patientid, "
			+ "rt.regimeesquema, "
			+" date_part(\'YEAR\',now())-date_part(\'YEAR\',pt.dateofbirth) as idade,  "
			+" p.motivomudanca AS motivomudanca, "
			+" p.datainicionoutroservico as datainicionoutroservico, "
			+ "lt.linhanome "
			+" FROM "
			+ "  patient pt, "
			+ "regimeterapeutico rt,  "
			+ "linhat lt, "
			+ "prescription AS p "
			+ "WHERE ("
			+ "(p.current = \'T\'::bpchar) "
			+ "AND "
			+ "(pt.id = p.patient) "
			+ "AND "
			+ "(pt.patientid=\'"+patientid+"\') "
			+ "AND "
			+ "(rt.regimeid=p.regimeid) "
			+ "AND "
			+ "(lt.linhaid=p.linhaid)) ";
	
	
	//ResultSet rs = st.executeQuery("select id, current, duration, reasonforupdate, notes, patientid from PrescriptioToPatient where patientid=\'"+patientid+"\'");
	List <PrescriptionToPatient> ptp = new ArrayList();
	ResultSet rs=st.executeQuery(query);
	if (rs != null)
        {
           
            while (rs.next())
            {

            	ptp.add(new PrescriptionToPatient(rs.getInt("id"), rs.getString("current"), rs.getInt("duration"),
            			rs.getString("reasonforupdate"),rs.getString("notes"), rs.getString("patientid"), rs.getString("regimeesquema"), rs.getInt("idade"), rs.getString("motivomudanca"),rs.getDate("datainicionoutroservico"),rs.getString("linhanome")));



           
            }
            rs.close(); // é necessário fechar o resultado ao terminar
        }
        
        st.close();
        conn_db.close();
        return ptp;
	}

/**
 * Converte uma data para o formato DD Mon YYYY
 * @param date
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public Date converteData(String date) throws ClassNotFoundException, SQLException{
	
	Date data=new Date();
	conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	
	String query="select to_date(\'"+date+"\', \'DD Mon YYYY\')";
	ResultSet rs=st.executeQuery(query);
	
	rs.next();
	data=rs.getDate("to_date");
	
	  st.close();
      conn_db.close();
      return data;
}



/**
 * devolve um vector de todos medicamentos com seus AMC, SALDO E QUANTIDADE DE REQUISICAO
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public Vector<RiscoRoptura> selectRiscoDeRopturaStock() throws ClassNotFoundException, SQLException{

	
		
	
	String query="SELECT drugname, consumo_max_ult_3meses, saldos "
			+ "FROM "
			+ "alimenta_risco_roptura";
	
	
    Vector<RiscoRoptura> riscos=new Vector<RiscoRoptura>();
 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
   
	ResultSet rs=st.executeQuery(query);
	if (rs != null)
        {
           
            while (rs.next())
            {

RiscoRoptura rr=new RiscoRoptura(rs.getString("drugname"), rs.getInt("consumo_max_ult_3meses"), rs.getInt("saldos"), rs.getInt("consumo_max_ult_3meses")*3 - rs.getInt("saldos"));

riscos.add(rr);
System.out.println(" \n");

            } 
            rs.close(); // é necessário fechar o resultado ao terminar
        }
	
	
      
        st.close();
        conn_db.close();
return riscos;

	
}


/**
 * Total de pacientes que levantaram ARVs num periodo
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesFarmacia(String startDate, String endDate) throws ClassNotFoundException, SQLException{

      String query=""
			+ "SELECT  "
			+ " distinct packagedruginfotmp.patientid "
			+ " FROM  "
			+ " packagedruginfotmp "
			+ "  WHERE "
			+ "  packagedruginfotmp.dispensedate::timestamp::date >=  "
			+ "\'"+startDate+"\'"
			+ "AND packagedruginfotmp.dispensedate::timestamp::date <= "
			+ " \'"+endDate+"\'"
					+ " AND "
					+ " dispensedate IS NOT NULL"
;
     
	int total=0;

	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

	total++;

	

	            } 
	            rs.close(); //
	        }
    
	
	return total;
}

/**
 * Total de pacientes que iniciaram o tratamento de ARV num periodo
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesInicio(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	

	

 


			String query=" SELECT  DISTINCT "
					
+ "	 dispensa_packege.patientid  "
	+ "	FROM  "

	+ "	( "
	+ "	  SELECT  "

	+ "		prescription.id, package.packageid  "

+ "		 FROM  "

	+ "	 prescription,  "
 	+ "	package  "
 
	+ "	 WHERE  "

	+ "	 prescription.id = package.prescription  "

	+ "	 AND  "
	 + "	 prescription.ppe=\'F\' "
      
  			
	 + "	AND   "

	+ "	 prescription.reasonforupdate=\'Inicia\'   "
	 
	+ "	 )as prescription_package,  "

	+ "	 (  "
	+ "	 SELECT  "
	

	+ "	 packagedruginfotmp.patientid,  "
	+ "	 packagedruginfotmp.packageid, "
	+ "	 packagedruginfotmp.dispensedate "
	 
+ "	 "
	+ "	 FROM "
	+ "	 package, packagedruginfotmp  "

	 + "	 WHERE  "

+ "		 package.packageid=packagedruginfotmp.packageid  "
+ "		 AND  "
 
	+ "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	+ " \'"+endDate+"\'::timestamp::date  "
	 + "	) as dispensa_packege  ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			
			
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}
/**
 * PARA MMIA PERSONALIZADO
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */

public int totalPacientesInicioP(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	

	
 


	
	String query=" SELECT  DISTINCT "
			+" dispensa_packege.patientid "
			+"	FROM "

		+"	(SELECT "

		+"	prescription.id, package.packageid "

			+" FROM "

			+" prescription, "
		+" 	package "

			+" WHERE "

			+" prescription.id = package.prescription "

			+" AND "
			+"  prescription.ppe=\'F\'  "
							
			+" AND  "

			+" prescription.reasonforupdate=\'Inicia\' AND prescription.ptv=\'F\' AND prescription.tb=\'F\' "
			 
			+" )as prescription_package, "

			+" ( "
			+" SELECT "
			 

			+" packagedruginfotmp.patientid, "
			+" packagedruginfotmp.packageid, "
			+ " packagedruginfotmp.dispensedate "

			+" FROM "
			+" package, packagedruginfotmp "

			+" WHERE "

			+" package.packageid=packagedruginfotmp.packageid "
			+" AND "

			+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
					+ " \'"+endDate+"\'::timestamp::date"
			+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			

	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 * Total de pacientes na manutencao de ARV num periodo
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesManter(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
	
	



 
	String query=" SELECT  DISTINCT "
+" dispensa_packege.patientid "
+"	FROM "

+"	(SELECT "

+"	prescription.id, package.packageid "

+" FROM "

+" prescription, "
+" 	package "

+" WHERE "

+" prescription.id = package.prescription "

+" AND "
+"  prescription.ppe=\'F\'  "
			
+" AND  "

+" (prescription.reasonforupdate=\'Manter\' OR prescription.reasonforupdate=\'Transfer de\' OR prescription.reasonforupdate=\'Reiniciar\')  "

+" )as prescription_package, "

+" ( "
+" SELECT "
 

+" packagedruginfotmp.patientid, "
+" packagedruginfotmp.packageid,"
+ "packagedruginfotmp.dispensedate "

+" FROM "
+" package, packagedruginfotmp "

+" WHERE "

+" package.packageid=packagedruginfotmp.packageid "
+" AND "

+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
	+ " \'"+endDate+"\'::timestamp::date"
+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			

	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 * PARA MMIA PERSONALIZADO
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */

public int totalPacientesManterP(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
	
	

 


	
	String query=" SELECT  DISTINCT "
			+" dispensa_packege.patientid"
			+"	FROM "

		+"	(SELECT "

		+"	prescription.id, package.packageid "

			+" FROM "

			+" prescription, "
		+" 	package "

			+" WHERE "

			+" prescription.id = package.prescription "

			+" AND "
			+"  prescription.ppe=\'F\' AND prescription.ptv=\'F\' AND prescription.tb=\'F\'  AND (prescription.reasonforupdate=\'Manter\' OR prescription.reasonforupdate=\'Transfer de\')"
							
			 
			 
			+" )as prescription_package, "

			+" ( "
			+" SELECT "
			 

			+" packagedruginfotmp.patientid, "
			+" packagedruginfotmp.packageid,"
			+ " packagedruginfotmp.dispensedate"

			+" FROM "
			+" package, packagedruginfotmp "

			+" WHERE "

			+" package.packageid=packagedruginfotmp.packageid "
			+" AND "

			+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
					+ " \'"+endDate+"\'::timestamp::date"
			+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			

	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 *  Total de pacientes na manutencao de ARV num periodo
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesAlterar(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
	
	
 
	

	String query=" SELECT  DISTINCT "
+" dispensa_packege.patientid "
+"	FROM "

+"	(SELECT "

+"	prescription.id, package.packageid "

+" FROM "

+" prescription, "
+" 	package "

+" WHERE "

+" prescription.id = package.prescription "

+" AND "
+"  prescription.ppe=\'F\'  "
			
+" AND  "

+" prescription.reasonforupdate=\'Alterar\'  "

+" )as prescription_package, "

+" ( "
+" SELECT "
 

+" packagedruginfotmp.patientid, "
+" packagedruginfotmp.packageid,"
+ " packagedruginfotmp.dispensedate "

+" FROM "
+" package, packagedruginfotmp "

+" WHERE "

+" package.packageid=packagedruginfotmp.packageid "
+" AND "

+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
	+ " \'"+endDate+"\'::timestamp::date"
+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			


	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 * PARA MMIA PERSONALIZADO
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesAlterarP(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
	
	

	 


	
	String query=" SELECT  DISTINCT "
+" dispensa_packege.patientid"
+"	FROM "

+"	(SELECT "

+"	prescription.id, package.packageid "

+" FROM "

+" prescription, "
+" 	package "

+" WHERE "

+" prescription.id = package.prescription "

+" AND "
+"  prescription.ppe=\'F\' AND  prescription.ptv=\'F\' AND prescription.tb=\'F\'  "
			
+" AND  "

+" prescription.reasonforupdate=\'Alterar\'  "

+" )as prescription_package, "

+" ( "
+" SELECT "
 

+" packagedruginfotmp.patientid, "
+" packagedruginfotmp.packageid,"
+ "packagedruginfotmp.dispensedate "

+" FROM "
+" package, packagedruginfotmp "

+" WHERE "

+" package.packageid=packagedruginfotmp.packageid "
+" AND "

+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
	+ " \'"+endDate+"\'::timestamp::date"
+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			

	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}


/**
 * Total de pacientes PPE
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesPPE(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
	
	

 


	String query=" SELECT  DISTINCT "
			+" dispensa_packege.patientid "
			+"	FROM "

			+"	(SELECT "

			+"	prescription.id, package.packageid "

			+" FROM "

			+" prescription, "
			+" 	package "

			+" WHERE "

			+" prescription.id = package.prescription "

			+" AND "
			+"  prescription.ppe=\'T\' AND  prescription.ptv=\'F\' AND prescription.tb=\'F\'  "
						
			 

			+" )as prescription_package, "

			+" ( "
			+" SELECT "
			 

			+" packagedruginfotmp.patientid, "
			+" packagedruginfotmp.packageid,"
			+ "packagedruginfotmp.dispensedate "

			+" FROM "
			+" package, packagedruginfotmp "

			+" WHERE "

			+" package.packageid=packagedruginfotmp.packageid "
			+" AND "

			+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
				+ " \'"+endDate+"\'::timestamp::date"
			+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			

	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 * Total de pacientes PTV iNICIO
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesPTVInicio(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
	
	 


	
	String query=" SELECT  DISTINCT "
			+" dispensa_packege.patientid "
			+"	FROM "

		+"	(SELECT "

		+"	prescription.id, package.packageid "

			+" FROM "

			+" prescription, "
		+" 	package "

			+" WHERE "

			+" prescription.id = package.prescription "

			+" AND "
			+"  prescription.ppe=\'F\' AND prescription.ptv=\'T\'  "
							
			+" AND  "

			+" prescription.reasonforupdate=\'Inicia\'  "
			 
			+" )as prescription_package, "

			+" ( "
			+" SELECT "
		 

			+" packagedruginfotmp.patientid, "
			+" packagedruginfotmp.packageid,"
			+ " packagedruginfotmp.dispensedate"

			+" FROM "
			+" package, packagedruginfotmp "

			+" WHERE "

			+" package.packageid=packagedruginfotmp.packageid "
			+" AND "

			+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
					+ " \'"+endDate+"\'::timestamp::date"
			+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			

	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 * Total de pacientes PTV Manter
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesPTVManter(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
 


	
	String query=" SELECT  DISTINCT "
			+" dispensa_packege.patientid "
			+"	FROM "

		+"	(SELECT "

		+"	prescription.id, package.packageid "

			+" FROM "

			+" prescription, "
		+" 	package "

			+" WHERE "

			+" prescription.id = package.prescription "

			+" AND "
			+"  prescription.ppe=\'F\' AND prescription.ptv=\'T\'  "
							
			+" AND  "

			+" prescription.reasonforupdate=\'Manter\'  "
			 
			+" )as prescription_package, "

			+" ( "
			+" SELECT "
 

			+" packagedruginfotmp.patientid, "
			+" packagedruginfotmp.packageid,"
			+ " packagedruginfotmp.dispensedate "

			+" FROM "
			+" package, packagedruginfotmp "

			+" WHERE "

			+" package.packageid=packagedruginfotmp.packageid "
			+" AND "

			+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
					+ " \'"+endDate+"\'::timestamp::date"
			+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			

	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 * Total de pacientes TB Alterar
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesTbAlterar(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
	
	

 

	
	String query=" SELECT  DISTINCT "
			+" dispensa_packege.patientid "
			+"	FROM "

		+"	(SELECT "

		+"	prescription.id, package.packageid "

			+" FROM "

			+" prescription, "
		+" 	package "

			+" WHERE "

			+" prescription.id = package.prescription "

			+" AND "
			+"  prescription.ppe=\'F\' AND prescription.tb=\'T\'  "
							
			+" AND  "

			+" prescription.reasonforupdate=\'Alterar\'  "
			 
			+" )as prescription_package, "

			+" ( "
			+" SELECT "



			+" packagedruginfotmp.patientid, "
			+" packagedruginfotmp.packageid,"
			+ " packagedruginfotmp.dispensedate"

			+" FROM "
			+" package, packagedruginfotmp "

			+" WHERE "

			+" package.packageid=packagedruginfotmp.packageid "
			+" AND "

			+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
					+ " \'"+endDate+"\'::timestamp::date"
			+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			


	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 * Devolve o regime anterior de uma prescricao
 * 
 * @param idpaciente
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public String carregaRegime(int idpaciente) throws ClassNotFoundException, SQLException

{
	
	String query=" "
			+ " SELECT "
			+ " regimeterapeutico.regimeesquema "
			+ "  FROM "
			+ "  regimeterapeutico , "
			+ "  prescription "
			+ "  WHERE "
			+ "  prescription.regimeid =regimeterapeutico.regimeid "
			+ "  AND "
			+ "  prescription.patient="+idpaciente
			+ "  AND "
			+ "  prescription.current=\'T\'"
			+ "";
	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);

String regime="";
		ResultSet rs=st.executeQuery(query);
		
		if (rs != null)
        {
           
            while (rs.next())
            {


regime=rs.getString("regimeesquema");

            } 
            rs.close(); //
        }
		
		return regime;
		
		
}


/**
 * Devolve ppe  duma prescricao
 * 
 * @param idpaciente
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */

public String carregaPpe(int idpaciente) throws ClassNotFoundException, SQLException

{
	
	String query=" "
			+ " SELECT "
			+ " ppe "
			+ "  FROM "
			+ "   "
			+ "  prescription "
			+ "  WHERE "
			+ "   "
			+ "  "
			+ "  prescription.patient="+idpaciente
			+ "  AND "
			+ "  prescription.current=\'T\'"
			+ "";
	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);

	 String ppe="";
		ResultSet rs=st.executeQuery(query);
		
		if (rs != null)
        {
           
            while (rs.next())
            {


ppe=rs.getString("ppe");

            } 
            rs.close(); //
        }
		
		return ppe;
		
		
}

/**
 * Devolve a linha anterior duma prescricao
 * 
 * @param idpaciente
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */

public String carregaLinha(int idpaciente) throws ClassNotFoundException, SQLException

{
	
	String query=" "
			+ " SELECT "
			+ " linhat.linhanome "
			+ "  FROM "
			+ "  linhat , "
			+ "  prescription "
			+ "  WHERE "
			+ "  prescription.linhaid =linhat.linhaid "
			+ "  AND "
			+ "  prescription.patient="+idpaciente
			+ "  AND "
			+ "  prescription.current=\'T\'"
			+ "";
	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);

String linha="";
		ResultSet rs=st.executeQuery(query);
		
		if (rs != null)
        {
           
            while (rs.next())
            {


linha=rs.getString("linhanome");

            } 
            rs.close(); //
        }
		
		return linha;
		
		
}



/**
 * Devolve tb  duma prescricao
 * 
 * @param idpaciente
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */

public String carregaTb(int idpaciente) throws ClassNotFoundException, SQLException

{
	
	String query=" "
			+ " SELECT "
			+ " tb "
			+ "  FROM "
			+ "   "
			+ "  prescription "
			+ "  WHERE "
			+ "   "
			+ "  "
			+ "  prescription.patient="+idpaciente
			+ "  AND "
			+ "  prescription.current=\'T\'"
			+ "";
	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);

	 String tb="";
		ResultSet rs=st.executeQuery(query);
		
		if (rs != null)
        {
           
            while (rs.next())
            {


tb=rs.getString("tb");

            } 
            rs.close(); //
        }
		
		return tb;
		
		
}


/**
 * Devolve se um ARV é pediátrico ou adulto
 * 
 * @param idpaciente
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */

public String carregaPediatric(int iddrug) throws ClassNotFoundException, SQLException

{
	
	String query=" "
			+ " SELECT "
			+ " pediatric "
			+ "  FROM "
			+ "   "
			+ "  drug "
			+ "  WHERE "
			+ "   "
			+ "  "
			+ "  drug.id="+iddrug;
	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);

	 String pediatric="";
		ResultSet rs=st.executeQuery(query);
		
		if (rs != null)
        {
           
            while (rs.next())
            {


            	pediatric=rs.getString("pediatric");

            } 
            rs.close(); //
        }
		
		return pediatric;
		
		
}

/**
 * Devolve ptv  duma prescricao
 * 
 * @param idpaciente
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */

public String carregaPtv(int idpaciente) throws ClassNotFoundException, SQLException

{
	
	String query=" "
			+ " SELECT "
			+ " ptv "
			+ "  FROM "
			+ "   "
			+ "  prescription "
			+ "  WHERE "
			+ "   "
			+ "  "
			+ "  prescription.patient="+idpaciente
			+ "  AND "
			+ "  prescription.current=\'T\'"
			+ "";
	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);

	 String ptv="";
		ResultSet rs=st.executeQuery(query);
		
		if (rs != null)
        {
           
            while (rs.next())
            {


ptv=rs.getString("ptv");

            } 
            rs.close(); //
        }
		
		return ptv;
		
		
}

/**
 * Total de Meses Dispensados
 * @param startDate
 * @param endDate
 * @return
 * @throws SQLException
 */

public int mesesDispensados(String startDate, String endDate) throws SQLException{
	
	int meses=0;
	double somaSemanas=0;
	
	String query=" SELECT "
			+ " weekssupply, packageid"
			+ " FROM packagedruginfotmp "
			+ ""
			+ " WHERE "
			+ "  packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date "
					+ "AND packagedruginfotmp.dispensedate::timestamp::date <="
					+ " \'"+endDate+"\'::timestamp::date GROUP BY packageid, weekssupply";
	
	ResultSet rs=st.executeQuery(query);
	
	if (rs != null)
    {
       
        while (rs.next())
        {


somaSemanas+=rs.getInt("weekssupply");

        } 
        rs.close(); //
        
        meses=(int) Math.round(somaSemanas/4);
    }
	
	
	return meses;
}

/**
 * Insere pacientes que nao estao ainda no SESP
 * @param nid
 * @param nomes
 * @param apelido
 * @param dataderegisto
 * @throws ClassNotFoundException
 * @throws SQLException
 */

public void inserPacienteIdart(String nid, String nomes, String apelido, Date dataderegisto) throws ClassNotFoundException, SQLException
{
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	 
	 st.executeUpdate(""
	 		+ " INSERT INTO registadosnoidart (nid, nomes, apelido, dataderegisto) "
	 		+ "  VALUES( \'"
	 		+ nid
	 		+ "\',\'"
	 		+ nomes
	 		+ "\',\'"
	 		+ apelido
	 		+ "\',\'"
	 		+new SimpleDateFormat("yyyy-MM-dd").format(dataderegisto)
	 		+ "\')");
	
}


/**
 * VE se o paciente foi dispensado ARV no periodo
 * @param patientid
 * @return
 * @throws ClassNotFoundException
 */
public boolean dispensadonoperiodo(String patientid) throws ClassNotFoundException
{
	
	
	boolean foidispensado=false;
	try {
		conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	
	try {
		ResultSet rs= st.executeQuery(""
				+ " SELECT "
				+ "  patientid FROM  "
				+ "   packagedruginfotmp "
				+ "  WHERE "
				+ " to_timestamp(dateexpectedstring, \'DD Mon YYYY\')::DATE > now()::DATE "
				+ "  AND patientid = \'"+patientid
				+ ""
				+ "\'");
		
		
		if(rs!=null)
			while(rs.next())
				foidispensado=true;
				
		
		
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
			
	

	return foidispensado;
	

}


/**
 * Total de pacientes TB iNICIO
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesTbInicio(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
	
	

 


	
	String query=" SELECT  DISTINCT "
			+" dispensa_packege.patientid  "
			+"	FROM "

		+"	(SELECT "

		+"	prescription.id, package.packageid "

			+" FROM "

			+" prescription, "
		+" 	package "

			+" WHERE "

			+" prescription.id = package.prescription "

			+" AND "
			+"  prescription.ppe=\'F\' AND prescription.tb=\'T\'  "
							
			+" AND  "

			+" prescription.reasonforupdate=\'Inicia\'  "
			 
			+" )as prescription_package, "

			+" ( "
			+" SELECT "
		 

			+" packagedruginfotmp.patientid, "
			+" packagedruginfotmp.packageid,"
			+ "packagedruginfotmp.dispensedate"

			+" FROM "
			+" package, packagedruginfotmp "

			+" WHERE "

			+" package.packageid=packagedruginfotmp.packageid "
			+" AND "

			+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
					+ " \'"+endDate+"\'::timestamp::date"
			+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			


	
	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 * Total de pacientes TB Manter
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesTbManter(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
	


	
	String query=" SELECT  DISTINCT "
			+" dispensa_packege.patientid "
			+"	FROM "

		+"	(SELECT "

		+"	prescription.id, package.packageid "

			+" FROM "

			+" prescription, "
		+" 	package "

			+" WHERE "

			+" prescription.id = package.prescription "

			+" AND "
			+"  prescription.ppe=\'F\' AND prescription.tb=\'T\'  "
							
			+" AND  "

			+"  prescription.reasonforupdate=\'Manter\'   "
			 
			+" )as prescription_package, "

			+" ( "
			+" SELECT "
			 

			+" packagedruginfotmp.patientid, "
			+" packagedruginfotmp.packageid ,"
			+ "packagedruginfotmp.dispensedate"

			+" FROM "
			+" package, packagedruginfotmp "

			+" WHERE "

			+" package.packageid=packagedruginfotmp.packageid "
			+" AND "

			+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
					+ " \'"+endDate+"\'::timestamp::date"
			+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			

	
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 * Total de pacientes PTV Alterar
 * @param startDate
 * @param endDate
 * @return
 * @throws ClassNotFoundException
 * @throws SQLException
 */
public int totalPacientesPTVAlterar(String startDate, String endDate)throws ClassNotFoundException, SQLException{
	int total=0;
	
	
	
 

	String query=" SELECT  DISTINCT"
			+" dispensa_packege.patientid "
			+"	FROM "

		+"	(SELECT "

		+"	prescription.id, package.packageid "

			+" FROM "

			+" prescription, "
		+" 	package "

			+" WHERE "

			+" prescription.id = package.prescription "

			+" AND "
			+"  prescription.ppe=\'F\'  AND prescription.ptv=\'T\' AND prescription.reasonforupdate=\'Alterar\'"
							
		 
			 
			+" )as prescription_package, "

			+" ( "
			+" SELECT "
			 

			+" packagedruginfotmp.patientid, "
			+" packagedruginfotmp.packageid,"
			+ "packagedruginfotmp.dispensedate "

			+" FROM "
			+" package, packagedruginfotmp "

			+" WHERE "

			+" package.packageid=packagedruginfotmp.packageid "
			+" AND "

			+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
					+ " \'"+endDate+"\'::timestamp::date"
			+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			

			

	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
	
}

/**
 * Total de pacientes pvt sem discriminar
 * @param startDate
 * @param endDate
 * @return
 */
public int totalPacientesPTV(String startDate, String endDate) throws ClassNotFoundException, SQLException{
	int total=0;
	
	
	

 
	String query=" SELECT DISTINCT "
			+" dispensa_packege.patientid "
			+"	FROM "

		+"	(SELECT  "

		+"	prescription.id, package.packageid "

			+" FROM "

			+" prescription, "
		+" 	package "

			+" WHERE "

			+" prescription.id = package.prescription "

			+" AND "
			+"  prescription.ppe=\'F\'  AND prescription.ptv=\'T\'"
							
		 
			 
			+" )as prescription_package, "

			+" ( "
			+" SELECT "
		 

			+" packagedruginfotmp.patientid, "
			+" packagedruginfotmp.packageid,"
			+ "  packagedruginfotmp.dispensedate"

			+" FROM "
			+" package, packagedruginfotmp "

			+" WHERE "

			+" package.packageid=packagedruginfotmp.packageid "
			+" AND "

			+"				 packagedruginfotmp.dispensedate::timestamp::date >= "
			+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <= "
					+ " \'"+endDate+"\'::timestamp::date"
			+" ) as dispensa_packege ,"
          
	 + " ("
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	 + "  	 WHERE  "

 	 + "	 package.packageid=packagedruginfotmp.packageid  "
 	 + "	 AND  "
 
	  + "					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "\'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	 + " \'"+endDate+"\'::timestamp::date  "
	  
	 + "  group by packagedruginfotmp.patientid "
 
      + "     ) as ultimadatahora "

	+ "	 WHERE  "
	+ "	 dispensa_packege.packageid=prescription_package.packageid  "
     + "	  and  "
     + "  dispensa_packege.dispensedate=ultimadatahora.lastdispense";
			

			
	 conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);


		ResultSet rs=st.executeQuery(query);
		if (rs != null)
	        {
	           
	            while (rs.next())
	            {

 	total++;

	            } 
	            rs.close(); //
	        }
		return total;
}
public String getQueryHistoricoLevantamentos(boolean i, boolean m, boolean a, String startDate, String endDate){
	
	
	
	Vector<String> v = new Vector<String>();
	
	if (i) v.add("Inicia");
	if (m) v.add("Manter");
	if (a) v.add("Alterar");
	
	String condicao="(\'";
	
	if(v.size()==3){
	for(int j=0;j<v.size()-1;j++)
		
	condicao +=v.get(j)+"\' , \'";
	
	condicao +=v.get(v.size()-1)+"\')";
	}
	
	if(v.size()==2){
		for(int j=0;j<v.size()-1;j++)
			
			condicao +=v.get(j)+"\' , \'";
		
		condicao +=v.get(v.size()-1)+"\')";
		}
	
	if(v.size()==1){
	 
			
	  
		condicao +=v.get(0)+"\')";
		}



	String query=""
			
			
		+ " SELECT DISTINCT dispensas_e_prescricoes.nid, patient.firstnames as nome, patient.lastname as apelido, "
		+ " dispensas_e_prescricoes.tipotarv,  "
     + "   dispensas_e_prescricoes.regime, "
     + "    dispensas_e_prescricoes.datalevantamento,"
    + "    dispensas_e_prescricoes.dataproximolevantamento "
    + "    FROM "
+ "  (SELECT   "
					
 	+ "  dispensa_packege.nid , "
    + "    prescription_package.tipotarv,  "
    + "    prescription_package.regime, "
     + "    dispensa_packege.datalevantamento, "
     + "    dispensa_packege.dataproximolevantamento "
	 + " 	FROM  "

	 + " 	( "
	 	+ "   SELECT  "

	 + " 		prescription.id, "
	 + " package.packageid ,prescription.reasonforupdate as tipotarv, regimeterapeutico.regimeesquema as regime "

 	+ " 	 FROM  "

	 + " 	 prescription,  "
 	 	+ " package , regimeterapeutico "
 
	 	+ "  WHERE   "

	 	 + " prescription.id = package.prescription  "

	 	+ "  AND  "
	  + " 	 prescription.ppe=\'F\' "
      
  		+ " 	AND 	prescription.regimeid=regimeterapeutico.regimeid "
	  	+ " AND   "

	+ "  	 prescription.reasonforupdate IN "+condicao   
	 
	+ " 	 )as prescription_package,  "

	 + " 	 (  "
	 			+ " 	 SELECT  "
	

	 + " 	 packagedruginfotmp.patientid as nid,  "
	 + " 	 packagedruginfotmp.packageid,"
	 + " 	 packagedruginfotmp.dispensedate as datalevantamento,"
	+ "  	 to_date(packagedruginfotmp.dateexpectedstring, 'DD-Mon-YYYY') as dataproximolevantamento "
	 	  
	+ "  	 FROM "
	 	+ "  	 package, packagedruginfotmp  "

	  + " 	 WHERE  "

 	+ " 	 package.packageid=packagedruginfotmp.packageid  "
 	+ " 	 AND  "
 
	+ "  					 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "  \'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	+ "   \'"+endDate+"\'::timestamp::date  "
	  + " 	) as dispensa_packege,"
      + "     ( "
      + "     select packagedruginfotmp.patientid,  "
	 	 
	 + " 	  max(packagedruginfotmp.dispensedate) as lastdispense"
	 
 	 
	 + " 	 FROM "
	 + " 	 package, packagedruginfotmp  "

	  	+ "  WHERE  "

 		+ "  package.packageid=packagedruginfotmp.packageid  "
 	+ " 	 AND  "
 
	 		+ " 			 packagedruginfotmp.dispensedate::timestamp::date >=  "
	+ "  \'"+startDate+"\'::timestamp::date  AND  packagedruginfotmp.dispensedate::timestamp::date <=  "
	+ "   \'"+endDate+"\'::timestamp::date  "
	  
	+ "   group by packagedruginfotmp.patientid "
 
   + "       ) as ultimadatahora  "

	+ "  	 WHERE  "
	+ "  	 dispensa_packege.packageid=prescription_package.packageid  "
	 	 
	 + " 	 and "
    + "    dispensa_packege.datalevantamento=ultimadatahora.lastdispense "
    + "    ) as dispensas_e_prescricoes "
   + "     ,"
       + "     patient "
       
    + "    where "
       
    + "    dispensas_e_prescricoes.nid=patient.patientid";
 

 
	return query;
	
}

public void insere_sync_temp_dispense(){
	
	delete_sync_temp_dispense();
	 try {
		conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	} catch (ClassNotFoundException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	} catch (SQLException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	} 
	
	ConexaoODBC conn=new ConexaoODBC();
	
	ResultSet data=conn.result_for_sync_dispense();
	
	
	if(data!=null)
	{
		try {
			

			while (data.next())
			{
			
				st.executeUpdate(" INSERT INTO sync_temp_dispense(nid,ultimo_levantamento) values (\'"+data.getString("nid")+"\',\'"+data.getString("ultimo_lev")+"\')"); 
		 
			}
			st.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	else System.out.println("NULL NULL NULL NULL");
}

public int total_rows( ) {
	 
	ResultSet data=null;
	try {
		conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	} catch (ClassNotFoundException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	} catch (SQLException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	}
	try {
		data = st.executeQuery("SELECT  *   FROM  sync_view_dispense ");
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	int rows=0;
	try {
		while (data.next())
		{
		rows++;
		}
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	try {
		data.close();
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	return rows;
}
public void delete_sync_temp_dispense(){
	
	try {
		conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	} catch (ClassNotFoundException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	} catch (SQLException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	}
	try {
		st.execute("DELETE FROM sync_temp_dispense");
		st.close();
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
}

public  Vector <SyncLinha> sync_table_dispense()
{
	
	insere_sync_temp_dispense();
	Vector<SyncLinha> linha = new Vector<SyncLinha>() ;
	try {
		conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	} catch (ClassNotFoundException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	} catch (SQLException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	}
	try
	{
		String query="SELECT "
				+ " sync_view_dispense.nid as a, "
				+ "  sync_view_dispense.ultimo_lev as b,  "
				+ "   sync_view_dispense.tipo_tarv as c, "
				+ "  sync_view_dispense.regime as d, "
				+ "   sync_view_dispense.linha as e, "
				+ "  "
				+ " sync_view_dispense.ultimo_sesp as f, to_date(tabela.proximolev, 'DD Mon YYYY')  as g  "
				+ ""
				+ " FROM  "
				+ "   sync_view_dispense,"
				+ ""
				+ "(select patientid, max (packagedruginfotmp.dateexpectedstring) proximolev from packagedruginfotmp "
	 
				+ ""
				+ ""
				+ "GROUP BY patientid ) as tabela  WHERE  "
				+ " sync_view_dispense.nid= tabela.patientid";
		
	ResultSet linhas =   st.executeQuery(query);
	
	
	
 
		
	
	//System.out.println(" Query: "+query );
			   

			

 


	
	while (linhas.next()){
		
 	 SyncLinha synclinha=new  SyncLinha(linhas.getString("a"),linhas.getString("b") ,linhas.getString("c") ,linhas.getString("d"),
	linhas.getString("e"),linhas.getString("f"), linhas.getString("g"));
 

	 System.out.println	( linhas.getString("a")+" "+linhas.getString("b") +" "+ linhas.getString("c") +" "+linhas.getString("d")+" "+
					linhas.getString("e")+" "+ linhas.getString("f"));
				 
				
	 linha.add(synclinha);
        
	}
	
 
	
	}catch(SQLException  e){
		
		
	}
	
	System.out.println(" Vector size "+linha.size());
	
	 return linha;
 
}

public Vector <SyncLinhaPatients> sync_table_patients() {

	Vector<SyncLinhaPatients> linha = new Vector<SyncLinhaPatients>() ;
	try {
		conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	} catch (ClassNotFoundException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	} catch (SQLException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	}
	try
	{
		
	ResultSet linhas =   st.executeQuery("SELECT "
			+ " sync_view_patients.nid as a, "
			+ "  sync_view_patients.datanasc  as b, "
			+ " sync_view_patients.pnomes as c, "
			+ " sync_view_patients.unome as d, "
			+ "  sync_view_patients.sexo as e, "
			+ "  sync_view_patients.dataabertura as f "
			+ "  FROM "
			+ " sync_view_patients ");
	
	while (linhas.next()){
		
		
		
		SyncLinhaPatients synclinha=new  SyncLinhaPatients(linhas.getString("a"),linhas.getString("b"), linhas.getString("c"), linhas.getString("d"), linhas.getString("e"), linhas.getString("f"));
 

	/*System.out.println	(linhas.getString("a")+" "+linhas.getString("b") +" "+ linhas.getString("c") +" "+linhas.getString("d")+" "+
					linhas.getString("e")+" "+ linhas.getString("f"));
				*/
				
	 linha.add(synclinha);
        
	}
	
 
	
	}catch(SQLException  e){
		
		
	}
	
	 return linha;
}

public void delete_sync_temp_patients() {
	// TODO Auto-generated method stub
	try {
		conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	} catch (ClassNotFoundException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	} catch (SQLException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	}
	try {
		st.execute("DELETE FROM sync_temp_patients");
		st.close();
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
}

public void insere_sync_temp_patients() {

	

	
	 try {
		conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
	} catch (ClassNotFoundException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	} catch (SQLException e1) {
		// TODO Auto-generated catch block
		e1.printStackTrace();
	} 
	
	ConexaoODBC conn=new ConexaoODBC();
	
	ResultSet data=conn.result_for_sync_patients();
	
 
	
	if(data!=null)
		try {
			

			while (data.next())
			{
				
			 String datanasc=data.getString("datanasc");
			 String dataabertura=data.getString("dataabertura");
			 String unomes=data.getString("apelido");
			 
			 if (unomes==null || contemInterrogacao(unomes) ) unomes ="  ";
			 if(datanasc==null) datanasc=new SimpleDateFormat("yyyy-MM-dd").format(new Date());
			 if(dataabertura==null) dataabertura=new SimpleDateFormat("yyyy-MM-dd").format(new Date());
			
			 String query=" INSERT INTO sync_temp_patients(nid,datanasc,pnomes, unomes, sexo, dataabertura) values (\'"+data.getString("nid")+"\',"
						+ "\'"+datanasc+"\',"
						+ "\'"+data.getString("nome")+"\',"
						+ "\'"+unomes+"\',"
						+ "\'"+data.getString("sexo")+"\',"
						+ "\'"+dataabertura+"\')"
						+ ""; 
				System.out.println(query);

						st.executeUpdate(query);
 
		 
			}
			st.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
}


private boolean contemInterrogacao(String unomes) {
	boolean contem=false;
	
	if(unomes!=null)
		
	{
		
		for(int i=0;i<unomes.length();i++)
			if(unomes.charAt(i)=='?')
			{
				contem=true;
				break;
			}
	}
	return contem;
	
}



public void syncdata_patients(SyncLinhaPatients syncLinhaPatients) {
 
	String sexo=syncLinhaPatients.getSexo();
	 if (sexo.trim().equals("null")) sexo ="U";
	 String apelido =syncLinhaPatients.getUnomes();
	 
		 if (apelido.trim().equals("null")) apelido =" ";
		 
	 try {
			conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
		} catch (ClassNotFoundException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} catch (SQLException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} 
	 
		try{
			int id=nextval_hibernate_sequence();
			
			st.executeUpdate(""
					+ "INSERT INTO "
					+ " patient "
					+ " (id, accountstatus, dateofbirth, clinic, firstnames, lastname, modified, patientid, province , sex) "
					+ " VALUES ( "
					+ ""+ id+","
					+ " \'t\',"
					+ "\'"+ syncLinhaPatients.getDatanasc()+"\',"
					+ "2,"
					+ "\'"+syncLinhaPatients.getPnomes()+"\',"
					+ "\'"+apelido+"\',"
					+ "\'T\',"
					+ "\'"+syncLinhaPatients.getNid()+"\',"
					+ "\'Select a Province\',"
					+ "\'" +sexo.trim().charAt(0)+"\')");
			
			st.executeUpdate( ""
					+ "INSERT INTO episode "
					+ "(id, "
					+ "startdate, "
					+ "startreason, "
					+ "patient, "
					+ "index, "
					+ "clinic"
					+ ") "
					+ "VALUES "
					+ "("
					+ ""+nextval_hibernate_sequence()+","
					+ "\'"+syncLinhaPatients.getDataabertura()+"\',"
					+ "\'Novo Paciente\',"
					+ ""+id+","
					+ "0,2)");
			
			st.executeUpdate(" INSERT INTO "
					+ " patientidentifier "
					+ "("
					+ "id, "
					+ "value, "
					+ "patient_id,"
					+ "type_id"
					+ ") "
					+ "VALUES "
					+ ""
					+ "("
					+ ""+nextval_hibernate_sequence()+","
					+ "\'"+syncLinhaPatients.getNid()+"\',"
					+ ""+id+", 0)");
					 
 
	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	
	}
	

}
private int nextval_hibernate_sequence(){
int id=0;
			
			 try {
					conecta(iDartProperties.hibernateUsername, iDartProperties.hibernatePassword);
				} catch (ClassNotFoundException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				} catch (SQLException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				} 
	
	ResultSet rsId=null;
	try {
		rsId = st.executeQuery("SELECT nextval(\'hibernate_sequence\') as id");
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	
	if(rsId!=null)
		try {
			while(rsId.next()) id=rsId.getInt("id");
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	
	return id;
}
}

