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
//      Fetches (Executive Summary) and displays db information into xml format. Takes in
//		a list of objects and communicates with the db for information.
//		The attributes fetched are determined by the required attribute
//		PEProperty. After PEProperty is initialized, call createObjectIntoXml
//		and then getDocument() to retrieve the Xml.
//
//  Required:
//		
//	Modification:
//
//		@AGQ072806	Removed single blog limiter 
//		@AGQ080106	Does not display archive blogs
//
/////////////////////////////////////////////////////////////////////

package mod.prmext;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;

import oct.codegen.phase;
import oct.codegen.planTaskManager;
import oct.codegen.project;
import oct.codegen.result;
import oct.codegen.resultManager;
import oct.codegen.taskManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.dom4j.Element;

public class PEExeSumFetcher extends PEFetcher {
	
	private final static String DEPRECATED = "' && Status!='Deprecated'";
	private final static String EXPTASKID = "TaskID='";
	private final static String BLOGS = "blogs";
	
	private String [] blogVarArr;
	private ArrayList blogSortArr;
		
	public PEExeSumFetcher() {
		super();
		
		blogVarArr = null;
		blogSortArr = new ArrayList();
		
	}
	
	public PEExeSumFetcher(PstAbstractObject [] pstObjArr, PEProperty peProperty, PstUserAbstractObject pstuser) {
		super(pstObjArr, peProperty, pstuser);	
	
		String s;
		Object [] tempArr = peProperty.getBlogVarArr().toArray();
		this.blogVarArr = new String[tempArr.length];
		for (int i=0; i<tempArr.length; i++) {
			s = tempArr[i].toString();
			this.blogVarArr[i] = s;
		}
		blogSortArr = peProperty.getBlogSortArr();
	}
	
	/**
	 * Handles Executive Summary Types. Checks pstObj to see if
	 * it contains a executive summary id. If it is found, retreive all
	 * the blog information.
	 * @param reqElement
	 * @param pstObj
	 * @throws PmpException
	 */
	protected void fetchObjectToXml(Element reqElement, PstAbstractObject pstObj) 
		throws PmpException {
		try {
			String taskID = null;
			String projectId = null;
			String options = null;
			String [] optionsArr = null;
			//String execSummary = null;
			Object object = null;
			String projName = null;
			
				if (pstObj != null) {
					Element curElement = null;
					// Find the Summary ID from projects
					
					projName = pstObj.getObjectName();
					object = pstObj.getAttribute("Option")[0];
					if (object!=null) {
						options = object.toString().trim();
						if (options.length()>0) {
							optionsArr = options.split(project.DELIMITER);
							String curOption;
							String [] curArr;
							for (int i=0; i<optionsArr.length; i++) {
								curOption = optionsArr[i].trim();
								curArr = curOption.split("=");
								if (curArr.length>=2) {
									if (curArr[0].equals("SUMMARY_ID")) {
										taskID = curArr[1];
										break;
									}
								}
							}
						}					
					}
					
					// Find the blog id from Task
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
						HashMap map = createAtt(taskID, null, null, projectId);
						curElement = peXmlWriter.addToElement(reqElement, type, map);						
						fetchVarToXml(curElement, tk, projName, ptk, TASK);
					}

				}
		} catch (PmpException e) {
			e.printStackTrace();
			//throw e;
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
						// @AGQ080106
						int [] ids = resultMgr.findId(pstuser, "(TaskID='" + pstObj.getObjectId() + "') && (Type='" + result.TYPE_TASK_BLOG + "')");
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
						
						// @AGQ072806 Removed the limit
						// limits the blog to one
						//if (noOfBlog > 1)
						//	noOfBlog = 1;
						
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
}
