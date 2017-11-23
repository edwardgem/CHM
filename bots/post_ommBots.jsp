<%@ page contentType="text/html; charset=utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%
//
//	Copyright (c) 2017, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:		post_ommBots.java
//	Author: 	ECC
//	Date:		04/03/17
//	Description:	Post page for ommBots.jsp to save changes on clone robot.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ page import = "javax.xml.parsers.*" %>
<%@ page import = "org.w3c.dom.*" %>
<%@ page import = "org.xml.sax.SAXException" %>
<%@ page import = "org.xml.sax.InputSource" %>
<%@ page import = "org.apache.commons.lang.StringEscapeUtils" %>

<%@ page import = "javax.xml.transform.OutputKeys" %>
<%@ page import = "javax.xml.transform.Transformer" %>
<%@ page import = "javax.xml.transform.TransformerFactory" %>
<%@ page import = "javax.xml.transform.dom.DOMSource" %>
<%@ page import = "javax.xml.transform.stream.StreamResult" %>

<%@ page import = "javax.xml.xpath.XPathFactory" %>
<%@ page import = "javax.xml.xpath.XPathExpression" %>
<%@ page import = "javax.xml.xpath.XPathConstants" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%!
	final int MAX_NODES		= 10;
	
	final String STR_NOTI_SERVICE		= "/NotificationManager/services/";
	
	final String EXT_XML				= ".xml";
	final String TAG_DOMAIN				= "Domain";
	final String TAG_URL				= "URL";				// webservice address
	final String TAG_AUTH				= "Authcode";			// authorization code to access webservice
	final String TAG_XML				= "XML";				// XML tag
	final String TAG_EXPR				= "Expr";
	final String TAG_ALPHA				= "Alpha";
	final String TAG_LAMBDA				= "Lambda";
	final String TAG_THETA				= "Theta";
	final String TAG_SLIMIT				= "Size_Limit";
	final String TAG_TLIMIT				= "Time_Limit";
	
	final String MIN_XML				= "<Organization><Name>xxx</Name></Organization>";

	public void removeDomEmptySpace(Element root)
	{
		// XPath to find empty text nodes.
		try {
			XPathFactory xpathFactory = XPathFactory.newInstance();
			XPathExpression xpathExp = xpathFactory.newXPath().compile(
			        "//text()[normalize-space(.) = '']");  
			NodeList emptyTextNodes = (NodeList) 
			        xpathExp.evaluate(root, XPathConstants.NODESET);
		
			// Remove each empty text node from document.
			for (int i = 0; i < emptyTextNodes.getLength(); i++) {
			    Node emptyTextNode = emptyTextNodes.item(i);
			    emptyTextNode.getParentNode().removeChild(emptyTextNode);
			}
		}
		catch (Exception e) {}
	}
%>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	
	
	// create or edit distribution list
	if ((pstuser instanceof PstGuest))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	robotManager rbMgr = robotManager.getInstance();

	// save node information
	String s;
	PstAbstractObject o;
	
	// handle delete (recycle) a robot
	s = request.getParameter("del");
	if (!StringUtil.isNullOrEmptyString(s)) {
		o = rbMgr.get(pstuser, Integer.parseInt(s));
		rbMgr.delete(o);
		String parentIdS = o.getStringAttribute("ParentID");
		System.out.println("Recycled robot [" + s + "]");
		response.sendRedirect("ommBots.jsp?id=" + parentIdS);
		return;
	}
	
	// handle change bot icon
	s = request.getParameter("chi");
	if (!StringUtil.isNullOrEmptyString(s)) {
		String botFile = "robot" + s + ".jpg";			// e.g. robot3.jpg
		s = request.getParameter("id");
		o = rbMgr.get(pstuser, Integer.parseInt(s));
		o.setAttribute("PictureFile", botFile);
		rbMgr.commit(o);
		String parentIdS = o.getStringAttribute("ParentID");
		s = request.getParameter("idx");
		response.sendRedirect("ommBots.jsp?id=" + parentIdS + "&idx=" + s);
		return;
	}
	
	s = request.getParameter("SaveOnly");
	boolean bSaveOnly = (!StringUtil.isNullOrEmptyString(s) && s.equals("true"));
	
	boolean isReadOnly = request.getParameter("isReadOnly").equals("true");
	
	int cloneId = Integer.parseInt(request.getParameter("cloneId"));
	robot rbObj = (robot) rbMgr.get(pstuser, cloneId);
	
	String modelId=null, selectIdxS=null;
	
	
	if (!isReadOnly) {
		String cloneBotName = request.getParameter("cloneBotName").trim();
		String cloneDesc = request.getParameter("cloneDesc").trim();
		modelId = rbObj.getStringAttribute("ParentID");
		
		selectIdxS = request.getParameter("selectIdx");
		
	
		s = request.getParameter("TotalXmlNodes");
		if (StringUtil.isNullOrEmptyString(s)) s = "0";
		int totalXmlNodes = Integer.parseInt(s);
		
		s = request.getParameter("XmlNodesOnPage");
		if (StringUtil.isNullOrEmptyString(s)) s = "0";
		int totalNodesOnPage = Integer.parseInt(s);
	
		
		//////////////////////////////
		// save XML
		
		String addr, auth, xmlStr;
		String newAddrStr = "";
		Element urlNode, authNode, xmlNode, aDomain, dom;
	
		ArrayList <Element> removeList = new ArrayList<Element>();
		
		String xml = rbObj.getRawAttributeAsUtf8("Content");
	
		if (xml != null) {
			xml = xml.replaceAll("&", "&amp;");		// escape & sign in the condition expression &\\s+
			xml = xml.replaceAll("<=", "&lt;&#61;");
		}
		else {
			xml = MIN_XML.replace("xxx", rbObj.getObjectName());
		}
			
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		DocumentBuilder builder = factory.newDocumentBuilder();
		InputSource is = new InputSource(new StringReader(xml));
		Document document = builder.parse(is);
		
		factory.setValidating(true);
		factory.setIgnoringElementContentWhitespace(true);
		
		Element root = document.getDocumentElement();
		
		// remove all domain in the old XML content and then add all domain on the form
		NodeList list = root.getElementsByTagName(TAG_DOMAIN);
		if (list != null && list.getLength() > 0) {
			for (int i=0; i<list.getLength(); i++) {
				aDomain = (Element) list.item(i);
				removeList.add(aDomain);
			}
		}
	
		// add nodes on the form
		ArrayList <String> formAddrList = new ArrayList <String> ();
		for (int i=1; i<=totalNodesOnPage; i++) {
			addr = request.getParameter("Node" + i);				// complete address
			if (StringUtil.isNullOrEmptyString(addr)) {
				continue;
			}
			
			// URL
			aDomain = document.createElement(TAG_DOMAIN);
			urlNode = document.createElement(TAG_URL);
			urlNode.appendChild(document.createTextNode(addr));
			aDomain.appendChild(urlNode);
			
			// AuthCode
			auth = request.getParameter("Auth" + i);
			authNode = document.createElement(TAG_AUTH);			// need to specify authorization access
			authNode.appendChild(document.createTextNode(auth));
			aDomain.appendChild(authNode);
			
			// XML
			for (int j=0; j<removeList.size(); j++) {
				dom = removeList.get(j);
				if (addr.equals(XML.getXMLString(TAG_URL, dom))) {
					xmlStr = XML.getXMLString(TAG_XML, dom);
					if (!StringUtil.isNullOrEmptyString(xmlStr)) {
						// found match, save the XML info
						xmlNode = document.createElement(TAG_XML);
						xmlNode.appendChild(document.createTextNode(xmlStr));
						aDomain.appendChild(xmlNode);
					}
					break;
				}
			}
	
			root.appendChild(aDomain);
		}
		
		// remove the deleted domains now
		for (Element e : removeList) {
			root.removeChild(e);
		}
	
		
		// save other values: expression, alpha, etc.
		String [] sA1 = {"Expr", "Alpha", "Lambda", "Theta", "SizeLimit", "TimeLimit"};
		String [] sA2 = {TAG_EXPR, TAG_ALPHA, TAG_LAMBDA, TAG_THETA, TAG_SLIMIT, TAG_TLIMIT};
		Node node;
		
		for (int i=0; i<sA1.length; i++) {
			s = request.getParameter(sA1[i]);
			if (!StringUtil.isNullOrEmptyString(s)) {
				node = root.getElementsByTagName(sA2[i]).item(0);	// there is only one item for Expr
				if (node != null)
					node.setTextContent(s);
				else {
					// insert new
					dom = document.createElement(sA2[i]);
					dom.appendChild(document.createTextNode(s));
					root.appendChild(dom);
				}
			}
		}
		
		removeDomEmptySpace(root);
	
		
		// write XML
		Transformer transformer =  TransformerFactory.newInstance().newTransformer();
	    transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
	    transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
	    transformer.setOutputProperty(OutputKeys.INDENT, "yes");
	    transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "3");
	    
	    
	    // save xml to robot
	    StringWriter writer = new StringWriter();
	    transformer.transform(new DOMSource(root), new StreamResult(writer));
	    xml = writer.getBuffer().toString();
	    rbObj.setRawAttributeUtf("Content", xml);
	    
	    rbObj.setAttribute("DisplayName", cloneBotName);
	    rbObj.setRawAttributeUtf("Description", cloneDesc);
	    
	    rbMgr.commit(rbObj);
	}

	// for submit, it should redirect to the domain map
	if (bSaveOnly) {
		response.sendRedirect("ommBots.jsp?id=" + modelId + "&idx=" + selectIdxS);
	}
	else {
		// deploy and check readiness of each node
		response.sendRedirect("botsCanvas.jsp?id=" + cloneId);
	}

%>
