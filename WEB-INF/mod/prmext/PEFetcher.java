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
//      Fetches and displays db information into xml format. Takes in
//		a list of objects and communicates with the db for information.
//		The attributes fetched are determined by the required attribute
//		PEProperty. After PEProperty is initialized, call createObjectIntoXml
//		and then getDocument() to retrieve the Xml.
//
//  Required:
//		pstObjArr	- A list of casted object
//		peProperty	- Contains variables and other information
//		
//	Modification:
/////////////////////////////////////////////////////////////////////


package mod.prmext;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;

import oct.codegen.phase;
import oct.codegen.resultManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.dom4j.Document;
import org.dom4j.Element;

class PEFetcher implements PEConstants {
	private final static String BLOGS = "blogs";
	
	private String [] blogVarArr;
	private ArrayList blogSortArr;
	private boolean isBlog;
	
	PstAbstractObject [] pstObjArr;
	String [] variableArr;
	String req;
	String type;
	PEXmlWriter peXmlWriter;
	PstUserAbstractObject pstuser;
	HashMap nameMap;
	
	public PEFetcher() {
		pstObjArr = null;
		variableArr = null;
		req = null;
		type = null;
		peXmlWriter = null;
		pstuser = null;
		nameMap = null;
		
		blogVarArr = null;
		blogSortArr = new ArrayList();
		isBlog = false;
	}
	
	/**
	 * Initialize PEFetcher. Extracts req, type and variable information 
	 * from peProperty. 
	 * @param pstObjArr 	An array of pstObj already cast to it's type
	 * @param peProperty	The peProperty class which contains information 
	 * 						of the type and required attributes to fetch from 
	 * 						the database. 
	 */
	public PEFetcher(PstAbstractObject [] pstObjArr, PEProperty peProperty, PstUserAbstractObject pstuser) {
		this();
		this.pstObjArr = pstObjArr;
		this.req = peProperty.getReq();
		this.type = peProperty.getType();
		this.peXmlWriter = new PEXmlWriter(PRMEXT);
		this.pstuser = pstuser;
		this.nameMap = new HashMap();
		
		Object [] tempArr = peProperty.getVariableArr().toArray();
		this.variableArr = new String[tempArr.length];
		for (int i=0; i<tempArr.length; i++) 
			this.variableArr[i] = tempArr[i].toString();
		
		String s;
		tempArr = peProperty.getBlogVarArr().toArray();
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
	}
	
	/**
	 * Creates an Xml document and starts creating child elements into the Xml document
	 * with the initialized objects. For each object it will fetch the information from
	 * the database and stores the into the document. Once this process is finished the
	 * document can be retrieved through @see getDocument().
	 * @return true is successful; false is not
	 */
	final public boolean createObjectIntoXml() 
		throws PmpException {
		try {
			if (pstObjArr != null && variableArr != null && req !=  null) {
				Element reqElement = peXmlWriter.addToRootElement(req);
				
				for (int i=0; i<pstObjArr.length; i++) {
					PstAbstractObject pstObj = pstObjArr[i];
					fetchObjectToXml(reqElement, pstObj);
				}
				return true;
			}
			else
				return false;
		} catch (PmpException e) {
			e.printStackTrace();
			// error in retrieving attribute
			throw e;
		}
	}
	
	/**
	 * Handles Normal Types
	 * @param reqElement
	 * @param pstObj
	 * @throws PmpException
	 */
	protected void fetchObjectToXml(Element reqElement, PstAbstractObject pstObj) 
		throws PmpException {
		// Create HashMap attribute (ID)
		HashMap map = new HashMap();
		map.put(ID, String.valueOf(pstObj.getObjectId()));
		Element curElement = peXmlWriter.addToElement(reqElement, type, map);
		
		fetchVarToXml(curElement, pstObj);
	}

	protected void fetchVarToXml(Element curElement, PstAbstractObject pstObj) 
	throws PmpException {
		fetchVarToXml(curElement, pstObj, null, null);
	}
	
	/**
	 * Handles Normal Attributes Fetching
	 * @param curElement
	 * @param pstObj
	 * @throws PmpException
	 */
	protected void fetchVarToXml(Element curElement, PstAbstractObject pstObj, String type, String [] variableArr) 
		throws PmpException {
		if (type == null) type = this.type;
		if (variableArr == null) variableArr = this.variableArr;
		
		// Loop through different required variables 
		for (int i=0; i<variableArr.length; i++) {
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
				else {
					Object [] attObjArr = null;
					int attTypeId = PEManager.getAttributeType(type, variableArr[i]);			
					switch (attTypeId) {
					case 0: 					// name
						peXmlWriter.addToElement(curElement, variableArr[i], pstObj.getObjectName());
						break;
					case PstAbstractObject.RAW: // binary 
						createRawAttChildInXml(curElement, pstObj, variableArr[i]);
						break;
					case PstAbstractObject.DATE:	// date
						attObjArr = pstObj.getAttribute(variableArr[i]);
						if (attObjArr[0] != null) {
							for (int j=0; j<attObjArr.length; j++) {
								attObjArr[j] = phase.parseDateToString((Date)attObjArr[j], DATESTANDARDFORMAT);
							}
						}
						createAttChildInXml(curElement, attObjArr, variableArr[i]);
						break;
					default: 					// normal variables
						attObjArr = pstObj.getAttribute(variableArr[i]);
						// change userId to Full Name
						if (PEManager.isUserIdAttribute(variableArr[i]))				
							PEManager.userIdToFullName(attObjArr, pstuser, nameMap);
						createAttChildInXml(curElement, attObjArr, variableArr[i]);
						break;
					}
				}
			}
		}
	}

	protected void createRawAttChildInXml(Element curElement, PstAbstractObject pstObj, String variable) 
		throws PmpException {
		createRawAttChildInXml(curElement, pstObj, variable, null);
	}
	
	/**
	 * Handles raw/binary attribute types. Translates the binary data into a byte array and
	 * writes to a xml child.
	 * @param curElement
	 * @param pstObj
	 * @param variable variable name
	 * @throws PmpException
	 */
	protected void createRawAttChildInXml(Element curElement, PstAbstractObject pstObj, String variable, String tagName) 
		throws PmpException {
		if (variable != null) {
			if (tagName == null) tagName = variable;
			
			Object attObj = pstObj.getAttribute(variable)[0];
			if (attObj != null) {
				byte [] byteArr = (byte[])attObj;
				if (byteArr.length > 0) {
					for (int i=0; i<byteArr.length; i++) {
						if (byteArr[i] == -96)
							byteArr[i] = 32;
					}
					String attObjS = new String(byteArr);
					peXmlWriter.addToElement(curElement, tagName, attObjS, true);
				}
			}
		}
	}
	
	/**
	 * Loops through all the attributes and creates a child element into the 
	 * curElement. 
	 * @param curElement
	 * @param attObjArr
	 * @param variable variable name
	 */
	protected void createAttChildInXml(Element curElement, Object[] attObjArr, String variable) {
		// Loop through each value and create an child tag
		if (attObjArr[0] != null) {
			for (int i=0; i<attObjArr.length; i++) {
				peXmlWriter.addToElement(curElement, variable, attObjArr[i].toString());
			}
		}
	}
	
	/**
	 * Retreives the Xml with all the requested pstObj attributes nicely labeled.<br />
	 * <pre>
	 * &lt;PrmExt&gt;
	 * &nbsp;&lt;<u>req name</u>&gt;
	 * &nbsp;&nbsp;&lt;<u>type name</u> id="..."&gt;
	 * &nbsp;&nbsp;&nbsp;&lt;<u>variable name</u>&gt;
	 * &nbsp;&nbsp;&nbsp;&nbsp;<b>information</b>
	 * &nbsp;&nbsp;&nbsp;&lt;/<u>variable name</u>&gt;
	 * &nbsp;&nbsp;&nbsp;...
	 * &nbsp;&nbsp;&nbsp;...
	 * &nbsp;&nbsp;&lt;/<u>type name</u>&gt;
	 * &nbsp;&nbsp;...
	 * &nbsp;&nbsp;...
	 * &nbsp;&lt;/<u>req name</u>&gt;
	 * &lt;/PrmExt&gt;
	 * </pre> 
	 * @return
	 */
	public Document getDocument() {
		return peXmlWriter.getDoc();
	}
}
