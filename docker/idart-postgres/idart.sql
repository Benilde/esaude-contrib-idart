--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.2
-- Dumped by pg_dump version 9.5.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: add_sched_visit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION add_sched_visit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
scriptid INT;
patid INT;
pvid INT;
latestdate timestamp;
mycount INT;
BEGIN
scriptid:=NEW.prescription;
patid:=(SELECT patient FROM prescription WHERE id=scriptid);
pvid:=(SELECT id FROM patientvisitreason WHERE reasonforvisit='Scheduled Visit');
mycount:=(SELECT Count(*) FROM patientvisit WHERE patient_id=patid and patientvisitreason_id=pvid);
latestdate:=(SELECT dateofvisit FROM patientvisit WHERE patient_id=patid and patientvisitreason_id=pvid ORDER BY dateofvisit DESC LIMIT 1);
IF (latestdate < (now()-interval '24 hours')) THEN
INSERT INTO patientvisit(id, patient_id, dateofvisit, isscheduled, patientvisitreason_id, diagnosis, notes)
    VALUES (nextval('hibernate_sequence'), patid, NEW.datereceived, 'Y', pvid, '', 'Scheduled Visit to Receive Package');
END IF;
IF (mycount=0) THEN
INSERT INTO patientvisit(id, patient_id, dateofvisit, isscheduled, patientvisitreason_id, diagnosis, notes)
    VALUES (nextval('hibernate_sequence'), patid, NEW.datereceived, 'Y', pvid, '', 'Scheduled Visit to Receive Package');
END IF;

RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_sched_visit() OWNER TO postgres;

--
-- Name: del_sched_visit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION del_sched_visit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
firstdash INT;
seconddash INT;
patstring VARCHAR(30);
patid INT;
pvid INT;
visitdate timestamp;
mycount INT;
delid INT;
BEGIN
firstdash:=position('-' in OLD.packageid);
IF (firstdash>0) THEN
patstring:=substring(OLD.packageid from firstdash+1);
seconddash:=position('-' in patstring);
patstring:=substring(patstring from 1 for seconddash-1);
patid:=(SELECT id FROM patient WHERE patientid=patstring);
pvid:=(SELECT id FROM patientvisitreason WHERE reasonforvisit='Scheduled Visit');
visitdate:=(SELECT dateofvisit FROM patientvisit where patient_id =patid and patientvisitreason_id=pvid order by dateofvisit desc LIMIT 1);
delid:=(SELECT id FROM patientvisit where patient_id =patid and patientvisitreason_id=pvid order by dateofvisit desc LIMIT 1);
IF ((date_part('month',visitdate)=date_part('month',OLD.datereceived)) AND (date_part('year',visitdate)=date_part('year',OLD.datereceived)) AND (date_part('day',visitdate)=date_part('day',OLD.datereceived))) THEN
DELETE FROM patientvisit where id=delid;
END IF;
END IF;
RETURN OLD;
END;
$$;


ALTER FUNCTION public.del_sched_visit() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: drug; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE drug (
    id integer NOT NULL,
    form integer NOT NULL,
    dispensinginstructions1 character varying(255),
    dispensinginstructions2 character varying(255),
    modified character(1),
    name character varying(255),
    packsize integer,
    sidetreatment character(1),
    defaultamnt double precision,
    defaulttimes integer,
    stockcode character varying(50),
    atccode_id integer,
    pediatric character(1)
);


ALTER TABLE drug OWNER TO postgres;

--
-- Name: packagedruginfotmp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE packagedruginfotmp (
    id integer NOT NULL,
    amountpertime character varying(255),
    batchnumber character varying(255),
    clinic character varying(255),
    dispensedate timestamp with time zone,
    dispensedqty integer,
    drugname character varying(255),
    expirydate timestamp with time zone,
    formlanguage1 character varying(255),
    formlanguage2 character varying(255),
    formlanguage3 character varying(255),
    notes character varying(255),
    packageindex integer,
    patientid character varying(255),
    patientfirstname character varying(255),
    specialinstructions1 character varying(255),
    specialinstructions2 character varying(255),
    stockid integer,
    timesperday integer,
    cluser integer NOT NULL,
    weekssupply integer,
    sidetreatment boolean,
    packageddrug integer NOT NULL,
    invalid boolean,
    qtyinhand character varying(255),
    summaryqtyinhand character varying(255),
    qtyinlastbatch character varying(255),
    patientlastname character varying(255),
    prescriptionduration integer,
    dateexpectedstring character varying(255),
    senttoekapa boolean,
    packageid character varying(255),
    firstbatchinprintjob boolean DEFAULT false,
    numberoflabels integer DEFAULT 0,
    dispensedforlaterpickup boolean DEFAULT false,
    pickupdate timestamp with time zone
);


ALTER TABLE packagedruginfotmp OWNER TO postgres;

--
-- Name: QTY_FRASCOS_DISP_MES_ULT_3MESES; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW "QTY_FRASCOS_DISP_MES_ULT_3MESES" AS
 SELECT packagedruginfotmp.drugname,
    date_part('MONTH'::text, packagedruginfotmp.dispensedate) AS mes,
    sum((packagedruginfotmp.dispensedqty / drug.packsize)) AS total
   FROM (packagedruginfotmp
     JOIN drug ON (((packagedruginfotmp.drugname)::text = (drug.name)::text)))
  WHERE ((packagedruginfotmp.dispensedate >= ((now())::date - 90)) AND (packagedruginfotmp.dispensedate <= now()))
  GROUP BY packagedruginfotmp.drugname, (date_part('MONTH'::text, packagedruginfotmp.dispensedate));


ALTER TABLE "QTY_FRASCOS_DISP_MES_ULT_3MESES" OWNER TO postgres;

--
-- Name: AMC; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW "AMC" AS
 SELECT "QTY_FRASCOS_DISP_MES_ULT_3MESES".drugname,
    max("QTY_FRASCOS_DISP_MES_ULT_3MESES".total) AS consumo_max_ult_3meses
   FROM "QTY_FRASCOS_DISP_MES_ULT_3MESES"
  GROUP BY "QTY_FRASCOS_DISP_MES_ULT_3MESES".drugname;


ALTER TABLE "AMC" OWNER TO postgres;

--
-- Name: accumulateddrugs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE accumulateddrugs (
    id integer NOT NULL,
    withpackage integer NOT NULL,
    pillcount integer NOT NULL
);


ALTER TABLE accumulateddrugs OWNER TO postgres;

--
-- Name: adherencerecordtmp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE adherencerecordtmp (
    id integer NOT NULL,
    adherencereason character varying(255),
    countdate timestamp with time zone,
    dayscarriedover integer,
    daysinhand integer,
    dayssincevisit integer,
    dayssupplied integer,
    pawcno character varying(255),
    pillcountid integer,
    cluser character varying(255)
);


ALTER TABLE adherencerecordtmp OWNER TO postgres;

--
-- Name: alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE alerts (
    id integer NOT NULL,
    alertmessage character varying(255) NOT NULL,
    alerttype character varying(255) NOT NULL,
    alertdate timestamp with time zone NOT NULL,
    void boolean
);


ALTER TABLE alerts OWNER TO postgres;

--
-- Name: stock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE stock (
    id integer NOT NULL,
    drug integer NOT NULL,
    batchnumber character varying(255),
    datereceived timestamp with time zone,
    stockcenter integer NOT NULL,
    expirydate timestamp with time zone,
    modified character(1),
    shelfnumber character varying(255),
    unitsreceived integer,
    manufacturer character varying(255),
    hasunitsremaining character(1),
    unitprice numeric(12,2)
);


ALTER TABLE stock OWNER TO postgres;

--
-- Name: stocklevel; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE stocklevel (
    id integer NOT NULL,
    batch integer NOT NULL,
    fullcontainersremaining integer,
    loosepillsremaining integer
);


ALTER TABLE stocklevel OWNER TO postgres;

--
-- Name: recebidos_saldos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW recebidos_saldos AS
 SELECT drug.name,
    sum(stock.unitsreceived) AS recebidos,
    sum(stocklevel.fullcontainersremaining) AS saldos
   FROM ((stocklevel
     JOIN stock ON ((stocklevel.batch = stock.id)))
     JOIN drug ON ((stock.drug = drug.id)))
  WHERE (stock.datereceived >= ((now())::date - 90))
  GROUP BY drug.name;


ALTER TABLE recebidos_saldos OWNER TO postgres;

--
-- Name: alimenta_risco_roptura; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW alimenta_risco_roptura AS
 SELECT "AMC".drugname,
    "AMC".consumo_max_ult_3meses,
    recebidos_saldos.saldos
   FROM "AMC",
    recebidos_saldos
  WHERE (("AMC".drugname)::text = (recebidos_saldos.name)::text);


ALTER TABLE alimenta_risco_roptura OWNER TO postgres;

--
-- Name: alternatepatientidentifier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE alternatepatientidentifier (
    id integer NOT NULL,
    identifier character varying(255),
    patient integer,
    datechanged timestamp with time zone,
    masterpatientid boolean,
    type_id integer NOT NULL
);


ALTER TABLE alternatepatientidentifier OWNER TO postgres;

--
-- Name: appointment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE appointment (
    id integer NOT NULL,
    appointmentdate timestamp with time zone,
    patient integer,
    visitdate timestamp with time zone
);


ALTER TABLE appointment OWNER TO postgres;

--
-- Name: atccode; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE atccode (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    mims character varying(255)
);


ALTER TABLE atccode OWNER TO postgres;

--
-- Name: atccode_chemicalcompound; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE atccode_chemicalcompound (
    atccode_id integer NOT NULL,
    chemicalcompound_id integer NOT NULL
);


ALTER TABLE atccode_chemicalcompound OWNER TO postgres;

--
-- Name: attributetype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE attributetype (
    id integer NOT NULL,
    datatype character varying(255),
    description character varying(255),
    name character varying(255)
);


ALTER TABLE attributetype OWNER TO postgres;

--
-- Name: campaign; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE campaign (
    id integer NOT NULL,
    description character varying(255),
    duration integer,
    name character varying(35) DEFAULT ''::character varying NOT NULL,
    startdate timestamp with time zone,
    status character varying(20) DEFAULT ''::character varying NOT NULL,
    timesperday integer,
    type character varying(20) DEFAULT ''::character varying NOT NULL,
    version bigint NOT NULL,
    mobilisrid bigint
);


ALTER TABLE campaign OWNER TO postgres;

--
-- Name: campaign_participant; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE campaign_participant (
    campaign_id integer NOT NULL,
    patient_id integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE campaign_participant OWNER TO postgres;

--
-- Name: chemicalcompound; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE chemicalcompound (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    acronym character varying(255)
);


ALTER TABLE chemicalcompound OWNER TO postgres;

--
-- Name: chemicaldrugstrength; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE chemicaldrugstrength (
    id integer NOT NULL,
    chemicalcompound integer NOT NULL,
    strength integer,
    drug integer NOT NULL
);


ALTER TABLE chemicaldrugstrength OWNER TO postgres;

--
-- Name: clinic; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE clinic (
    id integer NOT NULL,
    notes character varying(255),
    telephone character varying(255),
    mainclinic boolean,
    clinicname character varying(255),
    clinicdetails_id integer
);


ALTER TABLE clinic OWNER TO postgres;

--
-- Name: clinicuser; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE clinicuser (
    clinicid integer NOT NULL,
    userid integer NOT NULL
);


ALTER TABLE clinicuser OWNER TO postgres;

--
-- Name: databasechangelog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE databasechangelog (
    id character varying(63) NOT NULL,
    author character varying(63) NOT NULL,
    filename character varying(200) NOT NULL,
    dateexecuted timestamp with time zone NOT NULL,
    orderexecuted integer NOT NULL,
    exectype character varying(10) NOT NULL,
    md5sum character varying(35),
    description character varying(255),
    comments character varying(255),
    tag character varying(255),
    liquibase character varying(20)
);


ALTER TABLE databasechangelog OWNER TO postgres;

--
-- Name: databasechangeloglock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE databasechangeloglock (
    id integer NOT NULL,
    locked boolean NOT NULL,
    lockgranted timestamp with time zone,
    lockedby character varying(255)
);


ALTER TABLE databasechangeloglock OWNER TO postgres;

--
-- Name: deleteditem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE deleteditem (
    id integer NOT NULL,
    deleteditemid integer,
    itemtype character varying(255)
);


ALTER TABLE deleteditem OWNER TO postgres;

--
-- Name: doctor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE doctor (
    id integer NOT NULL,
    emailaddress character varying(255),
    firstname character varying(255),
    lastname character varying(255),
    mobileno character varying(255),
    modified character(1),
    telephoneno character varying(255),
    active boolean,
    category integer
);


ALTER TABLE doctor OWNER TO postgres;

--
-- Name: doctorcategory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE doctorcategory (
    id integer NOT NULL,
    categoria character varying(255)
);


ALTER TABLE doctorcategory OWNER TO postgres;

--
-- Name: episode; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE episode (
    id integer NOT NULL,
    startdate timestamp with time zone NOT NULL,
    stopdate timestamp with time zone,
    startreason character varying(255),
    stopreason character varying(255),
    startnotes character varying(255),
    stopnotes character varying(255),
    patient integer,
    index integer,
    clinic integer NOT NULL
);


ALTER TABLE episode OWNER TO postgres;

--
-- Name: form; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE form (
    id integer NOT NULL,
    form character varying(255),
    actionlanguage1 character varying(255),
    actionlanguage2 character varying(255),
    actionlanguage3 character varying(255),
    formlanguage1 character varying(255),
    formlanguage2 character varying(255),
    formlanguage3 character varying(255),
    dispinstructions1 character varying(255),
    dispinstructions2 character varying(255)
);


ALTER TABLE form OWNER TO postgres;

--
-- Name: hibernate_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE hibernate_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hibernate_sequence OWNER TO postgres;

--
-- Name: identifiertype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE identifiertype (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    index integer,
    voided boolean DEFAULT false NOT NULL
);


ALTER TABLE identifiertype OWNER TO postgres;

--
-- Name: linhat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE linhat (
    linhaid integer DEFAULT nextval('hibernate_sequence'::regclass) NOT NULL,
    linhanome character varying(255) NOT NULL,
    active boolean NOT NULL
);


ALTER TABLE linhat OWNER TO postgres;

--
-- Name: logging; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE logging (
    id integer NOT NULL,
    itemid character varying(255),
    modified character(1),
    transactiondate timestamp with time zone,
    transactiontype character varying(255),
    idart_user integer NOT NULL,
    message text
);


ALTER TABLE logging OWNER TO postgres;

--
-- Name: messageschedule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE messageschedule (
    id integer NOT NULL,
    description character varying(255),
    messagetype character varying(255) NOT NULL,
    scheduledate timestamp with time zone NOT NULL,
    daystoschedule integer,
    scheduledsuccessfully boolean DEFAULT true,
    senttoalerts boolean DEFAULT false,
    messagenumber integer,
    language character varying(50)
);


ALTER TABLE messageschedule OWNER TO postgres;

--
-- Name: motivomudanca; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE motivomudanca (
    idmotivo integer NOT NULL,
    motivo character varying(255),
    active boolean
);


ALTER TABLE motivomudanca OWNER TO postgres;

--
-- Name: nationalclinics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE nationalclinics (
    id integer NOT NULL,
    province character varying(255) NOT NULL,
    district character varying(255) NOT NULL,
    subdistrict character varying(255) NOT NULL,
    facilityname character varying(255) NOT NULL,
    facilitytype character varying(255) NOT NULL
);


ALTER TABLE nationalclinics OWNER TO postgres;

--
-- Name: patient; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE patient (
    id integer NOT NULL,
    accountstatus boolean,
    cellphone character varying(255),
    dateofbirth timestamp with time zone,
    clinic integer NOT NULL,
    firstnames character varying(255),
    homephone character varying(255),
    lastname character varying(255),
    modified character(1),
    patientid character varying(255) NOT NULL,
    province character varying(255),
    sex character(1),
    workphone character varying(255),
    address1 character varying(255),
    address2 character varying(255),
    address3 character varying(255),
    nextofkinname character varying(255),
    nextofkinphone character varying(255),
    race character varying(255)
);


ALTER TABLE patient OWNER TO postgres;

--
-- Name: paciente; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW paciente AS
 SELECT patient.patientid,
    patient.firstnames,
    patient.lastname,
    patient.dateofbirth,
    patient.sex
   FROM patient;


ALTER TABLE paciente OWNER TO postgres;

--
-- Name: package; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE package (
    id integer NOT NULL,
    dateleft timestamp with time zone,
    datereceived timestamp with time zone,
    modified character(1),
    packageid character varying(255),
    packdate timestamp with time zone,
    pickupdate timestamp with time zone,
    prescription integer,
    weekssupply integer,
    datereturned timestamp with time zone,
    stockreturned boolean,
    packagereturned boolean,
    reasonforpackagereturn character varying(255),
    clinic integer,
    drugtypes character varying(20)
);


ALTER TABLE package OWNER TO postgres;

--
-- Name: packageddrugs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE packageddrugs (
    id integer NOT NULL,
    amount integer,
    stock integer NOT NULL,
    parentpackage integer NOT NULL,
    modified character(1),
    packageddrugsindex integer
);


ALTER TABLE packageddrugs OWNER TO postgres;

--
-- Name: patientattribute; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE patientattribute (
    id integer NOT NULL,
    value character varying(255),
    patient integer,
    type_id integer
);


ALTER TABLE patientattribute OWNER TO postgres;

--
-- Name: patientidentifier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE patientidentifier (
    id integer NOT NULL,
    value character varying(255) NOT NULL,
    patient_id integer NOT NULL,
    type_id integer NOT NULL
);


ALTER TABLE patientidentifier OWNER TO postgres;

--
-- Name: patientstatistic; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE patientstatistic (
    id integer NOT NULL,
    entry_id integer,
    patient_id integer,
    datetested date,
    daterecorded date,
    patientstattype_id integer,
    statnumeric double precision,
    stattext character varying(255),
    statdate date
);


ALTER TABLE patientstatistic OWNER TO postgres;

--
-- Name: patientstattypes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE patientstattypes (
    id integer NOT NULL,
    statname character varying(30),
    statformat character varying(1)
);


ALTER TABLE patientstattypes OWNER TO postgres;

--
-- Name: patientvisit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE patientvisit (
    id integer NOT NULL,
    patient_id integer,
    dateofvisit date,
    isscheduled character varying(1),
    patientvisitreason_id integer,
    diagnosis character varying(255),
    notes character varying(255)
);


ALTER TABLE patientvisit OWNER TO postgres;

--
-- Name: patientvisitreason; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE patientvisitreason (
    id integer NOT NULL,
    reasonforvisit character varying(50)
);


ALTER TABLE patientvisitreason OWNER TO postgres;

--
-- Name: pillcount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE pillcount (
    id integer NOT NULL,
    accum integer NOT NULL,
    previouspackage integer NOT NULL,
    dateofcount timestamp with time zone NOT NULL,
    drug integer NOT NULL
);


ALTER TABLE pillcount OWNER TO postgres;

--
-- Name: pregnancy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE pregnancy (
    id integer NOT NULL,
    confirmdate timestamp with time zone,
    enddate timestamp with time zone,
    patient integer NOT NULL,
    modified character(1)
);


ALTER TABLE pregnancy OWNER TO postgres;

--
-- Name: prescribeddrugs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE prescribeddrugs (
    id integer NOT NULL,
    amtpertime double precision,
    drug integer,
    prescription integer,
    timesperday integer,
    modified character(1),
    prescribeddrugsindex integer
);


ALTER TABLE prescribeddrugs OWNER TO postgres;

--
-- Name: prescription; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE prescription (
    id integer NOT NULL,
    clinicalstage integer,
    current character(1),
    date timestamp with time zone,
    doctor integer,
    duration integer,
    modified character(1),
    patient integer NOT NULL,
    prescriptionid character varying(255),
    weight double precision,
    reasonforupdate character varying(255),
    notes character varying(255),
    enddate timestamp with time zone,
    drugtypes character varying(20),
    regimeid integer,
    datainicionoutroservico timestamp(6) with time zone,
    motivomudanca character varying(32),
    linhaid integer,
    ppe character(1),
    ptv character(1),
    tb character(1),
    tpi character(1),
    tpc character(1)
);


ALTER TABLE prescription OWNER TO postgres;

--
-- Name: prescriptiotopatient; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW prescriptiotopatient AS
 SELECT prescription.id,
    prescription.current,
    prescription.duration,
    prescription.reasonforupdate,
    prescription.notes,
    patient.patientid
   FROM prescription,
    patient
  WHERE ((prescription.current = 'T'::bpchar) AND (patient.id = prescription.patient));


ALTER TABLE prescriptiotopatient OWNER TO postgres;

--
-- Name: regimen; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE regimen (
    id integer NOT NULL,
    modified character(1),
    notes character varying(255),
    regimenname character varying(255),
    druggroup character varying(255)
);


ALTER TABLE regimen OWNER TO postgres;

--
-- Name: regimendrugs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE regimendrugs (
    id integer NOT NULL,
    amtpertime double precision,
    drug integer,
    modified character(1),
    regimen integer,
    timesperday integer,
    notes character varying(255),
    regimendrugsindex integer
);


ALTER TABLE regimendrugs OWNER TO postgres;

--
-- Name: regimeterapeutico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE regimeterapeutico (
    regimeid integer DEFAULT nextval('hibernate_sequence'::regclass) NOT NULL,
    regimeesquema character varying(30) NOT NULL,
    active boolean,
    pediatrico character varying(1),
    regimenomeespecificado character varying(60)
);


ALTER TABLE regimeterapeutico OWNER TO postgres;

--
-- Name: regimespacientes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW regimespacientes AS
 SELECT DISTINCT regimeterapeutico.regimeesquema,
    regimeterapeutico.regimeid,
    packagedruginfotmp.patientid,
    (packagedruginfotmp.dispensedate)::date AS pickupdate
   FROM regimeterapeutico,
    drug,
    prescription,
    packagedruginfotmp,
    package
  WHERE ((regimeterapeutico.active = true) AND (prescription.regimeid = regimeterapeutico.regimeid) AND (prescription.id = package.prescription) AND ((packagedruginfotmp.packageid)::text = (package.packageid)::text) AND (packagedruginfotmp.pickupdate IS NOT NULL))
  GROUP BY regimeterapeutico.regimeesquema, regimeterapeutico.regimeid, packagedruginfotmp.packageid, packagedruginfotmp.patientid, packagedruginfotmp.dispensedate;


ALTER TABLE regimespacientes OWNER TO postgres;

--
-- Name: registadosnoidart; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE registadosnoidart (
    nid character varying(50),
    nomes character varying(100),
    apelido character varying(50),
    dataderegisto date
);


ALTER TABLE registadosnoidart OWNER TO postgres;

--
-- Name: simpledomain; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE simpledomain (
    id integer NOT NULL,
    description character varying(255),
    name character varying(255),
    value character varying(255)
);


ALTER TABLE simpledomain OWNER TO postgres;

--
-- Name: stockadjustment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE stockadjustment (
    id integer NOT NULL,
    capturedate timestamp with time zone,
    stock integer NOT NULL,
    notes character varying(255),
    stocktake integer,
    stockcount integer,
    adjustedvalue integer,
    finalised boolean
);


ALTER TABLE stockadjustment OWNER TO postgres;

--
-- Name: stockcenter; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE stockcenter (
    id integer NOT NULL,
    stockcentername character varying(255),
    preferred boolean
);


ALTER TABLE stockcenter OWNER TO postgres;

--
-- Name: stocktake; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE stocktake (
    id integer NOT NULL,
    enddate timestamp with time zone,
    startdate timestamp with time zone,
    stocktakenumber character varying(255),
    open boolean
);


ALTER TABLE stocktake OWNER TO postgres;

--
-- Name: study; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE study (
    id integer NOT NULL,
    studyname character varying(255) NOT NULL
);


ALTER TABLE study OWNER TO postgres;

--
-- Name: studyparticipant; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE studyparticipant (
    id integer NOT NULL,
    studygroup character varying(255) NOT NULL,
    startdate date NOT NULL,
    enddate date,
    patient integer NOT NULL,
    study integer NOT NULL,
    randomizationid character varying(40),
    alternatecellphone character varying(20),
    network character varying(40) NOT NULL,
    language character varying(50)
);


ALTER TABLE studyparticipant OWNER TO postgres;

--
-- Name: sync_temp_dispense; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE sync_temp_dispense (
    nid character varying NOT NULL,
    ultimo_levantamento date
);


ALTER TABLE sync_temp_dispense OWNER TO postgres;

--
-- Name: sync_temp_patients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE sync_temp_patients (
    nid character varying NOT NULL,
    datanasc character varying(255),
    pnomes character varying(255),
    unomes character varying(255),
    sexo character varying(255),
    dataabertura character varying(255)
);


ALTER TABLE sync_temp_patients OWNER TO postgres;

--
-- Name: sync_view_dispense; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW sync_view_dispense AS
 SELECT idart.nid,
    idart.ultimo_lev,
    idart.tipo_tarv,
    idart.regime,
    idart.linha,
    (idart.ultimo_lev + 28) AS dataproxima,
    sync_temp_dispense.ultimo_levantamento AS ultimo_sesp
   FROM ( SELECT dispensa.nid,
            dispensa.ultimo_lev,
            prescricao.tipo_tarv,
            prescricao.regime,
            prescricao.linha
           FROM ( SELECT packagedruginfotmp.patientid AS nid,
                    (max(packagedruginfotmp.dispensedate))::date AS ultimo_lev
                   FROM packagedruginfotmp
                  GROUP BY packagedruginfotmp.patientid
                  ORDER BY packagedruginfotmp.patientid) dispensa,
            ( SELECT DISTINCT patient.patientid AS nid,
                    prescription.reasonforupdate AS tipo_tarv,
                    regimeterapeutico.regimeesquema AS regime,
                    linhat.linhanome AS linha
                   FROM patient,
                    prescription,
                    linhat,
                    regimeterapeutico
                  WHERE ((patient.id = prescription.patient) AND (prescription.current = 'T'::bpchar) AND (prescription.regimeid = regimeterapeutico.regimeid) AND (prescription.linhaid = linhat.linhaid))) prescricao
          WHERE ((dispensa.nid)::text = (prescricao.nid)::text)) idart,
    sync_temp_dispense
  WHERE (((idart.nid)::text = (sync_temp_dispense.nid)::text) AND (idart.ultimo_lev > sync_temp_dispense.ultimo_levantamento));


ALTER TABLE sync_view_dispense OWNER TO postgres;

--
-- Name: sync_view_patients; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW sync_view_patients AS
 SELECT sync_temp_patients.nid,
    sync_temp_patients.datanasc,
    sync_temp_patients.pnomes,
    sync_temp_patients.unomes AS unome,
    sync_temp_patients.sexo,
    sync_temp_patients.dataabertura
   FROM sync_temp_patients
  WHERE (NOT ((sync_temp_patients.nid)::text IN ( SELECT patient.patientid
           FROM patient)));


ALTER TABLE sync_view_patients OWNER TO postgres;

--
-- Name: test; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW test AS
 SELECT DISTINCT regimeterapeutico.regimeesquema,
    regimeterapeutico.regimeid,
    packagedruginfotmp.patientid
   FROM regimeterapeutico,
    drug,
    prescription,
    packagedruginfotmp,
    package
  WHERE ((regimeterapeutico.active = true) AND (prescription.regimeid = regimeterapeutico.regimeid) AND (prescription.current = 'T'::bpchar) AND (prescription.id = package.prescription) AND ((packagedruginfotmp.packageid)::text = (package.packageid)::text))
  GROUP BY regimeterapeutico.regimeesquema, regimeterapeutico.regimeid, packagedruginfotmp.packageid, packagedruginfotmp.patientid;


ALTER TABLE test OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE users (
    id integer NOT NULL,
    modified character(1),
    cl_password character varying(255),
    role character varying(255),
    cl_username character varying(255),
    permission character(1)
);


ALTER TABLE users OWNER TO postgres;

--
-- Name: v_pacientes_que_levantaram_arvs_hoje; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW v_pacientes_que_levantaram_arvs_hoje AS
 SELECT packagedruginfotmp.patientid,
    packagedruginfotmp.dispensedate,
    packagedruginfotmp.dispensedqty,
    packagedruginfotmp.drugname,
    packagedruginfotmp.weekssupply,
    packagedruginfotmp.dateexpectedstring,
    packagedruginfotmp.prescriptionduration
   FROM packagedruginfotmp
  WHERE ((date_part('DAY'::text, now()) = date_part('DAY'::text, packagedruginfotmp.dispensedate)) AND (date_part('MONTH'::text, now()) = date_part('MONTH'::text, packagedruginfotmp.dispensedate)) AND (date_part('YEAR'::text, now()) = date_part('YEAR'::text, packagedruginfotmp.dispensedate)));


ALTER TABLE v_pacientes_que_levantaram_arvs_hoje OWNER TO postgres;

--
-- Name: v_pacientes_para_acess; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW v_pacientes_para_acess AS
 SELECT v_pacientes_que_levantaram_arvs_hoje.patientid,
    v_pacientes_que_levantaram_arvs_hoje.dispensedate,
    v_pacientes_que_levantaram_arvs_hoje.dispensedqty,
    v_pacientes_que_levantaram_arvs_hoje.drugname,
    v_pacientes_que_levantaram_arvs_hoje.weekssupply,
    to_date((v_pacientes_que_levantaram_arvs_hoje.dateexpectedstring)::text, 'DD Mon YYYY'::text) AS dateexpectedstring,
    v_pacientes_que_levantaram_arvs_hoje.prescriptionduration,
    (date_part('YEAR'::text, now()) - date_part('YEAR'::text, patient.dateofbirth)) AS idade,
    prescription.reasonforupdate,
    prescription.notes
   FROM v_pacientes_que_levantaram_arvs_hoje,
    patient,
    prescription
  WHERE (((v_pacientes_que_levantaram_arvs_hoje.patientid)::text = (patient.patientid)::text) AND (patient.id = prescription.patient) AND (prescription.current = 'T'::bpchar));


ALTER TABLE v_pacientes_para_acess OWNER TO postgres;

--
-- Data for Name: accumulateddrugs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY accumulateddrugs (id, withpackage, pillcount) FROM stdin;
\.


--
-- Data for Name: adherencerecordtmp; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY adherencerecordtmp (id, adherencereason, countdate, dayscarriedover, daysinhand, dayssincevisit, dayssupplied, pawcno, pillcountid, cluser) FROM stdin;
\.


--
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY alerts (id, alertmessage, alerttype, alertdate, void) FROM stdin;
\.


--
-- Data for Name: alternatepatientidentifier; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY alternatepatientidentifier (id, identifier, patient, datechanged, masterpatientid, type_id) FROM stdin;
\.


--
-- Data for Name: appointment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY appointment (id, appointmentdate, patient, visitdate) FROM stdin;
152716	2016-07-06 22:00:00+00	152685	\N
152710	2016-07-06 22:00:00+00	152685	2016-06-09 08:47:57.005+00
152758	2016-07-11 22:00:00+00	152748	\N
152772	2016-07-11 22:00:00+00	152762	\N
152744	2016-07-06 22:00:00+00	152720	2016-08-04 23:18:36.491+00
152809	2016-09-01 22:00:00+00	152799	\N
152817	2016-09-01 22:00:00+00	152745	\N
152787	2016-09-01 22:00:00+00	152720	2016-08-04 23:47:58.18+00
152829	2016-09-01 22:00:00+00	152720	\N
152823	2016-09-01 22:00:00+00	152720	2016-08-04 23:49:18.01+00
152840	2016-09-01 22:00:00+00	152830	2016-08-04 23:53:29.92+00
152846	2016-09-01 22:00:00+00	152830	2016-08-04 23:53:55.53+00
152850	2016-09-01 22:00:00+00	152830	2016-08-05 00:00:24.236+00
152862	2016-09-01 22:00:00+00	152830	\N
152858	2016-09-01 22:00:00+00	152830	2016-08-05 00:03:04.174+00
152866	2016-09-01 22:00:00+00	152788	\N
152798	2016-09-01 22:00:00+00	152788	2016-08-05 00:05:48.965+00
152878	2016-09-05 22:00:00+00	152732	\N
152871	2016-09-05 22:00:00+00	152732	2016-08-09 09:07:19.703+00
152915	2016-09-05 22:00:00+00	152895	2016-08-09 14:33:40.968+00
152919	2016-09-05 22:00:00+00	152895	2016-08-09 14:39:12.45+00
152929	2016-09-05 22:00:00+00	152895	\N
152925	2016-09-05 22:00:00+00	152895	2016-08-09 14:41:37.251+00
\.


--
-- Data for Name: atccode; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY atccode (id, name, code, mims) FROM stdin;
31	Abacavir	08S01	19.12
41233	Abacavir 	08S01B	\N
41235	Efavirenz 50 	08S19	\N
41236	Efavirenz 600 	08S21	\N
40	Efavirenz 200	08S20	19.12
30	Lamivudine	08S13	18.9
38	Nevirapine 200	08S22	18.12
26	Zidovudine 300	08S15	18.12
18	Ritonavir	08S29	18.12
50	Stavudine, Lamivudine and Nevirapine	08S36	\N
41237	Lamivudine and Stavudine	08S32	\N
48	Zidovudine, Lamivudine and Nevirapine	08S42	\N
41238	Tenofovir, Lamivudina and Efavirenze	08S18Y	\N
44	Zidovudine and Lamivudine	08S40	\N
41239	Tenofovir and Lamivudine	08S18Z	\N
41240	Lopinavir and Ritonavir	08S39Z	\N
41241	Lamivudina 30, Stavudina 6 and Nevirapina 50	8S34B	\N
41242	Lamivudina 30 and Stavudina 6	08S32B	\N
41243	Lamivudina 30, Zidovudina 60 and Nevirapina 50	ZEL111	\N
41244	Lamivudina 30 and Zidovudina 60	ZEL110	\N
41245	Lopinavir 100 and Ritonavir 25	08S39B	\N
41234	Tenofovir 	08S18	18.12
41246	Abacavir 60 and Lamivudina 30	08S01Z	\N
\.


--
-- Data for Name: atccode_chemicalcompound; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY atccode_chemicalcompound (atccode_id, chemicalcompound_id) FROM stdin;
31	1
40	3
30	4
38	5
18	6
26	8
44	8
44	4
48	8
48	4
48	5
50	7
50	4
50	5
\.


--
-- Data for Name: attributetype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY attributetype (id, datatype, description, name) FROM stdin;
1	java.util.Date	Date for First ARV package dispensing.	ARV Start Date
\.


--
-- Data for Name: campaign; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY campaign (id, description, duration, name, startdate, status, timesperday, type, version, mobilisrid) FROM stdin;
\.


--
-- Data for Name: campaign_participant; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY campaign_participant (campaign_id, patient_id, id) FROM stdin;
\.


--
-- Data for Name: chemicalcompound; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY chemicalcompound (id, name, acronym) FROM stdin;
1	Abacavir	ABC
3	Efavirenz	EFV
4	Lamivudine	3TC
5	Nevirapine	NVP
6	Ritonavir	RTV
7	Stavudine	D4T
8	Zidovudine	AZT
9	Lopinavir	LPV
11	Tenofovir	TDF
120	Atazanavir	ATV
122	Darunavir	DRV
138	Raltegravir	RAL
41460	Sulfametazol	SLF
41461	Trimetoprim	TMT
\.


--
-- Data for Name: chemicaldrugstrength; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY chemicaldrugstrength (id, chemicalcompound, strength, drug) FROM stdin;
41166	6	20	41165
41167	9	80	41165
41573	1	300	41131
41574	1	60	41133
41195	1	600	41194
41196	4	300	41194
41198	120	300	41197
41200	138	400	41199
41202	122	300	41201
41225	122	75	41223
41227	122	150	41226
41229	120	150	41228
41231	120	100	41230
41249	11	300	41135
41250	3	200	41137
41251	3	50	41139
41252	3	600	41141
41253	4	150	41143
41254	8	300	41160
41255	6	100	41168
41256	4	150	41170
41257	7	30	41170
41258	5	200	41170
41146	5	200	41145
41148	5	50	41147
41150	5	50	41149
41153	6	80	41151
41155	7	6	41154
41157	7	30	41156
41163	6	33	41162
41164	9	133	41162
41267	1	60	41220
41268	4	30	41220
41288	4	300	41287
41289	11	300	41287
41290	3	600	41287
41292	4	150	41291
41293	8	300	41291
41294	5	200	41291
41295	4	30	41203
41296	7	60	41203
41297	5	50	41203
41298	4	30	41207
41299	7	60	41207
41300	4	30	41210
41301	8	60	41210
41302	5	50	41210
41303	6	25	41217
41304	9	100	41217
41305	4	300	41188
41306	11	300	41188
41307	6	50	41191
41308	9	200	41191
41309	4	150	41185
41310	8	300	41185
41806	8	50	41158
41809	4	150	41808
41810	7	30	41808
\.


--
-- Data for Name: clinic; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY clinic (id, notes, telephone, mainclinic, clinicname, clinicdetails_id) FROM stdin;
2			t	Local Desconhecido	\N
\.


--
-- Data for Name: clinicuser; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY clinicuser (clinicid, userid) FROM stdin;
2	1
\.


--
-- Data for Name: databasechangelog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY databasechangelog (id, author, filename, dateexecuted, orderexecuted, exectype, md5sum, description, comments, tag, liquibase) FROM stdin;
0.2.2	simon	org/celllife/idart/database/baseline-constraints.xml	2013-06-20 08:44:44.476+00	40	EXECUTED	\N	Custom SQL		\N	2.0.2
0.1.1	simon	org/celllife/idart/database/baseline-with-core-data.xml	2013-06-20 08:44:43.968+00	38	EXECUTED	\N	SQL From File		\N	2.0.2
0.2.1	simon (generated)	org/celllife/idart/database/baseline-constraints.xml	2013-06-20 08:44:44.361+00	39	EXECUTED	\N	Add Primary Key, Add Unique Constraint (x6), Add Foreign Key Constraint (x26), Create Sequence		\N	2.0.2
0.2.3	pavas	org/celllife/idart/database/baseline-constraints.xml	2013-06-20 08:44:44.626+00	41	EXECUTED	\N	SQL From File		\N	2.0.2
3.5.11	Rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.892+00	52	EXECUTED	3:85c8b62fbe2c0cf41c2df3cbf594120a	Modify data type		\N	2.0.2
3.5.1	simon	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.567+00	42	EXECUTED	3:06f92ee3a5ab2c8ec1d5f167f13cbd66	Delete Data		\N	2.0.2
fix_primary_keys_pillcount	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:26.217+00	92	MARK_RAN	3:098787c053f1495b25b68221b0711f2e	Add Primary Key		\N	2.0.2
fix_primary_keys_pregnancy	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:27.707+00	93	MARK_RAN	3:b48fe6a3d391d8719a7974156b0528b6	Add Primary Key		\N	2.0.2
fix_primary_keys_prescribeddrugs	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:29.259+00	94	MARK_RAN	3:65a37b6f2b1999a99ce48478205776c2	Add Primary Key		\N	2.0.2
fix_primary_keys_prescription	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:30.914+00	95	MARK_RAN	3:8119ee5ec17cdb51c1fdb6d1997077fc	Add Primary Key		\N	2.0.2
fix_primary_keys_regimen	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:32.501+00	96	MARK_RAN	3:b913910ee776e770b5631768f2014074	Add Primary Key		\N	2.0.2
fix_primary_keys_regimendrugs	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:33.93+00	97	MARK_RAN	3:3c079643b3b3ffcaf7370fc4edaa3073	Add Primary Key		\N	2.0.2
fix_primary_keys_simpledomain	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:35.408+00	98	MARK_RAN	3:6f095ddb484c809556de817a9f70f58e	Add Primary Key		\N	2.0.2
0.0.14	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.151+00	14	EXECUTED	\N	Create Table		\N	2.0.2
3.5.12	Rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.929+00	53	EXECUTED	3:a0f475c2c60eaf1e853bf5e892f72381	Modify data type		\N	2.0.2
3.5.13	Simon	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.937+00	54	MARK_RAN	3:c4c586c4997f27694312d5f15b276b14	Custom SQL		\N	2.0.2
3.5.14	Simon	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.944+00	55	MARK_RAN	3:8478b82cc56f1155e30e7ac5c5e36089	Custom SQL		\N	2.0.2
3.5.15	Simon	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.951+00	56	MARK_RAN	3:80e226e67bb3c6b63091082a199e3b80	Custom SQL		\N	2.0.2
3.5.16	Simon	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.959+00	57	MARK_RAN	3:d697ebd4eefc083a078f434ba49c2ab6	Custom SQL		\N	2.0.2
3.5.17	Simon	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.966+00	58	EXECUTED	3:55e58578b4c2277aea2f49ff603d31b4	Delete Data		\N	2.0.2
3.5.18	rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.977+00	59	EXECUTED	3:abd9b2cadc09308d405543382df29e61	Custom SQL	Fix Packages' clinic	\N	2.0.2
3.5.19	Adiel	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.984+00	60	EXECUTED	3:22d04b68a1e3b49ef4a39c397c7263b4	Custom SQL		\N	2.0.2
3.5.20	Adiel	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.99+00	61	EXECUTED	3:ba7c31674014814ae4a521573689c6fd	Custom SQL		\N	2.0.2
3.5.21	Michael	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.997+00	62	EXECUTED	3:56d4896db1b37f814119aa316ca28146	Custom SQL		\N	2.0.2
3.5.22	Adiel	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:46.008+00	63	EXECUTED	3:6745a08f7a48753740df4c73e13cfa9e	Custom SQL		\N	2.0.2
3.5.23	Rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:46.051+00	64	EXECUTED	3:43e7cae6a3a625e260058772610e39d9	Create Table, Add Unique Constraint		\N	2.0.2
3.5.24	Rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:46.111+00	65	EXECUTED	3:5fc5e15bd7b784c9116bbf064f556906	Drop Column (x6), Add Column, Add Foreign Key Constraint		\N	2.0.2
3.5.25	Rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:46.136+00	66	EXECUTED	3:2ad484bf2499ec868213817c62867414	Add Column (x2), Custom SQL (x2)	Speed up Reports	\N	2.0.2
fix_primary_keys_accumulateddrugs	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:44:47.769+00	67	MARK_RAN	3:939371dde470d32979d3386e711901f9	Add Primary Key		\N	2.0.2
fix_primary_keys_adherencerecordtmp	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:44:49.336+00	68	MARK_RAN	3:56ed9caab0c21d7bbb1a5b615f7632ea	Add Primary Key		\N	2.0.2
fix_primary_keys_alternatepatientidentifier	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:44:50.79+00	69	MARK_RAN	3:9dcce1f6aa98cbc94a481070354309a9	Add Primary Key		\N	2.0.2
fix_primary_keys_appointment	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:44:52.286+00	70	MARK_RAN	3:df4f3b29b59be5a0725e7457ecec92ae	Add Primary Key		\N	2.0.2
fix_primary_keys_attributetype	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:44:53.795+00	71	MARK_RAN	3:5f647ba3df5f8fbda4968387aada8820	Add Primary Key		\N	2.0.2
fix_primary_keys_chemicalcompound	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:44:55.272+00	72	MARK_RAN	3:4f2d55734a340fe14856a7349f58cad2	Add Primary Key		\N	2.0.2
fix_primary_keys_chemicaldrugstrength	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:44:57.086+00	73	MARK_RAN	3:760bbfc4bb724593bf505e2dd952ca2a	Add Primary Key		\N	2.0.2
fix_primary_keys_clinic	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:44:58.606+00	74	MARK_RAN	3:f0e32061314a533fa9c7d89508cf71a2	Add Primary Key		\N	2.0.2
fix_primary_keys_clinicuser	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:00.305+00	75	MARK_RAN	3:f41464f9cadff6ce4d32c4eefbf4d58e	Add Primary Key		\N	2.0.2
fix_primary_keys_deleteditem	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:01.898+00	76	MARK_RAN	3:d86af96b10dce9536ffb925ca520ff63	Add Primary Key		\N	2.0.2
fix_primary_keys_doctor	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:03.361+00	77	MARK_RAN	3:150e9df32c7dfae298b066ccc8f3253a	Add Primary Key		\N	2.0.2
fix_primary_keys_drug	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:04.788+00	78	MARK_RAN	3:bcc91d113176a838348f060104556979	Add Primary Key		\N	2.0.2
fix_primary_keys_episode	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:06.248+00	79	MARK_RAN	3:d18e148c09c508392adf242921ab8925	Add Primary Key		\N	2.0.2
fix_primary_keys_form	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:07.766+00	80	MARK_RAN	3:0e547f3099cfb7ceccc92b99a0b0a3a3	Add Primary Key		\N	2.0.2
fix_primary_keys_logging	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:09.23+00	81	MARK_RAN	3:cf402d4d984c4d466c464ef900403690	Add Primary Key		\N	2.0.2
fix_primary_keys_nationalclinics	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:10.93+00	82	MARK_RAN	3:343a61856a2c58ffeee85a46350e2004	Add Primary Key		\N	2.0.2
fix_primary_keys_package	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:12.529+00	83	MARK_RAN	3:b17ca9f02c53b701ef23f2bdcaa1cd71	Add Primary Key		\N	2.0.2
fix_primary_keys_packageddrugs	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:13.976+00	84	MARK_RAN	3:8f7cc929b79f8f157b182005a48ea0bf	Add Primary Key		\N	2.0.2
fix_primary_keys_packagedruginfotmp	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:15.557+00	85	MARK_RAN	3:ed88b8c605d8b624b3170437d96e88db	Add Primary Key		\N	2.0.2
fix_primary_keys_patient	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:17.031+00	86	MARK_RAN	3:972d66e0f8aeb2893763b3c2f25afd52	Add Primary Key		\N	2.0.2
fix_primary_keys_patientattribute	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:18.514+00	87	MARK_RAN	3:f79b236293590521ede8231caaddf1b9	Add Primary Key		\N	2.0.2
fix_primary_keys_patientstatistic	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:20.136+00	88	MARK_RAN	3:b943e1bb21e770e22903800b0873768d	Add Primary Key		\N	2.0.2
0.0.1	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:42.773+00	1	EXECUTED	\N	Create Table		\N	2.0.2
0.0.2	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:42.83+00	2	EXECUTED	\N	Create Table		\N	2.0.2
0.0.3	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:42.855+00	3	EXECUTED	\N	Create Table		\N	2.0.2
0.0.4	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:42.874+00	4	EXECUTED	\N	Create Table		\N	2.0.2
0.0.5	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:42.898+00	5	EXECUTED	\N	Create Table		\N	2.0.2
0.0.6	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:42.963+00	6	EXECUTED	\N	Create Table		\N	2.0.2
0.0.7	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:42.98+00	7	EXECUTED	\N	Create Table		\N	2.0.2
0.0.8	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.006+00	8	EXECUTED	\N	Create Table		\N	2.0.2
0.0.9	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.015+00	9	EXECUTED	\N	Create Table		\N	2.0.2
0.0.10	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.035+00	10	EXECUTED	\N	Create Table		\N	2.0.2
0.0.11	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.063+00	11	EXECUTED	\N	Create Table		\N	2.0.2
0.0.12	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.093+00	12	EXECUTED	\N	Create Table		\N	2.0.2
0.0.13	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.122+00	13	EXECUTED	\N	Create Table		\N	2.0.2
fix_primary_keys_patientstattypes	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:21.619+00	89	MARK_RAN	3:83a936bf2942dffcdc2b5e668fd289ba	Add Primary Key		\N	2.0.2
fix_primary_keys_patientvisit	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:23.144+00	90	MARK_RAN	3:6e96a12e3a56fab550b2d402b28f744d	Add Primary Key		\N	2.0.2
fix_primary_keys_patientvisitreason	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:24.635+00	91	MARK_RAN	3:768a2a17e512e73ceb2de12a0b03d329	Add Primary Key		\N	2.0.2
fix_primary_keys_stock	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:37.05+00	99	MARK_RAN	3:ad4e3536ea32daacfa809c2a94be4492	Add Primary Key		\N	2.0.2
fix_primary_keys_stockadjustment	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:38.551+00	100	MARK_RAN	3:7436350105baf235f1e864bf644fa5b2	Add Primary Key		\N	2.0.2
fix_primary_keys_stockcenter	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:40.081+00	101	MARK_RAN	3:1946a57ea71da6248ffbe36374fdb500	Add Primary Key		\N	2.0.2
fix_primary_keys_stocklevel	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:41.664+00	102	MARK_RAN	3:f71b887f75813b86f1273830653b4106	Add Primary Key		\N	2.0.2
fix_primary_keys_stocktake	simon@cell-life.org	org/celllife/idart/database/changelog-primary_key_fix.xml	2013-06-20 08:45:43.063+00	103	MARK_RAN	3:1adfcebe89367d6337d0c9739cf11b48	Add Primary Key		\N	2.0.2
3.6.1	Rashid	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:43.079+00	104	EXECUTED	3:616fb6986989fc5f66df221d7a2f556e	Add Column, Custom SQL, Drop Column (x2)	Add Visit Date to Appointment	\N	2.0.2
3.6.2	Rashid	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:43.144+00	105	EXECUTED	3:ffeda6a0d1569a40e35e3abe91be0806	Create Table (x2), Add Foreign Key Constraint (x2)	Add Study Tables	\N	2.0.2
3.6.3	michael	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:43.19+00	106	EXECUTED	3:11db8e6d05bc02a2ac93c6c3c598b501	Create Table (x2), Add Primary Key (x2), Add Foreign Key Constraint (x2)	Add the Campaign Tables	\N	2.0.2
3.6.4	Rashid	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:43.208+00	107	EXECUTED	3:c05629ab79e09785a097ab9d764424f5	Drop Column (x2), Insert Row		\N	2.0.2
3.6.5	michael	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:43.216+00	108	EXECUTED	3:925abbe7f63bcc6baaf38077efb58cf8	Rename Column (x2)		\N	2.0.2
3.6.6	michael	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:43.223+00	109	EXECUTED	3:88e395de53809d80e593985b69f86e29	Update Data		\N	2.0.2
3.6.7	michael	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:44.952+00	110	EXECUTED	3:f6db5316e7afda52473f7912dde896db	Drop Primary Key, Add Column		\N	2.0.2
3.6.8	michael	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:44.961+00	111	EXECUTED	3:f10291b1b9fab823894a8670685c0370	Add Column		\N	2.0.2
3.6.9	Rashid	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:44.985+00	112	EXECUTED	3:427f17df0b33724b2b21cd79c4bfe7da	Create Table		\N	2.0.2
3.6.10	Rashid	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.052+00	113	EXECUTED	3:e4eed782620204e080ccecc094e661de	Add Column, Create Table		\N	2.0.2
3.6.11	Rashid	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.082+00	114	EXECUTED	3:e93141c5abaf0a3730a54bd867b8920e	Add Column		\N	2.0.2
0.0.15	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.182+00	15	EXECUTED	\N	Create Table		\N	2.0.2
0.0.16	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.208+00	16	EXECUTED	\N	Create Table		\N	2.0.2
0.0.17	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.224+00	17	EXECUTED	\N	Create Table		\N	2.0.2
0.0.18	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.255+00	18	EXECUTED	\N	Create Table		\N	2.0.2
0.0.19	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.282+00	19	EXECUTED	\N	Create Table		\N	2.0.2
0.0.20	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.304+00	20	EXECUTED	\N	Create Table		\N	2.0.2
0.0.21	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.322+00	21	EXECUTED	\N	Create Table		\N	2.0.2
0.0.22	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.34+00	22	EXECUTED	\N	Create Table		\N	2.0.2
0.0.23	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.362+00	23	EXECUTED	\N	Create Table		\N	2.0.2
0.0.24	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.372+00	24	EXECUTED	\N	Create Table		\N	2.0.2
0.0.25	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.388+00	25	EXECUTED	\N	Create Table		\N	2.0.2
0.0.26	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.406+00	26	EXECUTED	\N	Create Table		\N	2.0.2
0.0.27	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.423+00	27	EXECUTED	\N	Create Table		\N	2.0.2
0.0.28	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.449+00	28	EXECUTED	\N	Create Table		\N	2.0.2
0.0.29	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.474+00	29	EXECUTED	\N	Create Table		\N	2.0.2
0.0.30	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.5+00	30	EXECUTED	\N	Create Table		\N	2.0.2
0.0.31	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.554+00	31	EXECUTED	\N	Create Table		\N	2.0.2
0.0.32	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.578+00	32	EXECUTED	\N	Create Table		\N	2.0.2
0.0.33	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.593+00	33	EXECUTED	\N	Create Table		\N	2.0.2
0.0.34	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.615+00	34	EXECUTED	\N	Create Table		\N	2.0.2
0.0.35	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.644+00	35	EXECUTED	\N	Create Table		\N	2.0.2
0.0.36	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.663+00	36	EXECUTED	\N	Create Table		\N	2.0.2
0.0.37	simon (generated)	org/celllife/idart/database/baseline-schema.xml	2013-06-20 08:44:43.685+00	37	EXECUTED	\N	Create Table		\N	2.0.2
3.6.12	michael	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.093+00	115	EXECUTED	3:1bafdd1302416a9b19f10e9a04591085	Drop Column		\N	2.0.2
3.6.13	simon	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.102+00	116	EXECUTED	3:6dc26347f47c566a3cf803c290486e6e	Update Data		\N	2.0.2
3.6.14	simon	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.109+00	117	EXECUTED	3:e0fe8f7443727d439d902ce408e5b90f	Add Column		\N	2.0.2
3.6.15	simon	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.124+00	118	EXECUTED	3:b5c630874eb303cc53b094fcc32628e3	Add Column, Custom SQL, Add Not-Null Constraint (x2)	add alternatecellphone and network columns to studyparticipant	\N	2.0.2
3.6.16	munaf	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.13+00	119	EXECUTED	3:47724cbcfa4df247a4beff4516c80d65	Add Column		\N	2.0.2
3.6.16	simon	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.14+00	120	EXECUTED	3:b87810e6f2fc28ae8e4957d6aa91b29f	Add Column, Drop Column, Add Column		\N	2.0.2
3.6.18	simon@cell-life.org	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.145+00	121	EXECUTED	3:2b3cb7423cb87952fd3159eebd4caaec	Drop Not-Null Constraint	make alternate mobile number for study participant not compulsory	\N	2.0.2
3.6.19	simon	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.156+00	122	EXECUTED	3:6b9f4c86fd991644a860e1df0af0114d	Add Column, Custom SQL, Drop Column		\N	2.0.2
3.6.20	simon@cell-life.org	org/celllife/idart/database/changelog-3.6.xml	2013-06-20 08:45:45.169+00	123	EXECUTED	3:be33e016e023dc54ad0b0d8a34012e47	Update Data (x2), Delete Data		\N	2.0.2
3.7.1	simon@cell-life.org	org/celllife/idart/database/changelog-3.7.xml	2013-06-20 08:45:45.24+00	124	EXECUTED	3:4e44a2695c2b51f780ed2d66d2ff6373	Create Table (x2), Add Unique Constraint, Add Foreign Key Constraint (x2), Insert Row (x6)	Add patient identifier and identifier type	\N	2.0.2
3.7.2	simon@cell-life.org	org/celllife/idart/database/changelog-3.7.xml	2013-06-20 08:45:45.257+00	125	EXECUTED	3:fb3be7afedeb57747c92167a2573da5b	Add Column, Update Data, Add Not-Null Constraint	Add type to alternate identifiers table	\N	2.0.2
National_Clinics	Rashid	org/celllife/idart/database/changelog-South_Africa_clinics.xml	2013-06-20 08:46:03.964+00	143	EXECUTED	\N	Load Data		\N	2.0.2
3.5.2	rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.605+00	43	EXECUTED	3:f8763b74414948b2bd556c9891a97273	Add Column, Custom SQL, Add Foreign Key Constraint, Add Not-Null Constraint	Add clinic to episode	\N	2.0.2
3.5.3	rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.631+00	44	EXECUTED	3:5b56280ba9a436fbfcc988756fa803ee	Add Column, Custom SQL, Add Foreign Key Constraint, Add Not-Null Constraint		\N	2.0.2
3.5.4	rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.658+00	45	EXECUTED	3:770e681bf3eaf906cd99413a034f5985	Add Column, Custom SQL, Add Foreign Key Constraint, Drop Column, Add Not-Null Constraint		\N	2.0.2
3.5.5	Rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.67+00	46	EXECUTED	3:b10b6f99f1fb8620a4d970637ec7632d	Add Column (x3)		\N	2.0.2
3.5.6	Rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.676+00	47	EXECUTED	3:2be576c02c1cc55a31ced38e91bf91e2	Drop Not-Null Constraint		\N	2.0.2
3.5.7	Simon	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.695+00	48	EXECUTED	3:768a2a17e512e73ceb2de12a0b03d329	Add Primary Key		\N	2.0.2
3.5.8	Rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.702+00	49	EXECUTED	3:d708f8fe9c982ce25de6570803183a98	Add Column		\N	2.0.2
3.5.9	Rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.816+00	50	EXECUTED	3:3933b4a01f066853ea2ae367f2537cb8	Add Column (x2)		\N	2.0.2
3.5.10	Rashid	org/celllife/idart/database/changelog-3.5.xml	2013-06-20 08:44:45.855+00	51	EXECUTED	3:171e09e01490880a9a03fe933f9c6cee	Add Column		\N	2.0.2
3.7.3	simon@cell-life.org	org/celllife/idart/database/changelog-3.7.xml	2013-06-20 08:45:45.264+00	126	EXECUTED	3:49eb17cc186a5c882670dff8865836fd	Custom SQL	Copy patientid to identifier	\N	2.0.2
3.7.4	simon@cell-life.org	org/celllife/idart/database/changelog-3.7.xml	2013-06-20 08:45:45.271+00	127	EXECUTED	3:27e9775ff64e414eac6fb0efaabd8eea	Custom SQL, Drop Column	Move patient idnum to identifier	\N	2.0.2
3.7.5	simon@cell-life.org	org/celllife/idart/database/changelog-3.7.xml	2013-06-20 08:45:45.28+00	128	EXECUTED	3:bcd45fc63c7efe87bdefaf23576be7c3	Rename Column, Drop Column		\N	2.0.2
3.7.6	simon@cell-life.org	org/celllife/idart/database/changelog-3.7.xml	2013-06-20 08:45:45.288+00	129	EXECUTED	3:c4bafff41b3d917dac1439df271071fa	Update Data (x2)	upgrade Communicate API	\N	2.0.2
3.7.7	simon@cell-life.org	org/celllife/idart/database/changelog-3.7.xml	2013-06-20 08:45:45.544+00	130	EXECUTED	3:50338297459c1b770481cdef223b4dca	Modify data type (x8), Custom SQL, Modify data type	changes from hibernate validation	\N	2.0.2
3.7.8	simon@cell-life.org	org/celllife/idart/database/changelog-3.7.xml	2013-06-20 08:45:45.557+00	131	EXECUTED	3:51d0162756927d98456f8e503527c3e8	Custom Change		\N	2.0.2
3.8.1	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:45.636+00	132	EXECUTED	3:f2152ae418f72472af21d01b36236d21	Create Table, Add Column, Drop Column, Add Column, Add Foreign Key Constraint (x2)	add atccode table	\N	2.0.2
3.8.2	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:45.648+00	133	EXECUTED	3:c1e8e01e3d81b17d8ef21b393f207c25	SQL From File	improvement to add_sched_visit trigger	\N	2.0.2
3.8.3	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:45.657+00	134	EXECUTED	3:cf152fd7e6956e72570a51537c595d94	Drop Unique Constraint	drop unique constraint on atccode.mims	\N	2.0.2
3.8.4	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:45.767+00	135	EXECUTED	3:5054cfc4ca0a4e0d0a00b867e34e6c84	Load Data, Update Data	load atc codes	\N	2.0.2
3.8.5	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:45.797+00	136	EXECUTED	3:4e7221a88ba3d72db17117c2fa7f3915	Drop Column, Create Table, Add Foreign Key Constraint (x2)	change atccode chemicalcompound relationship to many to many	\N	2.0.2
3.8.6	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:45.823+00	137	EXECUTED	3:362abc77e0ca16a84e9ea4a7b1d7ed64	Add Not-Null Constraint, Add Unique Constraint (x2)	add constraints to chemical compound	\N	2.0.2
3.8.7	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:45.97+00	138	EXECUTED	3:577941530aff7f698fd0d697949f6a2f	Custom Change	link atc codes to chemical compounds	\N	2.0.2
3.8.8	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:45.978+00	139	EXECUTED	3:d71c15bf71a06cbbb0e87790ec908c41	Delete Data	remove didanosine link from tenofovir	\N	2.0.2
3.8.9	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:48.124+00	140	EXECUTED	3:7dc21d4eabf676cbb547e3b04e8cff3f	Custom Change	link atc codes to drugs	\N	2.0.2
3.8.10	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:48.132+00	141	EXECUTED	3:40b758ff6046b50a405906e7dc532e72	Add Column	add pickupdate to packagedruginfotmp	\N	2.0.2
3.8.11	simon@cell-life.org	org/celllife/idart/database/changelog-3.8.xml	2013-06-20 08:45:48.158+00	142	EXECUTED	3:69c0217fe01285898133b514ece2144c	Drop Column (x2)	remove invalid columns from adherencerecordtmp and deleteditem	\N	2.0.2
\.


--
-- Data for Name: databasechangeloglock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY databasechangeloglock (id, locked, lockgranted, lockedby) FROM stdin;
1	f	\N	\N
\.


--
-- Data for Name: deleteditem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY deleteditem (id, deleteditemid, itemtype) FROM stdin;
37363	37089	PackageDrugInfo
37364	37090	PackageDrugInfo
37365	37091	PackageDrugInfo
115265	115229	PackageDrugInfo
\.


--
-- Data for Name: doctor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY doctor (id, emailaddress, firstname, lastname, mobileno, modified, telephoneno, active, category) FROM stdin;
36748		Provider	Generic		T		t	0
36749		Agostinho	Cavalo		T		t	0
\.


--
-- Data for Name: doctorcategory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY doctorcategory (id, categoria) FROM stdin;
0	GERAL
\.


--
-- Data for Name: drug; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY drug (id, form, dispensinginstructions1, dispensinginstructions2, modified, name, packsize, sidetreatment, defaultamnt, defaulttimes, stockcode, atccode_id, pediatric) FROM stdin;
41149	16			T	[NVP] Nevirapine 50mg/5ml	240	F	0	2		\N	T
41151	16			T	[RTV] Ritonavir 80mg/ml	90	F	0	2		\N	T
41154	14			T	[D4T] Stavudine 6mg	60	F	0	2		\N	T
41156	14			T	[D4T] Stavudine 30mg	60	F	1	2		\N	F
41158	16			T	[AZT] Zidovudine 50mg/5ml	240	F	0	2		\N	T
41162	14			T	[LPV/RTV]  Lopinavir/Ritonavir-Kaletra 133.3/33.3 mg	180	F	3	2		\N	F
41165	16			T	[LPV/RTV]  Lopinavir/Ritonavir-Kaletra 80/20 mg/ml	60	F	0	2		\N	T
41287	14			T	[TDF/3TC/EFV] Tenofovir 300mg/Lamivudina 300mg/Efavirenze 600mg	30	F	1	1		41238	F
41194	14			T	[ABC/3TC] Abacavir 600mg/Lamivudina 300mg 	30	F	0	0		\N	F
41197	14			T	[ATC] Atazanavir 300mg  	30	F	1	1		\N	F
41199	14			T	[RAL] Raltegravir 400mg	60	F	1	2		\N	F
41201	14			T	[DRV] Darunavir 300mg 	120	F	2	2		\N	F
41291	14			T	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	60	F	1	2		48	F
41170	14			T	[3TC/D4T/NVP] Lamivudina 150mg/Stavudina 30mg/Nevirapina 200mg	60	F	1	2		50	F
41203	14			T	[3TC/D4T/NVP] Lamivudina 30mg/Stavudina 6mg/Nevirapina 50mg	60	F	0	0		41241	T
41210	14			T	[3TC/AZT/NVP] Lamivudina 30mg/Zidovudina 60mg/Nevirapina 50mg	60	F	0	0		41243	T
41217	14			T	[LPV/RTV] Lopinavir/Ritonavir -Aluvia 100mg/25mg	60	F	0	0		41245	T
41188	14			T	[TDF/3TC] Tenofovir 300mg/Lamivudina 300mg	30	F	1	1		41239	F
41191	14			T	[LPV/RTV] Lopinavir/Ritonavir -Aluvia 200mg/50mg	120	F	2	2		41240	F
41185	14			T	[3TC/AZT] Lamivudina 150mg/ Zidovudina 300mg	60	F	1	2		44	F
41131	14			T	[ABC] Abacavir 300mg	60	F	1	2	19.12	31	F
41133	14			T	[ABC] Abacavir 60mg	60	F	1	2		41233	T
41147	14			T	[NVP]  Nevirapina 50mg	60	F	0	0		\N	T
41223	14			T	[DRV] Darunavir 75mg 	60	F	0	0		\N	T
41226	14			T	[DRV]  Darunavir 150 mg 	60	F	0	0		\N	T
41230	14			T	[ATV] Atazanavir 100mg	60	F	0	0		\N	T
41228	14			T	[ATV]  Atazanavir 150mg	60	F	0	0		\N	T
41143	14			T	[3TC] Lamivudine150mg	60	F	1	2	18.9	30	F
41160	14			T	[AZT] Zidovudine 300mg	60	F	1	2	18.12	26	F
41168	14			T	[RTV] Ritonavir100mg	84	F	0	0	18.12	18	F
41137	14			T	[EFV] Efavirenz 200mg	90	F	0	1	19.12	40	F
41139	14			T	[EFV] Efavirenz 50mg	30	F	0	1		41235	F
41141	14			T	[EFV] Efavirenz 600mg	30	F	1	1		41236	F
41220	14			T	[ABC/3TC] Abacavir 60 and Lamivudina 30mg	60	F	0	0		41246	T
41207	14			T	[3TC/D4T]Lamivudina 30mg/Stavudina 6mg	60	F	0	0		41242	T
41808	14			T	[3TC/D4T]Lamivudina 150mg/Stavudina 30mg	60	F	1	2		41237	F
41135	14			T	[TDF] Tenofovir 300mg	30	F	1	1		41234	F
41145	14			T	[NVP] Nevirapine 200mg	60	F	1	2		38	F
4180823	14	\N	\N	t	[3TC/AZT] Lamivudina 30mg/ Zidovudina 60mg	60	F	0	2	\N	41244	T
\.


--
-- Data for Name: episode; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY episode (id, startdate, stopdate, startreason, stopreason, startnotes, stopnotes, patient, index, clinic) FROM stdin;
152687	2016-06-08 22:00:00+00	\N	Novo Paciente				152685	0	2
152718	2016-06-08 22:00:00+00	\N	Novo Paciente				152717	0	2
152722	2016-06-08 22:00:00+00	\N	Novo Paciente				152720	0	2
152728	2016-06-08 22:00:00+00	\N	Novo Paciente				152726	0	2
152734	2016-06-08 22:00:00+00	\N	Novo Paciente				152732	0	2
152746	2016-06-08 22:00:00+00	\N	Novo Paciente				152745	0	2
152749	2016-06-12 22:00:00+00	\N	Novo Paciente				152748	0	2
152763	2016-06-13 22:00:00+00	\N	Novo Paciente				152762	0	2
152790	2016-08-04 22:00:00+00	\N	Novo Paciente				152788	0	2
152801	2016-08-04 22:00:00+00	\N	Novo Paciente				152799	0	2
152832	2016-08-04 22:00:00+00	\N	Novo Paciente				152830	0	2
152873	2016-08-08 22:00:00+00	\N	Novo Paciente				152872	0	2
152881	2016-08-08 22:00:00+00	\N	Novo Paciente				152879	0	2
152885	2016-08-08 22:00:00+00	\N	Novo Paciente				152883	0	2
152889	2016-08-08 22:00:00+00	\N	Novo Paciente				152887	0	2
152897	2016-08-08 22:00:00+00	\N	Novo Paciente				152895	0	2
\.


--
-- Data for Name: form; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY form (id, form, actionlanguage1, actionlanguage2, actionlanguage3, formlanguage1, formlanguage2, formlanguage3, dispinstructions1, dispinstructions2) FROM stdin;
1	Lozenges	Suck			lozenge(s)
9	Suppository	Insert			suppository
10	Nose drops	Instill			drops			in each nostril
11	Eye drops	Instill			drops			in __ eye(s)
12	Ear drops	Instill			drops			in __ ear(s)
13	Sobonete	Lavar com sabonete
16	Xarope	Tomar			ml
15	Suspension	Tomar			ml
2	Cream	Aplicar
3	Ointment	Aplicar
4	Gel	Aplicar
5	Oral Gel	Aplicar						to the mouth / emlonyeni
6	Lotion	Aplicar
8	Eye Ointment	Aplicar						to __ eye(s)
7	Vaginal Cream	Inserir						Vaginal Cream / Isithambiso sangaphantsi
17	Capsula	Tomar			capsulas
14	Comprimido	Tomar			Comp
\.


--
-- Name: hibernate_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('hibernate_sequence', 152929, true);


--
-- Data for Name: identifiertype; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY identifiertype (id, name, index, voided) FROM stdin;
0	NID	0	f
\.


--
-- Data for Name: linhat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY linhat (linhaid, linhanome, active) FROM stdin;
40323	1ª Linha	t
40324	1ª Linha Alternativa	t
40325	2ª Linha	t
40326	3ª Linha	t
\.


--
-- Data for Name: logging; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY logging (id, itemid, modified, transactiondate, transactiontype, idart_user, message) FROM stdin;
36769	36752	Y	2014-07-15 10:53:16.247+00	Delete Prescription	1	Deleted Prescription 140715A-3165/10 from Patient 3165/10
36867	36749	Y	2014-07-15 12:52:46.549+00	Delete Prescription	1	Deleted Prescription 140714A-909/76 from Patient 909/76
36872	36780	Y	2014-07-15 13:40:52.378+00	Delete Prescription	1	Deleted Prescription 140715A-1833/08 from Patient 1833/08
37304	37154	Y	2014-07-29 08:14:49.149+00	Delete Prescription	1	Deleted Prescription 140717A-109/11 from Patient 109/11
37315	37223	Y	2014-07-29 08:18:45.201+00	Delete Prescription	1	Deleted Prescription 140721A-1150/09 from Patient 1150/09
37359	36742	Y	2014-07-29 10:30:22.386+00	Destroy Stock	1	Destroyed 2700 units of drug [D4T] Stavudine 15mg from batch 3398 Reason: exp
37362	37088	Y	2014-07-29 10:32:41.882+00	Delete Package	1	Deleted package 140715A-4547/08-1 (AZT 100, 3TC 150, NVP 200)
37489	37485	Y	2014-07-29 14:46:15.985+00	Delete Prescription	1	Deleted Prescription 140729B-1691/09 from Patient 1691/09
37506	37502	Y	2014-07-29 14:56:50.33+00	Delete Prescription	1	Deleted Prescription 140729D-1691/09 from Patient 1691/09
37539	37535	Y	2014-07-29 15:00:01.545+00	Delete Prescription	1	Deleted Prescription 140729A-2076/08 from Patient 2076/08
37731	37187	Y	2014-07-31 14:09:30.848+00	Delete Prescription	1	Deleted Prescription 140717A-2240/11 from Patient 2240/11
37910	37908	Y	2014-08-04 09:56:55.422+00	Delete Prescription	1	Deleted Prescription 140804B-09090909090 from Patient 09090909090
38027	38004	Y	2014-08-06 16:11:36.645+00	Delete Prescription	1	Deleted Prescription 140806A-750/09 from Patient 750/09
38040	38028	Y	2014-08-06 16:16:40.497+00	Delete Prescription	1	Deleted Prescription 140806B-750/09 from Patient 750/09
38051	38047	Y	2014-08-07 06:49:30.278+00	Delete Prescription	1	Deleted Prescription 140807A-1691/09 from Patient 1691/09
38231	38229	Y	2014-08-07 13:48:58.3+00	Delete Prescription	1	Deleted Prescription 140807C-09090909090 from Patient 09090909090
38234	38232	Y	2014-08-07 13:49:24.591+00	Delete Prescription	1	Deleted Prescription 140807D-09090909090 from Patient 09090909090
38251	38249	Y	2014-08-07 14:08:54.383+00	Delete Prescription	1	Deleted Prescription 140807A-11050801/13/1219 from Patient 11050801/13/1219
38304	38111	Y	2014-08-07 15:40:11.394+00	Delete Prescription	1	Deleted Prescription 140807C-1691/09 from Patient 1691/09
40007	39974	Y	2014-09-09 15:23:33.508+00	Delete Prescription	1	Deleted Prescription 140829A-11050801/13/12377 from Patient 11050801/13/12377
40012	40005	Y	2014-09-09 15:25:48.657+00	Delete Prescription	1	Deleted Prescription 140909B-07/335 from Patient 07/335
40021	40013	Y	2014-09-10 14:38:29.114+00	Delete Prescription	1	Deleted Prescription 140909C-07/335 from Patient 07/335
40024	40008	Y	2014-09-10 14:39:03.744+00	Delete Prescription	1	Deleted Prescription 140909A-11050801/13/12377 from Patient 11050801/13/12377
40036	40025	Y	2014-09-10 15:49:59.677+00	Delete Prescription	1	Deleted Prescription 140910A-11050801/13/12377 from Patient 11050801/13/12377
40064	40060	Y	2014-09-11 12:31:13.59+00	Delete Prescription	1	Deleted Prescription 140911A-07/335 from Patient 07/335
40067	40065	Y	2014-09-11 12:32:05.571+00	Delete Prescription	1	Deleted Prescription 140911B-07/335 from Patient 07/335
40070	40068	Y	2014-09-11 12:40:55.336+00	Delete Prescription	1	Deleted Prescription 140911C-07/335 from Patient 07/335
40075	40071	Y	2014-09-11 13:34:30.325+00	Delete Prescription	1	Deleted Prescription 140911D-07/335 from Patient 07/335
40336	40334	Y	2014-09-30 15:18:22.83+00	Delete Prescription	1	Deleted Prescription 140930A-11050801/013/861 from Patient 11050801/013/861
40339	40337	Y	2014-09-30 15:18:59.371+00	Delete Prescription	1	Deleted Prescription 140930B-11050801/013/861 from Patient 11050801/013/861
40344	40340	Y	2014-09-30 15:21:19.042+00	Delete Prescription	1	Deleted Prescription 140930C-11050801/013/861 from Patient 11050801/013/861
40347	40345	Y	2014-09-30 15:24:25.299+00	Delete Prescription	1	Deleted Prescription 140930D-11050801/013/861 from Patient 11050801/013/861
40352	40350	Y	2014-09-30 15:55:02.238+00	Delete Prescription	1	Deleted Prescription 140930A-11050801/13/2143 from Patient 11050801/13/2143
40779	40777	Y	2014-12-08 15:19:27.259+00	Delete Prescription	1	Deleted Prescription 141108A-67777 from Patient 67777
40809	40807	Y	2014-12-09 14:44:50.908+00	Delete Prescription	1	Deleted Prescription 141209A-909090 from Patient 909090
40879	40864	Y	2015-01-12 08:05:56.169+00	Delete Prescription	1	Deleted Prescription 150112A-0002 from Patient 0002
40884	40882	Y	2015-01-12 08:16:35.899+00	Delete Prescription	1	Deleted Prescription 150112C-0002 from Patient 0002
40887	40885	Y	2015-01-12 08:16:51.632+00	Delete Prescription	1	Deleted Prescription 150112D-0002 from Patient 0002
40890	40888	Y	2015-01-12 08:25:14.798+00	Delete Prescription	1	Deleted Prescription 150112E-0002 from Patient 0002
40893	40891	Y	2015-01-12 08:30:37.264+00	Delete Prescription	1	Deleted Prescription 150112F-0002 from Patient 0002
40933	40931	Y	2015-01-13 06:12:46.158+00	Delete Prescription	1	Deleted Prescription 150112A-1 from Patient 1
40938	40934	Y	2015-01-13 06:13:26.547+00	Delete Prescription	1	Deleted Prescription 150113A-1 from Patient 1
40957	40953	Y	2015-01-13 06:28:34.166+00	Delete Prescription	1	Deleted Prescription 150113A-1 from Patient 1
40960	40958	Y	2015-01-13 06:35:05.434+00	Delete Prescription	1	Deleted Prescription 150113B-1 from Patient 1
41013	41011	Y	2015-01-13 14:33:00.852+00	Delete Prescription	1	Deleted Prescription 150113A-2 from Patient 2
41016	41014	Y	2015-01-13 14:39:06.825+00	Delete Prescription	1	Deleted Prescription 150113B-2 from Patient 2
41457	41455	Y	2015-01-22 08:51:24.095+00	Delete Prescription	1	Deleted Prescription 150120A-01VVVV1307/012/47 from Patient 01VVVV1307/012/47
41470	41466	Y	2015-01-27 15:37:40.228+00	Delete Prescription	1	Deleted Prescription 150127A-77777777777 from Patient 77777777777
41662	41659	Y	2015-02-07 12:30:39.38+00	Delete Prescription	1	Deleted Prescription 150207A-66666666/5555/66666 from Patient 66666666/5555/66666
41665	41663	Y	2015-02-08 07:19:45.222+00	Delete Prescription	1	Deleted Prescription 150207B-66666666/5555/66666 from Patient 66666666/5555/66666
42103	42102	Y	2015-02-18 04:59:12.377+00	Added New User	1	Added New User edias with clinic access CS 25 DE SETEMBRO
42105	42104	Y	2015-02-18 05:00:03.663+00	Added New User	42102	Added New User ediasii with clinic access CS 25 DE SETEMBRO
42111	42110	Y	2015-02-19 07:22:08.922+00	Added New User	1	Added New User MUAGERICO with clinic access CS 25 DE SETEMBRO
42443	42438	Y	2015-02-19 09:50:29.759+00	Delete Prescription	1	Deleted Prescription 150219A-147/2015 from Patient 147/2015
42449	42444	Y	2015-02-19 09:51:47.149+00	Delete Prescription	1	Deleted Prescription 150219B-147/2015 from Patient 147/2015
42481	42479	Y	2015-02-19 10:20:19.829+00	Delete Prescription	1	Deleted Prescription 150219A-235/14 from Patient 235/14
42637	42634	Y	2015-02-19 11:02:32.876+00	Delete Prescription	1	Deleted Prescription 150219A-10/8563 from Patient 10/8563
42653	42650	Y	2015-02-19 11:09:32.131+00	Delete Prescription	1	Deleted Prescription 150219A-9/20134 from Patient 9/20134
42690	42689	Y	2015-02-23 08:32:48.789+00	Added New User	1	Added New User dele with clinic access CS 25 DE SETEMBRO
42692	42691	Y	2015-02-23 08:33:17.441+00	Added New User	1	Added New User 123 with clinic access CS 25 DE SETEMBRO
42695	42694	Y	2015-02-23 10:39:48.617+00	Added New User	1	Added New User ribeiro with clinic access CS 25 DE SETEMBRO
42697	42696	Y	2015-02-23 10:42:11.154+00	Added New User	1	Added New User Muagerico with clinic access CS 25 DE SETEMBRO
42699	42698	Y	2015-02-23 10:43:49.365+00	Added New User	1	Added New User ATUMANE with clinic access CS 25 DE SETEMBRO
114405	114404	Y	2015-02-25 08:13:32.115+00	Added New User	1	Added New User eteldivage with clinic access CS 1 DE MAIO
114959	114958	Y	2015-02-27 07:14:56.865+00	Added New User	1	Added New User maria with clinic access CS 1 DE MAIO
114961	114960	Y	2015-02-27 07:26:12.515+00	Added New User	1	Added New User candela with clinic access CS 1 DE MAIO
114993	114992	Y	2015-02-27 08:09:45.56+00	Added New User	1	Added New User germano with clinic access CS 1 DE MAIO
115264	115228	Y	2015-02-27 11:52:10.623+00	Delete Package	1	Deleted package 150227A-03010801/13/498-1 (3TC 30/AZT 60/NVP 50)
115266	115262	Y	2015-02-27 11:53:31.986+00	Delete Prescription	1	Deleted Prescription 150227B-03010801/13/498 from Patient 03010801/13/498
115490	115487	Y	2015-02-27 14:02:18.428+00	Delete Prescription	114992	Deleted Prescription 150227A-03010101/05/832 from Patient 03010101/05/832
115837	115835	Y	2015-02-28 10:37:52.626+00	Delete Prescription	1	Deleted Prescription 150228A-03010801/10/1126 from Patient 03010801/10/1126
115847	115845	Y	2015-02-28 10:39:43.439+00	Delete Prescription	1	Deleted Prescription 150228A-03010801/11/48 from Patient 03010801/11/48
115864	115862	Y	2015-02-28 10:42:13.028+00	Delete Prescription	1	Deleted Prescription 150228A-03010801/12/1302 from Patient 03010801/12/1302
116069	116068	Y	2015-02-28 11:27:13.078+00	Added New User	1	Added New User conceita with clinic access CS 1 DE MAIO
120936	117531	Y	2015-03-11 08:18:11.453+00	Delete Prescription	1	Deleted Prescription 150303A-03010801/12/1544 from Patient 03010801/12/1544
121352	121350	Y	2015-03-11 10:05:51.344+00	Delete Prescription	1	Deleted Prescription 150311A-032007/07/698 from Patient 032007/07/698
121702	121700	Y	2015-03-12 08:26:20.66+00	Delete Prescription	114960	Deleted Prescription 150312A-03010801/13/432 from Patient 03010801/13/432
122232	122230	Y	2015-03-13 12:41:12.403+00	Delete Prescription	114992	Deleted Prescription 150313D-03010801/11/642 from Patient 03010801/11/642
122235	122233	Y	2015-03-13 12:42:27.165+00	Delete Prescription	114992	Deleted Prescription 150313E-03010801/11/642 from Patient 03010801/11/642
123344	123342	Y	2015-03-16 10:41:09.938+00	Delete Prescription	114992	Deleted Prescription 150316A-03010801/13/1223 from Patient 03010801/13/1223
127582	127579	Y	2015-03-25 06:58:24.443+00	Delete Prescription	1	Deleted Prescription 150323A-03010101/08/996 from Patient 03010101/08/996
128451	128449	Y	2015-03-25 10:52:06.345+00	Delete Prescription	1	Deleted Prescription 150323A-03010801/11/1370 from Patient 03010801/11/1370
128963	128961	Y	2015-03-29 09:59:26.499+00	Delete Prescription	114960	Deleted Prescription 150329A-03010101/09/720 from Patient 03010101/09/720
129110	129107	Y	2015-03-29 10:35:40.601+00	Delete Prescription	114960	Deleted Prescription 150329A-03010801/14/650 from Patient 03010801/14/650
129154	129152	Y	2015-03-29 10:55:11.736+00	Delete Prescription	114960	Deleted Prescription 150329A-03010801/12/684 from Patient 03010801/12/684
129174	129172	Y	2015-03-29 11:00:43.434+00	Delete Prescription	114960	Deleted Prescription 150329A-03010801/11/310 from Patient 03010801/11/310
129231	129229	Y	2015-03-29 11:19:03.001+00	Delete Prescription	114960	Deleted Prescription 150329A-03010801/15/86 from Patient 03010801/15/86
129262	129260	Y	2015-03-29 11:27:48.447+00	Delete Prescription	114960	Deleted Prescription 150329A-03010801/13/756 from Patient 03010801/13/756
129416	129414	Y	2015-03-29 12:01:34.53+00	Delete Prescription	114960	Deleted Prescription 150327A-03010101/09/751 from Patient 03010101/09/751
129991	129989	Y	2015-04-01 12:06:36.922+00	Delete Prescription	114960	Deleted Prescription 150401A-03010801/12/0148 from Patient 03010801/12/0148
130191	117494	Y	2015-04-01 12:37:00.632+00	Delete Prescription	114960	Deleted Prescription 150302A-03010801/11/878 from Patient 03010801/11/878
130555	117878	Y	2015-04-03 13:44:48.66+00	Delete Prescription	114992	Deleted Prescription 150304A-03010101/06/228 from Patient 03010101/06/228
132113	132110	Y	2015-04-08 09:57:59.88+00	Delete Prescription	114960	Deleted Prescription 150408A-03010801/14/1138 from Patient 03010801/14/1138
132134	132132	Y	2015-04-08 10:04:00.384+00	Delete Prescription	114960	Deleted Prescription 150403A-03010801/14/1353 from Patient 03010801/14/1353
132555	132553	Y	2015-04-08 12:18:45.773+00	Delete Prescription	114960	Deleted Prescription 150403A-03010801/13/1066 from Patient 03010801/13/1066
133523	133521	Y	2015-04-15 09:59:59.781+00	Delete Prescription	1	Deleted Prescription 150401A-03010801/15/272 from Patient 03010801/15/272
134167	134165	Y	2015-04-17 10:46:38.303+00	Delete Prescription	114960	Deleted Prescription 150417A-040108/12/50 from Patient 040108/12/50
138187	129594	Y	2015-04-24 13:24:45.432+00	Delete Prescription	116068	Deleted Prescription 150325A-03010801/10/582 from Patient 03010801/10/582
138428	138426	Y	2015-04-27 10:02:37.79+00	Delete Prescription	114960	Deleted Prescription 150409A-03010101/09/887 from Patient 03010101/09/887
138441	138439	Y	2015-04-27 10:04:22.367+00	Delete Prescription	114960	Deleted Prescription 150409A-03010101/06/959 from Patient 03010101/06/959
138602	138599	Y	2015-04-27 10:47:14.448+00	Delete Prescription	114960	Deleted Prescription 150427A-03010801/12/1191 from Patient 03010801/12/1191
138672	138670	Y	2015-04-27 11:10:18.655+00	Delete Prescription	114960	Deleted Prescription 150427A-03010801/14/593 from Patient 03010801/14/593
138733	138730	Y	2015-04-27 11:20:48.921+00	Delete Prescription	114960	Deleted Prescription 150427A-03010801/12/864 from Patient 03010801/12/864
138768	138764	Y	2015-04-27 11:43:06.338+00	Delete Prescription	114960	Deleted Prescription 150427A-03010101/04/723 from Patient 03010101/04/723
138802	138800	Y	2015-04-27 11:48:27.266+00	Delete Prescription	114960	Deleted Prescription 150409A-03010801/14/308 from Patient 03010801/14/308
139037	139033	Y	2015-04-27 12:39:49.865+00	Delete Prescription	114960	Deleted Prescription 150409A-03010801/11/1239 from Patient 03010801/11/1239
139041	139038	Y	2015-04-27 12:40:37.395+00	Delete Prescription	114960	Deleted Prescription 150409B-03010801/11/1239 from Patient 03010801/11/1239
139060	139058	Y	2015-04-27 12:45:00.548+00	Delete Prescription	114960	Deleted Prescription 150409A-03010801/15/1 from Patient 03010801/15/1
140445	140443	Y	2015-04-29 12:24:54.145+00	Delete Prescription	114992	Deleted Prescription 150429A-03010801/14/616 from Patient 03010801/14/616
140702	120930	Y	2015-04-29 13:05:10.019+00	Delete Prescription	114992	Deleted Prescription 150310A-03010101/13/940 from Patient 03010101/13/940
140889	140886	Y	2015-05-02 12:06:30.409+00	Delete Prescription	114960	Deleted Prescription 150502A-03010801/14/465 from Patient 03010801/14/465
140933	140931	Y	2015-05-02 12:15:14.488+00	Delete Prescription	114960	Deleted Prescription 150427A-03010801/13/1468 from Patient 03010801/13/1468
144074	144073	Y	2015-05-07 11:53:16.008+00	Added New User	1	Added New User Abilio Junior with clinic access CS 1 DE MAIO
146213	146210	Y	2015-05-12 07:51:48.986+00	Delete Prescription	114960	Deleted Prescription 150507A-03010801/10/396 from Patient 03010801/10/396
146217	146214	Y	2015-05-12 07:53:13.686+00	Delete Prescription	114960	Deleted Prescription 150512A-03010801/10/396 from Patient 03010801/10/396
152901	152899	Y	2016-08-09 13:39:09.984+00	Delete Prescription	1	Deleted Prescription 160809A-04050301/09/0347 from Patient 04050301/09/0347
152904	152902	Y	2016-08-09 14:26:41.924+00	Delete Prescription	1	Deleted Prescription 160809B-04050301/09/0347 from Patient 04050301/09/0347
\.


--
-- Data for Name: messageschedule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY messageschedule (id, description, messagetype, scheduledate, daystoschedule, scheduledsuccessfully, senttoalerts, messagenumber, language) FROM stdin;
\.


--
-- Data for Name: motivomudanca; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY motivomudanca (idmotivo, motivo, active) FROM stdin;
39994	Alergia NVP	t
39995	Anemia	t
39996	Anemia (A)	t
39997	Falencia terapeutica (FT)	t
39998	Fim de tto TB	t
39999	Gravidez (Gr)	t
40000	Inicio de tto TB	t
40001	Outras	t
40002	Tuberculose (TB)	t
\.


--
-- Data for Name: nationalclinics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY nationalclinics (id, province, district, subdistrict, facilityname, facilitytype) FROM stdin;
25	NAMPULA	CIDADE DE NAMPULA		CS 1 DE MAIO	CS
\.


--
-- Data for Name: package; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY package (id, dateleft, datereceived, modified, packageid, packdate, pickupdate, prescription, weekssupply, datereturned, stockreturned, packagereturned, reasonforpackagereturn, clinic, drugtypes) FROM stdin;
152706	2016-06-09 08:09:51.011+00	2016-06-09 08:09:51.011+00	T	160609A-04070601/15/0107-1	2016-06-09 08:09:51.011+00	2016-06-09 08:09:51.011+00	152694	4	\N	f	f	\N	2	ARV
152713	2016-06-09 08:47:57.005+00	2016-06-09 08:47:57.005+00	T	160609B-04070601/15/0107-1	2016-06-09 08:47:57.005+00	2016-06-09 08:47:57.005+00	152711	4	\N	f	f	\N	2	ARV
152740	2016-06-09 11:28:34.118+00	2016-06-09 11:28:34.118+00	T	160609B-04030201/15/0017-1	2016-06-09 11:28:34.118+00	2016-06-09 11:28:34.118+00	152738	4	\N	f	f	\N	2	ARV
152753	2016-06-14 07:49:04.295+00	2016-06-14 07:49:04.295+00	T	160614A-04020101/10/0300-1	2016-06-14 07:49:04.295+00	2016-06-14 07:49:04.295+00	152751	4	\N	f	f	\N	2	ARV
152767	2016-06-14 08:43:21.885+00	2016-06-14 08:43:21.885+00	T	160614A-04070601/15/0104-1	2016-06-14 08:43:21.885+00	2016-06-14 08:43:21.885+00	152765	4	\N	f	f	\N	2	ARV
152783	2016-08-04 23:18:36.491+00	2016-08-04 23:18:36.491+00	T	160609B-04030201/15/0017-2	2016-08-04 23:18:36.491+00	2016-08-04 23:18:36.491+00	152738	4	\N	f	f	\N	2	ARV
152794	2016-08-04 23:29:40.118+00	2016-08-04 23:29:40.118+00	T	160805A-04030201/15/0049-1	2016-08-04 23:29:40.118+00	2016-08-04 23:29:40.118+00	152792	4	\N	f	f	\N	2	ARV
152805	2016-08-04 23:42:49.004+00	2016-08-04 23:42:49.004+00	T	160805A-04030201/15/0051-1	2016-08-04 23:42:49.004+00	2016-08-04 23:42:49.004+00	152803	4	\N	f	f	\N	2	ARV
152812	2016-08-04 23:47:03.116+00	2016-08-04 23:47:03.116+00	T	160805A-04030201/15/0021-1	2016-08-04 23:47:03.116+00	2016-08-04 23:47:03.116+00	152810	4	\N	f	f	\N	2	ARV
152820	2016-08-04 23:47:58.18+00	2016-08-04 23:47:58.18+00	T	160805A-04030201/15/0017-1	2016-08-04 23:47:58.18+00	2016-08-04 23:47:58.18+00	152818	4	\N	f	f	\N	2	ARV
152826	2016-08-04 23:49:18.01+00	2016-08-04 23:49:18.01+00	T	160805B-04030201/15/0017-1	2016-08-04 23:49:18.01+00	2016-08-04 23:49:18.01+00	152824	4	\N	f	f	\N	2	ARV
152836	2016-08-04 23:51:36.294+00	2016-08-04 23:51:36.294+00	T	160805A-04030201/15/0055-1	2016-08-04 23:51:36.294+00	2016-08-04 23:51:36.294+00	152834	4	\N	f	f	\N	2	ARV
152843	2016-08-04 23:53:29.92+00	2016-08-04 23:53:29.92+00	T	160805B-04030201/15/0055-1	2016-08-04 23:53:29.92+00	2016-08-04 23:53:29.92+00	152841	4	\N	f	f	\N	2	ARV
152847	2016-08-04 23:53:55.53+00	2016-08-04 23:53:55.53+00	T	160805B-04030201/15/0055-2	2016-08-04 23:53:55.53+00	2016-08-04 23:53:55.53+00	152841	4	\N	f	f	\N	2	ARV
152855	2016-08-05 00:00:24.236+00	2016-08-05 00:00:24.236+00	T	160805B-04030201/15/0055-3	2016-08-05 00:00:24.236+00	2016-08-05 00:00:24.236+00	152841	4	\N	f	f	\N	2	ARV
152859	2016-08-05 00:03:04.174+00	2016-08-05 00:03:04.174+00	T	160805B-04030201/15/0055-4	2016-08-05 00:03:04.174+00	2016-08-05 00:03:04.174+00	152841	4	\N	f	f	\N	2	ARV
152863	2016-08-05 00:05:48.965+00	2016-08-05 00:05:48.965+00	T	160805A-04030201/15/0049-2	2016-08-05 00:05:48.965+00	2016-08-05 00:05:48.965+00	152792	4	\N	f	f	\N	2	ARV
152867	2016-08-09 07:56:11.561+00	2016-08-09 07:56:11.561+00	T	160609A-04030201/15/0020-1	2016-08-09 07:56:11.561+00	2016-08-09 07:56:11.561+00	152736	4	\N	f	f	\N	2	ARV
152875	2016-08-09 09:07:19.703+00	2016-08-09 09:07:19.703+00	T	160609A-04030201/15/0020-2	2016-08-09 09:07:19.703+00	2016-08-09 09:07:19.703+00	152736	4	\N	f	f	\N	2	ARV
152911	2016-08-09 14:31:41.334+00	2016-08-09 14:31:41.334+00	T	160809C-04050301/09/0347-1	2016-08-09 14:31:41.334+00	2016-08-09 14:31:41.334+00	152905	4	\N	f	f	\N	2	ARV
152916	2016-08-09 14:33:40.968+00	2016-08-09 14:33:40.968+00	T	160809C-04050301/09/0347-2	2016-08-09 14:33:40.968+00	2016-08-09 14:33:40.968+00	152905	4	\N	f	f	\N	2	ARV
152922	2016-08-09 14:39:12.45+00	2016-08-09 14:39:12.45+00	T	160809D-04050301/09/0347-1	2016-08-09 14:39:12.45+00	2016-08-09 14:39:12.45+00	152920	4	\N	f	f	\N	2	ARV
152926	2016-08-09 14:41:37.251+00	2016-08-09 14:41:37.251+00	T	160809D-04050301/09/0347-2	2016-08-09 14:41:37.251+00	2016-08-09 14:41:37.251+00	152920	4	\N	f	f	\N	2	ARV
\.


--
-- Data for Name: packageddrugs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY packageddrugs (id, amount, stock, parentpackage, modified, packageddrugsindex) FROM stdin;
152707	60	152690	152706	T	0
152714	60	152690	152713	T	0
152741	60	152690	152740	T	0
152754	60	152690	152753	T	0
152768	60	152690	152767	T	0
152784	60	152774	152783	T	0
152795	60	152774	152794	T	0
152806	60	152774	152805	T	0
152813	30	152692	152812	T	0
152821	60	152774	152820	T	0
152827	60	152774	152826	T	0
152837	60	152774	152836	T	0
152844	60	152774	152843	T	0
152848	60	152774	152847	T	0
152856	60	152851	152855	T	0
152860	60	152851	152859	T	0
152864	60	152851	152863	T	0
152868	60	152851	152867	T	0
152876	60	152851	152875	T	0
152912	60	152851	152911	T	0
152917	60	152851	152916	T	0
152923	60	152851	152922	T	0
152927	60	152851	152926	T	0
\.


--
-- Data for Name: packagedruginfotmp; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY packagedruginfotmp (id, amountpertime, batchnumber, clinic, dispensedate, dispensedqty, drugname, expirydate, formlanguage1, formlanguage2, formlanguage3, notes, packageindex, patientid, patientfirstname, specialinstructions1, specialinstructions2, stockid, timesperday, cluser, weekssupply, sidetreatment, packageddrug, invalid, qtyinhand, summaryqtyinhand, qtyinlastbatch, patientlastname, prescriptionduration, dateexpectedstring, senttoekapa, packageid, firstbatchinprintjob, numberoflabels, dispensedforlaterpickup, pickupdate) FROM stdin;
152709	1	34344	HR Alto Molocue	2016-06-09 08:09:51.011+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2029-12-31 22:00:00+00	Comp				1	04070601/15/0107	Ana Andrade			152690	2	1	4	f	152707	f	(60)	(60)	(60)	Catarina	4	07 Jul 2016	f	160609A-04070601/15/0107-1	t	1	f	2016-06-09 08:09:52.222+00
152715	1	34344	HR Alto Molocue	2016-06-09 08:47:57.005+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2029-12-31 22:00:00+00	Comp				1	04070601/15/0107	Ana Andrade			152690	2	1	4	f	152714	f	(60)	(60)	(60)	Catarina	4	07 Jul 2016	f	160609B-04070601/15/0107-1	t	1	f	2016-06-09 08:48:05.553+00
152743	1	34344	HR Alto Molocue	2016-06-09 11:28:34.118+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2029-12-31 22:00:00+00	Comp				1	04030201/15/0017	Zinedine			152690	2	1	4	f	152741	f	(60)	(60)	(60)	Zidane	4	07 Jul 2016	f	160609B-04030201/15/0017-1	t	1	f	2016-06-09 11:29:31.983+00
152757	1	34344	HR Alto Molocue	2016-06-14 07:49:04.295+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2029-12-31 22:00:00+00	Comp				1	04020101/10/0300	Joana			152690	2	1	4	f	152754	f	(60)	(60)	(60)	Paulo	4	12 Jul 2016	f	160614A-04020101/10/0300-1	t	1	f	2016-06-14 07:49:36.151+00
152771	1	34344	HR Alto Molocue	2016-06-14 08:43:21.885+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2029-12-31 22:00:00+00	Comp				1	04070601/15/0104	Laura			152690	2	1	4	f	152768	f	(60)	(60)	(60)	Nacapa	4	12 Jul 2016	f	160614A-04070601/15/0104-1	t	1	f	2016-06-14 08:43:25.368+00
152786	1	343444	HR Alto Molocue	2016-08-04 23:18:36.491+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2058-01-31 22:00:00+00	Comp				2	04030201/15/0017	Zinedine			152774	2	1	4	f	152784	f	(60)	(60)	(60)	Zidane	4	02 Sep 2016	f	160609B-04030201/15/0017-2	t	1	f	2016-08-04 23:18:38.054+00
152797	1	343444	HR Alto Molocue	2016-08-04 23:29:40.118+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2058-01-31 22:00:00+00	Comp				1	04030201/15/0049	Teste Registo			152774	2	1	4	f	152795	f	(60)	(60)	(60)	Paciente	4	02 Sep 2016	f	160805A-04030201/15/0049-1	t	1	f	2016-08-04 23:29:45.689+00
152808	1	343444	HR Alto Molocue	2016-08-04 23:42:49.004+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2058-01-31 22:00:00+00	Comp				1	04030201/15/0051	openmrs			152774	2	1	4	f	152806	f	(60)	(60)	(60)	only	4	02 Sep 2016	f	160805A-04030201/15/0051-1	t	1	f	2016-08-04 23:42:51.626+00
152816	1	445555	HR Alto Molocue	2016-08-04 23:47:03.116+00	30	[3TC/AZT/NVP] Lamivudina 30mg/Zidovudina 60mg/Nevirapina 50mg	2043-04-30 22:00:00+00	Comp				1	04030201/15/0021	Ronaldinho			152692	1	1	4	f	152813	f	(30)	(30)	(30)	Gaucho	4	02 Sep 2016	f	160805A-04030201/15/0021-1	t	1	f	2016-08-04 23:47:12.762+00
152822	1	343444	HR Alto Molocue	2016-08-04 23:47:58.18+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2058-01-31 22:00:00+00	Comp				1	04030201/15/0017	Zinedine			152774	2	1	4	f	152821	f	(60)	(60)	(60)	Zidane	4	02 Sep 2016	f	160805A-04030201/15/0017-1	t	1	f	2016-08-04 23:48:26.193+00
152828	1	343444	HR Alto Molocue	2016-08-04 23:49:18.01+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2058-01-31 22:00:00+00	Comp				1	04030201/15/0017	Zinedine			152774	2	1	4	f	152827	f	(60)	(60)	(60)	Zidane	4	02 Sep 2016	f	160805B-04030201/15/0017-1	t	1	f	2016-08-04 23:49:22.954+00
152839	1	343444	HR Alto Molocue	2016-08-04 23:51:36.294+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2058-01-31 22:00:00+00	Comp				1	04030201/15/0055	teste			152774	2	1	4	f	152837	f	(60)	(60)	(60)	teste	4	02 Sep 2016	f	160805A-04030201/15/0055-1	t	1	f	2016-08-04 23:51:41.313+00
152845	1	343444	HR Alto Molocue	2016-08-04 23:53:29.92+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2058-01-31 22:00:00+00	Comp				1	04030201/15/0055	teste			152774	2	1	4	f	152844	f	(60)	(60)	(60)	teste	4	02 Sep 2016	f	160805B-04030201/15/0055-1	t	1	f	2016-08-04 23:53:32.649+00
152849	1	343444	HR Alto Molocue	2016-08-04 23:53:55.53+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2058-01-31 22:00:00+00	Comp				2	04030201/15/0055	teste			152774	2	1	4	f	152848	f	(60)	(60)	(60)	teste	4	02 Sep 2016	f	160805B-04030201/15/0055-2	t	1	f	2016-08-04 23:53:59.449+00
152857	1	45455	HR Alto Molocue	2016-08-05 00:00:24.236+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2055-08-31 22:00:00+00	Comp				3	04030201/15/0055	teste			152851	2	1	4	f	152856	f	(60)	(60)	(60)	teste	4	02 Sep 2016	f	160805B-04030201/15/0055-3	t	1	f	2016-08-05 00:00:25.727+00
152861	1	45455	HR Alto Molocue	2016-08-05 00:03:04.174+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2055-08-31 22:00:00+00	Comp				4	04030201/15/0055	teste			152851	2	1	4	f	152860	f	(60)	(60)	(60)	teste	4	02 Sep 2016	f	160805B-04030201/15/0055-4	t	1	f	2016-08-05 00:03:08.766+00
152865	1	45455	HR Alto Molocue	2016-08-05 00:05:48.965+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2055-08-31 22:00:00+00	Comp				2	04030201/15/0049	Teste Registo			152851	2	1	4	f	152864	f	(60)	(60)	(60)	Paciente	4	02 Sep 2016	f	160805A-04030201/15/0049-2	t	1	f	2016-08-05 00:05:50.533+00
152870	1	45455	HR Alto Molocue	2016-08-09 07:56:11.561+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2055-08-31 22:00:00+00	Comp				1	04030201/15/0020	Cristiano			152851	2	1	4	f	152868	f	(60)	(60)	(60)	Ronaldo	4	06 Sep 2016	f	160609A-04030201/15/0020-1	t	1	f	2016-08-09 07:56:16.875+00
152877	1	45455	HR Alto Molocue	2016-08-09 09:07:19.703+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2055-08-31 22:00:00+00	Comp				2	04030201/15/0020	Cristiano			152851	2	1	4	f	152876	f	(60)	(60)	(60)	Ronaldo	4	06 Sep 2016	f	160609A-04030201/15/0020-2	t	1	f	2016-08-09 09:07:26.127+00
152914	1	45455	HR Alto Molocue	2016-08-09 14:31:41.334+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2055-08-31 22:00:00+00	Comp				1	04050301/09/0347	pascal			152851	2	1	4	f	152912	f	(60)	(60)	(60)	brandt	4	06 Sep 2016	f	160809C-04050301/09/0347-1	t	1	f	2016-08-09 14:31:42.92+00
152918	1	45455	HR Alto Molocue	2016-08-09 14:33:40.968+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2055-08-31 22:00:00+00	Comp				2	04050301/09/0347	pascal			152851	2	1	4	f	152917	f	(60)	(60)	(60)	brandt	4	06 Sep 2016	f	160809C-04050301/09/0347-2	t	1	f	2016-08-09 14:33:43.115+00
152924	1	45455	HR Alto Molocue	2016-08-09 14:39:12.45+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2055-08-31 22:00:00+00	Comp				1	04050301/09/0347	pascal			152851	2	1	4	f	152923	f	(60)	(60)	(60)	brandt	4	06 Sep 2016	f	160809D-04050301/09/0347-1	t	1	f	2016-08-09 14:39:23.776+00
152928	1	45455	HR Alto Molocue	2016-08-09 14:41:37.251+00	60	[3TC/AZT/NVP] Lamivudina 150mg/Zidovudina 300mg/Nevirapina 200mg	2055-08-31 22:00:00+00	Comp				2	04050301/09/0347	pascal			152851	2	1	4	f	152927	f	(60)	(60)	(60)	brandt	4	06 Sep 2016	f	160809D-04050301/09/0347-2	t	1	f	2016-08-09 14:41:42.557+00
\.


--
-- Data for Name: patient; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY patient (id, accountstatus, cellphone, dateofbirth, clinic, firstnames, homephone, lastname, modified, patientid, province, sex, workphone, address1, address2, address3, nextofkinname, nextofkinphone, race) FROM stdin;
152685	t	829087657	1991-09-20 22:00:00+00	2	Ana Andrade		Catarina	T	04070601/15/0107		F							\N
152717	t		1987-06-16 22:00:00+00	2	teste		misau	T	04070601/15/0108	Select a Province	M							\N
152720	t	823098765	1978-06-13 22:00:00+00	2	Zinedine		Zidane	T	04030201/15/0017	Select a Province	M							\N
152726	t	823076543	1975-06-24 22:00:00+00	2	Zlatan		Ibrahimovic	T	04030201/15/0018	Select a Province	M							\N
152732	t	843067987	1998-06-16 22:00:00+00	2	Cristiano		Ronaldo	T	04030201/15/0020	Select a Province	M							\N
152745	t		1968-06-10 22:00:00+00	2	Ronaldinho		Gaucho	T	04030201/15/0021	Select a Province	M							\N
152748	t		1979-06-30 22:00:00+00	2	Joana		Paulo	T	04020101/10/0300	Select a Province	F							\N
152762	t		1987-06-11 22:00:00+00	2	Laura		Nacapa	T	04070601/15/0104	Select a Province	F							\N
152788	t	829091879	1983-11-22 22:00:00+00	2	Teste Registo		Paciente	T	04030201/15/0049	Select a Province	M							\N
152799	t	829091879	1983-11-22 22:00:00+00	2	openmrs		only	T	04030201/15/0051	Select a Province	M							\N
152830	t	829091879	1985-09-22 22:00:00+00	2	teste		teste	T	04030201/15/0055	Select a Province	F							\N
152872	t		1983-11-22 22:00:00+00	2	ucsf		test	T	04020101/07/01701	Select a Province	M							\N
152879	t	829091879	\N	2	ucsf1		teste1	T	04020101/07/01700	Select a Province	M							\N
152883	t	829091879	\N	2	Helio		Machabane	T	04020101/07/01702	Select a Province	M							\N
152887	t	829091879	\N	2	Helio_1		Machabane_1	T	04020101/07/01703	Select a Province	M							\N
152895	t	123	\N	2	pascal		brandt	T	04050301/09/0347	Select a Province	M							\N
\.


--
-- Data for Name: patientattribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY patientattribute (id, value, patient, type_id) FROM stdin;
152686	18 Jun 2009	152685	1
152721	14 Jun 2007	152720	1
152727	12 Jun 2009	152726	1
152733	16 Jun 2007	152732	1
152755	14 Jun 2016	152748	1
152769	14 Jun 2016	152762	1
152789	23 Aug 2012	152788	1
152800	23 Aug 2001	152799	1
152814	05 Aug 2016	152745	1
152831	13 Aug 2009	152830	1
152880	15 Aug 2013	152879	1
152884	21 Aug 2013	152883	1
152888	13 Aug 2014	152887	1
152896	02 Aug 2015	152895	1
\.


--
-- Data for Name: patientidentifier; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY patientidentifier (id, value, patient_id, type_id) FROM stdin;
152688	04070601/15/0107	152685	0
152689	04050301/09/0345	152685	0
152719	04070601/15/0108	152717	0
152723	04030201/15/0017	152720	0
152729	04030201/15/0018	152726	0
152735	04030201/15/0020	152732	0
152747	04030201/15/0021	152745	0
152750	04020101/10/0300	152748	0
152764	04070601/15/0104	152762	0
152791	04030201/15/0049	152788	0
152802	04030201/15/0051	152799	0
152833	04030201/15/0055	152830	0
152874	04020101/07/01701	152872	0
152882	04020101/07/01700	152879	0
152886	04020101/07/01702	152883	0
152890	04020101/07/01703	152887	0
152898	04050301/09/0347	152895	0
\.


--
-- Data for Name: patientstatistic; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY patientstatistic (id, entry_id, patient_id, datetested, daterecorded, patientstattype_id, statnumeric, stattext, statdate) FROM stdin;
\.


--
-- Data for Name: patientstattypes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY patientstattypes (id, statname, statformat) FROM stdin;
1	CD4 Count	N
2	Viral Load	N
3	CD4 Percentage	N
4	ALT	C
\.


--
-- Data for Name: patientvisit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY patientvisit (id, patient_id, dateofvisit, isscheduled, patientvisitreason_id, diagnosis, notes) FROM stdin;
152708	152685	2016-06-09	Y	5		Scheduled Visit to Receive Package
152742	152720	2016-06-09	Y	5		Scheduled Visit to Receive Package
152756	152748	2016-06-14	Y	5		Scheduled Visit to Receive Package
152770	152762	2016-06-14	Y	5		Scheduled Visit to Receive Package
152785	152720	2016-08-05	Y	5		Scheduled Visit to Receive Package
152796	152788	2016-08-05	Y	5		Scheduled Visit to Receive Package
152807	152799	2016-08-05	Y	5		Scheduled Visit to Receive Package
152815	152745	2016-08-05	Y	5		Scheduled Visit to Receive Package
152838	152830	2016-08-05	Y	5		Scheduled Visit to Receive Package
152869	152732	2016-08-09	Y	5		Scheduled Visit to Receive Package
152913	152895	2016-08-09	Y	5		Scheduled Visit to Receive Package
\.


--
-- Data for Name: patientvisitreason; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY patientvisitreason (id, reasonforvisit) FROM stdin;
5	Scheduled Visit
6	Not Feeling Well
7	Counselling
8	Advice
9	Other
\.


--
-- Data for Name: pillcount; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY pillcount (id, accum, previouspackage, dateofcount, drug) FROM stdin;
\.


--
-- Data for Name: pregnancy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY pregnancy (id, confirmdate, enddate, patient, modified) FROM stdin;
\.


--
-- Data for Name: prescribeddrugs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY prescribeddrugs (id, amtpertime, drug, prescription, timesperday, modified, prescribeddrugsindex) FROM stdin;
152695	1	41291	152694	2	T	0
152712	1	41291	152711	2	T	0
152725	1	41291	152724	2	T	0
152731	1	41291	152730	2	T	0
152737	1	41291	152736	2	T	0
152739	1	41291	152738	2	T	0
152752	1	41291	152751	2	T	0
152766	1	41291	152765	2	T	0
152793	1	41291	152792	2	T	0
152804	1	41291	152803	2	T	0
152811	1	41210	152810	1	T	0
152819	1	41291	152818	2	T	0
152825	1	41291	152824	2	T	0
152835	1	41291	152834	2	T	0
152842	1	41291	152841	2	T	0
152906	1	41291	152905	2	T	0
152921	1	41291	152920	2	T	0
\.


--
-- Data for Name: prescription; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY prescription (id, clinicalstage, current, date, doctor, duration, modified, patient, prescriptionid, weight, reasonforupdate, notes, enddate, drugtypes, regimeid, datainicionoutroservico, motivomudanca, linhaid, ppe, ptv, tb, tpi, tpc) FROM stdin;
152711	0	T	2016-06-09 08:47:55.389+00	36748	4	T	152685	160609B-04070601/15/0107	0	Manter		\N	ARV	41094	\N		40323	F	F	F	F	F
152694	0	F	2016-06-09 07:58:14.01+00	36748	4	T	152685	160609A-04070601/15/0107	0	Manter		2016-06-09 08:47:55.389+00	ARV	41094	\N		40323	F	F	F	F	F
152730	0	T	2016-06-09 10:06:59.384+00	36748	4	T	152726	160609A-04030201/15/0018	0	Manter		\N	ARV	41094	\N		40323	F	F	F	F	F
152736	0	T	2016-06-09 10:07:47.199+00	36748	4	T	152732	160609A-04030201/15/0020	0	Manter		\N	ARV	41094	\N		40323	F	F	F	F	F
152724	0	F	2016-06-09 10:06:00.584+00	36748	4	T	152720	160609A-04030201/15/0017	0	Manter		2016-06-09 10:13:17.591+00	ARV	41094	\N		40323	F	F	F	F	F
152751	0	T	2016-06-14 07:49:02.701+00	36748	4	T	152748	160614A-04020101/10/0300	0	Manter		\N	ARV	41094	\N		40323	F	F	F	F	F
152765	0	T	2016-06-14 08:43:20.582+00	36748	4	T	152762	160614A-04070601/15/0104	0	Manter		\N	ARV	41094	\N		40323	F	F	F	F	F
152792	0	T	2016-08-04 23:29:38.62+00	36748	4	T	152788	160805A-04030201/15/0049	0	Manter		\N	ARV	41094	\N		40323	F	F	F	F	F
152803	0	T	2016-08-04 23:42:47.557+00	36748	4	T	152799	160805A-04030201/15/0051	0	Manter		\N	ARV	41094	\N		40323	F	F	F	F	F
152810	0	T	2016-08-04 23:47:01.917+00	36749	4	T	152745	160805A-04030201/15/0021	0	Manter		\N	ARV	41094	\N		40323	F	F	F	F	F
152738	0	F	2016-06-09 10:13:17.591+00	36748	4	T	152720	160609B-04030201/15/0017	0	Manter		2016-08-04 23:47:57.052+00	ARV	41094	\N		40323	F	F	F	F	F
152824	0	T	2016-08-04 23:49:16.652+00	36749	4	T	152720	160805B-04030201/15/0017	0	Manter		\N	ARV	41094	\N		40323	F	F	F	F	F
152818	0	F	2016-08-04 23:47:57.052+00	36748	4	T	152720	160805A-04030201/15/0017	0	Manter		2016-08-04 23:49:16.652+00	ARV	41094	\N		40323	F	F	F	F	F
152841	0	T	2016-08-04 23:53:28.844+00	36748	4	T	152830	160805B-04030201/15/0055	0	Manter		\N	ARV	41094	\N		40323	F	F	F	F	F
152834	0	F	2016-08-04 23:51:34.98+00	36749	4	T	152830	160805A-04030201/15/0055	0	Manter		2016-08-04 23:53:28.844+00	ARV	41094	\N		40323	F	F	F	F	F
152920	0	T	2016-08-09 14:39:11.181+00	36748	4	T	152895	160809D-04050301/09/0347	0	Manter		\N	ARV	41096	\N		40324	F	F	F	F	F
152905	0	F	2016-08-09 14:26:35.438+00	36748	4	T	152895	160809C-04050301/09/0347	0	Manter		2016-08-09 14:39:11.181+00	ARV	41094	\N		40323	F	F	F	F	F
\.


--
-- Data for Name: regimen; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY regimen (id, modified, notes, regimenname, druggroup) FROM stdin;
40187	T		grp1	1A
\.


--
-- Data for Name: regimendrugs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY regimendrugs (id, amtpertime, drug, modified, regimen, timesperday, notes, regimendrugsindex) FROM stdin;
\.


--
-- Data for Name: regimeterapeutico; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY regimeterapeutico (regimeid, regimeesquema, active, pediatrico, regimenomeespecificado) FROM stdin;
41094	AZT+3TC+NVP	t	F	ZIDOVUDINE+LAMIVUDINE+NEVIRAPINE
41095	TDF+3TC+EFV	t	F	TDF+3TC+EFV
41096	AZT+3TC+EFV	t	F	ZIDOVUDINA+LAMIVUDINA+EFAVIRENZ
152773	AZT+3TC+LPV/r	t	F	ZIDOVUDINA+LAMIVUDINA+LOPINAVIR
152760	D4T+3TC+ABC	t	T	STAVUDINA+LAMIVUDINA+ABACAVIR
152761	D4T+3TC+NVP	t	T	STAVUDINA+LAMIVUDINA+NEVIRAPINA
152762	D4T+3TC+LPV/r	t	T	STAVUDINA+LAMIVUDINA+LOPINAVIR
152763	D4T+3TC+EFV	t	T	STAVUDINE+LAMIVUDINE+EFAVIRENNZ
152764	D4T 6+3TC+NVP (Triomune Baby)	t	T	D4T 6+3TC+NVP
152765	ABC+3TC+NVP	t	T	ABACAVIR+LAMIVUDINA+NEVIRAPINA
152766	AZT+3TC+ABC	t	T	AZT+3TC+ABC1
152767	D4T+3TC+ABC+LPV/r (2ª Linha)	t	T	D4T+3TC+ABC+LPVr
152768	AZT+3TC+ABC+LPV/r (2ª Linha)	t	T	AZT+3TC+ABC+LPV/r
152769	D4T+3TC+ABC+EFV (2ª Linha)	t	T	D4T+3TC+ABC+EFV
152770	AZT+3TC+ABC+EFV (2ª Linha)	t	T	AZT+3TC+ABC+EFV
152771	AZT+DDI+LPV/r	t	T	ZIDOVUDINA+DADINOSE+LOPINAVIR
152772	TDF+3TC+RAL+DRV/r (3ª Linha)	t	T	TDF+3TC+RAL+DRV/r
41093	TDF+3TC+NVP	t	T	TENOFOVIRA+ZIDOVUDINA+NEVIRAPINA
152774	ABC+3TC+EFV	t	T	ABACAVIR+LAMIVUDINA+EFAVIRENZ
152775	ABC+3TC+LPV/r	t	T	ABACAVIR+LAMIVUDINA+LOPINAVIR
152776	TDF+3TC+LPV/r (2ª Linha)	t	T	TENOFOVIR+LAMIVUDINA+LOPINAVIR
152777	AZT+3TC+LPV/r (2ª Linha)	t	T	AZT+3TC+LPV (2 Linha)
152778	ABC+3TC+LPV/r (2ª Linha)	t	T	ABC+3TC+LPV/r (2 Linha)
152779	AZT+3TC+RAL+DRV/r (3ª Linha)	t	T	AZT+3TC+RAL+DRVr
152780	OUTRO	t	T	OUTRO MEDICAMENTO ANTI-RETROVIRAL
\.


--
-- Data for Name: registadosnoidart; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY registadosnoidart (nid, nomes, apelido, dataderegisto) FROM stdin;
04070601/15/0107	Ana Andrade	Catarina	2016-06-09
04070601/15/0107	Ana Andrade	Catarina	2016-06-09
04070601/15/0108	teste	misau	2016-06-09
04030201/15/0017	Zinedine	Zidane	2016-06-09
04030201/15/0018	Zlatan	Ibrahimovic	2016-06-09
04030201/15/0020	Cristiano	Ronaldo	2016-06-09
04030201/15/0021	Ronaldinho	Gaucho	2016-06-09
04020101/10/0300	Joana	Paulo	2016-06-13
04070601/15/0104			2016-06-14
04070601/15/0104	Laura	Nacapa	2016-06-14
04030201/15/0049	Teste Registo	Paciente	2016-08-05
04030201/15/0051	openmrs	only	2016-08-05
04030201/15/0055	teste	teste	2016-08-05
04020101/07/01701	ucsf	test	2016-08-09
04020101/07/01700	ucsf1	teste1	2016-08-09
04020101/07/01702	Helio	Machabane	2016-08-09
04020101/07/01703	Helio_1	Machabane_1	2016-08-09
04020101/07/01702	Helio	Machabane	2016-08-09
04050301/09/0347	pascal	brandt	2016-08-09
04050301/09/0347	pascal	brandt	2016-08-09
\.


--
-- Data for Name: simpledomain; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY simpledomain (id, description, name, value) FROM stdin;
1	WHO Clinical Stage 1	clinical_stage	1
2	WHO Clinical Stage 2	clinical_stage	2
3	WHO Clinical Stage 3	clinical_stage	3
4	WHO Clinical Stage 4	clinical_stage	4
40		activation_reason	Re-referred In
41		activation_reason	Referred In
43		activation_reason	Restart at Down Referral Clinic
44		activation_reason	Start at Down Referral Clinic
48		activation_reason	Up Referred
49		activation_reason	Visitor In
52		deactivation_reason	Defaulted
53		deactivation_reason	Down Referred
54		deactivation_reason	Lost to Follow Up
56		deactivation_reason	Re-referred Out
57		deactivation_reason	Referred Out
59		deactivation_reason	Stopped ART by Clinician
62		deactivation_reason	Visitor Out
67	pharmacy_detail	pharmacist	Demo Pharmacist, B.Pharm
68	pharmacy_detail	assistant_pharmacist	Demo Pharmacist2, B.Pharm
72	pharmacy_detail	pharmacy_contact_no	Tel
73	Regimen 1A	regimen	1A
74	Regimen 1B	regimen	1B
75	Regimen 2	regimen	2
76	Mixed Regimen	regimen	Mixed
77	Regimen 1C	regimen	1C
78	Regimen 1D	regimen	1D
79	\N	reason_for_update	Manter
80	\N	reason_for_update	Transfer de
15		reason_for_update	Alterar
28		reason_for_update	Reiniciar
29	\N	reason_for_update	Inicia
30		prescriptionDuration	1 semana
31		prescriptionDuration	2 semanas
32		prescriptionDuration	1 mes
33		prescriptionDuration	2 meses
34		prescriptionDuration	3 meses
35		prescriptionDuration	4 meses
36		prescriptionDuration	5 meses
37		prescriptionDuration	6 meses
66	Package Return Reason	packageReturnReason	Falta no Levantamento
65	Package Return Reason	packageReturnReason	Frasco perdido no transito
64	Package Return Reason	packageReturnReason	Mudança de Medicamentos
63	Package Return Reason	packageReturnReason	Já não recebe mais tratamento na US
69	pharmacy_detail	pharmacy_name	Unidade Sanitária
39		activation_reason	Novo Paciente
42		activation_reason	Reinicio TARV
45		activation_reason	Inicio PPE
58		deactivation_reason	Fim PPE
60		deactivation_reason	Transferido Para
46		activation_reason	Transferido de
47		activation_reason	Desconhecido
50		activation_reason	Outro
51		deactivation_reason	Obito
61		deactivation_reason	Desconhecido
71	pharmacy_detail	pharmacy_city	Cidade
70	pharmacy_detail	pharmacy_street	Av./Rua
55		deactivation_reason	Outro
\.


--
-- Data for Name: stock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY stock (id, drug, batchnumber, datereceived, stockcenter, expirydate, modified, shelfnumber, unitsreceived, manufacturer, hasunitsremaining, unitprice) FROM stdin;
152692	41210	445555	2016-06-08 22:00:00+00	42112	2043-04-30 22:00:00+00	T	0	5	USA	T	\N
152690	41291	34344	2016-06-08 22:00:00+00	42112	2029-12-31 22:00:00+00	T	0	5	USA	F	\N
152774	41291	343444	2016-08-04 22:00:00+00	42112	2058-01-31 22:00:00+00	T	0	343444	USA	T	\N
152851	41291	45455	2016-08-04 22:00:00+00	42112	2055-08-31 22:00:00+00	T	34343	10000	USA	T	\N
152853	41210	fvfvf	2016-08-04 22:00:00+00	42112	2062-02-28 22:00:00+00	T	0	10000	USA	T	\N
\.


--
-- Data for Name: stockadjustment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY stockadjustment (id, capturedate, stock, notes, stocktake, stockcount, adjustedvalue, finalised) FROM stdin;
\.


--
-- Data for Name: stockcenter; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY stockcenter (id, stockcentername, preferred) FROM stdin;
1	Main	f
42112	HR Alto Molocue	t
\.


--
-- Data for Name: stocklevel; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY stocklevel (id, batch, fullcontainersremaining, loosepillsremaining) FROM stdin;
152693	152692	4	30
152775	152774	343436	0
152854	152853	10000	0
152852	152851	9991	0
\.


--
-- Data for Name: stocktake; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY stocktake (id, enddate, startdate, stocktakenumber, open) FROM stdin;
\.


--
-- Data for Name: study; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY study (id, studyname) FROM stdin;
\.


--
-- Data for Name: studyparticipant; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY studyparticipant (id, studygroup, startdate, enddate, patient, study, randomizationid, alternatecellphone, network, language) FROM stdin;
\.


--
-- Data for Name: sync_temp_dispense; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY sync_temp_dispense (nid, ultimo_levantamento) FROM stdin;
\.


--
-- Data for Name: sync_temp_patients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY sync_temp_patients (nid, datanasc, pnomes, unomes, sexo, dataabertura) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY users (id, modified, cl_password, role, cl_username, permission) FROM stdin;
1	T	123	Pharmacist	admin	A
\.


--
-- Name: accumulateddrugs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY accumulateddrugs
    ADD CONSTRAINT accumulateddrugs_pkey PRIMARY KEY (id);


--
-- Name: adherencerecordtmp_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY adherencerecordtmp
    ADD CONSTRAINT adherencerecordtmp_pkey PRIMARY KEY (id);


--
-- Name: alternatepatientidentifier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alternatepatientidentifier
    ADD CONSTRAINT alternatepatientidentifier_pkey PRIMARY KEY (id);


--
-- Name: appointment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY appointment
    ADD CONSTRAINT appointment_pkey PRIMARY KEY (id);


--
-- Name: atccode_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY atccode
    ADD CONSTRAINT atccode_code_key UNIQUE (code);


--
-- Name: atccode_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY atccode
    ADD CONSTRAINT atccode_name_key UNIQUE (name);


--
-- Name: attributetype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attributetype
    ADD CONSTRAINT attributetype_pkey PRIMARY KEY (id);


--
-- Name: campaign_participant_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY campaign_participant
    ADD CONSTRAINT campaign_participant_pkey PRIMARY KEY (id);


--
-- Name: campaign_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY campaign
    ADD CONSTRAINT campaign_pkey PRIMARY KEY (id);


--
-- Name: chemicalcompound_acronym_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY chemicalcompound
    ADD CONSTRAINT chemicalcompound_acronym_key UNIQUE (acronym);


--
-- Name: chemicalcompound_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY chemicalcompound
    ADD CONSTRAINT chemicalcompound_name_key UNIQUE (name);


--
-- Name: chemicaldrugstrength_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY chemicaldrugstrength
    ADD CONSTRAINT chemicaldrugstrength_pkey PRIMARY KEY (id);


--
-- Name: cl_chemicalcompound_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY chemicalcompound
    ADD CONSTRAINT cl_chemicalcompound_pkey PRIMARY KEY (id);


--
-- Name: clinic_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clinic
    ADD CONSTRAINT clinic_pkey PRIMARY KEY (id);


--
-- Name: clinicuser_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clinicuser
    ADD CONSTRAINT clinicuser_pkey PRIMARY KEY (userid, clinicid);


--
-- Name: deleteditem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deleteditem
    ADD CONSTRAINT deleteditem_pkey PRIMARY KEY (id);


--
-- Name: doctor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY doctor
    ADD CONSTRAINT doctor_pkey PRIMARY KEY (id);


--
-- Name: doctorcategory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY doctorcategory
    ADD CONSTRAINT doctorcategory_pkey PRIMARY KEY (id);


--
-- Name: drug_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drug
    ADD CONSTRAINT drug_pkey PRIMARY KEY (id);


--
-- Name: episode_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY episode
    ADD CONSTRAINT episode_pkey PRIMARY KEY (id);


--
-- Name: form_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY form
    ADD CONSTRAINT form_pkey PRIMARY KEY (id);


--
-- Name: identifiertype_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY identifiertype
    ADD CONSTRAINT identifiertype_name_key UNIQUE (name);


--
-- Name: linhat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY linhat
    ADD CONSTRAINT linhat_pkey PRIMARY KEY (linhaid);


--
-- Name: logging_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY logging
    ADD CONSTRAINT logging_pkey PRIMARY KEY (id);


--
-- Name: motivo_mudanca_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY motivomudanca
    ADD CONSTRAINT motivo_mudanca_pkey PRIMARY KEY (idmotivo);


--
-- Name: package_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY package
    ADD CONSTRAINT package_pkey PRIMARY KEY (id);


--
-- Name: packageddrugs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY packageddrugs
    ADD CONSTRAINT packageddrugs_pkey PRIMARY KEY (id);


--
-- Name: packagedruginfotmp_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY packagedruginfotmp
    ADD CONSTRAINT packagedruginfotmp_pkey PRIMARY KEY (id);


--
-- Name: patient_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patient
    ADD CONSTRAINT patient_pkey PRIMARY KEY (id);


--
-- Name: patientattribute_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientattribute
    ADD CONSTRAINT patientattribute_pkey PRIMARY KEY (id);


--
-- Name: patientvisitreason_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientvisitreason
    ADD CONSTRAINT patientvisitreason_pkey PRIMARY KEY (id);


--
-- Name: pillcount_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pillcount
    ADD CONSTRAINT pillcount_pkey PRIMARY KEY (id);


--
-- Name: pk_alerts; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alerts
    ADD CONSTRAINT pk_alerts PRIMARY KEY (id);


--
-- Name: pk_atccode; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY atccode
    ADD CONSTRAINT pk_atccode PRIMARY KEY (id);


--
-- Name: pk_databasechangelog; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY databasechangelog
    ADD CONSTRAINT pk_databasechangelog PRIMARY KEY (id, author, filename);


--
-- Name: pk_databasechangeloglock; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY databasechangeloglock
    ADD CONSTRAINT pk_databasechangeloglock PRIMARY KEY (id);


--
-- Name: pk_identifiertype; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY identifiertype
    ADD CONSTRAINT pk_identifiertype PRIMARY KEY (id);


--
-- Name: pk_messageschedule; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY messageschedule
    ADD CONSTRAINT pk_messageschedule PRIMARY KEY (id);


--
-- Name: pk_nationalclinics; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY nationalclinics
    ADD CONSTRAINT pk_nationalclinics PRIMARY KEY (id);


--
-- Name: pk_patientidentifier; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientidentifier
    ADD CONSTRAINT pk_patientidentifier PRIMARY KEY (id);


--
-- Name: pk_patientstatistic; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientstatistic
    ADD CONSTRAINT pk_patientstatistic PRIMARY KEY (id);


--
-- Name: pk_patientstattype; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientstattypes
    ADD CONSTRAINT pk_patientstattype PRIMARY KEY (id);


--
-- Name: pk_patientvisit; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientvisit
    ADD CONSTRAINT pk_patientvisit PRIMARY KEY (id);


--
-- Name: pk_study; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY study
    ADD CONSTRAINT pk_study PRIMARY KEY (id);


--
-- Name: pk_studyparticipant; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY studyparticipant
    ADD CONSTRAINT pk_studyparticipant PRIMARY KEY (id);


--
-- Name: pregnancy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pregnancy
    ADD CONSTRAINT pregnancy_pkey PRIMARY KEY (id);


--
-- Name: prescribeddrugs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prescribeddrugs
    ADD CONSTRAINT prescribeddrugs_pkey PRIMARY KEY (id);


--
-- Name: prescription_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prescription
    ADD CONSTRAINT prescription_pkey PRIMARY KEY (id);


--
-- Name: regimen_fkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY regimen
    ADD CONSTRAINT regimen_fkey PRIMARY KEY (id);


--
-- Name: regimendrugs_fkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY regimendrugs
    ADD CONSTRAINT regimendrugs_fkey PRIMARY KEY (id);


--
-- Name: regimeterapeutico_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY regimeterapeutico
    ADD CONSTRAINT regimeterapeutico_pkey PRIMARY KEY (regimeid);


--
-- Name: simpledomain_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY simpledomain
    ADD CONSTRAINT simpledomain_pkey PRIMARY KEY (id);


--
-- Name: stock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_pkey PRIMARY KEY (id);


--
-- Name: stockadjustment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stockadjustment
    ADD CONSTRAINT stockadjustment_pkey PRIMARY KEY (id);


--
-- Name: stockcenter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stockcenter
    ADD CONSTRAINT stockcenter_pkey PRIMARY KEY (id);


--
-- Name: stocklevel_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stocklevel
    ADD CONSTRAINT stocklevel_pkey PRIMARY KEY (id);


--
-- Name: stocktake_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stocktake
    ADD CONSTRAINT stocktake_pkey PRIMARY KEY (id);


--
-- Name: study_studyname_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY study
    ADD CONSTRAINT study_studyname_key UNIQUE (studyname);


--
-- Name: sync_temp_dispense_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sync_temp_dispense
    ADD CONSTRAINT sync_temp_dispense_pkey PRIMARY KEY (nid);


--
-- Name: sync_temp_patients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY sync_temp_patients
    ADD CONSTRAINT sync_temp_patients_pkey PRIMARY KEY (nid);


--
-- Name: unique_batch; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stocklevel
    ADD CONSTRAINT unique_batch UNIQUE (batch);


--
-- Name: unique_clinicname; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clinic
    ADD CONSTRAINT unique_clinicname UNIQUE (clinicname);


--
-- Name: unique_clinicuser; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clinicuser
    ADD CONSTRAINT unique_clinicuser UNIQUE (userid, clinicid);


--
-- Name: unique_facilities; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY nationalclinics
    ADD CONSTRAINT unique_facilities UNIQUE (facilityname, subdistrict);


--
-- Name: unique_identifier_type; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientidentifier
    ADD CONSTRAINT unique_identifier_type UNIQUE (type_id, value);


--
-- Name: unique_regimen; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY regimen
    ADD CONSTRAINT unique_regimen UNIQUE (regimenname, druggroup);


--
-- Name: unique_regimendrug; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY regimendrugs
    ADD CONSTRAINT unique_regimendrug UNIQUE (regimen, drug);


--
-- Name: unique_stockcentername; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stockcenter
    ADD CONSTRAINT unique_stockcentername UNIQUE (stockcentername);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: add_sched_visit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER add_sched_visit AFTER INSERT ON package FOR EACH ROW EXECUTE PROCEDURE add_sched_visit();


--
-- Name: del_sched_visit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER del_sched_visit BEFORE DELETE ON package FOR EACH ROW EXECUTE PROCEDURE del_sched_visit();


--
-- Name: alternateid_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY alternatepatientidentifier
    ADD CONSTRAINT alternateid_patient FOREIGN KEY (patient) REFERENCES patient(id);


--
-- Name: appointment_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY appointment
    ADD CONSTRAINT appointment_fkey FOREIGN KEY (patient) REFERENCES patient(id);


--
-- Name: batch_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stocklevel
    ADD CONSTRAINT batch_fkey FOREIGN KEY (batch) REFERENCES stock(id);


--
-- Name: campaign_participant_campaign_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY campaign_participant
    ADD CONSTRAINT campaign_participant_campaign_fk FOREIGN KEY (campaign_id) REFERENCES campaign(id);


--
-- Name: campaign_participant_patient_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY campaign_participant
    ADD CONSTRAINT campaign_participant_patient_fk FOREIGN KEY (patient_id) REFERENCES patient(id);


--
-- Name: chemicalcompound_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY chemicaldrugstrength
    ADD CONSTRAINT chemicalcompound_fkey FOREIGN KEY (chemicalcompound) REFERENCES chemicalcompound(id);


--
-- Name: drug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY regimendrugs
    ADD CONSTRAINT drug_fkey FOREIGN KEY (drug) REFERENCES drug(id);


--
-- Name: drug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY chemicaldrugstrength
    ADD CONSTRAINT drug_fkey FOREIGN KEY (drug) REFERENCES drug(id);


--
-- Name: drug_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pillcount
    ADD CONSTRAINT drug_fkey FOREIGN KEY (drug) REFERENCES drug(id);


--
-- Name: drug_form; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drug
    ADD CONSTRAINT drug_form FOREIGN KEY (form) REFERENCES form(id);


--
-- Name: episode_clinic_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY episode
    ADD CONSTRAINT episode_clinic_fkey FOREIGN KEY (clinic) REFERENCES clinic(id);


--
-- Name: fk_atccode_chemicalcompound; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY atccode_chemicalcompound
    ADD CONSTRAINT fk_atccode_chemicalcompound FOREIGN KEY (atccode_id) REFERENCES atccode(id);


--
-- Name: fk_chemicalcompound_atccode; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY atccode_chemicalcompound
    ADD CONSTRAINT fk_chemicalcompound_atccode FOREIGN KEY (chemicalcompound_id) REFERENCES chemicalcompound(id);


--
-- Name: fk_drug_atccode; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY drug
    ADD CONSTRAINT fk_drug_atccode FOREIGN KEY (atccode_id) REFERENCES atccode(id);


--
-- Name: fk_episode_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY episode
    ADD CONSTRAINT fk_episode_patient FOREIGN KEY (patient) REFERENCES patient(id);


--
-- Name: fkey_clinic_details; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY clinic
    ADD CONSTRAINT fkey_clinic_details FOREIGN KEY (clinicdetails_id) REFERENCES nationalclinics(id);


--
-- Name: package_clinic_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY package
    ADD CONSTRAINT package_clinic_fkey FOREIGN KEY (clinic) REFERENCES clinic(id);


--
-- Name: package_parent; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY packageddrugs
    ADD CONSTRAINT package_parent FOREIGN KEY (parentpackage) REFERENCES package(id);


--
-- Name: packageddrugtmp_cluser; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY packagedruginfotmp
    ADD CONSTRAINT packageddrugtmp_cluser FOREIGN KEY (cluser) REFERENCES users(id);


--
-- Name: packageddrugtmp_packageddrug; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY packagedruginfotmp
    ADD CONSTRAINT packageddrugtmp_packageddrug FOREIGN KEY (packageddrug) REFERENCES packageddrugs(id);


--
-- Name: patient_clinic; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patient
    ADD CONSTRAINT patient_clinic FOREIGN KEY (clinic) REFERENCES clinic(id);


--
-- Name: patientattribute_attributetype; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientattribute
    ADD CONSTRAINT patientattribute_attributetype FOREIGN KEY (type_id) REFERENCES attributetype(id);


--
-- Name: patientattribute_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientattribute
    ADD CONSTRAINT patientattribute_patient FOREIGN KEY (patient) REFERENCES patient(id);


--
-- Name: patientidentifier_identifiertype; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientidentifier
    ADD CONSTRAINT patientidentifier_identifiertype FOREIGN KEY (type_id) REFERENCES identifiertype(id);


--
-- Name: patientidentifier_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY patientidentifier
    ADD CONSTRAINT patientidentifier_patient FOREIGN KEY (patient_id) REFERENCES patient(id);


--
-- Name: pillcount_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY accumulateddrugs
    ADD CONSTRAINT pillcount_fkey FOREIGN KEY (pillcount) REFERENCES pillcount(id);


--
-- Name: pregnancy_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pregnancy
    ADD CONSTRAINT pregnancy_patient FOREIGN KEY (patient) REFERENCES patient(id);


--
-- Name: prescribed_drug; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prescribeddrugs
    ADD CONSTRAINT prescribed_drug FOREIGN KEY (drug) REFERENCES drug(id);


--
-- Name: prescribed_prescription; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prescribeddrugs
    ADD CONSTRAINT prescribed_prescription FOREIGN KEY (prescription) REFERENCES prescription(id);


--
-- Name: prescription_doctor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prescription
    ADD CONSTRAINT prescription_doctor FOREIGN KEY (doctor) REFERENCES doctor(id);


--
-- Name: prescription_linha; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prescription
    ADD CONSTRAINT prescription_linha FOREIGN KEY (linhaid) REFERENCES linhat(linhaid);


--
-- Name: prescription_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prescription
    ADD CONSTRAINT prescription_patient FOREIGN KEY (patient) REFERENCES patient(id);


--
-- Name: prescription_regime; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY prescription
    ADD CONSTRAINT prescription_regime FOREIGN KEY (regimeid) REFERENCES regimeterapeutico(regimeid);


--
-- Name: previouspackage_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pillcount
    ADD CONSTRAINT previouspackage_fkey FOREIGN KEY (previouspackage) REFERENCES package(id);


--
-- Name: regimen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY regimendrugs
    ADD CONSTRAINT regimen_fkey FOREIGN KEY (regimen) REFERENCES regimen(id);


--
-- Name: stock_drug; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_drug FOREIGN KEY (drug) REFERENCES drug(id);


--
-- Name: stock_stockcenter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_stockcenter_fkey FOREIGN KEY (stockcenter) REFERENCES stockcenter(id);


--
-- Name: stocktake_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stockadjustment
    ADD CONSTRAINT stocktake_fkey FOREIGN KEY (stocktake) REFERENCES stocktake(id);


--
-- Name: studyparticipant_patient_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY studyparticipant
    ADD CONSTRAINT studyparticipant_patient_fkey FOREIGN KEY (patient) REFERENCES patient(id);


--
-- Name: studyparticipant_study_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY studyparticipant
    ADD CONSTRAINT studyparticipant_study_fkey FOREIGN KEY (study) REFERENCES study(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--
