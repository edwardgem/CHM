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
//
//  Required:
//		
//	Modification:
/////////////////////////////////////////////////////////////////////

package mod.prmext;

import java.io.IOException;
import java.util.ArrayList;
import java.util.TreeSet;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

import com.sun.org.apache.xerces.internal.parsers.DOMParser;

public class PEProperty implements PEConstants{
	private static final String DELIM = ",";
	private static final int VARIABLEARR = 0;
	private static final int SORTEDBYARR = 1;
	private static final int BLOGVARARR = 2;
	private static final int BLOGSORTARR = 3;
	
	private String req;
	private String prmExtFile;
	private ArrayList variableArr;
	private ArrayList blogVarArr;
	private ArrayList sortedByArr;
	private ArrayList blogSortArr;
	private String type;
	
	public PEProperty() {
		req = null;
		prmExtFile = null;
		variableArr = new ArrayList();
		sortedByArr = new ArrayList();
		blogVarArr = new ArrayList();
		blogSortArr = new ArrayList();
		type = null;
	}
	
	public PEProperty(String req, String prmExtFile) throws Exception{
		this();
		this.req = req;
		this.prmExtFile = prmExtFile;
		readPropertiesFile();
	}
	
	final private void readPropertiesFile() 
		throws Exception {
		try {			
			if (prmExtFile != null) {
				DOMParser domXMLParser = new DOMParser();
			    domXMLParser.parse(prmExtFile);
			    Document doc = domXMLParser.getDocument();  
		        
		        // normalize text representation
				doc.getDocumentElement().normalize();
		
				NodeList listOfReq = doc.getElementsByTagName(req);
				int totalReq = listOfReq.getLength();

				if (totalReq > 0) {
					for(int i=0; i<1; i++) {
						Node curReqNode = listOfReq.item(i);
						if(curReqNode.getNodeType() == Node.ELEMENT_NODE){
							Element curElement = (Element)curReqNode;
							
							if (curElement.hasAttribute(TYPE)) {
								setType(curElement.getAttribute(TYPE));
							}
							else {
								// TODO: handle no attributes
								// handle no type break; or throw sax exception
							}
							
							// handles blog node
							NodeList blogList = curElement.getElementsByTagName("blogs");
							if (blogList.getLength() > 0) {
								Node blogNode = blogList.item(0);
								Element blogElement = (Element) blogNode;
								
								getTagArrItems(blogElement, OUTPUT, BLOGVARARR);
								getTagArrItems(blogElement, SORTEDBY, BLOGSORTARR);
							}
							
							getTagArrItems(curElement, OUTPUT, VARIABLEARR);
							getTagArrItems(curElement, SORTEDBY, SORTEDBYARR);
						}
					}
				}
				// could not find req
				else {
					throw new IOException();
					// should be some kinda sax exception 
				}
			}
		} catch (IOException e) {
			e.printStackTrace();
			throw e;
		} catch (SAXParseException e) {
			// Parsing Error
			System.out.println ("** Parsing error" + ", line " 
		             + e.getLineNumber () + ", uri " + e.getSystemId ());
		        System.out.println(" " + e.getMessage ());
			e.printStackTrace();
			throw e;
		} catch (SAXException e) {
			// Parsing File Error
			Exception x = e.getException ();
	        ((x == null) ? e : x).printStackTrace ();
			e.printStackTrace();
			throw e;
		} 
	}

// **********************
// Getters and Setters
// **********************

	public String getPrmExtFile() {
		return prmExtFile;
	}

	public void setPrmExtFile(String prmExtFile) {
		this.prmExtFile = prmExtFile;
	}

	public String getReq() {
		return req;
	}

	public void setReq(String req) {
		this.req = req;
	}

	/**
	 * Changes the arraylist into a TreeSet and back
	 * to an array to remove duplicates
	 * @return
	 */
	public ArrayList getVariableArr() {
		return new ArrayList( new TreeSet(variableArr));
	}

	public void setVariableArr(ArrayList variableArr) {
		this.variableArr = variableArr;
	}
	
	public void appendVariableArr(String variable) {
		if (variable.length() > 0)
			variableArr.add(variable);
	}
	
	public ArrayList getSortedByArr() {
		return sortedByArr;
	}
	
	public void setSortedByArr(ArrayList sortedByArr) {
		this.sortedByArr = sortedByArr;
	}
	
	public void appendSortedByArr(String sortedBy) {
		if (sortedBy.length() > 0)
			sortedByArr.add(sortedBy);
	}
	
	public ArrayList getBlogVarArr() {
		return new ArrayList( new TreeSet(blogVarArr));
	}

	public ArrayList getBlogSortArr() {
		return blogSortArr;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}
	
	/* Try to calculate the time for this method	                   
    StringBuffer sb = new StringBuffer();
    for (int j=0; j<variables.length(); j++) {
    	char curChar = variables.charAt(j);
    	if (curChar == ',') {
    		if (sb.length() > 0) {
        		appendVariableArr(sb.toString().trim());
        		sb.delete(0, sb.length());
    		}
    	}
    	else
    		sb.append(curChar);
    }
    if (sb.length() > 0) {
    	appendVariableArr(sb.toString());
    	sb.delete(0, sb.length());
    }
*/
	
	private int getIntValue(String variableName) {
		//if (variableName.equalsIgnoreCase())
		return 0;
	}
	
	private void getTagArrItems(Element curElement, String tagName, int arrName) {
		NodeList outputList = curElement.getElementsByTagName(tagName);
		int length = outputList.getLength();
		int j;
		for (j=0; j<length; j++) {
			Element outputElement = (Element)outputList.item(j);
			if (curElement.getNodeName().equalsIgnoreCase(outputElement.getParentNode().getNodeName())) {				
				curElement.getNodeName();
				NodeList textFNList = outputElement.getChildNodes();
				if (textFNList.getLength() > 0) { 					
					String variables = ((Node)textFNList.item(0)).getNodeValue().trim();
	                  
					String [] variableArr = variables.split(DELIM);
					for (int i=0; i<variableArr.length; i++) {
						setArrValues(variableArr[i].trim(), arrName);
					}
				}
				break;
			}
		}
		if (j == length)
			System.out.println("Cannot find " + tagName);
	}
	
	private void setArrValues(String value, int arrName) {
		switch (arrName) {
		case VARIABLEARR:
			appendVariableArr(value);
			break;
		case SORTEDBYARR:
			appendSortedByArr(value);
			break;
		case BLOGVARARR:
			if (value.length() > 0)
				blogVarArr.add(value);
			break;
		case BLOGSORTARR:
			if (value.length() > 0)
				blogSortArr.add(value);
			break;
		}
	}
}
