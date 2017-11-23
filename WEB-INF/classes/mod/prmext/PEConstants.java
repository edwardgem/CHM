//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	Allen G Quan
//	Date:	$Date$
//  Description:
//      Constants
//		
//	Modification:
/////////////////////////////////////////////////////////////////////


package mod.prmext;

public interface PEConstants {
	// PrmExt.java servlet
	public static final String U = "u";
	public static final String P = "p";
	public static final String REQ = "req";
	public static final String PARAM = "param";
	public static final String EXPR = "expr";
	public static final String PST = "pst";
	public static final String PRM_EXT_FILE = "PRM_EXT_FILE";
	public static final String ERROR = "error";
	public static final String UPLOAD = "upload";
	// PEProperty.java
	public static final String TYPE = "type";
	public static final String OUTPUT = "output";
	public static final String SORTEDBY = "sortedBy";
	// PrmExt.xml
	public static final String PROJECT = "project";
	public static final String EXECSUM = "execsum";
	public static final String PHASE = "phase";
	public static final String MEETING = "meeting";
	public static final String BUG = "bug";
	public static final String USER = "user";
	public static final String RESULT = "result";
	public static final String TASK = "task";
	// PrmExt
	public static final String PRMEXT = "PrmExt";
	
	//PEFetcher.java
	public static final String ID = "id";
	public static final String TASKID = "taskId";
	public static final String NUMBER = "number";
	public static final String PROJECTID = "projectId";
	public static final String PHASEID = "phaseId";
	
	// Properties Attributes
	public static final String NAME = "Name";
	public static final String STARTDATE = "StartDate";
	public static final String EXPIREDATE = "ExpireDate";
	public static final String COMPLETEDATE = "CompleteDate";
	public static final String STATUS = "Status";
	public static final String SUBPHASE = "SubPhase";
	public static final String SUBPHASES = "SubPhases";
	public static final String EFFECTIVEDATE = "EffectiveDate";
	public static final String CREATOR = "Creator";
	public static final String OWNER = "Owner";
	public static final String TEAMMEMBERS = "TeamMembers";
	public static final String PRIORITY = "Priority";
	public static final String SEVERITY = "Severity";
	public static final String STATE = "State";
	public static final String TYPEATT = "Type";
	public static final String SUPERVISOR1 = "Supervisor1";
	public static final String PLANEXPIREDATE = "PlanExpireDate";
	
	public final static String DATESTANDARDFORMAT = "MM/dd/yyyy HH:mm:ss z";
}
