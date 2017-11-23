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
//      Manages what types of object and takes the objects from ommtool.
//		Performs sorting, detecting attribute types, and detects what type
//		of calls the user is seeking.
//
//  Required:
//		
//	Modification:
/////////////////////////////////////////////////////////////////////

package mod.prmext;

import java.util.ArrayList;
import java.util.HashMap;

import oct.codegen.bug;
import oct.codegen.bugManager;
import oct.codegen.meeting;
import oct.codegen.meetingManager;
import oct.codegen.phase;
import oct.codegen.phaseManager;
import oct.codegen.project;
import oct.codegen.projectManager;
import oct.codegen.resultManager;
import oct.codegen.taskManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;

import org.dom4j.Document;

import util.Util;

public class PEManager implements PEConstants{
	private final static String ALLOBJECT = "om_acctname='%'";
	private final static String NAMEEQUAL = "Name=";
	private final static String OM_ACCTNAMEEQUAL = "om_acctname=";
	private final static String PROJECTIDEQUAL = "ProjectID=";
	private final static char APOS = '\'';
	private final static String AND = "&&";
	private final static char PARENOPEN = '(';
	private final static char PARENCLOSE = ')';
	private final static String EMPTY = "";
	
	/**
	 * 
	 * @param peProperty
	 * @param pstuser
	 * @param param
	 * @param expr
	 * @return xml document with all the information according to peProperty or null if peProperty does not exist
	 * @throws PmpException
	 */
	public static Document getXmlDocument(PEProperty peProperty, PstUserAbstractObject pstuser, String param, String expr, String project) throws PmpException {
		try {
			if (peProperty != null) {
				// Modify the expr if user typed in a project name				
				if (project != null && project.length() > 0)
					expr = modifyExpr(pstuser, project, expr, peProperty.getType());			
				PstAbstractObject [] objArr = getTypeObjArr(pstuser, peProperty, param, expr);
				// extracts all the information into an Xml Document
				PEFetcher peFetcher = getPEFetcher(objArr, peProperty, pstuser);
				peFetcher.createObjectIntoXml();
				return peFetcher.getDocument();
			}
			else {
				return null;
			}
		} catch (PmpException e) {
			// Unable to get the item
			e.printStackTrace();
			throw e;
		}
	}
	
	/**
	 * This method looks at what type of object is requested and retreives all the objects. If a param is specified, then it will
	 * look for that object id. If param is not specified but an expr is, then it will look for objects matching the expression.
	 * e.g. 
	 * @param pstuser
	 * @param peProperty Contains type and sortedBy information
	 * @param param 0 for all object or specific object id
	 * @param expr 	Only read when param is 0 or null
	 * 				ProjectID='12345'&&Type='issue'
	 * 				ProjectID='12345'||Type='issue'
	 * @return objArr of all the objects retrieved from the type and conditions above
	 * @throws PmpException
	 */
	private static PstAbstractObject [] getTypeObjArr(PstUserAbstractObject pstuser, PEProperty peProperty, String param, String expr) 
		throws PmpException {
		try {
			PstAbstractObject [] objArr;
			String type = peProperty.getType();
			ArrayList sortedByArr = peProperty.getSortedByArr();
			PstManager mgr = getManager(type);
			
			int objectId = 0;
			if (param != null && param.length() > 0) {
				objectId = Integer.parseInt(param);
			}
			// get specified object id 
			if (objectId > 0) {
				objArr = new PstAbstractObject[1];
				objArr[0] = mgr.get(pstuser, objectId);
			}
			// Find all matching objects
			else {
				// set expr String
				if (expr != null && expr.length() > 0) {
					// change "Name=" to "om_acctname="				
					if (expr.contains(NAMEEQUAL))
						expr = expr.replaceAll(NAMEEQUAL, OM_ACCTNAMEEQUAL);					
				}
				else
					expr = ALLOBJECT;
				int [] objIds = mgr.findId(pstuser, expr);
				objArr = mgr.get(pstuser, objIds);
			}
			// cast back to it's "type"
			castObject(type, objArr);

			// sort the objects backwards to have a group by effect
			for (int i=sortedByArr.size()-1; i>=0; i--) {
				String sortedBy = (sortedByArr.get(i)).toString();				
				if (sortedBy != null && sortedBy.length() > 0) {
					int attTypeId = getAttributeType(type, sortedBy);
					if (attTypeId >= 0)
						sortByAttribute(pstuser, objArr, attTypeId, sortedBy);
				}
			}
			
			return objArr;
			
		} catch (NumberFormatException e) {
			e.printStackTrace();
			// number format exception
			throw e;
		} catch (PmpException e) {
			e.printStackTrace();
			// Unable to get the item
			// Cannot find attribute Type
			throw e;
		} 
	}
	
	/**
	 * Changes the user id array into user names array. 
	 * @param attObjArr User ID array
	 * @param pstuser user object
	 * @param nameMap an optional hashmap to speed search 
	 * 					by remembering the previous user names 
	 */
	public static void userIdToFullName(Object [] attObjArr, PstUserAbstractObject pstuser, HashMap nameMap) {
		try {
			PstManager mgr = getManager(USER);
			user u = null;
			if (attObjArr[0] != null) {
				for (int i=0; i<attObjArr.length; i++) {
					Object key = attObjArr[i];
					int id = Integer.parseInt(key.toString());
					if (nameMap != null && nameMap.containsKey(key)) {
						attObjArr[i] = nameMap.get(key);				
					}
					else {
						u = (user) mgr.get(pstuser, id);
						attObjArr[i] = u.getFullName();
						if (nameMap != null)
							nameMap.put(key, attObjArr[i]);
					}
				}
			}
		} catch (PmpException e) {
			e.printStackTrace();
		}
	}
	
	/**
	 * Detects which sorting method to use by receiving the attribute type id from
	 * @see getAttributeType method. If none of the the id matches, it will use sortString
	 * method. 
	 * @param objArr
	 * @param attTypeId
	 * @param att
	 */
	public static void sortByAttribute(PstUserAbstractObject pstuser, PstAbstractObject [] objArr, int attTypeId, String att) {
		try {
			switch (attTypeId) {
			case 0:
				Util.sortName(objArr);
				break;
			case PstAbstractObject.DATE: 
				Util.sortDate(objArr, att, true);
				break;
			case PstAbstractObject.INT:
				Util.sortInteger(objArr, att, false);
				break;
			default:
				if (isUserIdAttribute(att))
					Util.sortUserId(pstuser, objArr, att, false);
				else if (isValueType(att)) {
					String [] values = getValues(att);
					Util.sortWithValues(objArr, att, values);
				}
				else
					Util.sortString(objArr, att);
				break;
			}
		} catch (PmpException e) {
			// Something went wrong w/ sort
			// most likely something is wrong w/ the user information in sortUserId
			e.printStackTrace();
		}
	}
	
	/**
	 * Given a project name, this method determines what to do with the project
	 * name according to what type of information is being processed. For type 
	 * project, expr will be set to om_acctname='name'. For bugs it will set
	 * expr to search for ProjectID='###'. It will also append the previous expr 
	 * with a && condition and surround the prev expr with parentesis. 
	 * (e.g. expr = ProjectID='###'&&(previous expression))
	 * @param pstuser user object
	 * @param project project name
	 * @param expr the expr user submitted from the url
	 * @param type the type of object the user is requesting
	 * @return an expr with an additional project name 
	 * @throws PmpException
	 */
	private static String modifyExpr(PstUserAbstractObject pstuser, String project, String expr, String type) 
		throws PmpException {
		try {			
			if (project != null && project.length() > 0 &&
					type != null && type.length() > 0) {
				StringBuffer sb = new StringBuffer();
				if (type.equalsIgnoreCase(PROJECT) || type.equalsIgnoreCase(EXECSUM)) {
					sb.append(OM_ACCTNAMEEQUAL + APOS + project + APOS);
				}
				else {
					// Currently handles Bug & Phase
					PstManager mgr = getManager(PROJECT);
					PstAbstractObject obj = mgr.get(pstuser, project);
					castObject(PROJECT, obj);
					if (type.equalsIgnoreCase(BUG) || type.equalsIgnoreCase(PHASE)) {
						sb.append(PROJECTIDEQUAL + APOS + obj.getObjectId() + APOS);
					}
				}
				if (expr != null && expr.length() > 0)
					sb.append(AND + PARENOPEN + expr + PARENCLOSE);
				return sb.toString();
			}
			else
				return expr;
		} catch (PmpException e) {
			e.printStackTrace();
			throw e;
		}
	}
	
// ****************************
// Helper Methods
// ****************************	
	
	/**
	 * Checks string value and returns the static version of the
	 * string. This method will return the lower case version
	 * of the text to make things consistent and since all the strings 
	 * will be static, we can use == comparison on strings.
	 * @param type
	 * @return
	 * @deprecated
	 */
	public static String getReqStaticString(String type) {
		if (type.equalsIgnoreCase(PROJECT) || type.equalsIgnoreCase(EXECSUM))
			return PROJECT;
		else if (type.equalsIgnoreCase(PHASE))
			return PHASE;
		else if (type.equalsIgnoreCase(MEETING))
			return MEETING;
		else if (type.equalsIgnoreCase(BUG))
			return BUG;
		else if (type.equalsIgnoreCase(USER))
			return USER;
		else
			return type;
	}
	
	/**
	 * Determines the type and returns the corresponding manager.
	 * @param type project, phase, meeting, bug, user
	 * @return the corresponding manager according to the type
	 * @throws PmpException
	 */
	private static PstManager getManager(String type) 
		throws PmpException {
		try {
			if (type.equalsIgnoreCase(PROJECT) || type.equalsIgnoreCase(EXECSUM))
				return projectManager.getInstance();
			else if (type.equalsIgnoreCase(PHASE))
				return phaseManager.getInstance();
			else if (type.equalsIgnoreCase(MEETING))
				return meetingManager.getInstance();
			else if (type.equalsIgnoreCase(BUG))
				return bugManager.getInstance();
			else if (type.equalsIgnoreCase(USER))
				return userManager.getInstance();
			else
				throw new PmpException();
		} catch (PmpException e) {  
			e.printStackTrace();
			throw e;
		}
	}
	
	/**
	 * Casts the object to it's corresponding type
	 * @param type	The type of object
	 * @param obj	The object to cast
	 * @throws PmpException
	 */
	private static void castObject(String type, PstAbstractObject obj) 
		throws PmpException {
		try {
			PstAbstractObject[] objArr = new PstAbstractObject[1];
			objArr[0] = obj;
			castObject(type, objArr);
		} catch (PmpException e) {
			e.printStackTrace();
			throw e;
		}
	}
	
	/**
	 * Casts the object to it's corresponding type. 
	 * @param type		The type of object
	 * @param objArr 	The objArr to cast
	 * @throws PmpException
	 */
	private static void castObject(String type, PstAbstractObject [] objArr) 
		throws PmpException {
		try {
			if (type.equalsIgnoreCase(PROJECT) || type.equalsIgnoreCase(EXECSUM)) {
				for (int i=0; i<objArr.length; i++) {
					objArr[i] = (project) objArr[i];
				}
			}
			else if (type.equalsIgnoreCase(PHASE)) {
				for (int i=0; i<objArr.length; i++) {
					objArr[i] = (phase) objArr[i];
				}
			}
			else if (type.equalsIgnoreCase(MEETING)){
				for (int i=0; i<objArr.length; i++) {
					objArr[i] = (meeting) objArr[i];
				}
			}
			else if (type.equalsIgnoreCase(BUG)){
				for (int i=0; i<objArr.length; i++) {
					objArr[i] = (bug) objArr[i];
				}
			}
			else if (type.equalsIgnoreCase(USER)){
				for (int i=0; i<objArr.length; i++) {
					objArr[i] = (user) objArr[i];
				}
			}
			else
				throw new PmpException();
		} catch (PmpException e) {
			e.printStackTrace();
			throw e;
		}
	}
	
	/**
	 * Determines which type of Fetcher class to use. Receives all the variables for all the different types
	 * of Fetchers and then looks through the peProperty to see which type the user wants to retrieves.
	 * @param objArr
	 * @param peProperty
	 * @param pstuser
	 * @return PEFetcher object
	 */
	private static PEFetcher getPEFetcher(PstAbstractObject [] objArr, PEProperty peProperty, PstUserAbstractObject pstuser) {
		String type = peProperty.getType();
		if (type.equalsIgnoreCase(PHASE)) {
			return new PEPhaseFetcher(objArr, peProperty, pstuser);
		}
		else if (type.equalsIgnoreCase(EXECSUM)) {
			return new PEExeSumFetcher(objArr, peProperty, pstuser);
		}
		else
			return new PEFetcher(objArr, peProperty, pstuser);
	}
	
	/**
	 * Finds the int value of the type by using @see getManagerAttributeType 
	 * method. 
	 * @param type		The type of object
	 * @param attribute	The attribute name
	 * @return 	0 if attribute name is Name or
	 * 			the attribute type value according to the type and attribute
	 * 			name @see PstAbstractObject static values
	 * @throws PmpException
	 */
	public static int getAttributeType(String type,  String attribute) 
		throws PmpException {
		try {
			// Name will use object's name with a few exceptional cases (phase)
			if (attribute.equalsIgnoreCase(NAME) && !type.equalsIgnoreCase(PHASE))
				return 0;
			else
				return getManagerAttributeType(type, attribute);
		} catch (PmpException e) {
			e.printStackTrace();
			throw e;
		}
	}
	
	/**
	 * Finds the corresponding manager and returns the attribute type's int value.
	 * @param type		The type of object
	 * @param attribute	The attribute name
	 * @return 	the attribute type value according to the type and attribute
	 * 			name @see PstAbstractObject static values
	 * @throws PmpException
	 */
	public static int getManagerAttributeType(String type, String attribute) 
		throws PmpException {
		try {
			if (type.equalsIgnoreCase(PROJECT) || type.equalsIgnoreCase(EXECSUM)) {
				return projectManager.getInstance().getAttributeType(attribute);
			}
			else if (type.equalsIgnoreCase(PHASE)) {
				return phaseManager.getInstance().getAttributeType(attribute);
			}
			else if (type.equalsIgnoreCase(MEETING)) {
				return meetingManager.getInstance().getAttributeType(attribute);
			}
			else if (type.equalsIgnoreCase(BUG)) {
				return bugManager.getInstance().getAttributeType(attribute);
			}
			else if (type.equalsIgnoreCase(USER)) {
				return userManager.getInstance().getAttributeType(attribute);
			}
			else if (type.equalsIgnoreCase(RESULT)) {
				return resultManager.getInstance().getAttributeType(attribute);
			}
			else if (type.equalsIgnoreCase(TASK)) {
				return taskManager.getInstance().getAttributeType(attribute);
			}
			else {
				throw new PmpException();
			}
		} catch (PmpException e) {
			e.printStackTrace();
			throw e;
		}
	}
	/**
	 * Checks to see if this attribute type is a userId type
	 * @param attribute
	 * @return
	 */
	public static boolean isUserIdAttribute(String attribute) {
		if (attribute.equalsIgnoreCase(CREATOR))
			return true;
		else if (attribute.equalsIgnoreCase(OWNER))
			return true;
		else if (attribute.equalsIgnoreCase(TEAMMEMBERS))
			return true;
		else if (attribute.equalsIgnoreCase(SUPERVISOR1))
			return true;
		else
			return false;
	}
	
	/**
	 * Checks to see if this attribute type uses the sortByValue
	 * sorting method.
	 * @param attribute
	 * @return	true if it belongs to sortByValue; or else false
	 */
	public static boolean isValueType(String attribute) {
		if (attribute.equalsIgnoreCase(PRIORITY))
			return true;
		else if (attribute.equalsIgnoreCase(SEVERITY))
			return true;
		else if (attribute.equalsIgnoreCase(STATE))
			return true;
		else if (attribute.equalsIgnoreCase(TYPEATT))
			return true;
		else 
			return false;
	}
	
	/**
	 * Retreiving the sortByValue's array
	 * @param attribute	The attribute name
	 * @return	The array which specifies the order of the attribute's type
	 */
	public static String [] getValues(String attribute) {
		if (attribute.equalsIgnoreCase(PRIORITY)) {
			// high - medium - low - null
			String [] array = {bug.PRI_HIGH, bug.PRI_MED, bug.PRI_LOW, EMPTY}; 
			int numUDefPri = 0;
			int idx;
			String s = Util.getPropKey("pst", "BUG_MAX_DEFINE_PRI");
			if (s!=null)
			{
				try {numUDefPri = Integer.parseInt(s.trim());}
				catch (Exception e) {/* invalid properties value */}
				if (numUDefPri > 0)
				{
					array = new String[numUDefPri + 4];	// plus the default 3
					for (idx=0; idx<numUDefPri; idx++)
						array[idx] = bug.PRI_HIGH + (idx+1);
					// append the default value to after the user-defined levels
					array[idx++] = bug.PRI_HIGH; array[idx++] = bug.PRI_MED; array[idx++] = bug.PRI_LOW; array[idx] = EMPTY;
				}
			}

			return array;
		}
		else if (attribute.equalsIgnoreCase(SEVERITY)) {
			// critical - serious - non critical - null
			String [] array = {bug.SEV_CRI, bug.SEV_SER, bug.SEV_NCR, EMPTY}; 
			return array;
		}
		else if (attribute.equalsIgnoreCase(STATE)) {
			return bug.STATE_ARRAY;
		}
		else if (attribute.equalsIgnoreCase(TYPEATT)) {
			return bug.CLASS_ARRAY;
		}
		else
			return null;
	}
}
