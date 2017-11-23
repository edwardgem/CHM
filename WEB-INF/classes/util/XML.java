/** utility class */
package util;

import java.io.StringReader;
import java.text.SimpleDateFormat;
import java.util.ArrayList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import oct.omm.client.OmsAttribDef;
import oct.omm.client.OmsSession;
import oct.omm.common.OmsAttribVal;
import oct.omm.common.OmsObject;
import oct.omm.util.OmsXMLDriver;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;

public class XML
{ /** create a new XML reader */
	
	final static private String TAG_DOMAIN		= "Domain";
	final static private String TAG_URL			= "URL";
	final static private String TAG_AUTH		= "Authcode";

	//final static private String TAG_ATTR		= OmsXMLDriver.TAG_ATTR;
	public final static String TAG_ONEATTR		= OmsXMLDriver.TAG_ONEATTR;
	final static private String TAG_ATTRNAME	= OmsXMLDriver.TAG_ATTRNAME;
	final static private String TAG_ATTRVAL		= OmsXMLDriver.TAG_ATTRVAL;
	
	final static private SimpleDateFormat df	= OmsAttribVal.df;
	

  final public static org.xml.sax.XMLReader makeXMLReader()
  	throws Exception
  	{ final javax.xml.parsers.SAXParserFactory saxParserFactory
  		= javax.xml.parsers.SAXParserFactory.newInstance();

  	  final javax.xml.parsers.SAXParser saxParser = saxParserFactory.newSAXParser();

  	  final org.xml.sax.XMLReader parser = saxParser.getXMLReader();

  	  return parser;
  	}
  
	
	/**
	 * get the XML element tag value, assume single value
	 * @param tagName
	 * @param element
	 * @return
	 */
	public static String getXMLString(String tagName, Element element) {
		NodeList list = element.getElementsByTagName(tagName);
		if (list != null && list.getLength() > 0) {
			NodeList subList = list.item(0).getChildNodes();

			if (subList != null && subList.getLength() > 0) {
				return subList.item(0).getNodeValue();
			}
		}

		return null;
	}

	/**
	 * this only gets the URL address part, ignoring the Webservice API
	 * @param nodeList
	 * @param root
	 * @param tag
	 */
	public static void getNodeIpAddr(ArrayList <String> nodeList, Element root, String tag) {
		NodeList list = root.getElementsByTagName(tag);
		int totalNodesInXML = list.getLength();
		String url;
		
		
		if (list != null && totalNodesInXML > 0) {
			Element oneDomain;
			
			for (int i=0; i<list.getLength(); i++) {
				oneDomain = (Element) list.item(i).getChildNodes();	// one domain
	
				if ((url = getOneNodeIpAddr(oneDomain)) != null)
					nodeList.add(url);
			}
		}
	}	// END: getNodeIpAddr()
	
	public static String getOneNodeIpAddr(Element aDomain)
	{
		String url = null;
		int idx;
		
		if (aDomain != null) {
			url = XML.getXMLString(TAG_URL, aDomain);
			idx = url.indexOf("//");
			if (idx != -1)
				url = url.substring(idx+2);					// skip http://
			else if (url.charAt(0) == '/')
				url = url.substring(1);						// skip initial /
			
			if ((idx = url.indexOf('/')) != -1) {
				url = url.substring(0, idx).trim();			// just the IP address
			}
		}
		return url;
	}

	public static void getNodeAuthcode(ArrayList <String> nodeList, Element root, String tag)
			throws PmpException
	{
		getNodeAuthcode(nodeList, root, tag, true);
	}
	
	public static void getNodeAuthcode(ArrayList <String> nodeList, Element root, String tag, boolean bCheck)
		throws PmpException
	{
		NodeList list = root.getElementsByTagName(tag);
		int totalNodesInXML = list.getLength();
		String authStr;
		
		if (list != null && totalNodesInXML > 0) {
			Element oneDomain;
			
			for (int i=0; i<list.getLength(); i++) {
				oneDomain = (Element) list.item(i).getChildNodes();	// one domain
	
				if (oneDomain != null) {
					authStr = OmsXMLDriver.getXMLString(TAG_AUTH, oneDomain);
					
					// get username and password strings
					if (bCheck) {
						String [] sa = authStr.split("::");
						if (sa.length != 2) {
							throw new PmpException("AUTHCODE must contain username and password separated by (::) " + authStr);
						}
					}
					
					nodeList.add(authStr);
				}
			}
		}
	}	// END: getNodeAuthcode()

	public static String getOneNodeAuthCode(Element root, String domainURL)
	{
		NodeList list = root.getElementsByTagName(TAG_DOMAIN);
		int totalDomainsInXML = list.getLength();
		String urlStr, authStr;
		
		if (list != null && totalDomainsInXML > 0) {
			Element oneDomain;
			
			for (int i=0; i<list.getLength(); i++) {
				oneDomain = (Element) list.item(i).getChildNodes();	// one domain
				
				if (oneDomain != null) {
					urlStr = OmsXMLDriver.getXMLString(TAG_URL, oneDomain);
					if (domainURL.equals(urlStr)) {
						// found the right domain
						authStr = OmsXMLDriver.getXMLString(TAG_AUTH, oneDomain);
						return authStr;
					}
				}
			}	// for loop of all domains
		}
		
		return null;
	}


	/**
	 * this gets the complete text value of URL including the Webservice API
	 * @param nodeList
	 * @param root
	 * @param tag
	 */
	public static void getNodeArray(ArrayList <String> nodeList, Element root, String tag) {
		NodeList list = root.getElementsByTagName(tag);
		int totalNodesInXML = list.getLength();
		String url;
		
		final String TAG_URL = "URL";
		
		if (list != null && totalNodesInXML > 0) {
			Element oneDomain;
			
			for (int i=0; i<list.getLength(); i++) {
				oneDomain = (Element) list.item(i).getChildNodes();	// one domain
	
				if (oneDomain != null) {
					url = getXMLString(TAG_URL, oneDomain).trim();
					nodeList.add(url);
				}
			}
		}
	}	// END: getNodeArray()
	
	public static void setObjectFromXml(
			PstUserAbstractObject uObj, PstManager mgr, PstAbstractObject resultObj, String xml)
			throws Exception {
		
		OmsSession sess = uObj.getSession();

		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		DocumentBuilder builder = factory.newDocumentBuilder();
		InputSource is = new InputSource(new StringReader(xml));
		Document document = builder.parse(is);
		
		Element root = document.getDocumentElement();
		Element oneAttr;		// oneValue;
		OmsAttribDef attrObj;
		String attrName, attrValue;
		int iType;
		
		NodeList attributesList = root.getElementsByTagName(TAG_ONEATTR);
		NodeList valueList, subList;
		
		if (attributesList != null)
		for (int i=0; i<attributesList.getLength(); i++) {
			oneAttr = (Element) attributesList.item(i).getChildNodes();	// one attribute
			
			attrName = getXMLString(TAG_ATTRNAME, oneAttr);
			attrObj = new OmsAttribDef(sess, attrName);
			iType = attrObj.getType();
			System.out.println("setObjectFromXml() attrName: " + attrName + " (" + iType + ")");
			
			// value can be multiple
			valueList = oneAttr.getElementsByTagName(TAG_ATTRVAL);

			for (int j=0; j<valueList.getLength(); j++) {

				subList = valueList.item(j).getChildNodes();
				if (subList==null || subList.getLength()<=0) {
					continue;
				}
				attrValue = subList.item(0).getNodeValue();

				
				//oneValue  = (Element) valueList.item(j);
				//attrValue = getXMLString(TAG_ATTRVAL, oneValue);
				System.out.println("   value=" + attrValue);
				
				switch (iType) {
					case OmsObject.OMS_INT_ATT:
						resultObj.appendAttribute(attrName, new Integer(attrValue));
						break;
						
					case OmsObject.OMS_FLOAT_ATT:
						resultObj.appendAttribute(attrName, new Float(attrValue));
						break;
						
					case OmsObject.OMS_STRING_ATT:
						resultObj.appendAttribute(attrName, attrValue);
						break;
						
					case OmsObject.OMS_DATE_ATT:
						resultObj.appendAttribute(attrName, df.parse(attrValue));
						break;
						
					case OmsObject.OMS_RAW_ATT:
						resultObj.setRawAttributeUtf(attrName, attrValue);
						break;
						
					default:
						break;
				}	// END: switch
			}	// END: for
			mgr.commit(resultObj);
		}

	}
}
