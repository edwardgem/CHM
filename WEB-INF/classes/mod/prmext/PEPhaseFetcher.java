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
//      Fetches (Phase & SubPhase) and displays db information into xml format. Takes in
//		a list of objects and communicates with the db for information.
//		The attributes fetched are determined by the required attribute
//		PEProperty. After PEProperty is initialized, call createObjectIntoXml
//		and then getDocument() to retrieve the Xml.
//
//  Required:
//		
//	Modification:
//
//		@AGQ041906	Do a more thorough check to make sure subphase does 
//					not contain information. This method will be removed 
//					once phase is changed to object type. Created for Spansion
//		@AGQ042806	Changed from calling phase to phase object
//
/////////////////////////////////////////////////////////////////////

package mod.prmext;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;

import oct.codegen.phase;
import oct.codegen.phaseManager;
import oct.codegen.planTaskManager;
import oct.codegen.project;
import oct.codegen.resultManager;
import oct.codegen.taskManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.dom4j.Element;

public class PEPhaseFetcher extends PEFetcher {
	
	private final static String DEPRECATED = "' && Status!='Deprecated'";
	private final static String EXPTASKID = "TaskID='";
	private final static String EMPTY = "";
	private final static String BLOGS = "blogs";
	
	private String [] blogVarArr;
	private ArrayList varSortArr;
	private ArrayList blogSortArr;
	private boolean isBlog;
		
	public PEPhaseFetcher() {
		super();
		
		blogVarArr = null;
		blogSortArr = new ArrayList();
		varSortArr = new ArrayList();
		isBlog = false;
		
	}
	
	public PEPhaseFetcher(PstAbstractObject [] pstObjArr, PEProperty peProperty, PstUserAbstractObject pstuser) {
		super(pstObjArr, peProperty, pstuser);	
	
		String s;
		Object [] tempArr = peProperty.getBlogVarArr().toArray();
		this.blogVarArr = new String[tempArr.length];
		for (int i=0; i<tempArr.length; i++) {
			s = tempArr[i].toString();
			this.blogVarArr[i] = s;
		}
		blogSortArr = peProperty.getBlogSortArr();
		for (int i=0; i<variableArr.length; i++) {
			if (variableArr[i].equalsIgnoreCase(BLOGS)) {
				isBlog = true;
				break;
			}
		}
		varSortArr = peProperty.getSortedByArr();
	}
	
	/**
	 * Handles Phase and SubPhase Types. Loops through pstObj and checks to see if
	 * it contains a taskID. If it contains a taskID, it will get the information 
	 * from 
	 * @param reqElement
	 * @param pstObj
	 * @throws PmpException
	 */
	protected void fetchObjectToXml(Element reqElement, PstAbstractObject pstObj) 
		throws PmpException {
		try {
			phaseManager phMgr = phaseManager.getInstance();
			String nodeName, phName, phIDS, phNumber, taskID;
			String projectId = null;
			Object object = null;
			boolean isSubPhase = false;
			boolean hasSubPhase = false;
			
				if (pstObj != null) {
					Element curElement = null;
					
					// Find out if it is a phase or a subphase
					object = pstObj.getAttribute(phase.PROJECTID)[0];
					// phase
					if (object != null) {
						projectId = object.toString();
						nodeName = type;
					}
					// subphase
					else {
						object = pstObj.getAttribute(phase.PARENTID)[0];
						projectId = (object != null)?object.toString():null;
						isSubPhase = true;
						nodeName = SUBPHASE;
					}
					
					phIDS = String.valueOf(pstObj.getObjectId());
					
					hasSubPhase = phMgr.hasSubPhases(pstuser, phIDS);
					
					// We only print phases w/ subphases
					if (isSubPhase || hasSubPhase) {	
						// Fetch common information
						object = pstObj.getAttribute(phase.NAME)[0];
						phName = (object != null)?object.toString():null;
						
						object = pstObj.getAttribute(phase.TASKID)[0];
						taskID = (object != null)?object.toString():null;
						
						object = pstObj.getAttribute(phase.PHASENUMBER)[0];
						phNumber = (object != null)?object.toString():null;
						
						// Task Object
						if (taskID != null) {
							taskManager tkMgr = taskManager.getInstance();
							planTaskManager ptMgr = planTaskManager.getInstance();
							PstAbstractObject tk, ptk;
							int [] ids;
							// get task object and plan task object
							tk = tkMgr.get(pstuser, taskID);
							ids = ptMgr.findId(pstuser, EXPTASKID + taskID + DEPRECATED);
							ptk = ptMgr.get(pstuser, ids[ids.length-1]);
							
							// Create HashMap attributes
							HashMap map = createAtt(taskID, phIDS, phNumber, projectId);
							curElement = peXmlWriter.addToElement(reqElement, nodeName, map);						
							fetchVarToXml(curElement, tk, phName, ptk, TASK);
						}
						// Phase Object
						else if (!isBlog){ 
							// Create HashMap attributes
							HashMap map = createAtt(EMPTY, phIDS, phNumber, projectId);
							curElement = peXmlWriter.addToElement(reqElement, nodeName, map);
							
							// Loop through different required variables 
							fetchVarToXml(curElement, pstObj, type, variableArr);
						}
					
						// Handle SubPhases; note: there are no sub-subphases
						if (!isSubPhase && hasSubPhase 
								&& !isBlog) { // when isBlog is true we do not want subphases; 
							PstAbstractObject [] phaseObjArr = phMgr.getSubPhases(pstuser, phIDS);
							// perform sort
							for (int j=varSortArr.size()-1; j>=0; j--) {
								String sortedBy = (varSortArr.get(j)).toString();				
								if (sortedBy != null && sortedBy.length() > 0) {
									int attTypeId = PEManager.getAttributeType(type, sortedBy);
									if (attTypeId >= 0)
										PEManager.sortByAttribute(pstuser, phaseObjArr, attTypeId, sortedBy);
								}
							}
							
							for (int j=0; j<phaseObjArr.length; j++) {
								PstAbstractObject phase = (phase)phaseObjArr[j];
								fetchObjectToXml(curElement, phase);
							}
						}
					}
				}
		} catch (PmpException e) {
			e.printStackTrace();
			throw e;
		}
	}
	
	protected void fetchVarToXml(Element curElement, PstAbstractObject pstObj, String name, PstAbstractObject ptk) 
	throws PmpException {
		fetchVarToXml(curElement, pstObj, name, ptk, null);
	}
	
	protected void fetchVarToXml(Element curElement, PstAbstractObject pstObj, String name, PstAbstractObject ptk, String type) 
		throws PmpException {
		Object [] attObjArr;
		if (type == null) type = this.type;
		// Loop through different required variables 
		for (int i=0; i<variableArr.length; i++) {
			try {
				if (variableArr[i] != null) {
					// handles blogs, which needs to be retreived elsewhere
					if (variableArr[i].equalsIgnoreCase(BLOGS)) {
						resultManager resultMgr = resultManager.getInstance();
						int [] ids = resultMgr.findId(pstuser, "TaskID='" + pstObj.getObjectId() + "'");
						PstAbstractObject [] pstObjArr = resultMgr.get(pstuser, ids);
						
						for (int j=blogSortArr.size()-1; j>=0; j--) {
							String sortedBy = (blogSortArr.get(j)).toString();				
							if (sortedBy != null && sortedBy.length() > 0) {
								int attTypeId = PEManager.getAttributeType(RESULT, sortedBy);
								if (attTypeId >= 0)
									PEManager.sortByAttribute(pstuser, pstObjArr, attTypeId, sortedBy);
							}
						}
					
						// display lastest blog
						int noOfBlog = pstObjArr.length;
						// limits the blog to one
						if (noOfBlog > 1)
							noOfBlog = 1;
						for (int j=0; j<noOfBlog; j++) {
							Element e = peXmlWriter.addToElement(curElement, BLOGS);
							fetchVarToXml(e, pstObjArr[j], RESULT, blogVarArr);
						}
					}
					// handles all other variables
					else {
						int attTypeId = PEManager.getAttributeType(type, variableArr[i]);			
						switch (attTypeId) {
						case 0: 						// name
							if (name.length() > 0)
								peXmlWriter.addToElement(curElement, variableArr[i], name);
							else 
								peXmlWriter.addToElement(curElement, variableArr[i], ptk.getAttribute(variableArr[i])[0].toString());
							break;
						case PstAbstractObject.DATE:	// date
							if (variableArr[i].equalsIgnoreCase(STARTDATE)) {
								attObjArr = pstObj.getAttribute(EFFECTIVEDATE);
								if (attObjArr[0] == null)
									attObjArr = pstObj.getAttribute(variableArr[i]);
							}
							else
								attObjArr = pstObj.getAttribute(variableArr[i]);
							
							if (attObjArr[0] != null) {
								for (int j=0; j<attObjArr.length; j++) {
									attObjArr[j] = phase.parseDateToString((Date)attObjArr[j], DATESTANDARDFORMAT);
								}
							}
							createAttChildInXml(curElement, attObjArr, variableArr[i]);
							break;
						case PstAbstractObject.RAW:		// binary
							createRawAttChildInXml(curElement, pstObj, variableArr[i]);
							break;
						default:						// normal variables
							attObjArr = pstObj.getAttribute(variableArr[i]);
							createAttChildInXml(curElement, attObjArr, variableArr[i]);
							break;
						}
					}
				}			
			} catch (PmpException e) {
				e.printStackTrace();
				// error in attribute names
			}
		}
	}
	
// ************************
// Helpers
// ************************
	
	private HashMap createAtt(String id, String phID, String no, String parent) {
		HashMap map = new HashMap();
		if (id != null)
			map.put(TASKID, id);
		if (phID != null)
			map.put(PHASEID, phID);
		if (no != null)
			map.put(NUMBER, no);
		if (parent != null)
			map.put(PROJECTID, parent);
		return map;
	}
	
	/**
	 * Translates the variable names into the matching idx. The standard
	 * is made from the jsp pages.
	 *  
	 * @param var see return
	 * @return 	PEConstants.NAME returns project.IDX_PH_NAME
	 * 			PEConstants.STARTDATE returns project.IDX_PH_START
	 * 			PEConstants.PLANEXDATE reutrns project.IDX_PH_PLANEX
	 * 			PEConstants.EXPIREDATE returns project.IDX_PH_EXPIRE
	 * 			PEConstants.COMPLETEDATE returns project.IDX_PH_DONE
	 * 			PEConstants.STATUS returns project.IDX_PH_STATUS
	 * 			PEConstants.SUBPHASE returns project.IDX_PH_EXT 
	 * 			if not found -1
	 * @deprecated Changed phase to phase object; use object's set & get instead
	 */
	private int castVarToInt(String var) {
		if (var.equalsIgnoreCase(NAME)) 
			return project.IDX_PH_NAME;
		else if (var.equalsIgnoreCase(STARTDATE))
			return project.IDX_PH_START;
		else if (var.equalsIgnoreCase(PLANEXPIREDATE))
			return project.IDX_PH_PLANEX;
		else if (var.equalsIgnoreCase(EXPIREDATE))
			return project.IDX_PH_EXPIRE;
		else if (var.equalsIgnoreCase(COMPLETEDATE))
			return project.IDX_PH_DONE;
		else if (var.equalsIgnoreCase(STATUS))
			return project.IDX_PH_STATUS;
		else if (var.equalsIgnoreCase(SUBPHASE))
			return project.IDX_PH_EXT;
		else
			return -1;
	}
	
	/**
	 * Detects if the supplied idx belongs to a date type. (e.g. 1,2 & 3)
	 * @see castVarToIn
	 * @param idx
	 * @return true if idx belongs to a Date idx; otherwise false
	 * @deprecated Changed phase to phase object; use object's set & get instead
	 */
	private boolean isDateVar(int idx) {
		switch (idx) {
		case project.IDX_PH_START:
			return true;
		case project.IDX_PH_EXPIRE:
			return true;
		case project.IDX_PH_PLANEX:
			return true;
		case project.IDX_PH_DONE:
			return true;
		default:
			return false;
		}
	}
}
