//
//  Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   robot.java
//  Author: FastPath CodeGen Engine
//  Date:   06.16.2006
//  Description:
//		Implementation of robot class
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//		@033004ECC	Support appending single data value to multiple data attribute.
//
/////////////////////////////////////////////////////////////////////
//
// robot.java : implementation of the robot class
//

package oct.codegen;
import java.io.IOException;
import java.io.StringReader;
import java.io.UnsupportedEncodingException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import mod.bots.ObdAjax;
import net.sf.json.JSONObject;
import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.omm.client.OmsWebservice;
import oct.omm.util.OmsXMLDriver;
import oct.pmp.exception.PmpCommitObjectException;
import oct.pmp.exception.PmpDeleteObjectException;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpInvalidAttributeException;
import oct.pmp.exception.PmpManagerCreationException;
import oct.pmp.exception.PmpObjectCreationException;
import oct.pmp.exception.PmpObjectException;
import oct.pmp.exception.PmpRawGetException;
import oct.pmp.exception.PmpTypeMismatchException;
import oct.pmp.exception.PmpUnsupportedTypeException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;
import util.StringUtil;
import util.XML;

/**
 *
 * <b>General Description:</b>  robot extends PmpAbstractObject.  This class
 * encapsulates the data of a member from the "robot" organization.
 *
 * The robot class provides a facility to modify data of an existing robot object.
 *
 *
 *
 * <b>Class Dependencies:</b>
 *   oct.custom.robotManager
 *   oct.pmp.PmpUser
 *   oct.pmp.PmpUserManager
 *
 *
 * <b>Miscellaneous:</b> There are methods that will be deprecated in future versions.
 *
 */


public class robot extends PstAbstractObject
{

	//Private attributes
	static final String TAG_DOMAIN			= "Domain";				// distributive domain specification
	static final String TAG_EXPR			= "Expr";
	static final String TAG_EVAL_METHOD		= "Eval_Method";		// class.method name for eval() entry-point
	static final String TAG_ACCESS_METHOD	= "Access_Method";		// class.method name accessing SQL attributes
	static final String TAG_URL				= "URL";				// webservice URL
	static final String TAG_AUTH			= "Authcode";			// authorization code to access webservice
	static final String TAG_XML				= "XML";				// external XML Filename

	static final String LOCALHOST			= "localhost";


	static robotManager manager;

	/**
	 * Constructor for instantiating a new robot.
	 * @param member An OmsMember representing a robot.
	 */
	public robot(OmsMember member)
	{
		super(member);
		try
		{
			manager = robotManager.getInstance();
		}
		catch(PmpException pe)
		{
			//throw new PmpInternalException("Error getting robotManager instance.");
		}
	}//End Constructor





	/**
	 * Constructor for instantiating a new robot.
	 * @param userObj A PmpUesr.
	 * @param org An organization.
	 * @param memberName The name of the member.
	 * @param password The password of the member.
	 */
	robot(PstUserAbstractObject userObj, OmsOrganization org, String memberName, String password)
			throws PmpException
			{
		super(userObj, org, memberName, password);
			}



	/**
	 * Constructor for creating a robot.  Used by robotManager.
	 * @param userObj A PmpUser.
	 * @param org The OmsOrganization for the robot.
	 */
	robot(PstUserAbstractObject userObj, OmsOrganization org)
			throws PmpObjectCreationException, PmpInternalException
			{
		super(userObj, org, "");
		try
		{
			manager = robotManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting robotManager instance.");
		}
			}//End Constructor

	/**
	 * Constructor for creating a robot.
	 * @param session An OmsSession.
	 * @param org The OmsOrganization for the robot.
	 */
	robot(OmsSession session, OmsOrganization org)
			throws PmpObjectCreationException, PmpInternalException
			{
		super(session, org, "");
		try
		{
			manager = robotManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting robotManager instance.");
		}
			}//End Constructor

	/**
	 * Constructor for creating a robot using a member name.
	 * @param userObj A PmpUser.
	 * @param org The OmsOrganization for the robot.
	 * @param robotMemName The member name for the created robot.
	 */
	robot(PstUserAbstractObject userObj, OmsOrganization org, String robotMemName)
			throws PmpObjectCreationException, PmpInternalException
			{
		super(userObj, org, robotMemName, null);
		try
		{
			manager = robotManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting robotManager instance.");
		}
			}//End Constructor

	/**
	 * Constructor for creating a robot using a member name.
	 * @param session An OmsSession.
	 * @param org The OmsOrganization for the robot.
	 * @param companyMemberName The member name for the created robot.
	 */
	robot(OmsSession session, OmsOrganization org, String robotMemName)
			throws PmpObjectCreationException, PmpInternalException
			{
		super(session, org, robotMemName, null);
		try
		{
			manager = robotManager.getInstance();
		}
		catch(PmpManagerCreationException pe)
		{
			throw new PmpInternalException("Error getting robotManager instance.");
		}
			}//End Constructor


	/**
	 * Currentyly Not Implemented.
	 * Determine whether attribute is settable.
	 * @param attributeName Name of attribute.
	 */
	private boolean isSetAuthorized(String attributeName)
	{
		return true;

	}//End isSetAuthorized

	/**
	 * Set attribute value.
	 * @param attributeId The attribute id.
	 * @param attributeValue The single value to set the attribute to.
	 * @exception PmpInvalidAttributeException The attribute is invalid.
	 * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
	 * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
	 * @exception PmpInteralException An internal error occurred.
	 */
	public void setAttribute(int attributeId, Object attributeValue)
			throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
	{
		String attributeName = manager.getAttributeName(attributeId);
		setAttribute(attributeName, attributeValue, false);
	}//End setAttribute

	/**
	 * Set attribute of multiple values.  Does not support setting raw datatype with multiple values.
	 * @param attributeId The attribute id.
	 * @param attributeValues The array of values to set the attribute to.
	 * @exception PmpInvalidAttributeException The attribute is invalid.
	 * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
	 * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
	 * @exception PmpInteralException An internal error occurred.
	 */
	public void setAttribute(int attributeId, Object [] attributeValues)
			throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
	{
		String attributeName = manager.getAttributeName(attributeId);
		setAttribute(attributeName, attributeValues);
	}//End setAttribute

	/**
	 * Append attribute value.
	 * @param attributeId The attribute id.
	 * @param attributeValue The single value to set the attribute to.
	 * @exception PmpInvalidAttributeException The attribute is invalid.
	 * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
	 * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
	 * @exception PmpInteralException An internal error occurred.
	 */
	public void appendAttribute(int attributeId, Object attributeValue)
			throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
	{
		String attributeName = manager.getAttributeName(attributeId);
		setAttribute(attributeName, attributeValue, true);
	}//End setAttribute

	/**
	 * Append attribute value.
	 * @param attributeName The attribute name.
	 * @param attributeValue The single value to set the attribute to.
	 * @exception PmpInvalidAttributeException The attribute is invalid.
	 * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
	 * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
	 * @exception PmpInteralException An internal error occurred.
	 */
	public void appendAttribute(String attributeName, Object attributeValue)
			throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
	{
		setAttribute(attributeName, attributeValue, true);
	}

	/**
	 * Set attribute value.
	 * @param attributeName The attribute name.
	 * @param attributeValue The single value to set the attribute to.
	 * @exception PmpInvalidAttributeException The attribute is invalid.
	 * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
	 * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
	 * @exception PmpInteralException An internal error occurred.
	 */
	public void setAttribute(String attributeName, Object attributeValue)
			throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
	{
		setAttribute(attributeName, attributeValue, false);
	}


	/**
	 * Set attribute value.
	 * @param attributeName The attribute name.
	 * @param attributeValue The single value to set the attribute to.
	 * @param bAppend True if the attribute value is to append to the current value list
	 * @exception PmpInvalidAttributeException The attribute is invalid.
	 * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
	 * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
	 * @exception PmpInteralException An internal error occurred.
	 */
	protected void setAttribute(String attributeName, Object attributeValue, boolean bAppend)
			throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
	{
		if(! manager.isValueValid(attributeName, attributeValue))
		{
			throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
		}

		if(isSetAuthorized(attributeName) == false)
		{
			throw new PmpInvalidAttributeException("Not authorized to set.");
		}

		if(manager.getAttributeType(attributeName) == RAW)
		{
			if(attributeValue instanceof byte[] || attributeValue==null)
			{
				super.setRawData(attributeName, (byte [])attributeValue);
			}
			else
			{
				throw new PmpTypeMismatchException("Data is not of RAW type.");
			}
		}
		else
		{
			super.setData(attributeName, attributeValue, bAppend);	// support appending data
		}

	}//End setAttribute

	/**
	 * Set attribute of multiple values.  Does not support setting raw datatype with multiple values.
	 * @param attributeName The attribute name.
	 * @param attributeValues The array of values to set the attribute to.
	 * @exception PmpInvalidAttributeException The attribute is invalid.
	 * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
	 * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
	 * @exception PmpInteralException An internal error occurred.
	 */
	public void setAttribute(String attributeName, Object [] attributeValues)
			throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
	{
		if(! manager.isValueValid(attributeName, attributeValues))
		{
			throw new PmpTypeMismatchException("Attribute values has an incorrect type.");
		}
		else if(manager.getAttributeType(attributeName)== RAW)
		{
			//Delete raw data value if null
			if(attributeValues == null)
			{
				super.setRawData(attributeName,null);
			}
			else
			{
				throw new PmpUnsupportedTypeException("Raw data with multiple values is not supported.");
			}
		}

		if(isSetAuthorized(attributeName) == false)
		{
			throw new PmpInvalidAttributeException("Not authorized to set.");
		}

		super.setData(attributeName, attributeValues);

	}//End setAttribute

	/**
	 * Remove an attribute value from a multi-value attribute.
	 * @param attributeName The attribute name.
	 * @param attributeValue The single value to be remove from the list.
	 * @exception PmpInvalidAttributeException The attribute is invalid.
	 * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
	 * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
	 * @exception PmpInteralException An internal error occurred.
	 */
	public void removeAttribute(String attributeName, Object attributeValue)
			throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
	{
		if(! manager.isValueValid(attributeName, attributeValue))
		{
			throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
		}

		if(manager.getAttributeType(attributeName) == RAW)
		{
			throw new PmpUnsupportedTypeException("This API does not support RAW datatype.");
		}
		else
		{
			super.removeData(attributeName, attributeValue);
		}

	}//End removeAttribute
	/**
	 * Remove an attribute value from a multi-value attribute.
	 * @param attributeName The attribute name.
	 * @param attributeValue The single value to be remove from the list.
	 * @exception PmpInvalidAttributeException The attribute is invalid.
	 * @exception PmpUnsupportedTypeException The type of the attributeValue is not supported.
	 * @exception PmpTypeMismatchException The type of the attributeValue does not match the real type for the attribute.
	 * @exception PmpInteralException An internal error occurred.
	 */
	public void removeAttributeIgnoreCase(String attributeName, Object attributeValue)
			throws PmpUnsupportedTypeException, PmpInvalidAttributeException, PmpTypeMismatchException, PmpObjectException, PmpInternalException, PmpManagerCreationException
	{
		if(! manager.isValueValid(attributeName, attributeValue))
		{
			throw new PmpTypeMismatchException("Attribute value has an incorrect type.");
		}

		if(manager.getAttributeType(attributeName) == RAW)
		{
			throw new PmpUnsupportedTypeException("This API does not support RAW datatype.");
		}
		else
		{
			super.removeDataIgnoreCase(attributeName, attributeValue);
		}

	}//End removeAttributeIgnoreCase

	/**
	 * Get the attribute value.
	 * @param attributeId The attribute id.
	 * @exception PmpInvalidAttributeException The attribute does not exist.
	 * @exception PmpRawGetException An error occurred obtaining the raw data.
	 * @exception PmpInteralException An internal error occurred.
	 * @return A non-empty array of Object values for that attribute.
	 */
	public Object [] getAttribute(int attributeId)
			throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException
	{
		String attributeName = manager.getAttributeName(attributeId);
		return getAttribute(attributeName);
	}//End getAttribute

	/**
	 * Get the attribute value.
	 * @param attributeName The attribute name.
	 * @exception PmpInvalidAttributeException The attribute does not exist.
	 * @exception PmpRawGetException An error occurred obtaining the raw data.
	 * @exception PmpInteralException An internal error occurred.
	 * @return A non-empty array of Object values for that attribute.
	 */
	public Object [] getAttribute(String attributeName)
			throws PmpObjectException, PmpManagerCreationException, PmpInvalidAttributeException, PmpRawGetException, PmpInternalException, PmpException
	{
		if(manager.getAttributeType(attributeName) == RAW)
		{
			byte [] rawResult = super.getRawData(attributeName);
			Object [] finalResult = new Object[1];
			finalResult[0] = rawResult;
			return finalResult;
		}

		if(manager.hasMultipleValues(attributeName))
		{
			return super.getMultipleData(attributeName, manager.getAttributeType(attributeName));
		}
		else
		{
			Object [] finalResult = new Object[1];
			finalResult[0] = super.getSingleData(attributeName, manager.getAttributeType(attributeName));
			return finalResult;
		}

	}//End getAttribute


	protected void delete()
			throws PmpDeleteObjectException
	{
		super.delete();
	}//End delete

	protected void save()
			throws PmpCommitObjectException
	{
		super.save();
	}//End save

	protected boolean refresh()
	{
		return super.refresh();
	}//End refresh

	/**
	 * key method for robot firing, for running the eval() program of the robot.
	 * This method may call evalRemote() to send do webservice call to remote node.
	 * 
	 * @param user
	 * @param expr overriding expression for learning.
	 * @param otherParams such as requesting for data visualization.
	 * @param node the node to run this robot, rather than all node on the xml.
	 * @return
	 */
	public String eval(String expr, String otherParams, String node)
			throws PmpException
	{
		System.out.println("in robot.eval() method ...");
		String retJSON = null;		// return JSON String

		// check the organization type, only support OMS_NON_NATIVE_NONUSER_ORG or OMS_NON_NATIVE_USER_ORG
		// to access eval()

		// XML is in the Content attribute of the robot


		// get the XML of this robot
		String xml = null;
		try {xml = this.getRawAttributeAsUtf8("Content");}
		catch (UnsupportedEncodingException e1) {}
		if (StringUtil.isNullOrEmptyString(xml)) {
			throw new PmpException("eval() failed: XML Content in robot cannot be empty.");
		}


		// if caller indicate this is a localhost eval
		boolean isLocalHost = node==null || node.contains(LOCALHOST);

		// extract from XML the user-defined entry point of eval()
		int idx;
		String s;
		Element root;
		
		
		// Document parser can't take && or < signs
		if (xml.indexOf('&')!=-1 && xml.indexOf("&amp;")==-1) {
			xml = xml.replaceAll("&", "&amp;");		// escape & sign in the condition expression &\\s+
			xml = xml.replaceAll("<=", "&lt;&#61;");
		}


		//////////////////
		// 1. get XML root node
		try {
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			DocumentBuilder builder = factory.newDocumentBuilder();
			InputSource is = new InputSource(new StringReader(xml));
			//is.setEncoding("ISO-8859-1");
			Document document = builder.parse(is);

			root = document.getDocumentElement();

		} catch (ParserConfigurationException
				| SAXException
				| IOException e) {
			System.out.println("eval() got exception: " + e.getMessage());
			throw new PmpException(e.getMessage());
		}

		// 2A. Check to see if it is a distributive processing (w/ Domain element)
		// note: on remote node there is no domain specification in XML
		List<JSONObject> domainsArray = new ArrayList<JSONObject>();
		boolean bFoundSpecifiedDomain = false;

		NodeList list = root.getElementsByTagName(TAG_DOMAIN);
		if (!isLocalHost && list != null && list.getLength() > 0) {
			System.out.println("!! processing Distributive robot eval: " + getObjectName());

			Element oneDomain;
			JSONObject tempJSON;
			String nodeStr;

			for (int i=0; i<list.getLength(); i++) {
				oneDomain = (Element) list.item(i).getChildNodes();	// one domain

				if (oneDomain != null) {
					nodeStr = OmsXMLDriver.getXMLString(TAG_URL, oneDomain);

					// check if caller only wants to eval() in one node at a time
					if (node != null) {
						// caller has specified a domain to eval()
						if (!nodeStr.contains(node))
							continue;
						bFoundSpecifiedDomain = true;
						System.out.println("   eval() on one node: " + nodeStr);
					}


					//////////////////
					// localhost specified in remote eval
					String ret = null;
					if (nodeStr.equals(LOCALHOST)) {
						ret = eval(expr, otherParams, LOCALHOST);
					}

					//////////////////
					// start remote eval()
					else {
						tempJSON = evalRemote(expr, otherParams, oneDomain);
						if (tempJSON != null) {
							domainsArray.add(tempJSON);
						}
					}

					if (ret != null) {
						// need to package the return string from one domain or localhost
						Map<String, String> domPart = new HashMap<String, String>();
						domPart.put("domain", nodeStr);
						domPart.put("result", ret);
						if ((tempJSON = JSONObject.fromObject(domPart)) != null) {
							domainsArray.add(tempJSON);
						}
					}

					if (bFoundSpecifiedDomain)
						break;					// just need to complete this one domain processing
				}
			}	// END: for each domain

			
			// JSON return combining all remote domains returns
			Map<String, Object> domMap = new HashMap<String, Object>();
			domMap.put("evals", domainsArray);

			JSONObject aJSON = JSONObject.fromObject(domMap);
			retJSON = aJSON.toString();
			System.out.println(">> eval() return from resolving remote eval() len:" + retJSON.length());

		}	// END: if multiple domains
		
		
		/*********************************************************************************************/
		///////////////////////////////
		// local domain processing
		else {
			
			////////////////////
			// 2B. local call the Access_Method in XML, a generic API [by kejl] to get the attribute values
			//     in an CSV format pass the expr to the method
			System.out.println("!! processing Local robot eval: " + getObjectName());

			if (StringUtil.isNullOrEmptyString(expr)) {
				// get expr from XML if there is no override expr
				if ((expr = XML.getXMLString(TAG_EXPR, root)) != null) {
					expr = expr.replaceAll("&amp;", "&").replaceAll("&lt;", "<").replaceAll("&gt;", ">");
				}
			}
			
			// access database to get raw data as CSV string
			String retCSV = null;		// get return from kejl's method, passing expr
			s = XML.getXMLString(TAG_ACCESS_METHOD, root);
			idx = s.lastIndexOf(".");
			if (idx == -1) {
				throw new PmpException("eval() <"+TAG_ACCESS_METHOD+"> tag illegal class.method expression: " + s);
			}
			String accessClassName  = s.substring(0,idx).trim();
			String accessMethodName = s.substring(idx+1).trim();
			System.out.println("eval() evokes ACCESS METHOD: className+methodName = " + accessClassName + "+" + accessMethodName);
			
			try {
				Class<?> c = Class.forName(accessClassName);
			    Object t = c.newInstance();
			    Method m = null;
			    
			    Method[] allMethods = c.getDeclaredMethods();
			    for (Method mm : allMethods) {
			    	if (mm.getName().equals(accessMethodName)) {
			    		m = mm;
			    		break;
			    	}
			    }

			    // access method expects two parameters, namely orgName (not used) and expression
			    m.setAccessible(true);
			    retCSV = (String) m.invoke(t, this.getObjectName(), expr);
			}
			catch (ClassNotFoundException
					| InstantiationException
					| IllegalAccessException
					| InvocationTargetException e) {
				System.out.println("eval() got exception when calling ACCESS method: "
					+ e.getClass().getName() + " - " + e.getMessage());
				throw new PmpException(e.getMessage());
			}

			
			//////////////////
			// 3. local call the eval() Entry method of user and get an Object back.
			//    Get class.method names (user [zouhf] defined) from XML for eval() method
			
			s = OmsXMLDriver.getXMLString(TAG_EVAL_METHOD, root);
			idx = s.lastIndexOf(".");
			if (idx == -1) {
				throw new PmpException("eval() <"+TAG_EVAL_METHOD+"> tag illegal class.method expression: " + s);
			}
			String evalClassName  = s.substring(0,idx).trim();
			String evalMethodName = s.substring(idx+1).trim();
			System.out.println("eval() evokes EVAL METHOD: className+methodName = " + evalClassName + "+" + evalMethodName);
			
			try {
				Class<?> c = Class.forName(evalClassName);
			    Object t = c.newInstance();
			    Method m = null;
			    
			    Method[] allMethods = c.getDeclaredMethods();
			    for (Method mm : allMethods) {
			    	if (mm.getName().equals(evalMethodName)) {
			    		m = mm;
			    		break;
			    	}
			    }
			    
			    retJSON = (String) m.invoke(t, retCSV, otherParams);
				System.out.println(">> eval() return from resolving local eval() len:" + retJSON.length());
			}
			catch (ClassNotFoundException
					| InstantiationException
					| IllegalAccessException
					| InvocationTargetException e) {
				System.out.println("robot.eval() got exception when calling " + evalMethodName + " method: " + e.getMessage());
				throw new PmpException(e.getMessage());
			}
		}	// END: else local domain processing
		

		// return result to caller
		return retJSON;				// DONE!! organization is distributed

	}


	private JSONObject evalRemote(String expr, String otherParams, Element oneDomain)
		throws PmpException
	{
		// call Webservice to perform eval() on the distributed organization
		System.out.println("<-- " + this.getObjectName() + ".evalRemote() begin");
		JSONObject retJSON = null;
		
		String node = OmsXMLDriver.getXMLString(TAG_URL, oneDomain);
		if (!node.startsWith("http")) node = "http://" + node;
		
		String authStr = OmsXMLDriver.getXMLString(TAG_AUTH, oneDomain);
		System.out.println("url=" + node + "; auth=" + authStr);
		
		String wsURI = ObdAjax.getNodeWS(node);

		if (wsURI!=null && authStr!=null) {
			// ready to call
			
			// get username and password strings
			String [] sa = authStr.split("::");
			if (sa.length != 2) {
				throw new PmpException("AUTHCODE must contain username and password separated by (::) " + authStr);
			}
			
			String username = sa[0];
			String password = sa[1];				// should encrypt this
			
			// Webservice call
			String retStr = OmsWebservice.eval(
					wsURI, this.getObjectName(), username, password, expr, otherParams);
			
			Map<String, String> domPart = new HashMap<String, String>(); // creator: { }
			domPart.put("domain", node);
			domPart.put("result", retStr);
			retJSON = JSONObject.fromObject(domPart);
			
			System.out.println("--> " + this.getObjectName() + ".evalRemote() end: got result, size: " + retJSON.size());
		}
		
		return retJSON;
	}

}	//End class robot





