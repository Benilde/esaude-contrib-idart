package org.celllife.idart.database.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Vector;

import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;
import org.celllife.idart.gui.sync.dispense.SyncLinha;
import org.celllife.idart.gui.sync.patients.SyncLinhaPatients;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Shell;
 
 
/**
 * Classe responsável por gerir conexões com a base de dados do MS-Access
 * @author EdiasJambaia
 *
 */
public class ConexaoODBC {
	
    private static final String username = "Admin";
    private static final String password = "";
    private static final String DSN = "ACCESSJAVA"; // nome da fonte de dados
    private static final String driver = "sun.jdbc.odbc.JdbcOdbcDriver"; // driver usado
    private static Connection conn = null;
	private static Logger log = Logger.getLogger(ConexaoODBC.class);        
    /**
     *  retorna uma conexão com a base de dados Access.
     *  
     */
    public static Connection getConnection() throws Exception {
    	DOMConfigurator.configure("log4j.xml");
        if(conn == null) {
  
            log.info("A Estabelecer a conexao com MS ACESS.....");
            String url = "jdbc:odbc:" + DSN;
            Class.forName(driver);
            try
            {
            conn = DriverManager.getConnection(url, username, password);
 
            log.info("A conexao com MS ACESS estabelecida com sucesso");
            
            }catch(Exception e)
            {
            	
            	log.error("Não foi possivel conectar a base de dados MS ACESS.....");
            }
        }
        return conn;
    }
     
    /**
     * Fecha a conexão com o Banco de dados access
     * Chamar esse método ao sair da aplicação
     */
     public static void close() {
        if(conn != null) {
            try {
            	System.out.println("++++++ A Fechar a conexao com MS ACESS.....");
                conn.close();
                System.out.println("++++++ Conexao com MS ACESS fechada com sucesso.....");
            } catch (SQLException ex) {
            	System.out.println("++++++ Problemas ao fechar a Conexao com MS ACESS.....");
                ex.printStackTrace();
            } finally {
                conn = null;
            }
        }
    }
     


    
    
    // Insere uma dispensa em t_tarv MS ACCESS
   
    public static void insereT_tarv(Vector medicamentos, String nid, String datatarv, int qtdComp,  String regime, int dias, 
    		String tipotarv, String dataproxima, int idade, String linha) throws Exception
    {
    	try {
            // inicilizando a conexão
            Connection conn = ConexaoODBC.getConnection();
 
            Statement st = conn.createStatement();
            System.out.println("++++++ A Preparar a Insercao de dados na tabela T_TARV do MS ACESS.....");
            //insere dados  
            
            switch(medicamentos.size())
            {
            case 1: //Se tiver apenas 1 medicamento na prescricao
            	   st.executeUpdate(""
            	    	+ "insert into t_tarv"
            	     	+ "("
                  		+ "nid,"
                  		+ "datatarv,"
                  		+ "codregime,"
                  		+ "dias,"
                  		+ "tipotarv,"
                  		+ "dataproxima,"
            	   	    + "QtdComp,"
                  		+ "idade,"
                  		+ "compromido, "
                  		+ "linhaTerapeutica"
            	   		+ ") "
            	      + "values ("            	   
                + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+","+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+linha+"\')");
                  System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                  
                  break;
                  
            case 2: //Se tiver apenas 2 medicamento na prescricao
            	  st.executeUpdate(""
                  		+ "insert into t_tarv"
                  		+ "("
                  		+ "nid,"
                  		+ "datatarv,"
                  		+ "codregime,"
                  		+ "dias,"
                  		+ "tipotarv,"
                  		+ "dataproxima,"
                  		+ "QtdComp,"
                  		+ "idade,"
                  		+ "compromido,"
                  		+ "compromido1, "
                  		+ "linhaTerapeutica"
                  		+ ") "
                + "values ("
                + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+","+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+(String)medicamentos.get(1)+"\',\'"+linha+"\')");
                  System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                  
                  break;
                  
            case 3: //Se tiver apenas 3 medicamento na prescricao
            	  st.executeUpdate(""
                  		+ "insert into t_tarv"
                  		+ "("
                  		+ "nid,"
                  		+ "datatarv,"
                  		+ "codregime,"
                  		+ "dias,"
                  		+ "tipotarv,"
                  		+ "dataproxima,"
                  		+ "QtdComp,"
                  		+ "idade,"
                  		+ "compromido,"
                  		+ "compromido1,"
                  		+ "compromido2, "
                  		+ "linhaTerapeutica"
                  		+ ") "
                + "values ("
                + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+","+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+(String)medicamentos.get(1)+"\',\'"+(String)medicamentos.get(2)+"\',\'"+linha+"\')");
                  System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                  
                  break;
                  default:   
                	  st.executeUpdate(""
                    		+ "insert into t_tarv"
                      		+ "("
                      		+ "nid,"
                      		+ "datatarv,"
                      		+ "codregime,"
                      		+ "dias,"
                      		+ "tipotarv,"
                      		+ "dataproxima,"
                      		+ "QtdComp,"
                      		+ "idade,"
                      		+ "compromido,"
                      		+ "compromido1,"
                      		+ "compromido2, "
                  		+ "linhaTerapeutica"
                      		+ ") "
                    + "values ("
                    + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+",\'"+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+(String)medicamentos.get(1)+"\',\'"+(String)medicamentos.get(2)+"\',\'"+linha+"\')");
                      System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                      
                      break;
                  
            }
            	
          
            // fechando a conexão
            ConexaoODBC.close();
        }


catch (Exception e)

{
 
     
	 log.error("++++++ Houve erro na Insercao de dados na tabela T_TARV do MS ACESS.....");
	 log.error(e.toString());
 

	/*MessageBox conexaoACCESS = new MessageBox(new Shell(), SWT.ICON_ERROR
			| SWT.OK);
	conexaoACCESS.setText("Conexão com Base de Dados SESP");
	conexaoACCESS
	.setMessage("O iDART não está a se conectar com o SESP.\n Por favor verifique se os cabos da rede estão ligados no seu \ncomputador ou se o computador com SESP está ligado!\n Saia do iDART e verifique estes apectos depois volte a entrar,\n se o problema persistir, todos registos de FILAS e registo dos novos pacientes não serão actualizados no SESP!  \n Não foi possível actualizada a última operação no SESP!");
	conexaoACCESS.open();
	e.printStackTrace();*/
 
}
    	
    	
    }

	//insere t_tarv com motivo de mudanca de ARV´S
	public static void insereT_tarvMotivo(Vector medicamentos, String nid, String datatarv, int qtdComp,  String regime, int dias, 
    		String tipotarv, String dataproxima, int idade, String codmudanca, String linha) throws Exception
    {
    	try {
            // inicilizando a conexão
            Connection conn = ConexaoODBC.getConnection();
 
            Statement st = conn.createStatement();
            System.out.println("++++++ A Preparar a Insercao de dados na tabela T_TARV do MS ACESS.....");
            //insere dados  
            
            switch(medicamentos.size())
            {
            case 1: //para 1 medicamento
            	   st.executeUpdate(""
            	    	+ "insert into t_tarv"
            	     	+ "("
                  		+ "nid,"
                  		+ "datatarv,"
                  		+ "codregime,"
                  		+ "dias,"
                  		+ "tipotarv,"
                  		+ "dataproxima,"
            	   	    + "QtdComp,"
                  		+ "codmudanca, "
            	   	   	+ "idade, "
                  		+ "compromido, "
                  		+ "linhaTerapeutica"
            	   		+ ") "
            	      + "values ("            	   
                + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+",\'"+codmudanca+"\',"+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+linha+"\')");
                  System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                  
                  break;
                  
            case 2: //para 2 medicamentos
            	  st.executeUpdate(""
                  		+ "insert into t_tarv"
                  		+ "("
                  		+ "nid,"
                  		+ "datatarv,"
                  		+ "codregime,"
                  		+ "dias,"
                  		+ "tipotarv,"
                  		+ "dataproxima,"
                  		+ "QtdComp,"
                  		+ "codmudanca, "
                  		+ "idade,"
                  		+ "compromido,"
                  		+ "compromido1, "
                  		+ "linhaTerapeutica"
                  		+ ") "
                + "values ("
                + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+",\'"+codmudanca+"\',"+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+(String)medicamentos.get(1)+"\',\'"+linha+"\')");
                  System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                  
                  break;
                  
            case 3://para 3 medicamento
            	  st.executeUpdate(""
                  		+ "insert into t_tarv"
                  		+ "("
                  		+ "nid,"
                  		+ "datatarv,"
                  		+ "codregime,"
                  		+ "dias,"
                  		+ "tipotarv,"
                  		+ "dataproxima,"
                  		+ "QtdComp,"
                  		+ "codmudanca, "
                  		+ "idade,"
                  		+ "compromido,"
                  		+ "compromido1,"
                  		+ "compromido2, "
                  		+ "linhaTerapeutica"
                  		+ ") "
                + "values ("
                + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+",\'"+codmudanca+"\',"+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+(String)medicamentos.get(1)+"\',\'"+(String)medicamentos.get(2)+"\',\'"+linha+"\'))");
                  System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                  
                  break;
                  default:   //para 3 medicamento
                	  st.executeUpdate(""
                    		+ "insert into t_tarv"
                      		+ "("
                      		+ "nid,"
                      		+ "datatarv,"
                      		+ "codregime,"
                      		+ "dias,"
                      		+ "tipotarv,"
                      		+ "dataproxima,"
                      		+ "QtdComp,"
                      		+ "codmudanca, "
                      		+ "idade,"
                      		+ "compromido,"
                      		+ "compromido1,"
                      		+ "compromido2, "
                  		+ "linhaTerapeutica"
                      		+ ") "
                    + "values ("
                    + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+",\'"+codmudanca+"\',"+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+(String)medicamentos.get(1)+"\',\'"+(String)medicamentos.get(2)+"\',\'"+linha+"\'))");
                      System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                      
                      break;
                  
            }
            	
          
            // fechando a conexão
            ConexaoODBC.close();
        }


catch (Exception e)

{
	 System.out.println("++++++ Houve erro na Insercao de dados na tabela T_TARV do MS ACESS.....");
	 log.error(e.toString());
   e.printStackTrace();
   

/*	MessageBox conexaoACCESS = new MessageBox(new Shell(), SWT.ICON_ERROR
			| SWT.OK);
	conexaoACCESS.setText("Conexão com Base de Dados SESP");
	conexaoACCESS
	.setMessage("O iDART não está a se conectar com o SESP.\n Por favor verifique se os cabos da rede estão ligados no seu \ncomputador ou se o computador com SESP está ligado!\n Saia do iDART e verifique estes apectos depois volte a entrar,\n se o problema persistir, todos registos de FILAS e registo dos novos pacientes não serão actualizados no SESP!  \n Não foi possível actualizada a última operação no SESP!");
	conexaoACCESS.open();
	e.printStackTrace();*/
 
}
    	
    	
    }

	//insere ttarv transferido de 
	public void insereT_tarvTransferidoDE(Vector medicamentos, String nid, String datatarv, int qtdComp,  String regime, int dias, 
    		String tipotarv, String dataproxima, int idade, String dataoutroservico, String linha) {

		try {
            // inicilizando a conexão
            Connection conn = ConexaoODBC.getConnection();
 
            Statement st = conn.createStatement();
            System.out.println("++++++ A Preparar a Insercao de dados na tabela T_TARV do MS ACESS.....");
            //insere dados  
            
            switch(medicamentos.size())
            {
            case 1:
            	   st.executeUpdate(""
            	    	+ "insert into t_tarv"
            	     	+ "("
                  		+ "nid,"
                  		+ "datatarv,"
                  		+ "codregime,"
                  		+ "dias,"
                  		+ "tipotarv,"
                  		+ "dataproxima,"
            	   	    + "QtdComp,"
                  		+ "dataoutroservico, "
            	   	   	+ "idade,"
                  		+ "compromido, "
                  		+ "linhaTerapeutica"
            	   		+ ") "
            	      + "values ("            	   
                + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+",\'"+dataoutroservico+"\',"+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+linha+"\')");
                  System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                  
                  break;
                  
            case 2: 
            	  st.executeUpdate(""
                  		+ "insert into t_tarv"
                  		+ "("
                  		+ "nid,"
                  		+ "datatarv,"
                  		+ "codregime,"
                  		+ "dias,"
                  		+ "tipotarv,"
                  		+ "dataoutroservico,"
                  		+ "QtdComp,"
                  		+ "codmudanca, "
                  		+ "idade,"
                  		+ "compromido,"
                  		+ "compromido1, "
                  		+ "linhaTerapeutica"
                  		+ ") "
                + "values ("
                + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+",\'"+dataoutroservico+"\',"+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+(String)medicamentos.get(1)+"\',\'"+linha+"\')");
                  System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                  
                  break;
                  
            case 3:
            	  st.executeUpdate(""
                  		+ "insert into t_tarv"
                  		+ "("
                  		+ "nid,"
                  		+ "datatarv,"
                  		+ "codregime,"
                  		+ "dias,"
                  		+ "tipotarv,"
                  		+ "dataproxima,"
                  		+ "QtdComp,"
                  		+ "dataoutroservico, "
                  		+ "idade,"
                  		+ "compromido,"
                  		+ "compromido1,"
                  		+ "compromido2, "
                  		+ "linhaTerapeutica"
                  		+ ") "
                + "values ("
                + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+",\'"+dataoutroservico+"\',"+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+(String)medicamentos.get(1)+"\',\'"+(String)medicamentos.get(2)+"\',\'"+linha+"\')");
                  System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                  
                  break;
                  default:   
                	  st.executeUpdate(""
                    		+ "insert into t_tarv"
                      		+ "("
                      		+ "nid,"
                      		+ "datatarv,"
                      		+ "codregime,"
                      		+ "dias,"
                      		+ "tipotarv,"
                      		+ "dataproxima,"
                      		+ "QtdComp,"
                      		+ "dataoutroservico, "
                      		+ "idade,"
                      		+ "compromido,"
                      		+ "compromido1,"
                      		+ "compromido2, "
                  		+ "linhaTerapeutica"
                      		+ ") "
                    + "values ("
                    + "\'"+nid+"\',\'"+datatarv+"\',\'"+regime+"\',"+dias+",\'"+tipotarv+"\',\'"+dataproxima+"\',"+qtdComp+",\'"+dataoutroservico+"\',"+idade+",\'"+(String)medicamentos.get(0)+"\',\'"+(String)medicamentos.get(1)+"\',\'"+(String)medicamentos.get(2)+"\',\'"+linha+"\')");
                      System.out.println("++++++ Os Dado inseridos com sucesso na tabela T_TARV.....");
                      
                      break;
                  
            }
            	
          
            // fechando a conexão
            ConexaoODBC.close();
        }


catch (Exception e)

{
	 System.out.println("++++++ Houve erro na Insercao de dados na tabela T_TARV do MS ACESS.....");
	 log.error(e.toString());
   e.printStackTrace();

/*	MessageBox conexaoACCESS = new MessageBox(new Shell(), SWT.ICON_ERROR
			| SWT.OK);
	conexaoACCESS.setText("Conexão com Base de Dados SESP");
	conexaoACCESS
	.setMessage("O iDART não está a se conectar com o SESP.\n Por favor verifique se os cabos da rede estão ligados no seu \ncomputador ou se o computador com SESP está ligado!\n Saia do iDART e verifique estes apectos depois volte a entrar,\n se o problema persistir, todos registos de FILAS e registo dos novos pacientes não serão actualizados no SESP!  \n Não foi possível actualizada a última operação no SESP!");
	conexaoACCESS.open();
	e.printStackTrace();*/
 
}
	}


	
	public static void selectAcess( String nid){
		

		
		String sqlQueryPaciente = "SELECT " 
	            + "sexo, " 
	            + "datanasc, " 
	            + "nome, " 
	            + "apelido, " 
	            + "avenida "
	        
	 + "FROM  t_paciente where nid=\'"+nid+"\'";
	    
	   

		
		ResultSet rs = null;
		try {
			Connection conn = ConexaoODBC.getConnection();
			 
		    Statement st=conn.createStatement();
			rs = st.executeQuery(sqlQueryPaciente);
			
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		if (rs != null)
	    {
	       
	        try {
				while (rs.next())
				{
	  
	System.out.println("Nome: "+ rs.getString("nome")+ " Sexo: "+rs.getString("sexo"));
	      
				}
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
	        try {
				rs.close();
			} catch (SQLException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
				 log.error(e.toString());
			} // é necessário fechar o resultado ao terminar
	    }
	}
	
public static void main(String [] ars)


{
	
	
	System.out.println("hdd "+codigoUS());
	
	selectAcess( "11050801/14/1062");
	 
	//inserePaciente("77454545455898500000","Nome O", "Apelido 0", new Date(), new Date(), 'M', new Date());

}

public int pacientesActivosEmTarv(){
	
	int pacientes=0;
	
	String query="  SELECT distinct nid FROM t_tarv "
			+ " WHERE DATEDIFF(\'d\', dataproxima, #"+ new SimpleDateFormat("yyyy-MM-dd").format(new Date()) +"#) <=60 ";

	
	
	ResultSet rs = null;
	try {
		 conn = ConexaoODBC.getConnection();
		 
	    Statement st=conn.createStatement();
		rs = st.executeQuery(query);
		
	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	
	if (rs != null)
    {
       
        try {
			while (rs.next())
			{
  System.out.println(rs.getString("nid"));
pacientes+=1;
      
			}
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        try {
			rs.close();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} // é necessário fechar o resultado ao terminar
    }
	
	
	return pacientes;
	
	
}

//consulta se existe um dado nid
public boolean existNid( String nid) {
	
boolean existe=false;
int i=0;
	
	String sqlQueryPaciente = "SELECT * " 
          
 + " FROM  t_paciente where nid=\'"+nid+"\'";
    
   

	
	ResultSet rs = null;
	try {
		conn = ConexaoODBC.getConnection();
		 
	    Statement st=conn.createStatement();
		rs = st.executeQuery(sqlQueryPaciente);
		
	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	
	if (rs!=null)
	{
		
	
		try {
			while(rs.next()){
				
				i++;

			}
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();	 log.error(e.toString());
		}
		
		
	}
		if(i>0) existe=true;

return existe;
}

public void inserePaciente(String nid, String nome, String apelido, Date dataabertura, Date datanasc, char sexo, Date datainiciotarv, String telefone)

{
	
	System.out.println(new SimpleDateFormat("yyyy-MM-dd").format(dataabertura));
	boolean sucesso=false;





 try {
	 
	 if(telefone.trim().length()>6) insereCelular(nid, telefone.trim());
	 // inicilizando a conexão
     conn = ConexaoODBC.getConnection();

     Statement st = conn.createStatement();
     
log.info(" A Preparar a Insercao de dados na tabela T_PACIENTE do MS ACESS.....");
	
	st.executeUpdate("INSERT INTO t_paciente "
			+ " (nid,hdd,nome,apelido, sexo,dataabertura,datainiciotarv,datanasc) "
			+ " VALUES "
			+ " (\'"
			+nid
			+ "\',\'"
			+ codigoUS()
			+ "\',\'"
			+ nome
			+ "\',\'"
			+ apelido
			+"\',\'"
			+ sexo
			+ "\',\'"
			+ new SimpleDateFormat("yyyy-MM-dd").format(dataabertura)
			+ "\',\'"
			+ new SimpleDateFormat("yyyy-MM-dd").format(datainiciotarv)
			+ "\',\'"
			+ new SimpleDateFormat("yyyy-MM-dd").format(datanasc)
			+ "\')");
st.executeQuery("INSERT INTO t_paciente "
		+ " (nid,hdd,nome,apelido, sexo,dataabertura,datainiciotarv,datanasc) "
		+ " VALUES "
		+ " (\'"
		+nid
		+ "\',\'"
		+ codigoUS()
		+ "\',\'"
		+ nome
		+ "\',\'"
		+ apelido
		+"\',\'"
		+ sexo
		+ "\',\'"
		+ new SimpleDateFormat("yyyy-MM-dd").format(dataabertura)
		+ "\',\'"
		+ new SimpleDateFormat("yyyy-MM-dd").format(datainiciotarv)
		+ "\',\'"
		+ new SimpleDateFormat("yyyy-MM-dd").format(datanasc)
		+ "\')");



} catch (Exception e) {
	// TODO Auto-generated catch block
	e.printStackTrace();
	 log.error(e.toString());
	/*MessageBox conexaoACCESS = new MessageBox(new Shell(), SWT.ICON_ERROR
			| SWT.OK);
	conexaoACCESS.setText("Conexão com Base de Dados SESP");
	conexaoACCESS
	.setMessage("O iDART não está a se conectar com o SESP.\n Por favor verifique se os cabos da rede estão ligados no seu \ncomputador ou se o computador com SESP está ligado!\n Saia do iDART e verifique estes apectos depois volte a entrar,\n se o problema persistir, todos registos de FILAS e registo dos novos pacientes não serão actualizados no SESP!  \n Não foi possível actualizada a última operação no SESP!");
	conexaoACCESS.open();
	e.printStackTrace();*/
}
 



}
//Devolve o codig

private static  String codigoUS()

{
	String codigoUS="";
	ResultSet rs=null;
	
	String q=" SELECT hdd from t_paciente";


	
	try {
		conn = ConexaoODBC.getConnection();
		Statement st = conn.createStatement();
		rs=st.executeQuery(q);


	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	
	if(rs!=null)
	{
		try {
			while(rs.next())
			{
				codigoUS=rs.getString("hdd");
			
			
			}
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	return codigoUS;


}

public ResultSet result_for_sync_dispense(){
	
	ResultSet rs=null;
	try {
		conn = ConexaoODBC.getConnection();
		Statement st = conn.createStatement();
		rs=st.executeQuery(" SELECT"
				+ " NID,"
				+ " MAX(datatarv) as ultimo_lev"
				+ " FROM"
				+ " t_tarv"
				+ "  GROUP BY nid"
				+ "");


	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	return rs;
}

//insere levantamentos - Syncronizacao
public void syncdata_dispense(SyncLinha syncLinha) {
	// TODO Auto-generated method stub
	



	 try {
		 // inicilizando a conexão
	     conn = ConexaoODBC.getConnection();

	     Statement st = conn.createStatement();
	     
	     if(!pesquisaRegime(syncLinha.getRegime()))
	     {
	    	 st.executeUpdate(" "
	    	 		+ "INSERT INTO "
	    	 		+ " t_regimeterapeutico "
	    	 		+ "("
	    	 		+ "codregime, "
	    	 		+ "idregime, "
	    	 		+ "linha, "
	    	 		+ "activo "
	    	 		+ ") "
	    	 		+ " VALUES "
	    	 		+ " ("
	    	 		+ "\'"+syncLinha.getRegime()+"\',"
	    	 				+ "\'"+syncLinha.getRegime()+"\',"
	    	 				+ "\'"+syncLinha.getLinha().charAt(0)+""+syncLinha.getLinha().charAt(1)+"\',true)");
	     }
	     
		
	     
	     
		
		st.executeUpdate(
				"INSERT INTO t_tarv ("
				+ "nid, "
				+ "datatarv, "
				+ "codregime, "
				+ "tipotarv,"
				+ " dataproxima, "
				+ "linhaTerapeutica"
				+ ") "
				+ "VALUES "
				+ "( "
				+ "\'"+ syncLinha.getNid()+ "\',"
						+ "\'"+syncLinha.getUltimo_lev() +"\',"
						+ "\'"+ syncLinha.getRegime()+"\',"
						+ "\'"+ syncLinha.getTipo_tarv()+"\',"
								+ " \'"+syncLinha.getDataproxima()+"\',"
						+ "\'"+syncLinha.getLinha() +"\'"
						 
						+ ")");


	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	
	}
	
}

//pesquisa regime
private boolean pesquisaRegime(String regime){
	boolean existe=false;
	
	int i=0;
	ResultSet rs=null;
	try {
		conn = ConexaoODBC.getConnection();
		Statement st = conn.createStatement();
		rs=st.executeQuery(" SELECT"
				+ "  * FROM t_regimeterapeutico"
				+ " WHERE codregime=\'"+regime
				+ "\'"
				+ "");


	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	try {
		while (rs.next()) i++;
	} catch (SQLException e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	if(i>0) existe=true;
	return existe;
}



public ResultSet result_for_sync_patients() {


	ResultSet rs=null;
	try {
		conn = ConexaoODBC.getConnection();
		Statement st = conn.createStatement();
		rs=st.executeQuery(" SELECT"
				+ " nid, "
				+ " nome,"
				+ " apelido, "
				+ " dataabertura,"
				+ "sexo, datanasc "
				+ " "
				+ " FROM"
				+ " t_paciente "
			
				+ "");


	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	return rs;
	
}
//Insere o nr de celulaar em t_adulto
private void insereCelular (String nid, String celular){
	
	 try {
		 // inicilizando a conexão
	     conn = ConexaoODBC.getConnection();

	     Statement st = conn.createStatement();
	     
 
	    
	    	 st.executeUpdate(" "
	    	 		+ "INSERT INTO "
	    	 		+ " t_adulto (nid, telefone) VALUES   "
	    	 		+ "(\'"
	    	 		+ nid +"\', \'"
	    	 		+ celular +"\'"
	    	 		+ ") "
	    	 	 
	    	 		+ " ");
	     
		
	     
	     
 

	} catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	
	}
}
}