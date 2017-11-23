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
//
//		@AGQ041906	Removed attributes feature and CDATA on blog feature
//
/////////////////////////////////////////////////////////////////////

package mod.prmext;

import java.util.HashMap;
import java.util.Iterator;

import org.dom4j.Document;
import org.dom4j.DocumentHelper;
import org.dom4j.Element;


public class PEXmlWriter {	
	private Document doc;
	private Element root;
	
	public PEXmlWriter() {
		doc = null;
		root = null;
	}
	
	public PEXmlWriter(String root) {
		this();
		doc = DocumentHelper.createDocument();
		//doc.setXMLEncoding("UTF-16");
		this.root = doc.addElement(root);
	}
	
	// Provide an insert method
	public boolean insertToElement(String elementName, String name, HashMap attribute, String text) {
		
		return false;
	}
	
	public Element addToRootElement(String name) {
		return addToRootElement(name, null, null);
	}
	
	public Element addToRootElement(String name, String text) {
		return addToRootElement(name, null, text);
	}
	
	public Element addToRootElement(String name, HashMap attribute) {
		return addToRootElement(name, attribute, null);
	}
	
	public Element addToRootElement(String name, HashMap attribute, String text) {
		return addToElement(root, name, attribute, text);
	}
	
	public Element addToElement(Element element, String name) {
		return addToElement(element, name, null, null);
	}
	
	public Element addToElement(Element element, String name, String text) {
		return addToElement(element, name, null, text, false);
	}
	
	public Element addToElement(Element element, String name, String text, boolean isBinary) {
		return addToElement(element, name, null, text, isBinary);
	}
	
	public Element addToElement(Element element, String name, HashMap attribute) {
		return addToElement(element, name, attribute, null);
	}
	
	public Element addToElement(Element element, String name, HashMap attribute, String text) {
		return addToElement(element, name, attribute, text, false);
	}
	
	/**
	 * Create a basic xml child into the given element with the supplied name, attributes, and text.
	 * If the name or element is null, then nothing is created.  
	 * @param element The parent of this new child element
	 * @param name The name of the new child element
	 * @param attribute 
	 * @param text
	 * @param isBinary
	 * @return The newly created child element or null if nothing was created
	 */
	public Element addToElement(Element element, String name, HashMap attribute, String text, boolean isBinary) {
		if (element != null && name != null && name.length() > 0) {
// @AGQ050506
			// Filter Out Expire -> Due
			if (name.equalsIgnoreCase("ExpireDate"))
				name = "DueDate";
			else if (name.equalsIgnoreCase("PlanExpireDate"))
				name = "PlanDueDate";
			
			// Create child element
			Element newElement = element.addElement(name);
			// Add Attributes
			if (attribute != null) {
// @AGQ041906
				Iterator it = attribute.keySet().iterator();
				while(it.hasNext()) {
					String curKey = it.next().toString();
					newElement.addAttribute(curKey, attribute.get(curKey).toString());
				}
			}
			// Add Text
			
			if (text != null && text.length() > 0) {
// @AGQ041906
				//if (isBinary)
					//newElement.addCDATA(text);
				//else
					newElement.addText(text);
			}

		
			return newElement;
		}
		else
			return null;
	}

	public Document getDoc() {
		return doc;
	}
}
