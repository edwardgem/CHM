////////////////////////////////////////////////////
//	Copyright (c) 2017, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	ObdAjax.java
//	Author:	ECC
//	Date:	04/15/17
//	Description:
//		Implementation of Big Data servlet.
//
//	Modification:
//
////////////////////////////////////////////////////////////////////

package mod.bots;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.StringReader;
import java.net.URL;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.apache.commons.lang.StringEscapeUtils;
import org.apache.log4j.Logger;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.xml.sax.InputSource;

import mod.mfchat.PrmMtgParticipants;
import net.sf.json.JSONObject;
import oct.codegen.robot;
import oct.codegen.robotManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;
import util.PrmLog;
import util.PrmMtgConstants;
import util.StringUtil;
import util.Util;
import util.XML;

public class ObdAjax extends HttpServlet {
	static final long serialVersionUID = 10170418L;
	static Logger l;
	
	private static robotManager rbMgr;
	
	public static final String EVENT_MESSAGE_TAG	= "Message";
	public static final String EVENT_RETURN_TAG		= "Result";
	
	public static final String OP_FIRE				= "fire";
	public static final String OP_GET_INFO			= "getInfo";
	public static final String OP_CHECK_NODE		= "ckNode";
	public static final String OP_DEPLOY			= "deploy";
	
	public static final String OP_BOTS_CLONE		= "clone";
	
	public static final String TAG_EXPR				= "Expr";
	
	public static final String USER_ORGNAME			= "user";
	private static final String LOCALHOST 			= "localhost";

	//private static final int PING_TIMEOUT = 3000;
	private int pstuserId = -1;
	private PstUserAbstractObject pstuser = null;
	
	static {
		l = PrmLog.getLog();
		try {
			rbMgr = robotManager.getInstance();
		}
		catch (PmpException e) {}
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException
	{
System.out.println(">> ObdAjax.doGet() >>>>>>>>>>>>>>>>>");
		// Get the current session and pstuser 
		String op	= request.getParameter("op");
		pstuser = null;
		HttpSession httpSession = request.getSession(false);
		// Verify that this is indeed the user
		// Check valid user
		if (httpSession != null)
			pstuser = (PstUserAbstractObject)httpSession.getAttribute(PrmMtgConstants.PSTUSER);
		if (pstuser==null && !op.equals(OP_GET_INFO))
		{
			l.error("No valid user");
			createXml(EVENT_MESSAGE_TAG, PrmMtgConstants.USERTIMEOUT, response);
			return;
		}
		//String s;
		
		if (pstuser != null)
			pstuserId = pstuser.getObjectId();
		
		robot rbObj;
		String xml;
		
		// retrieve parameters
		String botName = request.getParameter("bot");
		String expr = request.getParameter("expr");
		String node = request.getParameter("node");
		String others = request.getParameter("oth");		// other parameters (e.g. charts)
		String orgName = request.getParameter("org");		// ECC: temp during migration
		
		if (expr != null)
			expr = StringEscapeUtils.unescapeHtml(expr);
		
System.out.println("op="+ op);
System.out.println("botName=" + botName);
System.out.println("orgName=" + orgName);
System.out.println("node=" + node);
System.out.println("expr="+ expr);
System.out.println("oth="+ others);

		//////////////////////////////////////////////////////////
		// OP_FIRE
		// perform the eval() function on this node and get the result back
		if (op.equals(OP_FIRE)) {
			try {
				// no need get expr if it is not in the request parameter because
				// at each node there is the XML in the robot object that contains default expr
				rbObj = (robot) rbMgr.get(pstuser, botName);
		
    			// ECC20170822 change eval implementation from OmsOrganization to robot class
				// because every robot is not the same
    			String retJSON = rbObj.eval(expr, others, node);
    			retJSON = packageEvalJson(retJSON);
				
				l.info("ObdAjax.doGet(): completed eval()");
				createXml(EVENT_RETURN_TAG, retJSON, response);
			}
			catch (Exception e) {
				l.info("ObdAjax.doGet(): failed to fire - " + e.getMessage());
				createXml(EVENT_MESSAGE_TAG, "(Error) " + e.getMessage(), response);
			}
			return;
		}
		
		
		//////////////////////////////////////////////////////////
		// OP_DEPLOY
		// clone the bot to the specified node
		else if (op.equals(OP_DEPLOY)) {
			try {
				rbObj = (robot) rbMgr.get(pstuser, botName);
				xml = rbObj.getRawAttributeAsUtf8("Content");
				
				//String botInXml = rbObj.getAttributesXML();
				int newBotId;
				
				if (xml != null) {
					Element root = getXMLroot(xml);
					if (StringUtil.isNullOrEmptyString(node))
						node = LOCALHOST;
					
					String wsURI = getNodeWS(node);
					
					if (!wsURI.contains(LOCALHOST) && !node.contains(LOCALHOST)) {
						String authCode = XML.getOneNodeAuthCode(root, node);
					
						// authCode: testUser::testPswd
						String [] sa = authCode.split("::");
						String uname = sa[0];
						String pswd  = sa[1];
						
						// call Webservice to clone if necessary
						System.out.println("-- clone robot to: " + wsURI);
						newBotId = rbMgr.cloneToDomain(uname, pswd, wsURI, rbObj);
						System.out.println("-- foreign clone done [" + newBotId + "]");
					}
					else {
						newBotId = rbObj.getObjectId();
					}
					
	    			Map<String, String> domPart = new HashMap<String, String>();
	    			domPart.put("botId", String.valueOf(newBotId));
	    			domPart.put("result", "Bot [" + newBotId + "] deployed");
	    			JSONObject json = JSONObject.fromObject(domPart);
					
					l.info("ObdAjax.doGet(): completed deploy()");
					createXml(EVENT_RETURN_TAG, json.toString(), response);
				}
			}
			catch (Exception e) {
				l.info("ObdAjax.doGet(): failed to deploy - " + e.getMessage());
				createXml(EVENT_MESSAGE_TAG, "(Error) " + e.getMessage(), response);
			}
			
			return;
		}
		
		
		//////////////////////////////////////////////////////////
		// OP_CHECK_NODE
		else if (op.equals(OP_CHECK_NODE)) {
			
			String ip = request.getParameter("ip");
			int idx = ip.indexOf("//");
			if (idx != -1)
				ip = ip.substring(idx+2);		// skip http://
			l.info("checking " + ip);
			Process p1 = java.lang.Runtime.getRuntime().exec("ping -n 3 " + ip);
			int returnVal = 2;
			try {returnVal = p1.waitFor();}
			catch (InterruptedException e) {}
			boolean bReachable = (returnVal==0);
			//System.out.println("   done checking " + ip);
			
			if (!bReachable) {
				createXml(EVENT_MESSAGE_TAG, "(Error) Server not responding", response);
	        }
			else {
				createXml(EVENT_MESSAGE_TAG, "Ready", response);
			}
			return;
		}
		
		
		//////////////////////////////////////////////////////////
		// OP_BOTS_CLONE
		// clone a robot from a robot model locally
		//
		else if (op.equals(OP_BOTS_CLONE)) {
			String dispName="", imgFileSrc=null;
			try {
				String newName = getNewBotVersion(botName + "-" + pstuserId);
				rbObj = (robot) rbMgr.create(pstuser, newName);
				PstAbstractObject parent = rbMgr.get(pstuser, botName);
				
				// displace name
				dispName = parent.getOption("ABBRV");						// DRG
				if (StringUtil.isNullOrEmptyString(dispName)) {
					dispName = botName;										// H-1701
				}
				dispName += newName.substring(newName.lastIndexOf('-'));	// DRG-003 or H-1701-003
				
				// image file
				imgFileSrc = parent.getStringAttribute("PictureFile");
				
				rbObj.setAttribute("ParentID", String.valueOf(parent.getObjectId()));
				rbObj.setAttribute("Owner", String.valueOf(pstuserId));
				rbObj.setAttribute("CreatedDate", new Date());
				rbObj.setAttribute("DisplayName", dispName);
				rbObj.setRawAttributeUtf("Content", parent.getRawAttributeAsUtf8("Content"));
				
				rbMgr.commit(rbObj);
				
			} catch (PmpException e) {
				e.printStackTrace();
				createXml(EVENT_MESSAGE_TAG, "(Error) Failed to clone robot model: " + botName, response);
				return;
			}
			
			// return JSON
			Map<String, String> domPart = new HashMap<String, String>();
			domPart.put("botName", dispName);
			domPart.put("imgSrc", imgFileSrc);
			JSONObject json = JSONObject.fromObject(domPart);
			createXml(EVENT_RETURN_TAG, json.toString(), response);

			return;
		}
		
		
		//////////////////////////////////////////////////////////
		// OP_GET_INFO
		else if (op.equals(OP_GET_INFO)) {
			// return a String of that info
			String infoType = request.getParameter("type");
			String res = "";
			PrintWriter out = response.getWriter(); 
			
			if (infoType.equalsIgnoreCase("wsuri")) {
				// get the WS URI
				res = Util.getPropKey("pst", "WS_URI");
			}
			out.print(res);
			out.close();
			
			System.out.println("OP_GET_INFO returns: " + res);
			return;
		}

		
		//////////////////////////////////////////////////////////
		else {
			l.error("Opcode undefined: " + op);
		}
		return;
	}

	/**
	 * Because if we are just running local eval without going through the multi-node
	 * code in robot.eval(), then the JSON is not formatted right (missing {} and [])
	 * and without the "evals" keyword in front, so we fix it here.
	 * 
	 * @param retJSON
	 * @return
	 */
	private String packageEvalJson(String retJSON) {
		if (!retJSON.startsWith("[") && !retJSON.startsWith("{")) {
			List<JSONObject> domainsArray = new ArrayList<JSONObject>();
			Map<String, String> domPart = new HashMap<String, String>();
			
			domPart.put("domain", LOCALHOST);		// assume it is localhost
			domPart.put("result", retJSON);
			JSONObject json = JSONObject.fromObject(domPart);
			domainsArray.add(json);
			
			Map<String, Object> domMap = new HashMap<String, Object>();
			domMap.put("evals", domainsArray);
			
			json = JSONObject.fromObject(domMap);
			retJSON = json.toString();
		}
		return retJSON;
	}

	public static String getNodeWS(String node) {
		// get the WS URL from the node's PRM servlet
		String res = "";
		if (!node.startsWith("http")) node = "http://" + node;
		
		try {
			URL url = new URL(node + "/servlet/ObdAjax?op=getInfo&type=wsuri" );
System.out.println("getNodeWS(): " + url);
			BufferedReader in = new BufferedReader(new InputStreamReader(url.openStream()));
			res = in.readLine();
			in.close();
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		return res;
	}

	private Element getXMLroot(String xml) 
		throws Exception 
	{
		xml = xml.replaceAll("&", "&amp;");		// escape & sign in the condition expression &\\s+
		xml = xml.replaceAll("<=", "&lt;&#61;");
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		DocumentBuilder builder = factory.newDocumentBuilder();
		InputSource is = new InputSource(new StringReader(xml));
		Document document = builder.parse(is);
		
		Element root = document.getDocumentElement();
		return root;
	}

	private String getNewBotVersion(String prefix)
		throws PmpException
	{
		int idx = 1;
		String idxS, ver;
		
		// get all this user's robot of this model
		int [] ids = rbMgr.findId(pstuser, "om_acctname='" + prefix + "%'");
		if (ids.length > 0) {
			PstAbstractObject [] rbArr = rbMgr.get(pstuser, ids);
			Util.sortName(rbArr);
			String s = rbArr[rbArr.length-1].getObjectName();
			s = s.substring(s.lastIndexOf('-')+1);
			idx = Integer.parseInt(s) + 1;
		}
		
		idxS = String.format("%03d", idx);
		ver = prefix + "-" + idxS;
		System.out.println("++ getNewBotVersion = " + ver);
		
		return ver;
	}

	private static void createXml(String tag, String msg, HttpServletResponse response)
		throws IOException
	{
		PrmMtgParticipants.initXml(response);
		PrmMtgParticipants.createXmlChild(tag, msg, response);
		response.getWriter().write(PrmMtgConstants.XML_RESPONSE_CL);
	}
}
